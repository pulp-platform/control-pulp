#![no_main]
#![no_std]

use core::panic::PanicInfo;

use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY2, DUMMY3, DUMMY4, DUMMY5, DUMMY6])]
mod app {

    use pulp_device::exit;
    use pulp_print::{print, print_nr, println, print_nr_only, Format};

    use riscv_monotonic::*;

    const max_runs: usize = 1000;

    #[cfg(feature = "timer_measurement")]
    macro_rules! get_ticks {
        () => {
            riscv_clic::peripheral::SYST::get_counter_lo()
        };
    }
    #[cfg(not(feature = "timer_measurement"))]
    macro_rules! get_ticks {
        () => {
            riscv_clic::register::mcycle::read() as u32
        };
    }

    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1>;

    #[shared]
    struct Shared {
        pt1_last_schedule: u32,
    }

    #[local]
    struct Local {
        pt1_last_start: u32,
        pt1_nr_of_runs: u32,
        pt1_period: u32,
        pt1_measured_periods: [u32; max_runs],
    }

    #[init]
    fn init(cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        // enable cycle counting
        unsafe {
            riscv_clic::register::mcountinhibit::clear_cy();
        }

        task0::spawn().unwrap();


        (
            Shared {
                pt1_last_schedule: 0,
            },
            Local {
                pt1_last_start: 0,
                pt1_nr_of_runs: 0,
                pt1_period: 2000,
                pt1_measured_periods: [0; max_runs],
            },
            init::Monotonics(mono),
        )
    }

    #[task(shared = [pt1_last_schedule], local = [], priority = 1)]
    fn task0(mut cx: task0::Context) {
        let now = get_ticks!();
        print_nr!("now", now, Format::Dec);

        // start periodic task
        let start_at = now + 4000;
        let start_instant = fugit::Instant::<u32, 1, 1>::from_ticks(start_at);
        periodic_task_1::spawn_at(start_instant).ok();

        cx.shared.pt1_last_schedule.lock(|pt1_last_schedule| {
            *pt1_last_schedule = start_at;
        });
    }

    #[task(shared = [pt1_last_schedule], local = [pt1_last_start, pt1_nr_of_runs, pt1_period, pt1_measured_periods], priority = 1)]
    fn periodic_task_1(mut cx: periodic_task_1::Context) {

        // end program after measurement
        if *cx.local.pt1_nr_of_runs == max_runs as u32 + 1 {
            exit(0);
            loop{};
        }

        // calculate jitter
        let current_run = *cx.local.pt1_nr_of_runs as usize;
        let now = get_ticks!();
        let measured_period = now - *cx.local.pt1_last_start;
        if current_run != 0 {
            (*cx.local.pt1_measured_periods)[current_run - 1] = measured_period;
        }
        *cx.local.pt1_last_start = now;

        print_nr!("Current Run:", current_run, Format::Dec);

        // output measured periods, as soon as array is full
        if *cx.local.pt1_nr_of_runs == max_runs as u32 {

            print!("[");
            for measurement in *cx.local.pt1_measured_periods {
                print_nr_only!(measurement, Format::Dec);
                print!(", ");
            }
            println!("]");

        }

        // reschedule task to make it periodic
        let start_at = cx
            .shared
            .pt1_last_schedule
            .lock(|pt1_last_schedule| *pt1_last_schedule + *cx.local.pt1_period);
        let start_instant = fugit::Instant::<u32, 1, 1>::from_ticks(start_at);
        periodic_task_1::spawn_at(start_instant).ok();
        cx.shared.pt1_last_schedule.lock(|pt1_last_schedule| {
            *pt1_last_schedule = start_at;
        });
        *cx.local.pt1_nr_of_runs += 1;
    
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
fn _mp_hook() -> bool {
    return true;
}

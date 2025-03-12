#![no_main]
#![no_std]

use core::panic::PanicInfo;
use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY2, DUMMY3, DUMMY4, DUMMY5])]
mod app {

    use pulp_device::exit;
    use pulp_print::{print_nr, Format};

    use riscv_monotonic::*;

    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1>;

    #[shared]
    struct Shared {
        task_1_started: usize,
        task_2_started: usize,
        high_prio_lock_time: usize,
        task_4_started: usize,
    }

    #[local]
    struct Local {}

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
                task_1_started: 0,
                task_2_started: 0,
                high_prio_lock_time: 0,
                task_4_started: 0,
            },
            Local {},
            init::Monotonics(mono),
        )
    }

    #[task(shared = [task_1_started, task_2_started, task_4_started, high_prio_lock_time], local = [], priority = 1)]
    fn task0(mut cx: task0::Context) {
        // Task 1 (Hardware)

        //println!("Start Task 1");

        let time_task_1_pended = riscv_clic::register::mcycle::read();
        riscv_clic::peripheral::CLIC::pend(pulp_device::interrupt::DUMMY1);
        unsafe { rtic::export::wfi() }

        let mut task_1_started_local = 0;

        cx.shared.task_1_started.lock(|task_1_started| {
            task_1_started_local = *task_1_started;
        });

        let difference = task_1_started_local - time_task_1_pended;

        print_nr!("Hardware Task Spawn", difference, Format::Dec);
        //print_nr!("time_task_1_pended", time_task_1_pended, Format::Hex);
        //print_nr!("task_1_started_local", task_1_started_local, Format::Hex);

        // Task 2 (Software)

        //println!("Start Task 2");

        let time_task_2_pended = riscv_clic::register::mcycle::read();
        task2::spawn().ok();
        unsafe { rtic::export::wfi() }

        let mut task_2_started_local = 0;

        cx.shared.task_2_started.lock(|task_2_started| {
            task_2_started_local = *task_2_started;
        });

        let difference = task_2_started_local - time_task_2_pended;

        print_nr!("Software Task Spawn", difference, Format::Dec);
        //print_nr!("time_task_2_pended", time_task_2_pended, Format::Hex);
        //print_nr!("task_2_started_local", task_2_started_local, Format::Hex);

        // Task 3 (Locking)

        //println!("Start Locking Test");

        let time_before_lock = riscv_clic::register::mcycle::read();
        cx.shared.high_prio_lock_time.lock(|high_prio_lock_time| {
            *high_prio_lock_time = 0;
        });
        let time_after_lock = riscv_clic::register::mcycle::read();

        let difference = time_after_lock - time_before_lock;

        print_nr!("Locking Low Prio", difference, Format::Dec);

        task3::spawn().ok();
        unsafe { rtic::export::wfi() }

        // Task 4 (Multiple Software Tasks with the same prio)

        //println!("Run Task 4");

        let time_task_4_pended = riscv_clic::register::mcycle::read();
        task4_0::spawn().ok();
        unsafe { rtic::export::wfi() }

        let mut task_4_started_local = 0;

        cx.shared.task_4_started.lock(|task_4_started| {
            task_4_started_local = *task_4_started;
        });

        let difference = task_4_started_local - time_task_4_pended;
        print_nr!(
            "Software Task Spawn, multiple task with same prio",
            difference,
            Format::Dec
        );
        //print_nr!("time_task_4_pended", time_task_4_pended, Format::Hex);
        //print_nr!("task_4_started_local", task_4_started_local, Format::Hex);

        let due_time = fugit::Instant::<u32, 1, 1>::from_ticks(4000);
        let time_task_5_schedule_start = riscv_clic::register::mcycle::read();
        task5::spawn_at(due_time).ok();
        let time_task_5_schedule_end = riscv_clic::register::mcycle::read();
        let difference = time_task_5_schedule_end - time_task_5_schedule_start;

        print_nr!("Scheduling time for timer task", difference, Format::Dec);

        exit(0);
    }

    #[task(shared = [task_1_started], local = [], binds = DUMMY1, priority = 2)]
    fn task1(mut cx: task1::Context) {
        let time_task_1_started = riscv_clic::register::mcycle::read();

        //println!("In Task 1");

        cx.shared.task_1_started.lock(|task_1_started| {
            *task_1_started = time_task_1_started;
        });
    }

    #[task(shared = [task_2_started], local = [], priority = 2)]
    fn task2(mut cx: task2::Context) {
        let time_task_2_started = riscv_clic::register::mcycle::read();

        //println!("In Task 2");

        cx.shared.task_2_started.lock(|task_2_started| {
            *task_2_started = time_task_2_started;
        });
    }

    #[task(shared = [high_prio_lock_time], local = [], priority = 3)]
    fn task3(mut cx: task3::Context) {
        let time_before_lock = riscv_clic::register::mcycle::read();
        cx.shared.high_prio_lock_time.lock(|high_prio_lock_time| {
            *high_prio_lock_time = 0;
        });
        let time_after_lock = riscv_clic::register::mcycle::read();

        cx.shared.high_prio_lock_time.lock(|high_prio_lock_time| {
            *high_prio_lock_time = time_after_lock - time_before_lock;
        });

        //println!("In Task 3");

        let difference = time_after_lock - time_before_lock;

        print_nr!("Locking High Prio", difference, Format::Dec);
    }

    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_0(mut cx: task4_0::Context) {
        let time_task_4_started = riscv_clic::register::mcycle::read();

        //println!("In Task 4");
        //print_nr!("time_task_4_started in task 4", time_task_4_started, Format::Hex);

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = time_task_4_started;
        });
    }

    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_1(mut cx: task4_1::Context) {
        //let time_task_4_started = riscv_clic::register::mcycle::read();

        //println!("In Task 4");

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = 1;
        });
    }
    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_2(mut cx: task4_2::Context) {
        //let time_task_4_started = riscv_clic::register::mcycle::read();

        //println!("In Task 4");

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = 2;
        });
    }

    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_3(mut cx: task4_3::Context) {
        //let time_task_4_started = riscv_clic::register::mcycle::read();

        //println!("In Task 4");

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = 3;
        });
    }

    #[task(shared = [], local = [], priority = 5)]
    fn task5(_: task5::Context) {
        let time_task_5_started = riscv_clic::peripheral::SYST::get_counter_lo();

        let time_timer_fired = 4000;

        let difference = time_task_5_started - time_timer_fired;

        print_nr!("Start time for timed task", difference, Format::Dec);
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

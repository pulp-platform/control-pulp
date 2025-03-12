#![no_main]
#![no_std]

use core::panic::PanicInfo;

use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY2, DUMMY1, DUMMY0])]
mod app {

    use pulp_device::exit;
    use pulp_print::{print_nr, println, Format};

    use riscv_monotonic::*;


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
    struct Shared {}

    #[local]
    struct Local {}

    #[init]
    fn init(mut cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        // enable cycle counting
        unsafe {
            riscv_clic::register::mcountinhibit::clear_cy();
        }

        task0::spawn().unwrap();

        (Shared {}, Local {}, init::Monotonics(mono))
    }

    #[task(shared = [], local = [], priority = 1)]
    fn task0(_: task0::Context) {
        println!("In Task 0, spawning task 2");
        task2::spawn().ok();
        println!("In Task 0, spawned task 2");
        exit(0);
    }

    #[task(shared = [], local = [], priority = 2)]
    fn task1(_: task1::Context) {
        println!("In Task 1");
    }

    #[task(shared = [], local = [], priority = 3)]
    fn task2(_: task2::Context) {
        println!("In Task 2, spawning Task 1");
        task1::spawn().ok();
        println!("In Task 2, spawned Task 1");
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

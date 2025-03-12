#![no_main]
#![no_std]

use core::panic::PanicInfo;

use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY0])]
mod app {

    use pulp_device::exit;
    use pulp_print::println;

    use riscv_monotonic::*;

    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1>;

    #[shared]
    struct Shared {}

    #[local]
    struct Local {}

    #[init]
    fn init(cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        task0::spawn().unwrap();

        (Shared {}, Local {}, init::Monotonics(mono))
    }

    #[task(shared = [], local = [], priority = 1)]
    fn task0(_: task0::Context) {
        // Task 0

        println!("Hello from Task 0");

        exit(0);
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

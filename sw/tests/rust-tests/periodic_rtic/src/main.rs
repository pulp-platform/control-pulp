#![no_main]
#![no_std]

use core::panic::PanicInfo;
use rtic::app;

macro_rules! println {
    ($($arg:tt),*) => {{
        $(
            print($arg);
            print(" ");
        )*
        print("\n");

    }};
}

#[app(device = pulp_device, dispatchers = [DUMMY0])]
mod app {

    use core::arch::asm;
    use pulp_device::exit;

    use riscv_monotonic::*;

    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1000>;

    fn print(text: &str) {
        let print_addr = 0x1A10FF80;

        for byte in text.as_bytes() {
            unsafe {
                asm!(
                    "sw	{1},0({0})",
                    in(reg) print_addr,
                    in(reg) *byte,
                );
            }
        }
    }

    #[shared]
    struct Shared {}

    #[local]
    struct Local {
        foo_counter: u32,
    }

    #[init]
    fn init(cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        foo::spawn_after(1.secs()).unwrap();

        (Shared {}, Local { foo_counter: 0 }, init::Monotonics(mono))
    }

    #[task(shared = [], local = [foo_counter])]
    fn foo(cx: foo::Context) {
        foo::spawn_after(1.secs()).unwrap();

        let foo_counter = cx.local.foo_counter;
        *foo_counter += 1;

        println!("foo");

        if *foo_counter == 10 {
            exit(0);
        }
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

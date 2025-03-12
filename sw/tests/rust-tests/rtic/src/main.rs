#![no_main]
#![no_std]

use core::panic::PanicInfo;
use rtic::app;
//use rtic::export::Peripherals;


macro_rules! println {
    ($($arg:tt),*) => {{
        $(
            print($arg);
            print(" ");
        )*
        print("\n");
        
    }};
}


#[app(device = pulp_device, dispatchers = [TEST])]
mod app {
    
    use pulp_device::exit;  
    use core::arch::asm;


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
    struct Local {}

    #[init]
    fn init(_: init::Context) -> (Shared, Local, init::Monotonics) {
        let a = 1;
        foo::spawn().unwrap();
        (Shared {}, Local {}, init::Monotonics())
    }

    #[task(shared = [], local = [])]
    fn foo(_: foo::Context) {
        // This task is only spawned once in `init`, hence this task will run
        // only once
    
        println!("foo");
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
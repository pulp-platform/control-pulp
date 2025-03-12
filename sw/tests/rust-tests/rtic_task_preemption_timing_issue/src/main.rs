#![no_main]
#![no_std]

use core::panic::PanicInfo;
use rtic::app;
use rtic::export::Peripherals;


macro_rules! println {
    ($($arg:tt),*) => {{
        $(
            print($arg);
            print(" ");
        )*
        print("\n");
        
    }};
}


#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY1, DUMMY2])]
mod app {
    
    use pulp_device::exit;
    use you_must_enable_the_rt_feature_for_the_pac_in_your_cargo_toml::CorePeripherals;  
    use core::arch::asm;

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
    struct Shared {
        task_bitmap: u32,
    }

    #[local]
    struct Local {
    }

    #[init]
    fn init(cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        task0::spawn().unwrap();

        (Shared {task_bitmap: 0}, Local {}, init::Monotonics(mono))
    }

    #[task(shared = [task_bitmap], local = [], priority = 1)]
    fn task0(mut cx: task0::Context) {
        let task_bitmap = cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<0;
            //println!("Spawning Task 1");
            //println!("Still in Task 0");
            *task_bitmap
        });
        task1::spawn().unwrap();

        //println!("Back in Task 0");


        let task_bitmap = cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap
        });

        exit(task_bitmap-3)

    }


    #[task(shared = [task_bitmap], local = [], priority = 2)]
    fn task1(mut cx: task1::Context) {
        //println!("In Task 1");

        cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<1;
        });
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
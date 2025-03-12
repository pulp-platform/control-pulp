#![no_main]
#![no_std]

use core::panic::PanicInfo;
use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY1, DUMMY2, DUMMY3])]
mod app {
    use pulp_device::exit;
    use pulp_print::println;
    
    use riscv_monotonic::*;
    
    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1000>;
       

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
        cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<0;
        });

        println!("Start Task 1");

        task1::spawn().unwrap();
        
        println!("Task 1 starting");
        
        exit(1);

    }


    #[task(shared = [task_bitmap], local = [], priority = 2)]
    fn task1(mut cx: task1::Context) {
        
        cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<1;
        });

        //println!("Start Task 2");
        
        task2::spawn_after(1.secs()).unwrap();

        loop {}
    }
    
    #[task(shared = [task_bitmap], local = [], priority = 3)]
    fn task2(mut cx: task2::Context) {

        cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<2;

            println!("Start Task 3");

            task3::spawn().unwrap();
            // returns 0 if all tasks have been executed (task3 should not execute, since we are in a critical section)
            exit(*task_bitmap - 0b111);
            *task_bitmap
        });

    }

    #[task(shared = [task_bitmap], local = [], priority = 4)]
    fn task3(mut cx: task3::Context) {

        cx.shared.task_bitmap.lock(|task_bitmap| {
            *task_bitmap |= 1<<2;
            *task_bitmap
        });

        // this should never be reached, since task3 is spawned in a critical section and the program should already be terminated until the end of the section
        exit(1)

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
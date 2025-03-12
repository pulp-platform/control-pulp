#![no_main]
#![no_std]

use core::panic::PanicInfo;
use riscv_rt::interrupt_handler;
use rtic::app;

use pulp_device::exit;
use pulp_print::{print, print_nr, println, Format};
use numtoa::NumToA;


#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY1, DUMMY2])]
mod app {
    use pulp_device::exit;
    use pulp_print::{print, print_nr, println, Format};
    use numtoa::NumToA;

    #[shared]
    struct Shared {}

    #[local]
    struct Local {}

    #[init]
    fn init(_: init::Context) -> (Shared, Local, init::Monotonics) {
        foo::spawn().unwrap();

        (Shared {}, Local {}, init::Monotonics())
    }

    #[idle]
    fn idle(_:idle::Context) -> !{

        /*
        let timer_int = pulp_device::Interrupt::TIMER_LO;
        let dummy_int = pulp_device::Interrupt::DUMMY0;
        
        loop {
            let level = riscv_clic::register::mintstatus::read().mil();
            print_nr!("idle interrupt level", level, Format::Dec);
            
            let counter_lo = riscv_clic::peripheral::SYST::get_counter_lo();
            print_nr!("counter_lo", counter_lo, Format::Hex);

            let comp_lo = riscv_clic::peripheral::SYST::get_compare_lo();
            print_nr!("comp_lo", comp_lo, Format::Hex);
            
            let is_pend = riscv_clic::peripheral::CLIC::is_pending(timer_int) as u32;
            print_nr!("is_pend timer", is_pend, Format::Bin);
            
            let is_pend = riscv_clic::peripheral::CLIC::is_pending(dummy_int) as u32;
            print_nr!("is_pend dummy", is_pend, Format::Bin);

            let timer_prio = riscv_clic::peripheral::CLIC::get_priority(timer_int);
            print_nr!("timer_prio", timer_prio, Format::Dec);

            let mie= riscv_clic::register::mstatus::read().mie() as u32;
            print_nr!("mie", mie, Format::Bin);
            
            
        }
        */

        loop {
            
        }
    }

    #[task(shared = [], local = [], priority = 1)]
    fn foo(cont: foo::Context) {
        use rtic::export::Peripherals;

        println!("Foo Start");

        // This task is only spawned once in `init`, hence this task will run
        // only once
        let mut periphs = unsafe { Peripherals::steal() };
        /*
        
        // setup timer interrupt
        let timer_int = pulp_device::Interrupt::TIMER_LO;
        let dummy_int = pulp_device::Interrupt::DUMMY0;
        
        unsafe {
            periphs.CLIC.enable_shv(timer_int);
            periphs.CLIC.set_priority(timer_int, 8);

            periphs.CLIC.set_trig(
                timer_int,
                riscv_clic::peripheral::clic::Trigger::EdgePositive,
            );
            
            riscv_clic::peripheral::CLIC::unmask(timer_int);
        }
        */
        /*
        unsafe {
            let threshold = riscv_clic::register::mintthresh::read().get_thresh();
            print_nr!("interrupt threshold", threshold, Format::Dec);

            let level = riscv_clic::register::mintstatus::read().mil();
            print_nr!("interrupt level", level, Format::Dec);

            let mstatus = riscv_clic::register::mstatus::read();
            let mie = mstatus.mie() as u32;
            print_nr!("mie", mie, Format::Bin);

            let dummy_prio = riscv_clic::peripheral::CLIC::get_priority(dummy_int);
            print_nr!("dummy_prio", dummy_prio, Format::Dec);

        }
        */

        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("foo interrupt level", level, Format::Dec);

        
        
        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("foo interrupt level", level, Format::Dec);
        
        
        
        // use lo timer independent from hi
        periphs.SYST.disable_cascaded_mode();
        
        periphs.SYST.set_compare_lo(0x8000);

        periphs.SYST.enable_interrupt_lo();

        periphs.SYST.set_cycle_mode_lo();

        periphs.SYST.enable_lo();
        
        
        
        match nested::spawn() {
            Ok(_) => (),
            Err(_) => println!("spawning nested failed"),
        }
        
        println!("Foo End");
        
    }
    
    #[task(shared = [], local = [], priority = 2)]
    fn nested(_:nested::Context){
        
        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("nested interrupt level", level, Format::Dec);
        

        println!("Nested Start");
        match inner::spawn() {
            Ok(_) => (),
            Err(_) => println!("spawning inner failed"),
        }
        println!("Nested End");
        

        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("nested interrupt level", level, Format::Dec);
    }

    #[task(shared = [], local = [], priority = 3)]
    fn inner(_:inner::Context){
        
        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("inner interrupt level", level, Format::Dec);
        

        println!("inner");

        loop {
            
        }

    }


    
    #[task(binds = TIMER_LO, priority = 4)]
    fn timer_lo_handler(_cx: timer_lo_handler::Context) {
        println!("Hello from timer task");

        let level = riscv_clic::register::mintstatus::read().mil();
        print_nr!("timer interrupt level", level, Format::Dec);

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

/*
#[interrupt_handler(TIMER_LO)]
fn timer_lo_handler() {
    println!("Hello from timer");

    let level = riscv_clic::register::mintstatus::read().mil();
    print_nr!("timer interrupt level", level, Format::Dec);
    
    exit(0);
}
*/

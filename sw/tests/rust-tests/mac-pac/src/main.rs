#![no_std]
#![no_main]

use core::{panic::PanicInfo};
use pulp_device::exit;
use pulp_print::{print, println};
use riscv_clic::{self};
use numtoa::NumToA;

use pulp_device;
use riscv_rt;
use riscv_rt::interrupt_handler;


//#[entry]
#[no_mangle]
fn main() -> () {

    unsafe {
        riscv_clic::interrupt::enable();
    }

    //return 0;
    //println!("Hello World");

    let mut core_peripherals = pulp_device::CorePeripherals::take().unwrap();

    let test_int = pulp_device::Interrupt::DUMMY0;
    let nested_int = pulp_device::Interrupt::DUMMY1;

    // enable selective hardware vectoring
    //println!("Enabling Hardware Vectoring");
    unsafe {
        core_peripherals.CLIC.enable_shv(test_int);
        core_peripherals.CLIC.enable_shv(nested_int);
    }

    // set to edge sensitivity
    //println!("Setting Edge Trigger Mode");
    unsafe {
        core_peripherals.CLIC.set_trig(
            test_int,
            riscv_clic::peripheral::clic::Trigger::EdgePositive,
        );
        core_peripherals.CLIC.set_trig(
            nested_int,
            riscv_clic::peripheral::clic::Trigger::EdgePositive,
        );
    }

    // set number of bits for level encoding
    //println!("Set #bits for level encoding");
    unsafe { core_peripherals.CLIC.set_level_bit_width(8) }

    // set interrupt level and priority
    //println!("set interrupt level and priority");
    unsafe { core_peripherals.CLIC.set_priority(test_int, 2) }
    unsafe { core_peripherals.CLIC.set_priority(nested_int, 3) }

    // enable interrupt
    //println!("enable interrupt");

    riscv_clic::peripheral::CLIC::unmask(test_int);
    riscv_clic::peripheral::CLIC::unmask(nested_int);

    // set interrupt threshold
    //println!("set interrupt threshold");
    let mut mintthresh_reg = riscv_clic::register::mintthresh::read();
    mintthresh_reg.set_thresh(0);
    riscv_clic::register::mintthresh::write(mintthresh_reg);

    let mtvt_val = riscv_clic::register::mtvt::read().bits();
    let mut buf = [0u8; 100];
    let mtvt_val = mtvt_val.numtoa_str(16, &mut buf);
    println!(mtvt_val);

    // manually trigger interrupt
    println!("manually trigger interrupt 1");
    riscv_clic::peripheral::CLIC::pend(test_int);

    println!("back in main");
    exit(0);

}

#[no_mangle]
fn _mp_hook() -> bool {
    return true;
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[interrupt_handler(0)]
fn my_handler() {

    let val = riscv_clic::register::mintthresh::read().bits();
    let mut buf = [0u8; 100];
    let val = val.numtoa_str(16, &mut buf);
    println!("mintthresh",val);

    let val = riscv_clic::register::mstatus::read().mie() as u32;
    let mut buf = [0u8; 100];
    let val = val.numtoa_str(16, &mut buf);
    println!("mie",val);

    let val = riscv_clic::register::mintstatus::read().mil() as u32;
    let mut buf = [0u8; 100];
    let val = val.numtoa_str(16, &mut buf);
    println!("mil",val);
    

    println!("in interrupt 0");

    println!("setting the interrupt threshold to 5");
    let mut mintthresh_reg = riscv_clic::register::mintthresh::read();
    mintthresh_reg.set_thresh(5);
    riscv_clic::register::mintthresh::write(mintthresh_reg);
    
    
    let nested_int = pulp_device::Interrupt::DUMMY1;
    println!("pending the nested interrupt");
    riscv_clic::peripheral::CLIC::pend(nested_int);
    

    println!("setting the interrupt threshold back to 0");
    let mut mintthresh_reg = riscv_clic::register::mintthresh::read();
    mintthresh_reg.set_thresh(0);
    riscv_clic::register::mintthresh::write(mintthresh_reg);


    println!("back in interrupt 0")

}

#[interrupt_handler(1)]
fn nested_handler() {
    println!("in nested handler");
}
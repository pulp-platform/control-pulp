#![no_std]
#![no_main]

use core::panic::PanicInfo;
use numtoa::NumToA;
use pulp_device::exit;
use pulp_print::{print, print_nr, println, Format};
use riscv_clic::{self};

use pulp_device;
use riscv_rt;
use riscv_rt::interrupt_handler;

//#[entry]
#[no_mangle]
fn main() -> () {
    unsafe {
        riscv_clic::interrupt::enable();
    }

    let mut core_peripherals = pulp_device::CorePeripherals::take().unwrap();

    let timer_int = pulp_device::Interrupt::TIMER_LO;

    // enable selective hardware vectoring
    //println!("Enabling Hardware Vectoring");
    unsafe {
        core_peripherals.CLIC.enable_shv(timer_int);
    }

    // set to edge sensitivity
    //println!("Setting Edge Trigger Mode");
    unsafe {
        core_peripherals.CLIC.set_trig(
            timer_int,
            riscv_clic::peripheral::clic::Trigger::EdgePositive,
        );
    }

    // set number of bits for level encoding
    //println!("Set #bits for level encoding");
    unsafe { core_peripherals.CLIC.set_level_bit_width(8) }

    // set interrupt level and priority
    //println!("set interrupt level and priority");
    unsafe { core_peripherals.CLIC.set_priority(timer_int, 2) }

    // enable interrupt
    //println!("enable interrupt");

    riscv_clic::peripheral::CLIC::unmask(timer_int);

    // set interrupt threshold
    //println!("set interrupt threshold");
    let mut mintthresh_reg = riscv_clic::register::mintthresh::read();
    mintthresh_reg.set_thresh(0);
    riscv_clic::register::mintthresh::write(mintthresh_reg);

    let mtvt_val = riscv_clic::register::mtvt::read().bits();
    print_nr!("mtvt_val", mtvt_val, Format::Hex);

    /*
    // manually trigger interrupt
    println!("manually trigger interrupt 1");
    riscv_clic::peripheral::CLIC::pend(timer_int);

    println!("back in main");
    exit(0);
    */

    // setup timer
    core_peripherals.SYST.disable_cascaded_mode();

    core_peripherals.SYST.set_compare_lo(0x800);

    core_peripherals.SYST.enable_interrupt_lo();

    core_peripherals.SYST.set_cycle_mode_lo();

    core_peripherals.SYST.enable_lo();

    loop {}
}

#[no_mangle]
fn _mp_hook() -> bool {
    return true;
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[interrupt_handler(TIMER_LO)]
fn my_handler() {
    println!("In timer handler");
    exit(0);
}

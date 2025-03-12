#![no_main]
#![no_std]

use core::panic::PanicInfo;
use pulp_device::{exit, interrupt, CLIC};
use pulp_print::println;
use riscv_clic;
use riscv_rt::entry;
use riscv_rt_macros::interrupt_handler;

#[entry]
fn main(_: usize, _: usize, _: usize) -> ! {
    println!("hello");

    let mut peripherals = pulp_device::CorePeripherals::take().unwrap();

    unsafe { peripherals.CLIC.set_level_bit_width(8) }
    let mut mintthresh_reg = riscv_clic::register::mintthresh::read();
    mintthresh_reg.set_thresh(0);
    riscv_clic::register::mintthresh::write(mintthresh_reg);

    unsafe {
        peripherals.CLIC.set_priority(interrupt::DUMMY0, 1);
        peripherals.CLIC.set_trig(
            interrupt::DUMMY0,
            riscv_clic::peripheral::clic::Trigger::EdgePositive,
        );
    }

    CLIC::unmask(interrupt::DUMMY0);
    CLIC::pend(interrupt::DUMMY0);

    unsafe {
        riscv_clic::interrupt::enable();
    }

    exit(0);
    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
fn _mp_hook() -> bool {
    return true;
}

#[interrupt_handler(DUMMY0)]
fn test_handler() {
    //CLIC::unpend(interrupt::DUMMY0);

    println!("hello form interrupt");
}

#![no_std]
#![no_main]

use core::{arch::asm, panic::PanicInfo};
use numtoa::NumToA;
use riscv::{self, asm::wfi};
use riscv_rt::{clic::addr, entry};

const CLIC_BASE: *mut u8 = 0x1A200000 as *mut u8;
const TIMER_BASE: *mut u8 = 0x1A10B000 as *mut u8;

static mut TIMER_COUNTER: isize = 0;

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

macro_rules! println {
    ($($arg:tt),*) => {{
        $(
            print($arg);
            print(" ");
        )*
        print("\n");

    }};
}

macro_rules! interrupt_prolog {
    () => {
        unsafe {
            asm!(
                "addi sp, sp, -(4 * 16)",
                "sw ra, 0(sp)",
                "sw t0, 4(sp)",
                "sw t1, 8(sp)",
                "sw t2, 12(sp)",
                "sw a0, 16(sp)",
                "sw a1, 20(sp)",
                "sw a2, 24(sp)",
                "sw a3, 28(sp)",
                "sw a4, 32(sp)",
                "sw a5, 36(sp)",
                "sw a6, 40(sp)",
                "sw a7, 44(sp)",
                "sw t3, 48(sp)",
                "sw t4, 52(sp)",
                "sw t5, 56(sp)",
                "sw t6, 60(sp)",
            );
        }
    };
}

macro_rules! interrupt_epilog {
    () => {
        unsafe {
            asm!(
                "lw ra, 0(sp)",
                "lw t0, 4(sp)",
                "lw t1, 8(sp)",
                "lw t2, 12(sp)",
                "lw a0, 16(sp)",
                "lw a1, 20(sp)",
                "lw a2, 24(sp)",
                "lw a3, 28(sp)",
                "lw a4, 32(sp)",
                "lw a5, 36(sp)",
                "lw a6, 40(sp)",
                "lw a7, 44(sp)",
                "lw t3, 48(sp)",
                "lw t4, 52(sp)",
                "lw t5, 56(sp)",
                "lw t6, 60(sp)",
                "addi sp, sp, (4 * 16)",
                "mret"
            );
        }
    };
}

fn busy_wait(cycles: u32) {
    let mut counter = 0;
    unsafe { core::ptr::write_volatile(&mut counter, 0) };
    loop {
        let mut cnt = unsafe { core::ptr::read_volatile(&counter) };
        cnt = cnt + 1;
        unsafe { core::ptr::write_volatile(&mut counter, cnt) };
        if cnt == cycles {
            break;
        }
    }
}

#[entry]
fn main() -> u32 {
    println!("Hello,", "world!");

    busy_wait(100);

    let mut buf = [0u8; 200];

    let clic_mapper = addr::MemoryMapper::new(CLIC_BASE);

    let intr_nr = 31;

    // enable selective hardware vectoring
    println!("Enabling Hardware Vectoring");
    clic_mapper.write_byte(
        addr::CLICINTATTR_REG_OFFSET(intr_nr),
        addr::CLICINTATTR_SHV_MASK,
        addr::CLICINTATTR_SHV_BIT,
        1,
    );

    // set to edge sensitivity
    println!("Setting Edge Trigger Mode");
    clic_mapper.write_byte(
        addr::CLICINTATTR_REG_OFFSET(intr_nr),
        addr::CLICINTATTR_TRIG_MASK,
        addr::CLICINTATTR_TRIG_OFFSET,
        addr::TRIG_EDGE,
    );

    // set number of bits for level encoding
    println!("Set #bits for level encoding");
    clic_mapper.write_byte(
        addr::CLICCFG_REG_OFFSET,
        addr::CLICCFG_NLBITS_MASK,
        addr::CLICCFG_NLBITS_OFFSET,
        8,
    );

    // read existing interrupt level and priority
    let prev_level = clic_mapper.read_byte(
        addr::CLICINTCTL_REG_OFFSET(intr_nr),
        addr::CLICINTCTL_CLICINTCTL_MASK,
        addr::CLICINTCTL_CLICINTCTL_OFFSET,
    );
    let prev_level = prev_level.numtoa_str(16, &mut buf);
    println!("Previous level", prev_level);

    // set interrupt level and priority
    clic_mapper.write_byte(
        addr::CLICINTCTL_REG_OFFSET(intr_nr),
        addr::CLICINTCTL_CLICINTCTL_MASK,
        addr::CLICINTCTL_CLICINTCTL_OFFSET,
        0x1,
    );

    // enable interrupt
    clic_mapper.write_byte(
        addr::CLICINTIE_REG_OFFSET(intr_nr),
        addr::CLICINTIE_CLICINTIE_MASK,
        addr::CLICINTIE_CLICINTIE_BIT,
        1,
    );

    /*
    let a = clic_mapper.read(addr::CLICINFO_REG_OFFSET, addr::CLICINFO_CLICINTCTLBITS_MASK, addr::CLICINFO_CLICINTCTLBITS_OFFSET);
    let a = a.numtoa_str(16, &mut buf);
    println!("CLICINTCTLBITS", a );
    */


    
    
    // set interrupt threshold
    unsafe {
        asm!("csrw 0x347, 0")
    }
    
    
    // trigger an interrupt manually
    println!("Triggering Interrupt");
    clic_mapper.write_byte(
        addr::CLICINTIP_REG_OFFSET(intr_nr),
        addr::CLICINTIP_CLICINTIP_MASK,
        0,
        1,
    );

    // wait for interrupt
    println!("Start Waiting");
    busy_wait(100);
    println!("Done Waiting");

    // setup timer

    let timer_intr_nr = 10;

    // enable selective hardware vectoring
    println!("Enabling Hardware Vectoring");
    clic_mapper.write_byte(
        addr::CLICINTATTR_REG_OFFSET(timer_intr_nr),
        addr::CLICINTATTR_SHV_MASK,
        addr::CLICINTATTR_SHV_BIT,
        1,
    );

    // set to edge sensitivity
    println!("Setting Edge Trigger Mode");
    clic_mapper.write_byte(
        addr::CLICINTATTR_REG_OFFSET(timer_intr_nr),
        addr::CLICINTATTR_TRIG_MASK,
        addr::CLICINTATTR_TRIG_OFFSET,
        addr::TRIG_EDGE,
    );

    // set interrupt level and priority
    clic_mapper.write_byte(
        addr::CLICINTCTL_REG_OFFSET(timer_intr_nr),
        addr::CLICINTCTL_CLICINTCTL_MASK,
        addr::CLICINTCTL_CLICINTCTL_OFFSET,
        0x5,
    );

    // enable interrupt
    clic_mapper.write_byte(
        addr::CLICINTIE_REG_OFFSET(timer_intr_nr),
        addr::CLICINTIE_CLICINTIE_MASK,
        addr::CLICINTIE_CLICINTIE_BIT,
        1,
    );

    let timer_mapper = addr::MemoryMapper::new(TIMER_BASE);

    let time = timer_mapper.read(
        addr::TIMER_CNT_LOW_REG_OFFSET,
        addr::TIMER_CNT_LO_CNT_LO_MASK,
        0,
    );

    let time_str = time.numtoa_str(10, &mut buf);
    println!("Time", time_str);

    // set comparison value
    timer_mapper.write(
        addr::TIMER_CMP_LOW_REG_OFFSET,
        addr::TIMER_CMP_LO_CMP_LO_MASK,
        0,
        0x800,
    );

    // enable timer
    timer_mapper.write(
        addr::TIMER_CFG_LOW_REG_OFFSET,
        addr::TIMER_CFG_LO_ENABLE_MASK,
        addr::TIMER_CFG_LO_ENABLE_BIT,
        1,
    );

    // enable timer interrupts
    timer_mapper.write(
        addr::TIMER_CFG_LOW_REG_OFFSET,
        addr::TIMER_CFG_LO_IRQEN_MASK,
        addr::TIMER_CFG_LO_IRQEN_BIT,
        1,
    );

    // enable timer looping
    timer_mapper.write(
        addr::TIMER_CFG_LOW_REG_OFFSET,
        addr::TIMER_CFG_LO_MODE_MASK,
        addr::TIMER_CFG_LO_MODE_BIT,
        1,
    );

    unsafe {
        while TIMER_COUNTER < 10 {
            let timer_counter_str = TIMER_COUNTER.numtoa_str(10, &mut buf);
            println!("TIMER_COUNTER", timer_counter_str);
            wfi();
        }
    }
    // disable interrupt
    clic_mapper.write_byte(
        addr::CLICINTIE_REG_OFFSET(timer_intr_nr),
        addr::CLICINTIE_CLICINTIE_MASK,
        addr::CLICINTIE_CLICINTIE_BIT,
        0,
    );

    /*
    busy_wait(1100);

    let time = timer_mapper.read(addr::TIMER_CNT_LOW_REG_OFFSET, addr::TIMER_CNT_LO_CNT_LO_MASK, 0);

    let time_str = time.numtoa_str(10, &mut buf);
    println!("Time", time_str);

    busy_wait(100);
    */

    /*
    unsafe {
        asm!(
            "la {0}, mtime",
            "lw {0}, {0}",
            out(reg) time,
        );
    }

    let mut buf = [0u8; 200];
    let time = time.numtoa_str(10, &mut buf);
    println!("Time", time);
    sim:/tb_sw/fixt_pms/i_dut/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_apb_timer_unit
    */

    /*
    unsafe {
        riscv::asm::wfi();
    }
    */

    return 0;
}

#[no_mangle]
fn clic_isr_hook() {
    println!("In,", "clic_isr_hook!");
}

#[no_mangle]
fn timer_isr_hook() {
    let mut buf = [0u8; 20];
    unsafe {
        let timer_counter_str = TIMER_COUNTER.numtoa_str(10, &mut buf);
        println!("In,", "timer_handler!", "Interrupt #", timer_counter_str);
        TIMER_COUNTER += 1;
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

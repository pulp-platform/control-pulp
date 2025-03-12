#![no_main]
#![no_std]

use core::panic::PanicInfo;

use rtic::app;

#[app(device = pulp_device, dispatchers = [DUMMY0, DUMMY2, DUMMY3, DUMMY4, DUMMY5, DUMMY6])]
mod app {
    
    use pulp_device::exit;
    use pulp_print::{print_nr, println, Format};
    
    use riscv_monotonic::*;

    #[cfg(feature="timer_measurement")]
    macro_rules! get_ticks {
        () => {
            riscv_clic::peripheral::SYST::get_counter_lo()
        }
    }
    #[cfg(not(feature="timer_measurement"))]
    macro_rules! get_ticks {
        () => {
            riscv_clic::register::mcycle::read() as u32
        }
    }

    #[monotonic(binds = TIMER_LO, default = true)]
    type MyMono = Systick<1>;

    #[shared]
    struct Shared {
        task_1_started: u32,
        task_2_started: u32,
        task_4_started: u32,
        task_5_scheduled_at: u32,
        task_6_ended: u32,
        task_7_ended: u32,
    }

    #[local]
    struct Local {}
    
    #[init]
    fn init(cx: init::Context) -> (Shared, Local, init::Monotonics) {
        let systick = cx.core.SYST;
        let mono = Systick::new(systick);

        // enable cycle counting
        unsafe {
            riscv_clic::register::mcountinhibit::clear_cy();
        }

        task0::spawn().unwrap();
        
        (
            Shared { task_1_started: 0, task_2_started: 0, task_4_started: 0, task_5_scheduled_at: 0, task_6_ended: 0, task_7_ended: 0 },
            Local {},
            init::Monotonics(mono),
        )
    }

    #[task(shared = [task_1_started, task_2_started, task_4_started, task_5_scheduled_at], local = [], priority = 1)]
    fn task0(mut cx: task0::Context) {
        
        // Task 1 (Hardware)

        //println!("Start Task 1");

        #[cfg(feature="timer_measurement")]
        println!("Using timer to measure");

        #[cfg(not(feature="timer_measurement"))]
        println!("Using MCYCLE to measure");

        
        let time_task_1_pended = get_ticks!();
        riscv_clic::peripheral::CLIC::pend(pulp_device::interrupt::DUMMY1);
        unsafe {rtic::export::wfi()}


        let mut task_1_started_local = 0;

        cx.shared.task_1_started.lock(|task_1_started| {
            task_1_started_local = *task_1_started;
        });
        
        let difference = task_1_started_local - time_task_1_pended;

        print_nr!("Hardware Task Spawn", difference, Format::Dec);
        //print_nr!("time_task_1_pended", time_task_1_pended, Format::Hex);
        //print_nr!("task_1_started_local", task_1_started_local, Format::Hex);

        
        // Task 2 (Software)

        //println!("Start Task 2");

        let time_task_2_pended = get_ticks!();
        task2::spawn().ok();
        unsafe {rtic::export::wfi()}

        let mut task_2_started_local = 0;
        
        cx.shared.task_2_started.lock(|task_2_started| {
            task_2_started_local = *task_2_started;
        });

        let difference = task_2_started_local - time_task_2_pended;

        print_nr!("Software Task Spawn", difference, Format::Dec);
        //print_nr!("time_task_2_pended", time_task_2_pended, Format::Hex);
        //print_nr!("task_2_started_local", task_2_started_local, Format::Hex);
        
        // Task 3 (Locking)

        //println!("Start Locking Test");

        let mut time_after_locking = 0;
        let mut time_before_unlocking = 0;

        let time_before_locking = get_ticks!();
        cx.shared.task_1_started.lock(|task_1_started| {
            time_after_locking = get_ticks!();
            *task_1_started = 0;
            time_before_unlocking = get_ticks!();
        });
        let time_after_lock = get_ticks!();

        let difference = time_after_locking - time_before_locking;
        print_nr!("Locking Low Prio", difference, Format::Dec);
        
        let difference = time_after_lock - time_before_unlocking;
        print_nr!("Unlocking Low Prio", difference, Format::Dec);
        
        task3::spawn().ok();
        unsafe {rtic::export::wfi()}

        // Task 4 (Multiple Software Tasks with the same prio)

        //println!("Run Task 4");
        
        let time_task_4_pended = get_ticks!();
        task4_0::spawn().ok();
        unsafe {rtic::export::wfi()}


        let mut task_4_started_local = 0;

        cx.shared.task_4_started.lock(|task_4_started| {
            task_4_started_local = *task_4_started;
        });

        let difference = task_4_started_local - time_task_4_pended;
        print_nr!("Software Task Spawn, multiple task with same prio", difference, Format::Dec);
        //print_nr!("time_task_4_pended", time_task_4_pended, Format::Hex);
        //print_nr!("task_4_started_local", task_4_started_local, Format::Hex);
        
        //let now = riscv_clic::peripheral::SYST::get_counter_lo();
        //let due_time = fugit::Instant::<u32, 1, 1>::from_ticks(now+4000);
        let schedule_task_5_at = 10000;
        let due_time = fugit::Instant::<u32, 1, 1>::from_ticks(schedule_task_5_at);

        cx.shared.task_5_scheduled_at.lock(|task_5_scheduled_at| {
            *task_5_scheduled_at = schedule_task_5_at;
        });

        let time_task_5_schedule_start = get_ticks!();
        task5::spawn_at(due_time).ok();
        let time_task_5_schedule_end = get_ticks!();
        let difference = time_task_5_schedule_end - time_task_5_schedule_start;

        print_nr!("Scheduling time for timer task", difference, Format::Dec);

        task6::spawn().ok();

    }

    #[task(shared = [task_1_started], local = [], binds = DUMMY1, priority = 2)]
    fn task1(mut cx: task1::Context) {
        let time_task_1_started = get_ticks!();

        //println!("In Task 1");
        
        cx.shared.task_1_started.lock(|task_1_started| {
            *task_1_started = time_task_1_started;
        });
    }
    
    #[task(shared = [task_2_started], local = [], priority = 2)]
    fn task2(mut cx: task2::Context) {
        let time_task_2_started = get_ticks!();

        //println!("In Task 2");

        cx.shared.task_2_started.lock(|task_2_started| {
            *task_2_started = time_task_2_started;
        });
    }

    #[task(shared = [task_1_started, task_2_started], local = [], priority = 3)]
    fn task3(mut cx: task3::Context) {
        let mut time_after_locking = 0;
        let mut time_before_unlocking = 0;

        let time_before_locking = get_ticks!();
        cx.shared.task_1_started.lock(|task_1_started| {
            time_after_locking = get_ticks!();
            *task_1_started = 0;
            time_before_unlocking = get_ticks!();
        });
        let time_after_lock = get_ticks!();

        let difference = time_after_locking - time_before_locking;
        print_nr!("Locking High Prio", difference, Format::Dec);

        let difference = time_after_lock - time_before_unlocking;
        print_nr!("Unlocking High Prio", difference, Format::Dec);
    }

    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_0(mut cx: task4_0::Context) {
        let time_task_4_started = get_ticks!();
        
        //println!("In Task 4");
        //print_nr!("time_task_4_started in task 4", time_task_4_started, Format::Hex);
        

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = time_task_4_started;
        });
    }

    
    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_1(mut cx: task4_1::Context) {
        //let time_task_4_started = get_ticks!();
        
        //println!("In Task 4");

        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = 1;
        });
    }
    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_2(mut cx: task4_2::Context) {
        //let time_task_4_started = get_ticks!();

        //println!("In Task 4");
        
        cx.shared.task_4_started.lock(|task_4_started| {
            *task_4_started = 2;
        });
    }

    
    #[task(shared = [task_4_started], local = [], priority = 4)]
    fn task4_3(mut cx: task4_3::Context) {
        //let time_task_4_started = get_ticks!();
        
        //println!("In Task 4");
        
        cx.shared.task_4_started.lock(|task_4_started| {

            *task_4_started = 3;
        });
    }

    #[task(shared = [task_5_scheduled_at], local = [], priority = 5)]
    fn task5(mut cx: task5::Context) {
        let time_task_5_started = riscv_clic::peripheral::SYST::get_counter_lo();

        let mut time_timer_fired = 0;

        cx.shared.task_5_scheduled_at.lock(|task_5_scheduled_at| {
            time_timer_fired = *task_5_scheduled_at;
        });

        let difference = time_task_5_started - time_timer_fired;
        
        print_nr!("Start time for timed task", difference, Format::Dec);
        exit(0);
    }

    #[task(shared = [task_6_ended], local = [], priority = 6)]
    fn task6(mut cx: task6::Context) {

        task7::spawn().ok();

        let time_task_6_ended = get_ticks!();
        cx.shared.task_6_ended.lock(|task_6_ended| {

            *task_6_ended = time_task_6_ended;
        });
    }

    #[task(shared = [task_6_ended, task_7_ended], local = [], priority = 5)]
    fn task7(mut cx: task7::Context) {
        let time_task_7_started = get_ticks!();
        let time_task_6_ended = cx.shared.task_6_ended.lock(|task_6_ended| {

            *task_6_ended
        });
        
        let difference = time_task_7_started - time_task_6_ended;
        
        print_nr!("Context switch time lower prio task", difference, Format::Dec);

        task8::spawn().ok();

        let time_task_7_ended = get_ticks!();
        cx.shared.task_7_ended.lock(|task_7_ended| {

            *task_7_ended = time_task_7_ended;
        });
    }

    #[task(shared = [task_7_ended], local = [], priority = 5)]
    fn task8(mut cx: task8::Context) {
                let time_task_8_started = get_ticks!();
        let time_task_7_ended = cx.shared.task_7_ended.lock(|task_7_ended| {

            *task_7_ended
        });
        
        let difference = time_task_8_started - time_task_7_ended;

        print_nr!("Context switch time same prio task", difference, Format::Dec);
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

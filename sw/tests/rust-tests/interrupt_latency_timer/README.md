# RTIC Test Application

## Content
This crate features a test program that measures the cycle count of various core transitions of the RTIC RTOS. It measures the cycle count automatically by reading out the `mcycle` register.

## Usage

### Setup
- Clone the control-pulp repository, and set up the environment as for the freeRTOS tests.
- Install rust, this code was tested with rustc and cargo version `1.67.1`
- Install the new rust targets with

`rustup target add riscv32imac-unknown-none-elf` (with atomics)

`rustup target add riscv32imc-unknown-none-elf` (without atomics)

- Setup the environment with

`source <path to local repo>/control-pulp/env/env.sh`

`export RISCV=/usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0`

- Now proceed with the build process below. If you want to develop Rust code, it makes sense to use VS Code, together with the rust-analyzer extensions. The extensions can normally be easily installed inside VS Code, but on the IIS lab computers, a few shared libraries are missing (or just to old) So I had to compile it from source. It works, but with extra steps.


### Build
To build the application run `make all`. The command internally uses `cargo build --release` to build the rust binary. Additionally, the following files are created:
- `target/rtic-expansion.rs` This is the Rust file of the program with all RTIC related macros expanded.
- `target/riscv32im<a>c-unknown-none-elf/release/interrupt_latency.dump` The assembly dump of the complete program.

The following options can be passed to the `make all` command:
- `nxti=1` It enables tail-gating using the `mnxti` register. It sets the flags inside rtic and inside the runtime crate.
- `no_atomics=1` It builds for the target `riscv32imc-unknown-none-elf` instead of `riscv32imac-unknown-none-elf`. So no atomics are used.
- `timer_measurement=1` It enables the measurement using the system timer that is attached to the system clock. Normally the `mcycle` register is used.

If any options are changed, please first run `make clean`, since make does not recognize the change of options at all time.

### Run
To run the program, use `make run` with the option `gui=1` to enable the gui.
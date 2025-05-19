# Rust regression tests

Minimal setup to execute Rust code in ControlPULP, including:

* Baremetal code;
* [Real-Time Interrupt-driven Concurrency (RTIC)](https://github.com/rtic-rs/rtic), a concurrency framework for building real-time systems.

## Dependencies

- cargo `>= 1.85.0`
- rustc `>= 1.85.0`

### Usage
- Setup the environment as explained in the main [README.md](../../../README.md)
- Install the new rust targets with

```shell
rustup target add riscv32imac-unknown-none-elf
```

### Build
To build the a program run:

```shell
cd <program>
make all
```

The command internally uses `cargo build --release` to build the rust binary.
Additionally, the following files are created:
- `target/riscv32imac-unknown-none-elf/release/expand.rs`: This is the Rust file
  of the program with all macros expanded.
- `target/riscv32imac-unknown-none-elf/release/<test>.dump`: The assembly dump
  of the program.

The following options can be passed to the `make all` command:
- `nxti=1` It enables tail-gating using the `mnxti` register. It sets the flags
  inside rtic and inside the runtime crate.
- `no_atomics=1` It builds for the target `riscv32imc-unknown-none-elf` instead
  of `riscv32imac-unknown-none-elf`. So no atomics are used.
- `timer_measurement=1` It enables the measurement using the system timer that
  is attached to the system clock. Normally the `mcycle` register is used.

If any options are changed, first run `make clean`.

### Questasim simulation
To simulate the program using Questasim to simulate the hardware, run:

```shell
make run
```

with the additional option `gui=1` to enable the gui. Make sure the simulation
platform is build as explained in the main [README.md](../../../README.md).

# Control PULP

ControlPULP is a research platform based on PULP, an open-source multi-core
computing system developed by ETH Zurich and the University of Bologna, started
in 2013.

ControlPULP is intended to be used as a real-time, mid-end embedded controller
in application domains with different requirements in terms of time-criticality.
Among those, it is employed as embedded power and thermal controller for HPC
systems.

The development of ControlPULP has been supported by the [European Processor
Initiative]()https://eurohpc-ju.europa.eu/research-innovation/our-projects/european-processor-initiative-epi_en
(EPI) project.

## Citing
If you are using ControlPULP in your academic work you can cite us:
```
@InProceedings{10.1007/978-3-031-15074-6_8,
author="Ottaviano, Alessandro
and Balas, Robert
and Bambini, Giovanni
and Bonfanti, Corrado
and Benatti, Simone
and Rossi, Davide
and Benini, Luca
and Bartolini, Andrea",
editor="Orailoglu, Alex
and Reichenbach, Marc
and Jung, Matthias",
title="ControlPULP: A RISC-V Power Controller for HPC Processors with Parallel Control-Law Computation Acceleration",
booktitle="Embedded Computer Systems: Architectures, Modeling, and Simulation",
year="2022",
publisher="Springer International Publishing",
address="Cham",
pages="120--135",
isbn="978-3-031-15074-6"
}
```

## Disclaimer

This project is still considered to be in early development; some parts may not
yet be functional, and existing interfaces and conventions may be broken without
prior notice. We target a formal release in the very near future.

## Dependencies

To *build* ControlPULP, you will need:

- GNU Make `>= 3.82`
- Python `>= 3.6.8`
- Bender `>= 0.27.1`
- RISCV GCC `>= 11.2.0`
- Questa `>= 2022.3`

We use [Bender](https://github.com/pulp-platform/bender) and git submodules for
hardware IP and dependency management. For more information on using Bender,
please see its documentation. You can install Bender directly through the Rust
package manager Cargo:

```
cargo install bender
```

Depending on your desired target, additional dependencies may be needed.

## Getting Started

ControlPULP uses Git submodules that have to be initialized. Either clone the
repository recursively using:

```
git clone --recursive <url>
```

or fetch the submodules afterwards in the repository:

```
git submodule update --init --recursive
```

You need the `pulp-runtime` or `freertos`, `vsim` (10.7b_1 or newer) and `pulp
gcc` (2.5.0 or newer). After building the simulation platform you can run tests
or write your own applications.

### RISC-V Toolchain
ControlPULP uses a RISC-V GCC toolchain by default. Compile and install PULP gcc from
[here](https://github.com/pulp-platform/riscv-gnu-toolchain) and make sure it is in your `PATH`:
```sh
export PATH=$YOUR_PULP_TOOLCHAIN/bin:$PATH
```

Alternatively, if you are at ETH you can use precompiled toolchain by either
*prefixing* all `make` commands with `riscv -pulp-gcc-2.5.0` or adding this path to your `PATH`:
```sh
export PATH=/usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0/bin/:$PATH
```

### Software stack

#### Bare-metal programs

We use a simple `pulp-runtime` to compile bare-metal programs. Call `source
env/env.sh` to configure your shell to execute cycle-accurate RTL simulations
using the bare-metal pulp-runtime setup.

#### Real-time operating system (RTOS)

* **FreeRTOS**: Freertos isn't natively available in the control_pulp repository
  after you clone it. To download freertos call `make freertos`. Call `source
  env/env.sh` to configure your shell to use pulp-freertos. Examples to run are
  available in `sw/freertos/tests` and `sw/freertos/demos`.

### Building the RTL simulation platform

You can build the simulation platform for `Questasim` by doing
the following:
```sh
# set path to to-be-simulated model
source env/env.sh
# build RTL source
make all
```

Similary for `vcs`

```sh
# set path to to-be-simulated model
source env/env.sh
# build RTL source
make vcs-build
```

and `verilator`
```sh
# set path to to-be-simulated model
source env/env.sh
# build RTL source
make veri-build
```

If you add or remove rtl code you have re-generate the build scripts.
Call `make gen` to re-generate the build scripts.

The ControlPULP IP does integrate the accelerator cluster by default. In some
implementations, for example some chips, we use the platform in single-core mode
(without the cluster).

You can refer to said chips repositories to build the hardware and software with
the cluster option disabled.

### Running tests
After building the RTL simulation platform, you can run a test using one of the
available software stacks. Currently, we support Questasim as a simulation
target for the tests.

### Bare-metal execution

To use `pulp-runtime` for a test, locate the test you want to run, and do:

```sh
cd sw/tests/control-pulp-tests/runtime_uart
make clean all run
```

### RTOS execution

The process is similar when using an RTOS.

* **Freertos**:
	```sh
	cd sw/freertos/tests/hello_world_pmsis
	make clean all run
	```

---

In case one did not set up the PATH for the RISCV toolchain as explained above,
one can pass it to `make` by setting the `RISCV` environment variable.

```sh
make RISCV=/usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0 clean all run
```

The open-source simulation platform relies on JTAG to emulate preloading of the
PULP L2 memory. If you want to simulate a more realistic scenario (e.g.
accessing an external SPI Flash), look at the sections below.

In case you want to see the Questasim GUI, just append `gui=1` like this
```sh
make run gui=1
```
before starting the simulation.

### Hardware-In-The-Loop (HIL) power and thermal management on FPGA
We emulate the controller on FPGA, and run the power control policy in-the-loop
with a co-simulation (or virtual platform) of the controlled system, comprising
a power/thermal model of a generic HPC processor with configurable number of
processing elements (PEs), a workload simulation model, and a governor model.

As a first initialization steps, download the co-simulation (power/thermal model
and HIL manager) framework.

```
make hpc-cosim
```

The Power Control Firmware (PCF) is already integrated in `sw/pcf`.

For hands-on instructions on how to run the in-the-loop emulation, visit the
FPGA documentation in the [`fpga`](./fpga/README.md) directory.

## Address mapping overview
The ControlPULP specific address mapping is defined with a set of macros in
`hw/includes/soc_mem_map.svh` and `hw/includes/cluster_bus_defines.sv`.

From the Control PULP viewpoint:

| Memory Area Name (Control PULP viewpoint) | Address range                |
| ----------------------------------------- | ---------------------------- |
| Cluster Subsystem                         | 0x1000\_0000 - 0x103F\_FFFF  |
| SoC peripherals and L2                    | 0x1A00\_0000 - 0x1FFF\_FFFF  |

The exploded version of this memory map can be found in the PMS MAS-HW Reference
Manual.

From an external viewpoint:

| Memory Area Name (external viewpoint )    | Address range                |
| ----------------------------------------- | ---------------------------- |
| SoC peripherals and L2                    | 0x1A00\_0000 - 0x1FFF\_FFFF  |

Note that in the current configuration, the cluster address space is not
externally visible.

## AXI interfaces
Control PULP exchanges off-IP information through the AMBA AXI4 protocol. The 5 AXI channels
are internally characterized by the following AXI widths in either directions `to-` and `from-` Control PULP:


| AXI WIDTH | EXT->ControlPULP | ControlPULP->EXT |
| ------ | ------ | ------ |
| ID WIDTH | 7 | 6 |
| DATA WIDTH | 64 | 64 |
| ADDRESS WIDTH | 32 | 32 |
| USER WIDTH | 6 | 6 |

where `EXT` is an actor external to the ControlPULP IP.

In addition, `AXI_ID_WIDTH` and `AXI_DATA_WIDTH` are made configurable through
AXI data width and ID width converters modules. This means that `AXI_ID_WIDTH` and
`AXI_DATA_WIDTH`, in either `to-` and `from-` Control PULP directions, are passed as parameters
in the top-level IP instantiation, and converted internally to match the aforementioned table.

## Clocking and reset

The clock ports are as follow:

| Clock name | Direction | Description |
| ------ | ------ | ------ |
| `sys_clk_i` | Input | System input clock (500 MHz). It generates SoC and Cluster clocks internally through integer division. |
| `ref_clk_i` | Input | Reference input clock (100 MHz). It generates peripheral and timer (32 kHz) clocks internally through integer division. |
| `soc_clk_o` | Output | SoC clock. It clocks AXI4 interfaces and L2 SoC memory. |
| `cluster_clk_o` | Output | Cluster clock. It clocks L1 cluster memory. |

While for reset:

| Reset name | Direction | Description |
| ------ | ------ | ------ |
| `rst_ni` | Input | System input reset. |
| `rst_l2_no` | output | Output reset towards L2 SoC Memory. |
| `rst_l1_no` | Output | Output reset towards L1 Cluster Memory. |

Visit the [boot](./boot) and [tb](./tb) directories for more information about the supported `bootmodes` and booting procedure respectively.

## Proprietary verification IPs
The full simulation platform can take advantage of a few models of commercial
SPI, I2C, I2S peripherals to attach to the open-source PULP simulation platform.
Read the output of `./generate-scripts --help`

When the SPI flash model is installed, it will be possible to switch to a more
realistic boot simulation, where the internal ROM of PULP is used to perform an
initial boot and to start to autonomously fetch the program from the SPI flash.
To do this, the `LOAD_L2` parameter of the testbench has to be switched from
`JTAG` to `STANDALONE`.

## Control PULP directory structure
After being fully setup as explained in the
Getting Started section, this root repository is structured as
follows:

 | Directory | Description | Documentation |
 | ------ | ------ | ------ |
 | `hw/pulp` | Contains PMS RTL top-level and first-level hierarchy modules. | [rtl/pulp/README.md](./hw/pulp) |
 | `tb` | Contains the main platform testbenches and the related files. | [tb/README.md](./tb) |
 | `tb/vip`| Contains the verification IPs used to emulate external peripherals, e.g. SPI flash and camera. | [tb/vip/README.md](./tb/vip) |
 | `ips` | Contains all IPs downloaded by `update-ips` script. Most of the actual logic of the platform (the SoC and the Cluster accelerator RTL code) is located in these IPs. | [ips/README.md](./ips) |
 | `sim` | Contains the ModelSim/QuestaSim simulation platform. |-|
 | `sw/pulp-runtime` | Contains the basic runtime used for bare-metal tests | [sw/pulp_runtime/README.md](https://github.com/pulp-platform/pulp-runtime)|
 | `sw/freertos` | Contains the main operating system used | [sw/freertos/README.md](https://github.com/pulp-platform/pulp-freertos)|
 | `boot` | Contains the bootcode and autogenerated bootroms for `ASIC/RTL` and `FPGA` targets. | [boot/README.md](./boot)|
 | `synth`| Contains the constraints of the PMS for ASIC synthesis and information about technology-dependent cells. | [synth/README.md](./synth) |
 | `fpga` | Contains the FPGA emulation of the PMS on the Xilinx Zynq ZCU102. | [fpga/README.md](./fpga)|
 | `util` | Contains utility tools | [util/README.md](./util) |
 | `ipstools` | Contains the utils to download and manage the IPs and their dependencies. | [ipstools/README.md](./ipstools) |
 | `ips_list.yml` | Contains the list of IPs required directly by the platform. Each of them could in turn depend on other IPs, so you will typically find many more IPs in the `ips` directory than are listed in this file. |---|
 | `rtl_list.yml` | Contains the list of places where local RTL sources are found (e.g. `tb`, `tb/vip`). |---|

## Repository organization and dependencies
The Control-PULP repository is a flattened and modified version of Open PULP,
generated with git subtree. Version tagged commits are considered stable.

## Requirements
The RTL platform has the following requirements:
- Relatively recent Linux-based operating system; we tested *CentOS 7*.
- ModelSim in reasonably recent version (we tested it with version *10.7b*).
- Python 3.6, with the `pyyaml` module installed (you can get that with
  `pip3 install pyyaml`).

## Verible support
Control-PULP supports Verible for code linting and formatting. For
more information, see the
[README.md](./util/verible)
under `util/verible`.

## License

Unless specified otherwise in the respective file headers, all code checked into
this repository is made available under a permissive license. All hardware
sources and tool scripts are licensed under the Solderpad Hardware License 0.51
(see `LICENSE`) with the exception of generated register file code, which is
generated by a fork of lowRISC's
[`regtool`](https://github.com/lowRISC/opentitan/blob/master/util/regtool.py)
and licensed under Apache 2.0. All software sources are licensed under Apache
2.0 or MIT.

# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
## Unreleased

## [5.3.0] - 2022-04-07
### Added
- Add switch between cluster and non-cluster configuration: elaboration time
  parameter (when not there, AXI signals to the cluster are routed to SLV_ERR,
  signals from the cluster are tied-off to '0)
- Add number of peripherals as configurable parameters to be chosen at the very
  top-level (or use default)
- Add memory sizes as configurable parameters to be chosen at the very top-level
  (or use default)
- Add DMA into fabric controller (single-core side) to handle sensor transfers:
  the DMA in the cluster can then come back to its original role, i.e. moving
  data horizontally between FC and cluster, keeping telemetry
- Add JTAG manufacturer code with PULP
- Add fast shadow interrupts in CLIC and CV32 core

### Changed
- Change location of `gpio` assignments: remove `safe_domain.sv` source file
- Connect dft test mode signals (89d5df3e and b78f1588)
- Refactor clock and reset generation (move the module in the top-level instead
  of hidden in the hierarchy)
- Move L1 cluster memory within cluster hierarchy again (needed for other
  projects such as chips)
- Overhaul package handling
- Update DMA version in the cluster DMA: now FC (see above) and cluster DMAs are
  the same, updated, IP

### Fixed
- Fix cluster timer reference clock (wrong wiring)
- Map bus errors to regular CLINT interrupts
- Fix some unconnected dft signals (22b7ff32)

## [5.2.0] - 2022-04-01
### Added
- Add srec loading support in testbench
- Add spyglass linting flow
- Add vcs support
- Add basic verilator support
- Add uart boot

### Changed
- Bump axi
- Use filelists for generic synthesis
- Clean up global defines

### Fixed
- Fix CV32 Tracer for multi-cycle APU instructions and ZFINX
- Fix multiple driven signals in tb fixture
- Uniquified output for ipstools so that we don't have duplicate modules anymore
- Fix Address width when instantiating rom macro
- Fix misaligned 64-bit access for fw rtl test

## [5.1.0] - 2022-02-08

### Changed
- Updated `riscv-dbg` to `v4.1.0`

### Fixed
- Various lint issues

## [5.0.0] - 2022-02-07

### Changed
- Update memory wrappers for L2, L1 and cluster cache data/tag fields. Memories are now parameterized with `BEHAV_MEM` parameter, which
arbitrates between a behavioral model (`tc_sram`) and a memory macro.
- Clean and streamline RTL and FPGA top-level modules: removed several levels of hierarchies between modules and aligned modules' names as agreed.
- Clean and streamline RTL and FPGA testbench directory: decouple testbenches simulation driver process from the device under test (DUT)
to avoid code replication and ease maintainability.
- Update power control FW RTL simulation test to latest realease
- Update README.md files to align with new naming and modules structure

### Added
- Add `SIM_TOP` variable in the simulation process to seamlessly select the top-level tb for a specific simulation.
- Add `SIM_STDOUT` parameter to control simulation stdout
- Add `MACRO_ROM` parameter to arbitrate between synthesizable ROM and a macro ROM.
- Add `ips/tech_mem` folder to store memory macros (L2, L1, cluster cache data and tag)
- Add I2C slave test and testbenches (RTL/FGPA)
- Add Watchdog timer (WDT) alert and clear-alert **top-level** signals to notify the TMB to drive pms reset when a failure happens,
preventing the pms to drive its own reset.

### Removed
- Remove legacy and unused IPs (legacy FPGA emulation modules, legacy RTC, legacy PLIC
- Remove legacy PLIC tests from CI
- Remove legacy documentation from classic PULP/PULPissimo

### Fixed
- Fix several I/O-specific bugs from previous release (GPIOs, I2C slave ...)
- Fix CLIC tests to be compliant with latest CLIC release
- Fix WDT formatting and code structure

## [4.0.0.] - 2021-11-27

### Changed
- Overhaul FPU configuration in RTL/ASIC and FPGA: 9 private FPUs (1 SoC, 8 Cluster) and one shared DIVSQRT unit in the Cluster
- Bump freertos to fe6e67
- Bump PMS FW to 0fe697

### Added
- Memory-map bootmode selection: choose whether to select the bootmode from an input signal (bootsel_i) or via register writing
- Add peripheral demultiplexer for direct core-DMA connection in the Cluster
- Add ACK/NACK acknowledgment from I2C slave devices when issuing from I2C master
- Add CLIC interrupt controller: route external/software/timer interrupts to the
  CLIC and redirects them to the core. Replaces the PLIC for external interrupt
  lines.
- asic: Add synthesis flow GF22 for control-pulp top level module
- asic: Add post-synthesis simulation flow with control-pulp top-level netlist
- Improve verification environment:
	- Select AXI preloaded boot testbench as default
	- Simulate control-pulp ASIC top-level module (control_pulp_top_with_mem) with exploded ports instead of array/struct top-level (control_pulp_with_mem)
	- Add PMS FW loop testbench + test
	- Add basic SCMI testbench + test
	- Add basic ACPI testbench + test
	- Add PVT register reading test from the Cluster
- fpga: Add peripherals (I2CM, SPIM, UART, GPIO) to control-pulp top-level FPGA wrapper
- fpga: Add end-to-end FPGA Linux flow: bitstream, Linux images and Linux rootfs generation for Xlinx ZCU102
- fpga: Clean FPGA testbenches with exact control-pulp FPGA top-level wrapper used with the board
- Add generic file list generation. Now used to compile hw with questasim.

### Removed
- Remove PLIC interrupt controller for external interrupts

### Fixed
- Fix FPU interconnect wrong multiplexing between FPU and external DIV/SQRT unit for cotnrol-pulp ASIC/FPGA
- Fix width mismatch with private memory-cuts for control-pulp ASIC/FPGA
- Fix uDMA clock-gating for control-pulp FPGA (bypass clock gating for FPGA flow)
- Fix wrong reset connected to timer module in control-pulp SoC	ASIC/FPGA
- Fix soc_clk_o (AXI and SoC clock) propagation for control-pulp top-level FPGA
- Fix wrong system reset connected to control_pulp top-level
- Fix HW compilation warnings (unconnected/undeclared signals)

## [3.0.0.] - 2021-07-30

### Changed
- Switch pulp-riscv-gnu-toolchain to `v2.2.0` in the CI (to be changed further in the future)
- Bump pulp-runtime to `v0.0.10`
- Bump tech_cells_generic to `v0.2.4`
- Bump (1:1 manual integration) pulp_soc to `v2.1.0`. This mainly consists of consistent changes in the `soc_interconnect`
- Bump pulp_cluster to `cluster-axi-update` dev branch (not released yet). This mainly consists of consistent changes in `cluster_interconnect` and `cluster_bus` backbones
- Bump cluster_peripherals to `v2.0.0`
- Bump cluster_interconnect to `v1.1.0`
- Bump icache_mp_128_pf to `6f2e54102001230db9c82432bf9e011842419a48`
- Bump hier-icache to `v1.2.0`
- Bump mchan to `5104953034dd0df46d574b3c4c839618079342ba`
- Bump axi to `v0.28.0`
- Set internal AXI ID and data width values within `pulp_soc` according to AXI xbar routing rules
- Change AXI clock domain crossing setup between `pulp_soc` and `pulp_cluster` with novel `axi_cdc_src` and `axi_cdc_dst` halves modules
- Decouple bootroms between RTL/ASIC and FPGA
- Overhaul top-level module port list according to specifications

### Added
- Add Xilinx IP to model PMS cluster L1 memory in the FPGA implementation
- Add dummy PMS firmware (no I/O) to CI
- Add Verible support for code linting/formatting
- Add cv32e40p IP from 91e7c749	(pulp-platform fork)
- Add ASIC synthesis constraints in the `synth` directory
- Add one private, per-core FPU in the cluster accelerator
- Add `float16`, `bfloat16` and `float SIMD` FPU support
- Add Platform Level Interrupt Controller (PLIC) for interrupt handling

### Removed
- Remove `soc_node` for AXI traffic. New `soc_interconnect` exploit its function.
- Remove sdk-releases directory

### Fixed
- Novel cluster interconnects give rise to a DRC error during FPGA placement, fixed with a set of two constraints

## [2.0.0] - 2021-04-12

### Changed
- Add soc and cluster in the same clock domain
- Make clock configurable. The actual setup has two main clocks, `sys_clk` and `ref_clk`. The former generates the clock for the SoC and the peripherals. The latter generates the 32 kHz timer clock.
- Expose memory cuts to top-level ports. In order to allow the IP to be tested without internal memory, we add a wrapper `control_pulp_with_mem` that instantiates either L2 memory (SoC) and L1 (Cluster) and is used in the testbenches.
- Overhaul AXI ports to be specifications-compliant: 1 AXI mst and 1 AXI slv
- Add intermediate level of structs for AXI ports. This is actually the primitive module (`control_pulp_structs`) instantiated within `control_pulp_with_mem` module
- Overhaul I/O interfaces to be specifications-compliant
- Bump `axi` to `v0.26.0`
- Bump `common_cells` to `v1.20.1`

### Added
- Add pulp-runtime `v0.0.5` as subtree
- Add `common_verification` `v0.1.1`
- Add `control_pulp` module with flatten AXI ports and I/O ports, the top-level IP of the PMS. It does instantiate `control_pulp_structs`
- Add SPI slave and ~~I2C slave~~ I/O modules
- Add independent bootrom, third boot mode (`PRELOADED`, from an external entity). Overhaul bootrom fallback
- Add testbenches for:
	- Executing software and test AXI master port (tb_control_pulp_aximst.sv)
	- Testing AXI slave port (tb_control_pulp_axislv.sv)
	- Testing SPI slave port (tb_control_pulp_spi_slv.sv)
	- Executing software and test AXI master port on FPGA wrapper (tb_control_pulp_aximst-txilzu9eg.sv)
	- Testing AXI slave port on FPGA wrapper (tb_control_pulp_axislv-txilzu9eg.sv)
	- Testing bootrom (tb_bootrom.sv)
	- Executing software and test AXI master port using PRELOADED boot, i.e. with binary loaded through AXI slave port (tb_control_pulp_axi_boot.sv)
	- Executing software and test AXI master port using PRELOADED boot, i.e. with binary loaded through AXI slave port on the FPGA wrapper (tb_control_pulp_axi_boot-txilzu9eg.sv)

- Add FPGA implementation:
	- Add RTL wrapper for FPGA, i.e. Vivado compliant (control_pulp_txilzu9eg.sv)
	- Add control_pulp IP packaging, block design creation, synthesis and implementation scripts (`fpga/` folder)

- Add tests to CI:
	- AXI master port test
	- AXI slave port test
	- SPI slave port test
	- Bootrom test
	- PRELOADED boot of control_pulp test
	- FPGA synthesis/implementation test replaces the previous implementation

### Removed
- Remove FLLs for clock generation
- Remove HWPE accelerator support
- Remove IBEX core support
- Remove unused I/O peripherals (e.g. camera interface)
- Remove L2 memory (SoC) and L1 memory (Cluster) from the design

### Fixed
- Rephrase FPGA implementation w.r.t. release [1.3.0]

##  Control PULP [1.3.0] - 2020-11-11

### Changed
- Enable ZFINX everywhere

### Added
- Add verification rams to noc and nocr07 axi out ports
- Add noc/nocr07 tests
- Add simple dc elaboration and generic synthesis test

### Fixed
- do not try to git pull when invoking ipstools
- access to noc and nocr07 from control pulp's view
- various tests
- various synthesis/elaboration problems

##  Control PULP [1.2.0] - 2020-05-19

### Changed
- Bump wdt to `v0.2` (multi driven net fix)
- Bump ipstools to 7c60243f
- Misc cleanups of code style (instance names, indentation, ...)
- Update CONTRIBUTING.md (workflow)

### Added
- Third boot mode by widening bootsel to 2 bits. Allows sms to boot by accessing
  memory mapped registers.
- Allow `generate-scripts` passing arguments to vlog

### Fixed
- Backport fixes from `pulp_soc` `v1.2.0`
  - parametrization of `NBIT_PADCFG`, `NUM_GPIO`
  - Constrain parameters to legal values
  - hartsel instantation as for loop instead of for gen loop
  - Declare constant functions before usage (dc synth fix)
- Fully expand parameters in instantiations
- Explod star in `pulp_soc`
- Remove dead `boot_l2` signal

## Control PULP [1.1.0] - 2020-02-28

### Changed
- Bump `pulp_cluster` to 741bbc94
- Pull updates from `pulp_soc` v1.1.1
- Setup scripts improvement

### Added
- Add `make help` target
- Support minimal runtime (pulp-runtime) and tests
- Allow fetch enable to be controlled by signals or register access

### Fixed
- Various CI issues
- Remove dead parameters

## Control PULP [1.0.0] - 2020-01-27

### Changed
- Clearly seperate pad frame stuff for simulation from control-pulp top-level
- Make SPI signals parametrizable
- Make I2C signals parametrizable
- Update sdk to `2019.12.05`
- Disable FPGA synthesis in CI (broken)
- Flatten all IPS with `git subtree`

### Added
- Fork PULP from `pulp-next-bluewww`
- Add `axi_data_width_converter.sv` from the `axi_dwc` (4cc7c1e) branch of `axi`
- Top-level for control-pulp
- Add gitlab CI (rtl, PULP software tests, fpga synthesis) and pipeline badge
- Add wdt and accompanying test
- Add `soc_node` (AXI interconnect for external AXI interfaces)

### Fixed
- AXI id widths from cluster to soc


## Open PULP 75cc0947d85cd86e63b499f5465fd054fa795e5aa - 2020-01-27
### Changed
- Use new `udma`
- Update `README.m` with FPGA usage instructions
- Move tests to subfolder `tests`
- Allow setting entry point with `-gENTRY_POINT`
- Update to sdk-release 2019.11.02
- Bump `pulp_soc` to `v1.1.0`

### Added
- DPI models for peripherals
- PMP support in RI5CY
- Debug module compliant with [RISC-V External Debug Support v0.13.1](https://github.com/riscv/riscv-debug-spec)
- Support for Xcelium
- ~~FPGA support for genesys2~~ (WIP)
- ~~FPGA support for Xilinx ZCU104~~ (WIP)
- ~~FPGA support for Xilinx ZCU102~~ (WIP)
- ~~FPGA support for Nexys Video~~ (WIP)
- ~~FPGA support for Zedboard~~ (WIP)
- [ibex](https://github.com/lowRISC/ibex/) support
- Improved software debugging (disassembly in simulator window)
- Gitlab CI (fpga synthesis, software tests, debug module tests)
- Automatic handling of VIPs (installing and compiling)
- CHANGELOG.md
- CI support for pulp-runtime to run tests, using bwruntest.py and
  tests/runtime-tests.yaml

### Removed
- Support for custom debug module
- zero-riscy support in the fabric controller

### Fixed
- JTAG issues
- Bad pad mux configuration
- Various jenkins CI issues
- Bootsel behavior
- Bugs in debug module integration
- AXI width issues
- USE_HWPE parameter propagation
- I2C EEPROM can now be concurrently used with I2C DPI model
- Small quartus compatibility fixes
- Many minor tb issues
- Properly propagate NB_CORES

## Open PULP [1.0.0] - 2018-02-09

### Added
- Initial release

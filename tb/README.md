# Control PULP - Verification

This is the testbench environment that is used to simulate `pms_top`. It provides
three execution modes:

- Load and execute programs through JTAG (JTAG boot, `bootsel=2'h1`)
- Execute preloaded programs on flash (QSPI boot, `bootsel=2'h2`)
- Load programs through AXI slave port (PRELOADED boot, `bootsel=2'h3`)

The aforementioned bootmodes are briefly highlighted in the [boot](../../boot) directory.

Before describing the booting recipes to follow in a simulation environment
according to the various bootmodes, the `fetch_enable` and `bootsel` signals are
hereby described.

The testbench setup is structured as follows:

- A module [fixture_pms_top.sv](fixture_pms_top.sv) instantiates the device under test (DUT), i.e. `pms_top`, and
the wrapper logic that is required to execute pure software tests or tests that involve interaction
with a simulated external environment. This module defines a batch of tasks to drive simulations.

- Several `tb_<testbench_name>.sv` that instantiate the `fixture_pms_top` and exploit the simulation tasks to drive the selected simulation.

The table below summarizes the testbenches available in the current state of the project.

| Testbench | Description |
| ------ | ------ |
| `tb_sw.sv` | Default tb for executing pure SW tests. It implements PRELOADED boot by default. |
| `tb_sw_jtag.sv` | It executes pure SW tests with JTAG boot. |
| `tb_bootrom.sv` | It checks bootrom and bootcode. |
| `tb_acpi.sv` | It simulates controlled CPU power-up/down sequencies via ACPI GPIOs. |
| `tb_fw.sv` | It simulates the Power Control FW control routine with external interaction using a simulation memory. |
| `tb_clic_prio_semantic.sv` | It simulates concurrent interrupt lines firing from the external to check CLIC's ability to arbitrate according to each interrupt line's level/priority. |
| `tb_i2c_slv_dump.sv` | It simulates an external I2C Master driver that writes to memory through Control PULP I2C slave port. Results are dumped. |
| `tb_i2c_slv_irq.sv` | External transactions from I2C Master fires an interrupt in Control PULP's CPU. Data are written when interrupt is acknowledged. |
| `tb_scmi_doorbell_b2b.sv` | It assumes SCMI messages lying in memory and notifies the controller via interrupt firing (doorbell). Interrupts are fired in back to back. |
| `tb_scmi_doorbell_conc.sv` | Same as above, but interrupts are fired concurrently, assuming several controlled processors write messages at the same time. |
| `tb_axi.sv` | It checks whether the AXI slave channel is functional. |

## Fetch enable and bootsel

Control PULP [top-level module](../pulp/pms_top.sv) shows the following signals associated to fetch enable and bootsel:

```verilog
[...]

  input logic              bootsel_valid_i,
  input logic [1:0]        bootsel_i,
  input logic              fc_fetch_en_valid_i,
  input logic              fc_fetch_en_i
);
```
Signals terminating with `_valid_i` enable triggering the fetch_enable or the chosen bootmode by:

1. Asserting the corresponding input logic signals (`fc_fetch_en_i` and `bootsel_i`);
2. Writing to memory mapped registers (shown below);

The following two tables highlight the relationship between each signal and the corresponding `_valid_i` counterpart:

| fc_fetch_en_valid_i | fc_fetch_en_i | Behaviour |
| ------ | ------ | ------ |
| 0 | 0/1 | Core Idle. Core wake-up by writing to address `0x1A10_4008` |
| 1 | 0 | Core idle |
| 1 | 1 | Core wake-up via `fc_fetch_en_i` logic signal |


| bootsel_valid_i | bootsel_i | Behaviour |
| ------ | ------ | ------ |
| 0 | X | Bootmode selection by writing to address `0x1A10_40C4` |
| 1 | `2'h1`/`2'h2`/`2'h3` | Bootmode selection via `bootsel_i` logic signal |

## Registers mapping

The table below shows registers addresses that are meaningful for the booting process.
They can be found under [ips/[..]/apb_soc_ctrl.sv](../../ips/pulp_soc/rtl/components/apb_soc_ctrl.sv) module.

| Register address | Description |
| ------ | ----- |
| `0x1A10_400C4` | Bootmode selection |
| `0x1A10_4008`| Fetch enable |
| `0x1A10_4004` | Boot address |
| `0x1A10_40A0` | Status register. EOC bit is Status[31] |

## Boot steps in the testbench environment

### JTAG and QSPI boot
When running tests or developing programs, we normally use the first mode to do
that. No special configuration is required to do that, just follow the PULP-SDK
documentation. By setting `LOAD_L2` to "STANDALONE" or "JTAG" you can boot from
flash or via JTAG respectively.

Currently we have two JTAG TAPs chained together: the first one is
[standard](https://github.com/riscv/riscv-debug-spec/blob/0.13-test-release/riscv-debug-spec.pdf)
compliant JTAG DTM (Debug Transport Module), while the second one is our custom
PULP TAP. Both can be used to access the L2 memory to load data into it. The
`USE_PULP_BUS_ACCESS` parameter can be used to choose which one to use. By
default we use the PULP TAP because it is much faster in simulation.

The overall flow for JTAG boot reads:

1. Assert fetch enable through register write or logic input signal assertion;
2. Select bootmode (`2'h1`) through register write or logic input signal;
3. Assert/De-assert active-low reset;
4. Fabric controller CPU (in pulp_soc) enters a busy loop `wfi`. Debug module takes control;
5. Debug module write elf image of the executing code (e.g. the Control FW) to control-pulp L2 memory;
6. Debug module writes entry point to `dpc` register in the core.
   Entry point is `0x1C00_8080` for bare-metal tests and `0x1C00_880` for freertos tests.
   `dpc` is a standard CSR from the RISC-V debug module standard;
7. Debug module calls `dret` and jumps to the entrypoint stored in the `dpc` CSR;
8. Core starts fetching instructions.
9. `Status` register is probed until EOC = Status[31]==1, which signals the end of computation.

### OpenOCD
If you wish to interact with the testbench through GDB and OpenOCD you can do
this by setting the `ENABLE_OPENOCD=1` parameter. Careful OpenOCD and GDB need a
long time to establish a connection with the testbench (due to simulation being
slow) so timeouts have to be set accordingly.

We recommend to do this with the following steps
1. Compile and run your program using the pulp-sdk with the following command:
   `make conf CONFIG_OPT="vsim/tcl_args=-sv_lib vsim/tcl_args="${VSIM_PATH}"/../rtl/tb/remote_bitbang/librbs vsim/tcl_args=-gENABLE_OPENOCD=1" clean all run`
2. If done correctly you get the following message:
   ```
   This emulator compiled with JTAG Remote Bitbang client.
   Listening on port 42087
   Attempting to accept client socket
   ```

   Set now the environment variable `JTAG_VPI_PORT` to the port the server is
   listening to by calling `export JTAG_VPI_PORT=[portname]`. The server will
   accept commands from openocd redirect those through DPI to the JTAG module in
   the testbench.
3. Call `openocd -f pulpissimo_debug.cfg`. After a while you will be prompted
   with an address you can connect gdb to, normally `localhost:3333`

### Preloaded boot

Preloaded bootmode can be used when an external driver will manage the booting procedure.
For example, an external OS could boot control-pulp in this mode.

The overall flow for Preloaded boot reads:

1. Select bootmode (`2'h3`) through register write or logic input signal;
2. Assert/De-assert active-low reset;
3. External driver write elf image of the executing code (e.g. the Control FW) to control-pulp L2 memory through AXI slave port;
5. External driver writes entry point to `boot address` register in the core.
   Entry point is `0x1C00_8080` for bare-metal tests and `0x1C00_880` for freertos tests.
   `boot address` is a standard CSR from the RISC-V debug module standard and reads `0x1A00_4000`;
6. Assert fetch enable through register write or logic input signal assertion;
7. Core starts fetching instructions;
8. `Status` register is probed until EOC = Status[31]==1, which signals the end of computation.

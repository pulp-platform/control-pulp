# Control PULP - Top-level module

The top-level module of Control PULP (PMS in EPI terminology) is
`pms_top.sv`.
It flattens the AXI4 ports and I/O peripherals ports from a more packed-oriented instantiation,
which is easier to handle, namely `control_pulp.sv`.

`control_pulp` consists of two main modules:

- `soc_domain.sv`: it hosts the SoC, which contains a single CV32E40P core
(Fabric Controller, FC). AXI ports, I/O peripherals are routed through AXI4
interconnect fabric. It contains a 512 KiB SRAM (L2) where the code to be
executed - by the FC or offloaded to the cluster accelerator - is preloaded.

- `cluster_domain.sv`: it hosts the Cluster accelerator, a cluster of 8 CV32E40P
cores routed through AXI4 fabric to a TCDM scratchpad memory (L1).

## Top-level parameters

The top-level module comes with several parameters. They are required to configure the PMS
according to the selected feature, or to control memory macro instantiation when the IP is not
used in a RTL simulation environment.
The table below shows their function:

| Parameter | Value=1 | Value=0 |
| ------ | ------ | ------ |
| `CORE_TYPE` | Use `CV32E40P` as 32-bit processor for both SoC and Cluster accelerator. | Raises an `Error`, since support for other processors is disabled in ControlPULP |
| `USE_FPU` | Instantiate one private FPU per-processor, 9 in total. Note that the FPU is decoupled from the processor. | Do not instantiate the FPU in any of the 9 processors. |
| `PULP_XPULP` | Use XPULP extensions. | Do not use XPULP extensions. |
| `SIM_STDOUT` | Control simulation `stdout`. **Set to 1 in simulation only.** | Remove non-sythesizable code related to `stdout` control. **Set to 0 during synthesis.** |
| `BEHAV_MEM` | Use behavioral memories for L2, L1 and cluster cache data/tag fields. **Set to 1 in simulation only.** | Use memory macros (technology dependent, under `ips/tech_mem`). **Set to 0 during synthesis.** |
| `MACRO_ROM` | Use ROM macro as BootROM. | Use synthesizable ROM as BootROM |

In addition, we make AXI Data and ID width configurable through internal converters as described in the [main README.md of this repository](../../README.md).
AXI Address width equals 32 bit, and it is not configurable.

| Parameter | Value |
| ------ | ------ |
| `AXI_DATA_INP_WIDTH_EXT` | PMS AXI4 Slave port data width |
| `AXI_DATA_OUP_WIDTH_EXT` | PMS AXI4 Master port data width |
| `AXI_ID_INP_WIDTH_EXT` | PMS AXI4 Slave port ID width|
| `AXI_ID_OUP_WIDTH_EXT` | PMS AXI4 Master port ID width |

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

## Example instantiation

The top-level module of Control PULP can be instantiated as follows:

```verilog
module pms_top
  import control_pulp_pkg::*; #(

  parameter int unsigned  CORE_TYPE = 0, // 0 for CV32E40P (other options are not supported)
  parameter int unsigned  USE_FPU = 1,
  parameter int unsigned  PULP_XPULP = 1,
  parameter int unsigned  SIM_STDOUT = 1,
  parameter int unsigned  BEHAV_MEM = 1,
  parameter int unsigned  MACRO_ROM = 0,

  parameter int unsigned  AXI_DATA_INP_WIDTH_EXT = 64, // External parameter from nci_cp_top
  localparam int unsigned AXI_STRB_INP_WIDTH_EXT = AXI_DATA_INP_WIDTH_EXT/8,
  parameter int unsigned  AXI_DATA_OUP_WIDTH_EXT = 64, // External parameter from nci_cp_top
  localparam int unsigned AXI_STRB_OUP_WIDTH_EXT = AXI_DATA_OUP_WIDTH_EXT/8,
  parameter int unsigned  AXI_ID_OUP_WIDTH_EXT   = 7,  // External parameter from nci_cp_top
  parameter int unsigned  AXI_ID_INP_WIDTH_EXT   = 6   // External parameter from nci_cp_top

) (

  // AXI ports to external, flattened

  // AXI Master to nci_cp_top
  output logic [AXI_ID_OUP_WIDTH_EXT-1:0]   awid_mst_o,
  output logic [AXI_ADDR_WIDTH_PMS-1:0]     awaddr_mst_o,
  output logic [7:0]                        awlen_mst_o,
  output logic [2:0]                        awsize_mst_o,
  output logic [1:0]                        awburst_mst_o,
  output logic                              awlock_mst_o,
  output logic [3:0]                        awcache_mst_o,
  output logic [2:0]                        awprot_mst_o,
  output logic [3:0]                        awqos_mst_o,
  output logic [3:0]                        awregion_mst_o,
  output logic [5:0]                        aw_atop_mst_o,
  output logic [AXI_USER_WIDTH_PMS-1:0]     awuser_mst_o,
  output logic                              awvalid_mst_o,
  input logic                               awready_mst_i,

  output logic [AXI_DATA_OUP_WIDTH_EXT-1:0] wdata_mst_o,
  output logic [AXI_STRB_OUP_WIDTH_EXT-1:0] wstrb_mst_o,
  output logic                              wlast_mst_o,
  output logic [AXI_USER_WIDTH_PMS-1:0]     wuser_mst_o,
  output logic                              wvalid_mst_o,
  input logic                               wready_mst_i,

  input logic [AXI_ID_OUP_WIDTH_EXT-1:0]    bid_mst_i,
  input logic [1:0]                         bresp_mst_i,
  input logic [AXI_USER_WIDTH_PMS-1:0]      buser_mst_i,
  input logic                               bvalid_mst_i,
  output logic                              bready_mst_o,

  output logic [AXI_ID_OUP_WIDTH_EXT-1:0]   arid_mst_o,
  output logic [AXI_ADDR_WIDTH_PMS-1:0]     araddr_mst_o,
  output logic [7:0]                        arlen_mst_o,
  output logic [2:0]                        arsize_mst_o,
  output logic [1:0]                        arburst_mst_o,
  output logic                              arlock_mst_o,
  output logic [3:0]                        arcache_mst_o,
  output logic [2:0]                        arprot_mst_o,
  output logic [3:0]                        arqos_mst_o,
  output logic [3:0]                        arregion_mst_o,
  output logic [AXI_USER_WIDTH_PMS-1:0]     aruser_mst_o,
  output logic                              arvalid_mst_o,
  input logic                               arready_mst_i,

  input logic [AXI_ID_OUP_WIDTH_EXT-1:0]    rid_mst_i,
  input logic [AXI_DATA_OUP_WIDTH_EXT-1:0]  rdata_mst_i,
  input logic [1:0]                         rresp_mst_i,
  input logic                               rlast_mst_i,
  input logic [AXI_USER_WIDTH_PMS-1:0]      ruser_mst_i,
  input logic                               rvalid_mst_i,
  output logic                              rready_mst_o,


  // AXI Slave from nci_cp_top
  input logic [AXI_ID_INP_WIDTH_EXT-1:0]    awid_slv_i,
  input logic [AXI_ADDR_WIDTH_PMS-1:0]      awaddr_slv_i,
  input logic [7:0]                         awlen_slv_i,
  input logic [2:0]                         awsize_slv_i,
  input logic [1:0]                         awburst_slv_i,
  input logic                               awlock_slv_i,
  input logic [3:0]                         awcache_slv_i,
  input logic [2:0]                         awprot_slv_i,
  input logic [3:0]                         awqos_slv_i,
  input logic [3:0]                         awregion_slv_i,
  input logic [5:0]                         aw_atop_slv_i,
  input logic [AXI_USER_WIDTH_PMS-1:0]      awuser_slv_i,
  input logic                               awvalid_slv_i,
  output logic                              awready_slv_o,

  input logic [AXI_DATA_INP_WIDTH_EXT-1:0]  wdata_slv_i,
  input logic [AXI_STRB_INP_WIDTH_EXT-1:0]  wstrb_slv_i,
  input logic                               wlast_slv_i,
  input logic [AXI_USER_WIDTH_PMS-1:0]      wuser_slv_i,
  input logic                               wvalid_slv_i,
  output logic                              wready_slv_o,

  output logic [AXI_ID_INP_WIDTH_EXT-1:0]   bid_slv_o,
  output logic [1:0]                        bresp_slv_o,
  output logic [AXI_USER_WIDTH_PMS-1:0]     buser_slv_o,
  output logic                              bvalid_slv_o,
  input logic                               bready_slv_i,

  input logic [AXI_ID_INP_WIDTH_EXT-1:0]    arid_slv_i,
  input logic [AXI_ADDR_WIDTH_PMS-1:0]      araddr_slv_i,
  input logic [7:0]                         arlen_slv_i,
  input logic [2:0]                         arsize_slv_i,
  input logic [1:0]                         arburst_slv_i,
  input logic                               arlock_slv_i,
  input logic [3:0]                         arcache_slv_i,
  input logic [2:0]                         arprot_slv_i,
  input logic [3:0]                         arqos_slv_i,
  input logic [3:0]                         arregion_slv_i,
  input logic [AXI_USER_WIDTH_PMS-1:0]      aruser_slv_i,
  input logic                               arvalid_slv_i,
  output logic                              arready_slv_o,

  output logic [AXI_ID_INP_WIDTH_EXT-1:0]   rid_slv_o,
  output logic [AXI_DATA_INP_WIDTH_EXT-1:0] rdata_slv_o,
  output logic [1:0]                        rresp_slv_o,
  output logic                              rlast_slv_o,
  output logic [AXI_USER_WIDTH_PMS-1:0]     ruser_slv_o,
  output logic                              rvalid_slv_o,
  input logic                               rready_slv_i,

  // inout signals are split into input, output and enables
  output logic [31:0][5:0]                  pad_cfg_o,
  // clock
  input logic                               ref_clk_i,
  input logic                               sys_clk_i,
  output logic                              soc_clk_o,
  input logic                               rst_ni,
  // jtag
  output logic                              jtag_tdo_o,
  input logic                               jtag_tck_i,
  input logic                               jtag_tdi_i,
  input logic                               jtag_tms_i,
  input logic                               jtag_trst_i,
  // wdt
  output logic [1:0]                        wdt_alert_o,
  input  logic                              wdt_alert_clear_i,
  // interrupts
  input logic                               scg_irq_i,
  input logic                               scp_irq_i,
  input logic                               scp_secure_irq_i,
  input logic [71:0]                        mbox_irq_i,
  input logic [71:0]                        mbox_secure_irq_i,

  // Inout signals are split into input, output and enables

  //
  // Master interfaces
  //

  //I2C
  output logic                              out_i2c0_vrm_mst_scl_o,
  output logic                              out_i2c0_vrm_mst_sda_o,
  output logic                              out_i2c0_vrm_mst_alert_o,

  output logic                              oe_i2c0_vrm_mst_scl_o,
  output logic                              oe_i2c0_vrm_mst_sda_o,
  output logic                              oe_i2c0_vrm_mst_alert_o,

  input logic                               in_i2c0_vrm_mst_scl_i,
  input logic                               in_i2c0_vrm_mst_sda_i,
  input logic                               in_i2c0_vrm_mst_alert_i,

  output logic                              out_i2c1_vrm_mst_scl_o,
  output logic                              out_i2c1_vrm_mst_sda_o,
  output logic                              out_i2c1_vrm_mst_alert_o,

  output logic                              oe_i2c1_vrm_mst_scl_o,
  output logic                              oe_i2c1_vrm_mst_sda_o,
  output logic                              oe_i2c1_vrm_mst_alert_o,

  input logic                               in_i2c1_vrm_mst_scl_i,
  input logic                               in_i2c1_vrm_mst_sda_i,
  input logic                               in_i2c1_vrm_mst_alert_i,

  output logic                              out_i2c2_vrm_mst_scl_o,
  output logic                              out_i2c2_vrm_mst_sda_o,
  output logic                              out_i2c2_vrm_mst_alert_o,

  output logic                              oe_i2c2_vrm_mst_scl_o,
  output logic                              oe_i2c2_vrm_mst_sda_o,
  output logic                              oe_i2c2_vrm_mst_alert_o,

  input logic                               in_i2c2_vrm_mst_scl_i,
  input logic                               in_i2c2_vrm_mst_sda_i,
  input logic                               in_i2c2_vrm_mst_alert_i,

  output logic                              out_i2c3_vrm_mst_scl_o,
  output logic                              out_i2c3_vrm_mst_sda_o,
  output logic                              out_i2c3_vrm_mst_alert_o,

  output logic                              oe_i2c3_vrm_mst_scl_o,
  output logic                              oe_i2c3_vrm_mst_sda_o,
  output logic                              oe_i2c3_vrm_mst_alert_o,

  input logic                               in_i2c3_vrm_mst_scl_i,
  input logic                               in_i2c3_vrm_mst_sda_i,
  input logic                               in_i2c3_vrm_mst_alert_i,

  output logic                              out_i2c4_vrm_mst_scl_o,
  output logic                              out_i2c4_vrm_mst_sda_o,
  output logic                              out_i2c4_vrm_mst_alert_o,

  output logic                              oe_i2c4_vrm_mst_scl_o,
  output logic                              oe_i2c4_vrm_mst_sda_o,
  output logic                              oe_i2c4_vrm_mst_alert_o,

  input logic                               in_i2c4_vrm_mst_scl_i,
  input logic                               in_i2c4_vrm_mst_sda_i,
  input logic                               in_i2c4_vrm_mst_alert_i,

  output logic                              out_i2cc_vrm_mst_scl_o,
  output logic                              out_i2cc_vrm_mst_sda_o,
  output logic                              out_i2cc_vrm_mst_alert_o,

  output logic                              oe_i2cc_vrm_mst_scl_o,
  output logic                              oe_i2cc_vrm_mst_sda_o,
  output logic                              oe_i2cc_vrm_mst_alert_o,

  input logic                               in_i2cc_vrm_mst_scl_i,
  input logic                               in_i2cc_vrm_mst_sda_i,
  input logic                               in_i2cc_vrm_mst_alert_i,

  output logic                              out_i2c6_rtc_mst_scl_o,
  output logic                              out_i2c6_rtc_mst_sda_o,
  output logic                              out_i2c6_rtc_mst_alert_o,

  output logic                              oe_i2c6_rtc_mst_scl_o,
  output logic                              oe_i2c6_rtc_mst_sda_o,
  output logic                              oe_i2c6_rtc_mst_alert_o,

  input logic                               in_i2c6_rtc_mst_scl_i,
  input logic                               in_i2c6_rtc_mst_sda_i,
  input logic                               in_i2c6_rtc_mst_alert_i,

  output logic                              out_i2c7_bmc_slv_scl_o,
  output logic                              out_i2c7_bmc_slv_sda_o,

  output logic                              oe_i2c7_bmc_slv_scl_o,
  output logic                              oe_i2c7_bmc_slv_sda_o,

  input logic                               in_i2c7_bmc_slv_scl_i,
  input logic                               in_i2c7_bmc_slv_sda_i,

  output logic                              out_i2c8_os_mst_scl_o,
  output logic                              out_i2c8_os_mst_sda_o,
  output logic                              out_i2c8_os_mst_alert_o,

  output logic                              oe_i2c8_os_mst_scl_o,
  output logic                              oe_i2c8_os_mst_sda_o,
  output logic                              oe_i2c8_os_mst_alert_o,

  input logic                               in_i2c8_os_mst_scl_i,
  input logic                               in_i2c8_os_mst_sda_i,
  input logic                               in_i2c8_os_mst_alert_i,

  output logic                              out_i2c9_pcie_pnp_mst_scl_o,
  output logic                              out_i2c9_pcie_pnp_mst_sda_o,
  output logic                              out_i2c9_pcie_pnp_mst_alert_o,

  output logic                              oe_i2c9_pcie_pnp_mst_scl_o,
  output logic                              oe_i2c9_pcie_pnp_mst_sda_o,
  output logic                              oe_i2c9_pcie_pnp_mst_alert_o,

  input logic                               in_i2c9_pcie_pnp_mst_scl_i,
  input logic                               in_i2c9_pcie_pnp_mst_sda_i,
  input logic                               in_i2c9_pcie_pnp_mst_alert_i,

  output logic                              out_i2ca_bios_mst_scl_o,
  output logic                              out_i2ca_bios_mst_sda_o,
  output logic                              out_i2ca_bios_mst_alert_o,

  output logic                              oe_i2ca_bios_mst_scl_o,
  output logic                              oe_i2ca_bios_mst_sda_o,
  output logic                              oe_i2ca_bios_mst_alert_o,

  input logic                               in_i2ca_bios_mst_scl_i,
  input logic                               in_i2ca_bios_mst_sda_i,
  input logic                               in_i2ca_bios_mst_alert_i,

  output logic                              out_i2cb_bmc_mst_scl_o,
  output logic                              out_i2cb_bmc_mst_sda_o,
  output logic                              out_i2cb_bmc_mst_alert_o,

  output logic                              oe_i2cb_bmc_mst_scl_o,
  output logic                              oe_i2cb_bmc_mst_sda_o,
  output logic                              oe_i2cb_bmc_mst_alert_o,

  input logic                               in_i2cb_bmc_mst_scl_i,
  input logic                               in_i2cb_bmc_mst_sda_i,
  input logic                               in_i2cb_bmc_mst_alert_i,

  //SPI
  input logic                               in_qspi_flash_mst_csn0_i,
  input logic                               in_qspi_flash_mst_csn1_i,
  input logic                               in_qspi_flash_mst_sck_i,
  input logic [3:0]                         in_qspi_flash_mst_sdio_i,

  output logic                              out_qspi_flash_mst_csn0_o,
  output logic                              out_qspi_flash_mst_csn1_o,
  output logic                              out_qspi_flash_mst_sck_o,
  output logic [3:0]                        out_qspi_flash_mst_sdio_o,

  output logic                              oe_qspi_flash_mst_csn0_o,
  output logic                              oe_qspi_flash_mst_csn1_o,
  output logic                              oe_qspi_flash_mst_sck_o,
  output logic [3:0]                        oe_qspi_flash_mst_sdio_o,

  input logic                               in_spi0_vrm_mst_csn0_i,
  input logic                               in_spi0_vrm_mst_csn1_i,
  input logic                               in_spi0_vrm_mst_sck_i,
  input logic                               in_spi0_vrm_mst_si_i,
  input logic                               in_spi0_vrm_mst_so_i,

  output logic                              out_spi0_vrm_mst_csn0_o,
  output logic                              out_spi0_vrm_mst_csn1_o,
  output logic                              out_spi0_vrm_mst_sck_o,
  output logic                              out_spi0_vrm_mst_si_o,
  output logic                              out_spi0_vrm_mst_so_o,

  output logic                              oe_spi0_vrm_mst_csn0_o,
  output logic                              oe_spi0_vrm_mst_csn1_o,
  output logic                              oe_spi0_vrm_mst_sck_o,
  output logic                              oe_spi0_vrm_mst_si_o,
  output logic                              oe_spi0_vrm_mst_so_o,

  input logic                               in_spi1_vrm_mst_csn0_i,
  input logic                               in_spi1_vrm_mst_csn1_i,
  input logic                               in_spi1_vrm_mst_sck_i,
  input logic                               in_spi1_vrm_mst_si_i,
  input logic                               in_spi1_vrm_mst_so_i,

  output logic                              out_spi1_vrm_mst_csn0_o,
  output logic                              out_spi1_vrm_mst_csn1_o,
  output logic                              out_spi1_vrm_mst_sck_o,
  output logic                              out_spi1_vrm_mst_si_o,
  output logic                              out_spi1_vrm_mst_so_o,

  output logic                              oe_spi1_vrm_mst_csn0_o,
  output logic                              oe_spi1_vrm_mst_csn1_o,
  output logic                              oe_spi1_vrm_mst_sck_o,
  output logic                              oe_spi1_vrm_mst_si_o,
  output logic                              oe_spi1_vrm_mst_so_o,

  input logic                               in_spi2_vrm_mst_csn0_i,
  input logic                               in_spi2_vrm_mst_csn1_i,
  input logic                               in_spi2_vrm_mst_sck_i,
  input logic                               in_spi2_vrm_mst_si_i,
  input logic                               in_spi2_vrm_mst_so_i,

  output logic                              out_spi2_vrm_mst_csn0_o,
  output logic                              out_spi2_vrm_mst_csn1_o,
  output logic                              out_spi2_vrm_mst_sck_o,
  output logic                              out_spi2_vrm_mst_si_o,
  output logic                              out_spi2_vrm_mst_so_o,

  output logic                              oe_spi2_vrm_mst_csn0_o,
  output logic                              oe_spi2_vrm_mst_csn1_o,
  output logic                              oe_spi2_vrm_mst_sck_o,
  output logic                              oe_spi2_vrm_mst_si_o,
  output logic                              oe_spi2_vrm_mst_so_o,

  input logic                               in_spi3_vrm_mst_csn_i,
  input logic                               in_spi3_vrm_mst_sck_i,
  input logic                               in_spi3_vrm_mst_si_i,
  input logic                               in_spi3_vrm_mst_so_i,

  output logic                              out_spi3_vrm_mst_csn_o,
  output logic                              out_spi3_vrm_mst_sck_o,
  output logic                              out_spi3_vrm_mst_si_o,
  output logic                              out_spi3_vrm_mst_so_o,

  output logic                              oe_spi3_vrm_mst_csn_o,
  output logic                              oe_spi3_vrm_mst_sck_o,
  output logic                              oe_spi3_vrm_mst_si_o,
  output logic                              oe_spi3_vrm_mst_so_o,

  input logic                               in_spi4_vrm_mst_csn_i,
  input logic                               in_spi4_vrm_mst_sck_i,
  input logic                               in_spi4_vrm_mst_si_i,
  input logic                               in_spi4_vrm_mst_so_i,

  output logic                              out_spi4_vrm_mst_csn_o,
  output logic                              out_spi4_vrm_mst_sck_o,
  output logic                              out_spi4_vrm_mst_si_o,
  output logic                              out_spi4_vrm_mst_so_o,

  output logic                              oe_spi4_vrm_mst_csn_o,
  output logic                              oe_spi4_vrm_mst_sck_o,
  output logic                              oe_spi4_vrm_mst_si_o,
  output logic                              oe_spi4_vrm_mst_so_o,

  input logic                               in_spi6_vrm_mst_csn_i,
  input logic                               in_spi6_vrm_mst_sck_i,
  input logic                               in_spi6_vrm_mst_si_i,
  input logic                               in_spi6_vrm_mst_so_i,

  output logic                              out_spi6_vrm_mst_csn_o,
  output logic                              out_spi6_vrm_mst_sck_o,
  output logic                              out_spi6_vrm_mst_si_o,
  output logic                              out_spi6_vrm_mst_so_o,

  output logic                              oe_spi6_vrm_mst_csn_o,
  output logic                              oe_spi6_vrm_mst_sck_o,
  output logic                              oe_spi6_vrm_mst_si_o,
  output logic                              oe_spi6_vrm_mst_so_o,

  //UART
  input logic                               in_uart1_rxd_i,
  input logic                               in_uart1_txd_i,

  output logic                              out_uart1_rxd_o,
  output logic                              out_uart1_txd_o,

  output logic                              oe_uart1_rxd_o,
  output logic                              oe_uart1_txd_o,

  //
  // Internally multiplexed interfaces
  //

  //I2C
  output logic                              out_i2c5_intr_sckt_scl_o,
  output logic                              out_i2c5_intr_sckt_sda_o,
  output logic                              out_i2c5_intr_sckt_alert_o,

  output logic                              oe_i2c5_intr_sckt_scl_o,
  output logic                              oe_i2c5_intr_sckt_sda_o,
  output logic                              oe_i2c5_intr_sckt_alert_o,

  input logic                               in_i2c5_intr_sckt_scl_i,
  input logic                               in_i2c5_intr_sckt_sda_i,
  input logic                               in_i2c5_intr_sckt_alert_i,

  //SPI
  input logic                               in_spi5_intr_sckt_csn_i,
  input logic                               in_spi5_intr_sckt_sck_i,
  input logic                               in_spi5_intr_sckt_si_i,
  input logic                               in_spi5_intr_sckt_so_i,
  input logic                               in_spi5_intr_sckt_alert_i,

  output logic                              out_spi5_intr_sckt_csn_o,
  output logic                              out_spi5_intr_sckt_sck_o,
  output logic                              out_spi5_intr_sckt_si_o,
  output logic                              out_spi5_intr_sckt_so_o,
  output logic                              out_spi5_intr_sckt_alert_o,

  output logic                              oe_spi5_intr_sckt_csn_o,
  output logic                              oe_spi5_intr_sckt_sck_o,
  output logic                              oe_spi5_intr_sckt_si_o,
  output logic                              oe_spi5_intr_sckt_so_o,
  output logic                              oe_spi5_intr_sckt_alert_o,

  //
  // SLP, SYS, CPU pins
  //
  output logic                              out_slp_s3_l_o,
  output logic                              out_slp_s4_l_o,
  output logic                              out_slp_s5_l_o,
  output logic                              out_sys_reset_l_o,
  output logic                              out_sys_rsmrst_l_o,
  output logic                              out_sys_pwr_btn_l_o,
  output logic                              out_sys_pwrgd_in_o,
  output logic                              out_sys_wake_l_o,
  output logic                              out_cpu_pwrgd_out_o,
  output logic [1:0]                        out_cpu_throttle_o,
  output logic                              out_cpu_thermtrip_l_o,
  output logic [3:0]                        out_cpu_errcode_o,
  output logic                              out_cpu_reset_out_l_o,
  output logic [1:0]                        out_cpu_socket_id_o,
  output logic [3:0]                        out_cpu_strap_o,

  output logic                              oe_slp_s3_l_o,
  output logic                              oe_slp_s4_l_o,
  output logic                              oe_slp_s5_l_o,
  output logic                              oe_sys_reset_l_o,
  output logic                              oe_sys_rsmrst_l_o,
  output logic                              oe_sys_pwr_btn_l_o,
  output logic                              oe_sys_pwrgd_in_o,
  output logic                              oe_sys_wake_l_o,
  output logic                              oe_cpu_pwrgd_out_o,
  output logic [1:0]                        oe_cpu_throttle_o,
  output logic                              oe_cpu_thermtrip_l_o,
  output logic [3:0]                        oe_cpu_errcode_o,
  output logic                              oe_cpu_reset_out_l_o,
  output logic [1:0]                        oe_cpu_socket_id_o,
  output logic [3:0]                        oe_cpu_strap_o,

  input logic                               in_slp_s3_l_i,
  input logic                               in_slp_s4_l_i,
  input logic                               in_slp_s5_l_i,
  input logic                               in_sys_reset_l_i,
  input logic                               in_sys_rsmrst_l_i,
  input logic                               in_sys_pwr_btn_l_i,
  input logic                               in_sys_pwrgd_in_i,
  input logic                               in_sys_wake_l_i,
  input logic                               in_cpu_pwrgd_out_i,
  input logic [1:0]                         in_cpu_throttle_i,
  input logic                               in_cpu_thermtrip_l_i,
  input logic [3:0]                         in_cpu_errcode_i,
  input logic                               in_cpu_reset_out_l_i,
  input logic [1:0]                         in_cpu_socket_id_i,
  input logic [3:0]                         in_cpu_strap_i,

  input logic                               bootsel_valid_i,
  input logic [1:0]                         bootsel_i,
  input logic                               fc_fetch_en_valid_i,
  input logic                               fc_fetch_en_i

);
```

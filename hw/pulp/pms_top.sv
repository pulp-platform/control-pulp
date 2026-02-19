// Copyright 2023 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law or
// agreed to in writing, software, hardware and materials distributed under this
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the specific
// language governing permissions and limitations under the License.

// SPDX-License-Identifier: SHL-0.51

// Robert Balas <balasr@iis.ee.ethz.ch>
// Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>


`include "pulp_soc_defines.sv"
`include "soc_bus_defines.sv"
`include "control_pulp_assign.svh"
`include "axi/assign.svh"
`include "axi/typedef.svh"


// PMS top-level module

module pms_top import pms_top_pkg::*; #(

  parameter int unsigned  CORE_TYPE = 0, // 0 for CV32E40P (other options are not supported)
  parameter int unsigned  USE_FPU = 1,
  parameter int unsigned  PULP_XPULP = 1,
  parameter int unsigned  SIM_STDOUT = 0,
  parameter int unsigned  BEHAV_MEM = 1,
  parameter int unsigned  MACRO_ROM = 0,
  parameter int unsigned  USE_CLUSTER = 1,
  parameter int unsigned  DMA_TYPE = 1, // 1 for idma (new), 0 for mchan (legacy). Default 1 for idma
  parameter int unsigned  SDMA_RT_MIDEND = 0, //only valid when using idma (DMA_TYPE=1

  parameter int unsigned N_L2_BANKS = 4,          // num interleaved banks
  parameter int unsigned N_L2_BANKS_PRI = 2,      // num private banks
  parameter int unsigned L2_BANK_SIZE = 28672,    // size of single L2 interleaved bank in 32-bit words
  parameter int unsigned N_L1_BANKS = 16,         // num of banks in cluster
  parameter int unsigned L1_BANK_SIZE = 1024,     // size of single L1 bank in 32-bit words

  parameter int unsigned  N_SOC_PERF_COUNTERS = 1,
  parameter int unsigned  N_CLUST_PERF_COUNTERS = 1,
  parameter int unsigned  N_I2C = 12,
  parameter int unsigned  N_I2C_SLV = 2,
  parameter int unsigned  N_SPI = 8,
  parameter int unsigned  N_UART = 1,

  parameter int unsigned  AXI_DATA_INP_WIDTH_EXT = 64, // External parameter from nci_cp_top
  localparam int unsigned AXI_STRB_INP_WIDTH_EXT = AXI_DATA_INP_WIDTH_EXT/8,
  parameter int unsigned  AXI_DATA_OUP_WIDTH_EXT = 64, // External parameter from nci_cp_top
  localparam int unsigned AXI_STRB_OUP_WIDTH_EXT = AXI_DATA_OUP_WIDTH_EXT/8,
  parameter int unsigned  AXI_ID_OUP_WIDTH_EXT = 7, // External parameter from nci_cp_top
  parameter int unsigned  AXI_ID_INP_WIDTH_EXT = 6, // External parameter from nci_cp_top

  // D2D link
  parameter int unsigned USE_D2D = 0,
  parameter int unsigned USE_D2D_DELAY_LINE = 0,
  parameter int unsigned D2D_NUM_CHANNELS = 1,
  parameter int unsigned D2D_NUM_LANES = 1,
  parameter int unsigned D2D_NUM_CREDITS = 1

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

  // D2D interface
  input logic  [D2D_NUM_CHANNELS-1:0]                    d2d_clk_i,
  input logic  [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_i,
  output logic [D2D_NUM_CHANNELS-1:0]                    d2d_clk_o,
  output logic [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_o,

  // inout signals are split into input, output and enables
  output logic [31:0][5:0]                  pad_cfg_o,

  // clock
  input logic                               ref_clk_i,
  input logic                               sys_clk_i,
  output logic                              soc_clk_o,
  // test clock and dft
  input logic                               test_clk_i,
  input logic                               dft_test_mode_i,
  input logic                               dft_cg_enable_i,
  // reset
  input logic                               rst_ni,
  // jtag
  output logic                              jtag_tdo_o,
  input logic                               jtag_tck_i,
  input logic                               jtag_tdi_i,
  input logic                               jtag_tms_i,
  input logic                               jtag_trst_ni,
  // wdt
  output logic [1:0]                        wdt_alert_o,
  input logic                               wdt_alert_clear_i,
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

  // Clock and reset generation, external clock configuration
  logic                    s_soc_clk, s_cluster_clk, s_periph_clk, s_timer_clk;
  logic                    s_soc_rstn, s_cluster_rstn, s_cluster_rstn_gen, s_cluster_rstn_reg;
  logic                    s_clk_mux_sel;

  APB_BUS                  s_apb_clk_ctrl_bus();
  APB_BUS                  s_apb_pad_cfg_bus();

  assign s_cluster_rstn = s_cluster_rstn_gen && s_cluster_rstn_reg;

  system_clk_rst_gen i_system_clk_rst_gen (
    .sys_clk_i                  ( sys_clk_i                     ), // External 800 MHz clock
    .ref_clk_i                  ( ref_clk_i                     ), // External 100 MHz clock
    .clk_sel_i                  ( s_clk_mux_sel                 ),

    .rstn_glob_i                ( rst_ni                        ),
    .rstn_soc_sync_o            ( s_soc_rstn                    ),
    .rstn_cluster_sync_o        ( s_cluster_rstn_gen            ),

    .test_mode_i                ( dft_test_mode_i               ),

    .apb_slave                  ( s_apb_clk_ctrl_bus            ), // From soc_domain: clock dividers config

    .clk_soc_o                  ( s_soc_clk                     ), // Generated clocks
    .clk_per_o                  ( s_periph_clk                  ),
    .clk_slow_o                 ( s_timer_clk                   ),
    .clk_cluster_o              ( s_cluster_clk                 )
  );

  // Tie Padframe configuration APB port
  assign s_apb_pad_cfg_bus.prdata = 1'b0;
  assign s_apb_pad_cfg_bus.pready = 1'b0;
  assign s_apb_pad_cfg_bus.pslverr = 1'b0;

  // AXI4 types and structs for ID and data width conversion, external (in/out)
  // direction

   // PMS AXI Master
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_inp_ext_t,     axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_inp_ext_t,      axi_data_inp_ext_t, axi_strb_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_inp_ext_t,      axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_inp_ext_t,     axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_inp_ext_t,      axi_data_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_inp_ext_t,    axi_aw_inp_ext_t, axi_w_inp_ext_t, axi_ar_inp_ext_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_inp_ext_t,   axi_b_inp_ext_t, axi_r_inp_ext_t);

   // PMS AXI Slave
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_oup_ext_t,     axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_oup_ext_t,      axi_data_oup_ext_t, axi_strb_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_oup_ext_t,      axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_oup_ext_t,     axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_oup_ext_t,      axi_data_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_oup_ext_t,    axi_aw_oup_ext_t, axi_w_oup_ext_t, axi_ar_oup_ext_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_oup_ext_t,   axi_b_oup_ext_t, axi_r_oup_ext_t);

  // PMS AXI Slave
  axi_req_inp_ext_t      from_ext_req;
  axi_resp_inp_ext_t     from_ext_resp;
  // PMS AXI Master
  axi_req_oup_ext_t      to_ext_req, to_ext_req_tied;
  axi_resp_oup_ext_t     to_ext_resp, to_ext_resp_tied;

  typedef logic [AXI_ID_INP_WIDTH_EXT-1:0]     axi_id_inp_nci_t;
  typedef logic [AXI_ID_OUP_WIDTH_EXT-1:0]     axi_id_oup_nci_t;
  typedef logic [AXI_DATA_INP_WIDTH_EXT-1:0]   axi_data_inp_nci_t;
  typedef logic [AXI_STRB_INP_WIDTH_EXT-1:0]   axi_strb_inp_nci_t;
  typedef logic [AXI_DATA_OUP_WIDTH_EXT-1:0]   axi_data_oup_nci_t;
  typedef logic [AXI_STRB_OUP_WIDTH_EXT-1:0]   axi_strb_oup_nci_t;

  // oup data width conversion
  `AXI_TYPEDEF_W_CHAN_T(axi_w_oup_nci_dwc_t, axi_data_oup_nci_t, axi_strb_oup_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_nci_dwc_t, axi_data_oup_nci_t, axi_id_oup_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_nci_dwc_t, axi_aw_oup_ext_t, axi_w_oup_nci_dwc_t, axi_ar_oup_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_nci_dwc_t, axi_b_oup_ext_t, axi_r_oup_nci_dwc_t);

  axi_req_oup_nci_dwc_t  to_ext_dwc_req;
  axi_resp_oup_nci_dwc_t to_ext_dwc_resp;

  // out ID width conversion
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_oup_nci_t, axi_addr_ext_t, axi_id_oup_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_oup_nci_t, axi_id_oup_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_oup_nci_t, axi_addr_ext_t, axi_id_oup_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_nci_t, axi_data_oup_nci_t, axi_id_oup_nci_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_nci_t, axi_aw_oup_nci_t, axi_w_oup_nci_dwc_t, axi_ar_oup_nci_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_nci_t, axi_b_oup_nci_t, axi_r_oup_nci_t);

  axi_req_oup_nci_t  to_nci_req;
  axi_resp_oup_nci_t to_nci_resp;

  // inp ID width conversion
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_inp_nci_t, axi_addr_ext_t, axi_id_inp_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_inp_nci_t, axi_data_inp_nci_t, axi_strb_inp_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_inp_nci_t, axi_id_inp_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_inp_nci_t, axi_addr_ext_t, axi_id_inp_nci_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_inp_nci_t, axi_data_inp_nci_t, axi_id_inp_nci_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_inp_nci_t, axi_aw_inp_nci_t, axi_w_inp_nci_t, axi_ar_inp_nci_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_inp_nci_t, axi_b_inp_nci_t, axi_r_inp_nci_t);

  axi_req_inp_nci_t  from_nci_req;
  axi_resp_inp_nci_t from_nci_resp;

  `AXI_TYPEDEF_R_CHAN_T(axi_r_inp_nci_idwc_t, axi_data_inp_nci_t, axi_id_inp_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_inp_nci_idwc_t, axi_aw_inp_ext_t, axi_w_inp_nci_t, axi_ar_inp_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_inp_nci_idwc_t, axi_b_inp_ext_t, axi_r_inp_nci_idwc_t);

  // nci_cp_top AXI Master
  axi_req_inp_nci_idwc_t  from_nci_idwc_req;
  axi_resp_inp_nci_idwc_t from_nci_idwc_resp;

  if (USE_D2D) begin : gen_d2d
    // tie AXI4 ports
    assign to_nci_req    = '0;
    assign from_nci_resp = '0;

  end else begin : gen_no_d2d
    // Wrap req/resp structs from control_pulp module into flatten AXI ports //

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // Define AXI request (req) and response (resp) type structs for control_pulp (internal AXI widths) //
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    // Tie atop to 0
    assign to_ext_req_tied = '{
      aw: '{
        id:     to_ext_req.aw.id,
        addr:   to_ext_req.aw.addr,
        len:    to_ext_req.aw.len,
        size:   to_ext_req.aw.size,
        burst:  to_ext_req.aw.burst,
        lock:   to_ext_req.aw.lock,
        cache:  to_ext_req.aw.cache,
        prot:   to_ext_req.aw.prot,
        qos:    to_ext_req.aw.qos,
        region: to_ext_req.aw.region,
        atop:   '0,
        user:   to_ext_req.aw.user,
        default: '0
      },
      aw_valid: to_ext_req.aw_valid,
      w:        to_ext_req.w,
      w_valid:  to_ext_req.w_valid,
      b_ready:  to_ext_req.b_ready,
      ar: '{
        id:     to_ext_req.ar.id,
        addr:   to_ext_req.ar.addr,
        len:    to_ext_req.ar.len,
        size:   to_ext_req.ar.size,
        burst:  to_ext_req.ar.burst,
        lock:   to_ext_req.ar.lock,
        cache:  to_ext_req.ar.cache,
        prot:   to_ext_req.ar.prot,
        qos:    to_ext_req.ar.qos,
        region: to_ext_req.ar.region,
        user:   to_ext_req.ar.user,
        default: '0
      },
      ar_valid: to_ext_req.ar_valid,
      r_ready:  to_ext_req.r_ready,
      default: '0
    };

    `AXI_ASSIGN_RESP_STRUCT(to_ext_resp, to_ext_resp_tied);

    /////////////////////////////////////////////////////////////////////////////////////////////////
    // Conver AXI widths between nci_cp_top (dictated from external) and PMS (internal AXI widths) //
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////
    // PMS to nci_cp_top direction //
    /////////////////////////////////

    // AXI data oup width conversion

    axi_dw_converter #(
      .AxiSlvPortDataWidth   ( AXI_DATA_OUP_WIDTH_PMS ), // 64 bit
      .AxiMstPortDataWidth   ( AXI_DATA_OUP_WIDTH_EXT ), // dictated by nci_cp_top
      .AxiAddrWidth          ( AXI_ADDR_WIDTH_PMS     ), // 32 bit
      .AxiIdWidth            ( AXI_ID_OUP_WIDTH_PMS   ), // 6 bit
      .aw_chan_t             ( axi_aw_oup_ext_t       ),
      .mst_w_chan_t          ( axi_w_oup_nci_dwc_t    ),
      .slv_w_chan_t          ( axi_w_oup_ext_t        ),
      .b_chan_t              ( axi_b_oup_ext_t        ),
      .ar_chan_t             ( axi_ar_oup_ext_t       ),
      .mst_r_chan_t          ( axi_r_oup_nci_dwc_t    ),
      .slv_r_chan_t          ( axi_r_oup_ext_t        ),
      .axi_mst_req_t         ( axi_req_oup_nci_dwc_t  ),
      .axi_mst_resp_t        ( axi_resp_oup_nci_dwc_t ),
      .axi_slv_req_t         ( axi_req_oup_ext_t      ),
      .axi_slv_resp_t        ( axi_resp_oup_ext_t     )
    ) i_axi_dwc_cpulp2ext (
      .clk_i                 ( s_soc_clk ),
      .rst_ni                ( rst_ni    ),
      // Slave interface
      .slv_req_i         ( to_ext_req_tied ),
      .slv_resp_o        ( to_ext_resp_tied),
      // Master interface
      .mst_req_o         ( to_ext_dwc_req  ),
      .mst_resp_i        ( to_ext_dwc_resp )
    );

    // AXI ID oup width conversion

    axi_iw_converter #(
      .AxiSlvPortIdWidth      ( AXI_ID_OUP_WIDTH_PMS   ),
      .AxiMstPortIdWidth      ( AXI_ID_OUP_WIDTH_EXT   ),
      .AxiSlvPortMaxUniqIds   ( 16                     ),
      .AxiSlvPortMaxTxnsPerId ( 13                     ),
      .AxiSlvPortMaxTxns      (                        ),
      .AxiMstPortMaxUniqIds   (                        ),
      .AxiMstPortMaxTxnsPerId (                        ),
      .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS     ),
      .AxiDataWidth           ( AXI_DATA_OUP_WIDTH_EXT ),
      .AxiUserWidth           ( AXI_USER_WIDTH_PMS     ),
      .slv_req_t              ( axi_req_oup_nci_dwc_t  ),
      .slv_resp_t             ( axi_resp_oup_nci_dwc_t ),
      .mst_req_t              ( axi_req_oup_nci_t      ),
      .mst_resp_t             ( axi_resp_oup_nci_t     )
    ) i_axi_iwc_cpulp2ext (
      .clk_i      ( s_soc_clk           ),
      .rst_ni     ( rst_ni              ),
      .slv_req_i  ( to_ext_dwc_req      ),
      .slv_resp_o ( to_ext_dwc_resp     ),
      .mst_req_o  ( to_nci_req          ),
      .mst_resp_i ( to_nci_resp         )
    );

    /////////////////////////////////
    // nci_cp_top to PMS direction //
    /////////////////////////////////

    // AXI ID inp width conversion

    axi_iw_converter #(
      .AxiSlvPortIdWidth      ( AXI_ID_INP_WIDTH_EXT    ),
      .AxiMstPortIdWidth      ( AXI_ID_INP_WIDTH_PMS    ),
      .AxiSlvPortMaxUniqIds   ( 16                      ),
      .AxiSlvPortMaxTxnsPerId ( 13                      ),
      .AxiSlvPortMaxTxns      (                         ),
      .AxiMstPortMaxUniqIds   (                         ),
      .AxiMstPortMaxTxnsPerId (                         ),
      .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS      ),
      .AxiDataWidth           ( AXI_DATA_INP_WIDTH_EXT  ),
      .AxiUserWidth           ( AXI_USER_WIDTH_PMS      ),
      .slv_req_t              ( axi_req_inp_nci_t       ),
      .slv_resp_t             ( axi_resp_inp_nci_t      ),
      .mst_req_t              ( axi_req_inp_nci_idwc_t  ),
      .mst_resp_t             ( axi_resp_inp_nci_idwc_t )
    ) i_axi_iwc_ext2cpulp (
      .clk_i      ( s_soc_clk            ),
      .rst_ni     ( rst_ni               ),
      .slv_req_i  ( from_nci_req         ),
      .slv_resp_o ( from_nci_resp        ),
      .mst_req_o  ( from_nci_idwc_req    ),
      .mst_resp_i ( from_nci_idwc_resp   )
    );

    // AXI data inp width conversion

    axi_dw_converter #(
      .AxiSlvPortDataWidth   ( AXI_DATA_INP_WIDTH_EXT ), // dictated by nci_cp_top
      .AxiMstPortDataWidth   ( AXI_DATA_INP_WIDTH_PMS ), // 64 bit
      .AxiAddrWidth          ( AXI_ADDR_WIDTH_PMS     ), // 32 bit
      .AxiIdWidth            ( AXI_ID_INP_WIDTH_PMS   ), // 7 bit
      .aw_chan_t             ( axi_aw_inp_ext_t       ),
      .mst_w_chan_t          ( axi_w_inp_ext_t        ),
      .slv_w_chan_t          ( axi_w_inp_nci_t        ),
      .b_chan_t              ( axi_b_inp_ext_t        ),
      .ar_chan_t             ( axi_ar_inp_ext_t       ),
      .mst_r_chan_t          ( axi_r_inp_ext_t        ),
      .slv_r_chan_t          ( axi_r_inp_nci_idwc_t   ),
      .axi_mst_req_t         ( axi_req_inp_ext_t      ),
      .axi_mst_resp_t        ( axi_resp_inp_ext_t     ),
      .axi_slv_req_t         ( axi_req_inp_nci_idwc_t ),
      .axi_slv_resp_t        ( axi_resp_inp_nci_idwc_t)
    ) i_axi_dwc_ext2cpulp (
      .clk_i                 ( s_soc_clk ),
      .rst_ni                ( rst_ni ),
      // Slave interface
      .slv_req_i         ( from_nci_idwc_req      ),
      .slv_resp_o        ( from_nci_idwc_resp     ),
      // Master interface
      .mst_req_o         ( from_ext_req           ),
      .mst_resp_i        ( from_ext_resp          )
    );

    /////////////////////////////////////////////////
    // Connect req/resp structs and exploded ports //
    /////////////////////////////////////////////////

    // Wrap exploded slave to struct slave (after AXI widths conversion)
    `AXI_WRAP_SLAVE_STRUCT(from_nci_req, from_nci_resp, slv);

    // Explode struct master to exploded master (after AXI widths conversion)
    `AXI_EXPLODE_MASTER_STRUCT(to_nci_req, to_nci_resp, mst);
  end

  ////////////////////
  // I/O flattening //
  ////////////////////

  //
  // Internal peripherals signals
  //

  //I2C
  logic [N_I2C-1:0]        in_i2c_sda_i;
  logic [N_I2C-1:0]        in_i2c_scl_i;
  logic [N_I2C-1:0]        in_i2c_alert_i;
  logic [N_I2C-1:0]        oe_i2c_sda_o;
  logic [N_I2C-1:0]        oe_i2c_scl_o;
  logic [N_I2C-1:0]        oe_i2c_alert_o;
  logic [N_I2C-1:0]        out_i2c_sda_o;
  logic [N_I2C-1:0]        out_i2c_scl_o;
  logic [N_I2C-1:0]        out_i2c_alert_o;

  //I2C slave
  logic [N_I2C_SLV-1:0]    in_i2c_slv_sda_i;
  logic [N_I2C_SLV-1:0]    in_i2c_slv_scl_i;
  logic [N_I2C_SLV-1:0]    oe_i2c_slv_sda_o;
  logic [N_I2C_SLV-1:0]    oe_i2c_slv_scl_o;
  logic [N_I2C_SLV-1:0]    out_i2c_slv_sda_o;
  logic [N_I2C_SLV-1:0]    out_i2c_slv_scl_o;

  //SPI
  logic [N_SPI-1:0][3:0]   oe_qspi_sdio_o;
  logic [N_SPI-1:0][3:0]   oe_qspi_csn_o;
  logic [N_SPI-1:0]        oe_qspi_sck_o;
  logic [N_SPI-1:0][3:0]   out_qspi_sdio_o;
  logic [N_SPI-1:0][3:0]   out_qspi_csn_o;
  logic [N_SPI-1:0]        out_qspi_sck_o;
  logic [N_SPI-1:0][3:0]   in_qspi_sdio_i;
  logic [N_SPI-1:0][3:0]   in_qspi_csn_i;
  logic [N_SPI-1:0]        in_qspi_sck_i;

  logic                    oe_spi_mst_alert_o;
  logic                    out_spi_mst_alert_o;
  logic                    in_spi_mst_alert_i;

  logic [3:0]              oe_spi_slv_sdio_o;
  logic                    oe_spi_slv_csn_o;
  logic                    oe_spi_slv_sck_o;
  logic [3:0]              out_spi_slv_sdio_o;
  logic                    out_spi_slv_csn_o;
  logic                    out_spi_slv_sck_o;
  logic [3:0]              in_spi_slv_sdio_i;
  logic                    in_spi_slv_csn_i;
  logic                    in_spi_slv_sck_i;

  logic                    oe_spi_slv_alert_o;
  logic                    out_spi_slv_alert_o;
  logic                    in_spi_slv_alert_i;

  //UART
  logic [N_UART-1:0]       oe_uart_rx_o;
  logic [N_UART-1:0]       oe_uart_tx_o;

  logic [N_UART-1:0]       out_uart_rx_o;
  logic [N_UART-1:0]       out_uart_tx_o;

  logic [N_UART-1:0]       in_uart_rx_i;
  logic [N_UART-1:0]       in_uart_tx_i;

  //GPIO
  logic [31:0]        gpio_in;
  logic [31:0]        gpio_out;
  logic [31:0]        gpio_dir;
  logic [31:0][3:0]   gpio_cfg;

  // Inter-socket mux select signals
  logic                    s_sel_spi_dir;
  logic                    spi_dir_sel_i;
  logic                    s_sel_i2c_dir;
  logic                    i2c_dir_sel_i;

  assign spi_dir_sel_i = s_sel_spi_dir;
  assign i2c_dir_sel_i = s_sel_i2c_dir;

  //
  // Exploding signals
  //

  //I2C
  `I2C_EXPLODE_STRUCT(i2c0_vrm_mst,     i2c, 0);
  `I2C_EXPLODE_STRUCT(i2c1_vrm_mst,     i2c, 1);
  `I2C_EXPLODE_STRUCT(i2c2_vrm_mst,     i2c, 2);
  `I2C_EXPLODE_STRUCT(i2c3_vrm_mst,     i2c, 3);
  `I2C_EXPLODE_STRUCT(i2c4_vrm_mst,     i2c, 4);
  `I2C_EXPLODE_STRUCT(i2c6_rtc_mst,     i2c, 6);
  `I2C_EXPLODE_STRUCT(i2c8_os_mst,      i2c, 7);
  `I2C_EXPLODE_STRUCT(i2c9_pcie_pnp_mst,i2c, 8);
  `I2C_EXPLODE_STRUCT(i2ca_bios_mst,    i2c, 9);
  `I2C_EXPLODE_STRUCT(i2cb_bmc_mst,     i2c, 10);
  `I2C_EXPLODE_STRUCT(i2cc_vrm_mst,     i2c, 11);

  //SPI
  `SPI_EXPLODE_STRUCT2(spi0_vrm_mst,   qspi, 0);
  `SPI_EXPLODE_STRUCT2(spi1_vrm_mst,   qspi, 1);
  `SPI_EXPLODE_STRUCT2(spi2_vrm_mst,   qspi, 2);
  `SPI_EXPLODE_STRUCT1(spi3_vrm_mst,   qspi, 3);
  `SPI_EXPLODE_STRUCT1(spi4_vrm_mst,   qspi, 4);
  `SPI_EXPLODE_STRUCT1(spi6_vrm_mst,   qspi, 6);
  `QSPI_EXPLODE_STRUCT(qspi_flash_mst, qspi, 7);

  //UART
  assign in_uart_rx_i[0] = in_uart1_rxd_i;
  assign in_uart_tx_i[0] = in_uart1_txd_i;

  assign out_uart1_rxd_o = out_uart_rx_o[0];
  assign out_uart1_txd_o = out_uart_tx_o[0];

  assign oe_uart1_rxd_o = oe_uart_rx_o[0];
  assign oe_uart1_txd_o = oe_uart_tx_o[0];


  //I2C slave from BMC
  assign in_i2c_slv_scl_i[0] = in_i2c7_bmc_slv_scl_i;
  assign in_i2c_slv_sda_i[0] = in_i2c7_bmc_slv_sda_i;

  assign out_i2c7_bmc_slv_scl_o = out_i2c_slv_scl_o[0];
  assign out_i2c7_bmc_slv_sda_o = out_i2c_slv_sda_o[0];

  assign oe_i2c7_bmc_slv_scl_o = oe_i2c_slv_scl_o[0];
  assign oe_i2c7_bmc_slv_sda_o = oe_i2c_slv_sda_o[0];


  // Multiplexing operation SPI
  assign out_spi5_intr_sckt_csn_o   = (spi_dir_sel_i == 1'b0) ? out_qspi_csn_o[5][0] : out_spi_slv_csn_o;
  assign out_spi5_intr_sckt_sck_o   = (spi_dir_sel_i == 1'b0) ? out_qspi_sck_o[5] : out_spi_slv_sck_o;
  assign out_spi5_intr_sckt_si_o    = (spi_dir_sel_i == 1'b0) ? out_qspi_sdio_o[5][0] : out_spi_slv_sdio_o[0];
  assign out_spi5_intr_sckt_so_o    = (spi_dir_sel_i == 1'b0) ? out_qspi_sdio_o[5][1] : out_spi_slv_sdio_o[1];
  assign out_spi5_intr_sckt_alert_o = (spi_dir_sel_i == 1'b0) ? out_spi_mst_alert_o : out_spi_slv_alert_o;

  assign oe_spi5_intr_sckt_csn_o   = (spi_dir_sel_i == 1'b0) ? oe_qspi_csn_o[5][0] : oe_spi_slv_csn_o;
  assign oe_spi5_intr_sckt_sck_o   = (spi_dir_sel_i == 1'b0) ? oe_qspi_sck_o[5] : oe_spi_slv_sck_o;
  assign oe_spi5_intr_sckt_si_o    = (spi_dir_sel_i == 1'b0) ? oe_qspi_sdio_o[5][0] : oe_spi_slv_sdio_o[0];
  assign oe_spi5_intr_sckt_so_o    = (spi_dir_sel_i == 1'b0) ? oe_qspi_sdio_o[5][1] : oe_spi_slv_sdio_o[1];
  assign oe_spi5_intr_sckt_alert_o = (spi_dir_sel_i == 1'b0) ? oe_spi_mst_alert_o : oe_spi_slv_alert_o;

  assign in_qspi_csn_i[5][0]  = (spi_dir_sel_i == 1'b0) ? in_spi5_intr_sckt_csn_i : 1'b1;
  assign in_qspi_sck_i[5]     = (spi_dir_sel_i == 1'b0) ? in_spi5_intr_sckt_sck_i : 1'b0;
  assign in_qspi_sdio_i[5][0] = (spi_dir_sel_i == 1'b0) ? in_spi5_intr_sckt_si_i : 1'b0;
  assign in_qspi_sdio_i[5][1] = (spi_dir_sel_i == 1'b0) ? in_spi5_intr_sckt_so_i : 1'b0;
  assign in_spi_mst_alert_i   = (spi_dir_sel_i == 1'b0) ? in_spi5_intr_sckt_alert_i : 1'b0;

  assign in_spi_slv_csn_i     = (spi_dir_sel_i == 1'b1) ? in_spi5_intr_sckt_csn_i : 1'b1;
  assign in_spi_slv_sck_i     = (spi_dir_sel_i == 1'b1) ? in_spi5_intr_sckt_sck_i : 1'b0;
  assign in_spi_slv_sdio_i[0] = (spi_dir_sel_i == 1'b1) ? in_spi5_intr_sckt_si_i : 1'b0;
  assign in_spi_slv_sdio_i[1] = (spi_dir_sel_i == 1'b1) ? in_spi5_intr_sckt_so_i : 1'b0;
  assign in_spi_slv_alert_i   = (spi_dir_sel_i == 1'b1) ? in_spi5_intr_sckt_alert_i : 1'b0;

  // Multiplexing operation I2C
  // I2C master Number 5 and I2C slave Number 1
  assign out_i2c5_intr_sckt_scl_o   =  (i2c_dir_sel_i == 1'b1)      ?   out_i2c_scl_o[5]          :   out_i2c_slv_scl_o[1];
  assign out_i2c5_intr_sckt_sda_o   =  (i2c_dir_sel_i == 1'b1)      ?   out_i2c_sda_o[5]          :   out_i2c_slv_sda_o[1];
  assign out_i2c5_intr_sckt_alert_o =  (i2c_dir_sel_i == 1'b1)      ?   out_i2c_alert_o[5]        :   1'b0;

  assign oe_i2c5_intr_sckt_scl_o    =  (i2c_dir_sel_i == 1'b1)      ?   oe_i2c_scl_o[5]           :   oe_i2c_slv_scl_o[1];
  assign oe_i2c5_intr_sckt_sda_o    =  (i2c_dir_sel_i == 1'b1)      ?   oe_i2c_sda_o[5]           :   oe_i2c_slv_sda_o[1];
  assign oe_i2c5_intr_sckt_alert_o  =  (i2c_dir_sel_i == 1'b1)      ?   oe_i2c_alert_o[5]         :   1'b0;

  assign in_i2c_scl_i[5]            =  (i2c_dir_sel_i == 1'b1)      ?   in_i2c5_intr_sckt_scl_i   :   1'b1;
  assign in_i2c_sda_i[5]            =  (i2c_dir_sel_i == 1'b1)      ?   in_i2c5_intr_sckt_sda_i   :   1'b1;
  assign in_i2c_alert_i[5]          =  (i2c_dir_sel_i == 1'b1)      ?   in_i2c5_intr_sckt_alert_i :   1'b0;

  assign in_i2c_slv_scl_i[1]        =  (i2c_dir_sel_i == 1'b1)      ?   1'b1                      :   in_i2c5_intr_sckt_scl_i;
  assign in_i2c_slv_sda_i[1]        =  (i2c_dir_sel_i == 1'b1)      ?   1'b1                      :   in_i2c5_intr_sckt_sda_i;

  // Not used signals
  for (genvar i=1; i < 4; i++) begin: assign_unused_spi0
    assign in_qspi_csn_i[5][i] = 1'b1;
  end

  for (genvar i=2; i < 4; i++) begin: assign_unused_spi1
    assign in_qspi_sdio_i[5][i] = 1'b0;
    assign in_spi_slv_sdio_i[i] = 1'b0;
  end

  assign soc_clk_o = s_soc_clk;

  // SLP, SYS, CPU pins
  assign out_slp_s3_l_o         = gpio_out[0];
  assign out_slp_s4_l_o         = gpio_out[1];
  assign out_slp_s5_l_o         = gpio_out[2];
  assign out_cpu_pwrgd_out_o    = gpio_out[3];
  assign out_cpu_thermtrip_l_o  = gpio_out[4];
  assign out_cpu_errcode_o[0]   = gpio_out[5];
  assign out_cpu_errcode_o[1]   = gpio_out[6];
  assign out_cpu_errcode_o[2]   = gpio_out[7];
  assign out_cpu_errcode_o[3]   = gpio_out[8];
  assign out_cpu_reset_out_l_o  = gpio_out[9];
  assign out_sys_reset_l_o      = gpio_out[10];
  assign out_sys_rsmrst_l_o     = gpio_out[11];
  assign out_sys_pwr_btn_l_o    = gpio_out[12];
  assign out_sys_pwrgd_in_o     = gpio_out[13];
  assign out_sys_wake_l_o       = gpio_out[14];
  assign out_cpu_throttle_o[0]  = gpio_out[15];
  assign out_cpu_throttle_o[1]  = gpio_out[16];
  assign out_cpu_socket_id_o[0] = gpio_out[17];
  assign out_cpu_socket_id_o[1] = gpio_out[18];
  assign out_cpu_strap_o[0]     = gpio_out[19];
  assign out_cpu_strap_o[1]     = gpio_out[20];
  assign out_cpu_strap_o[2]     = gpio_out[21];
  assign out_cpu_strap_o[3]     = gpio_out[22];

  // SLP, SYS, CPU pins
  assign gpio_in[0]  = in_slp_s3_l_i;
  assign gpio_in[1]  = in_slp_s4_l_i;
  assign gpio_in[2]  = in_slp_s5_l_i;
  assign gpio_in[3]  = in_cpu_pwrgd_out_i;
  assign gpio_in[4]  = in_cpu_thermtrip_l_i;
  assign gpio_in[5]  = in_cpu_errcode_i[0];
  assign gpio_in[6]  = in_cpu_errcode_i[1];
  assign gpio_in[7]  = in_cpu_errcode_i[2];
  assign gpio_in[8]  = in_cpu_errcode_i[3];
  assign gpio_in[9]  = in_cpu_reset_out_l_i;
  assign gpio_in[10] = in_sys_reset_l_i;
  assign gpio_in[11] = in_sys_rsmrst_l_i;
  assign gpio_in[12] = in_sys_pwr_btn_l_i;
  assign gpio_in[13] = in_sys_pwrgd_in_i;
  assign gpio_in[14] = in_sys_wake_l_i;
  assign gpio_in[15] = in_cpu_throttle_i[0];
  assign gpio_in[16] = in_cpu_throttle_i[1];
  assign gpio_in[17] = in_cpu_socket_id_i[0];
  assign gpio_in[18] = in_cpu_socket_id_i[1];
  assign gpio_in[19] = in_cpu_strap_i[0];
  assign gpio_in[20] = in_cpu_strap_i[1];
  assign gpio_in[21] = in_cpu_strap_i[2];
  assign gpio_in[22] = in_cpu_strap_i[3];

  // SLP, SYS, CPU pins: output enables set set to '1' if pin is an output and
  // to '0' if it's an input pin (assuming a pull up behaviour of the final pad)
  assign oe_slp_s3_l_o         = gpio_dir[0];
  assign oe_slp_s4_l_o         = gpio_dir[1];
  assign oe_slp_s5_l_o         = gpio_dir[2];
  assign oe_cpu_pwrgd_out_o    = gpio_dir[3];
  assign oe_cpu_thermtrip_l_o  = gpio_dir[4];
  assign oe_cpu_errcode_o[0]   = gpio_dir[5];
  assign oe_cpu_errcode_o[1]   = gpio_dir[6];
  assign oe_cpu_errcode_o[2]   = gpio_dir[7];
  assign oe_cpu_errcode_o[3]   = gpio_dir[8];
  assign oe_cpu_reset_out_l_o  = gpio_dir[9];
  assign oe_sys_reset_l_o      = gpio_dir[10];
  assign oe_sys_rsmrst_l_o     = gpio_dir[11];
  assign oe_sys_pwr_btn_l_o    = gpio_dir[12];
  assign oe_sys_pwrgd_in_o     = gpio_dir[13];
  assign oe_sys_wake_l_o       = gpio_dir[14];
  assign oe_cpu_throttle_o[0]  = gpio_dir[15];
  assign oe_cpu_throttle_o[1]  = gpio_dir[16];
  assign oe_cpu_socket_id_o[0] = gpio_dir[17];
  assign oe_cpu_socket_id_o[1] = gpio_dir[18];
  assign oe_cpu_strap_o[0]     = gpio_dir[19];
  assign oe_cpu_strap_o[1]     = gpio_dir[20];
  assign oe_cpu_strap_o[2]     = gpio_dir[21];
  assign oe_cpu_strap_o[3]     = gpio_dir[22];

  // Unused GPIOs
  for (genvar i = 24; i < 32; i++) begin: assign_gpio_unused
    assign gpio_in[i]  = 1'b0;
  end

  for (genvar i = 0; i < 32; i++) begin: assign_padcfg
    assign pad_cfg_o[i] = {2'b0, gpio_cfg[i]};
  end

  // Instantiate control-pulp
  // Control PULP SoC
  control_pulp #(
    .CORE_TYPE(CORE_TYPE),
    .USE_FPU(USE_FPU),
    .USE_HWPE(0), // Not present in PMS
    .USE_CLUSTER_HWPE(0), // Not present in PMS
    .PULP_XPULP(PULP_XPULP),
    .SIM_STDOUT(SIM_STDOUT),
    .BEHAV_MEM(BEHAV_MEM),
    .MACRO_ROM(MACRO_ROM),
    .USE_CLUSTER(USE_CLUSTER),
    .DMA_TYPE(DMA_TYPE),
    .SDMA_RT_MIDEND(SDMA_RT_MIDEND),

    .N_SOC_PERF_COUNTERS(N_SOC_PERF_COUNTERS),
    .N_CLUST_PERF_COUNTERS(N_CLUST_PERF_COUNTERS),
    .N_L2_BANKS(N_L2_BANKS),
    .N_L2_BANKS_PRI(N_L2_BANKS_PRI),
    .L2_BANK_SIZE(L2_BANK_SIZE),
    .N_L1_BANKS(N_L1_BANKS),
    .L1_BANK_SIZE(L1_BANK_SIZE),
    .N_I2C(N_I2C),
    .N_I2C_SLV(N_I2C_SLV),
    .N_SPI(N_SPI),
    .N_UART(N_UART),
    .CLUST_NB_FPU(CLUST_NB_FPU),
    .CLUST_NB_EXT_DIVSQRT(CLUST_NB_EXT_DIVSQRT),
    // D2D link
    .USE_D2D (USE_D2D),
    .USE_D2D_DELAY_LINE (USE_D2D_DELAY_LINE),
    .D2D_NUM_CHANNELS (D2D_NUM_CHANNELS),
    .D2D_NUM_LANES (D2D_NUM_LANES),
    .D2D_NUM_CREDITS (D2D_NUM_CREDITS),

     // nci_cp_top Master
    .axi_req_inp_ext_t       (axi_req_inp_ext_t),
    .axi_resp_inp_ext_t      (axi_resp_inp_ext_t),
     // nci_cp_top Slave
    .axi_req_oup_ext_t       (axi_req_oup_ext_t),
    .axi_resp_oup_ext_t      (axi_resp_oup_ext_t)

  ) i_control_pulp (

     // control-pulp interaction ports with off-pmu objects

     // nci_cp_top Master
    .from_ext_req_i       (from_ext_req),
    .from_ext_resp_o      (from_ext_resp),
     // nci_cp_top Slave
    .to_ext_req_o         (to_ext_req),
    .to_ext_resp_i        (to_ext_resp),

    .d2d_clk_i,
    .d2d_data_i,
    .d2d_clk_o,
    .d2d_data_o,

    // on-pmu internal peripherals (soc)

    .soc_clk_i          ( s_soc_clk             ),
    .periph_clk_i       ( s_periph_clk          ),
    .cluster_clk_i      ( s_cluster_clk         ),
    .ref_clk_i          ( s_timer_clk           ),
    .test_clk_i, // dft
    .soc_rst_ni         ( s_soc_rstn            ),
    .cluster_rst_ni     ( s_cluster_rstn        ),
    .cluster_rst_reg_no ( s_cluster_rstn_reg    ),

    .dft_test_mode_i,
    .dft_cg_enable_i,

    .jtag_tdo_o        ( jtag_tdo_o             ),
    .jtag_tck_i        ( jtag_tck_i             ),
    .jtag_tdi_i        ( jtag_tdi_i             ),
    .jtag_tms_i        ( jtag_tms_i             ),
    .jtag_trst_ni      ( jtag_trst_ni           ),

    .sel_spi_dir_o     ( s_sel_spi_dir          ),
    .sel_i2c_mux_o     ( s_sel_i2c_dir          ),

    .wdt_alert_o,
    .wdt_alert_clear_i,

    .scg_irq_i,
    .scp_irq_i,
    .scp_secure_irq_i,
    .mbox_irq_i,
    .mbox_secure_irq_i,

    .oe_qspi_sdio_o,
    .oe_qspi_csn_o,
    .oe_qspi_sck_o,
    .oe_spi_mst_alert_o,
    .oe_spi_slv_sdio_o,
    .oe_spi_slv_csn_o,
    .oe_spi_slv_sck_o,
    .oe_spi_slv_alert_o,
    .oe_i2c_sda_o,
    .oe_i2c_scl_o,
    .oe_i2c_alert_o,

    .oe_i2c_slv_sda_o,
    .oe_i2c_slv_scl_o,

    .oe_uart_rx_o,
    .oe_uart_tx_o,

    .out_qspi_sdio_o,
    .out_qspi_csn_o,
    .out_qspi_sck_o,
    .out_spi_mst_alert_o,
    .out_spi_slv_sdio_o,
    .out_spi_slv_csn_o,
    .out_spi_slv_sck_o,
    .out_spi_slv_alert_o,
    .out_i2c_sda_o,
    .out_i2c_scl_o,
    .out_i2c_alert_o,

    .out_i2c_slv_sda_o,
    .out_i2c_slv_scl_o,

    .out_uart_rx_o,
    .out_uart_tx_o,

    .in_qspi_sdio_i,
    .in_qspi_csn_i,
    .in_qspi_sck_i,
    .in_spi_mst_alert_i,
    .in_spi_slv_sdio_i,
    .in_spi_slv_csn_i,
    .in_spi_slv_sck_i,
    .in_spi_slv_alert_i,
    .in_i2c_sda_i,
    .in_i2c_scl_i,
    .in_i2c_alert_i,

    .in_i2c_slv_sda_i,
    .in_i2c_slv_scl_i,

    .in_uart_rx_i,
    .in_uart_tx_i,

    .gpio_in_i           ( gpio_in             ),
    .gpio_out_o          ( gpio_out            ),
    .gpio_dir_o          ( gpio_dir            ),
    .gpio_cfg_o          ( gpio_cfg            ),

    .bootsel_valid_i     ( bootsel_valid_i     ),
    .bootsel_i           ( {1'b0, bootsel_i}   ),
    .fc_fetch_en_valid_i ( fc_fetch_en_valid_i ),
    .fc_fetch_en_i       ( fc_fetch_en_i       ),

    .apb_clk_ctrl_bus    ( s_apb_clk_ctrl_bus  ),
    .apb_pad_cfg_bus     ( s_apb_pad_cfg_bus   ),
    .clk_mux_sel_o       ( s_clk_mux_sel       ));

endmodule // pms_explode_ports

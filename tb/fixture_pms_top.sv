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


`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "control_pulp_assign.svh"
`include "register_interface/assign.svh"
`include "register_interface/typedef.svh"

module fixture_pms_top;
  import pms_top_pkg::AXI_ADDR_WIDTH_PMS;
  import pms_top_pkg::AXI_USER_WIDTH_PMS;
  import pms_top_pkg::N_SPI;
  import pms_top_pkg::N_UART;
  import pms_top_pkg::N_I2C;
  import pms_top_pkg::N_I2C_SLV;
  import srec_pkg::*;

  parameter CONFIG_FILE = "NONE";

  // Simulation platform parameters

  // Choose your core: 0 for RISCY, 1 for ZERORISCY
  parameter CORE_TYPE = 0;
  // if RISCY is instantiated (CORE_TYPE == 0), RISCY_FPU enables the FPU
  parameter RISCY_FPU = 1;
  // Choose whether to enable simulation only stdout (not synthesizable)
  parameter SIM_STDOUT = 1;
  // Choose whether to use hardwired ROM or behavioral/compiled memory macro (according to BEHAV_MEM)
  parameter MACRO_ROM = 0;
  // Choose whether to use behavioral memory models or compiled memory macros
  parameter BEHAV_MEM = 1;
  // Choose whether to use the PULP Cluster
  parameter USE_CLUSTER = 1;

  // D2D link
  parameter USE_D2D = 0;
  parameter USE_D2D_DELAY_LINE = 0;
  parameter D2D_NUM_CHANNELS = 8;
  parameter D2D_NUM_LANES = 8;
  parameter D2D_NUM_CREDITS = 128;

  // TODO: period of the system clock (600MhZ)
  // period of the external reference clock (100MhZ)
  parameter REF_CLK_PERIOD = 10ns;

  parameter LOAD_L2 = "PRELOADED";

  // core hart id
  localparam logic [9:0] FC_CORE_ID = {5'd31, 5'd0};

  // configuration address constants
  localparam logic [31:0] SOC_CTRL_BOOT_ADDR        = 32'h1A10_4004;
  localparam logic [31:0] SOC_CTRL_FETCH_EN_ADDR    = 32'h1A10_4008;
  localparam logic [31:0] SOC_CTRL_BOOTSEL_ADDR     = 32'h1A10_40C4;
  localparam logic [31:0] SOC_CTRL_CORE_STATUS_ADDR = 32'h1A10_40A0;

  // UART baud rate in bps
  parameter BAUDRATE = 115200;

  // SPI standards, do not change
  parameter logic [1:0] SPI_STD = 2'b00;
  parameter logic [1:0] SPI_QUAD_TX = 2'b01;
  parameter logic [1:0] SPI_QUAD_RX = 2'b10;

  // exit
  localparam int EXIT_SUCCESS = 0;
  localparam int EXIT_FAIL = 1;
  localparam int EXIT_ERROR = -1;

  // AXI parameters
  // from/to nci_cp_top
  localparam int unsigned AXI_DATA_INP_WIDTH_EXT = 64;
  localparam int unsigned AXI_STRB_INP_WIDTH_EXT = AXI_DATA_INP_WIDTH_EXT / 8;
  localparam int unsigned AXI_DATA_OUP_WIDTH_EXT = 64;
  localparam int unsigned AXI_STRB_OUP_WIDTH_EXT = AXI_DATA_OUP_WIDTH_EXT / 8;
  localparam int unsigned AXI_ID_OUP_WIDTH_EXT = 7;
  localparam int unsigned AXI_ID_INP_WIDTH_EXT = 7;
  localparam int unsigned AXI_USER_WIDTH_EXT = 6;
  localparam int unsigned AXI_ADDR_WIDTH_EXT = 32;

  // simulation vars
  logic uart_tb_rx_en = 1'b0;

  int stim_fd;
  int num_stim = 0;
  int ret_code;

  // Monitor boot process for AXI handshake check
  logic is_test_axi = 1'b1;
  logic is_preload = 1'b1;
  logic is_entry_point = 1'b1;
  logic is_bootaddr = 1'b1;

  int exit_status = EXIT_FAIL;  // per default we fail

  // AXI ports to external, flattened
  // AXI Master to nci_cp_top
  logic [AXI_ID_OUP_WIDTH_EXT-1:0] awid_mst_o;
  logic [AXI_ADDR_WIDTH_PMS-1:0] awaddr_mst_o;
  logic [7:0] awlen_mst_o;
  logic [2:0] awsize_mst_o;
  logic [1:0] awburst_mst_o;
  logic awlock_mst_o;
  logic [3:0] awcache_mst_o;
  logic [2:0] awprot_mst_o;
  logic [3:0] awqos_mst_o;
  logic [3:0] awregion_mst_o;
  logic [5:0] aw_atop_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] awuser_mst_o;
  logic awvalid_mst_o;
  logic awready_mst_i;

  logic [AXI_DATA_OUP_WIDTH_EXT-1:0] wdata_mst_o;
  logic [AXI_STRB_OUP_WIDTH_EXT-1:0] wstrb_mst_o;
  logic wlast_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] wuser_mst_o;
  logic wvalid_mst_o;
  logic wready_mst_i;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] bid_mst_i;
  logic [1:0] bresp_mst_i;
  logic [AXI_USER_WIDTH_PMS-1:0] buser_mst_i;
  logic bvalid_mst_i;
  logic bready_mst_o;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] arid_mst_o;
  logic [AXI_ADDR_WIDTH_PMS-1:0] araddr_mst_o;
  logic [7:0] arlen_mst_o;
  logic [2:0] arsize_mst_o;
  logic [1:0] arburst_mst_o;
  logic arlock_mst_o;
  logic [3:0] arcache_mst_o;
  logic [2:0] arprot_mst_o;
  logic [3:0] arqos_mst_o;
  logic [3:0] arregion_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] aruser_mst_o;
  logic arvalid_mst_o;
  logic arready_mst_i;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] rid_mst_i;
  logic [AXI_DATA_OUP_WIDTH_EXT-1:0] rdata_mst_i;
  logic [1:0] rresp_mst_i;
  logic rlast_mst_i;
  logic [AXI_USER_WIDTH_PMS-1:0] ruser_mst_i;
  logic rvalid_mst_i;
  logic rready_mst_o;


  // AXI Slave from nci_cp_top
  logic [AXI_ID_INP_WIDTH_EXT-1:0] awid_slv_i;
  logic [AXI_ADDR_WIDTH_PMS-1:0] awaddr_slv_i;
  logic [7:0] awlen_slv_i;
  logic [2:0] awsize_slv_i;
  logic [1:0] awburst_slv_i;
  logic awlock_slv_i;
  logic [3:0] awcache_slv_i;
  logic [2:0] awprot_slv_i;
  logic [3:0] awqos_slv_i;
  logic [3:0] awregion_slv_i;
  logic [5:0] aw_atop_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] awuser_slv_i;
  logic awvalid_slv_i;
  logic awready_slv_o;

  logic [AXI_DATA_INP_WIDTH_EXT-1:0] wdata_slv_i;
  logic [AXI_STRB_INP_WIDTH_EXT-1:0] wstrb_slv_i;
  logic wlast_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] wuser_slv_i;
  logic wvalid_slv_i;
  logic wready_slv_o;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] bid_slv_o;
  logic [1:0] bresp_slv_o;
  logic [AXI_USER_WIDTH_PMS-1:0] buser_slv_o;
  logic bvalid_slv_o;
  logic bready_slv_i;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] arid_slv_i;
  logic [AXI_ADDR_WIDTH_PMS-1:0] araddr_slv_i;
  logic [7:0] arlen_slv_i;
  logic [2:0] arsize_slv_i;
  logic [1:0] arburst_slv_i;
  logic arlock_slv_i;
  logic [3:0] arcache_slv_i;
  logic [2:0] arprot_slv_i;
  logic [3:0] arqos_slv_i;
  logic [3:0] arregion_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] aruser_slv_i;
  logic arvalid_slv_i;
  logic arready_slv_o;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] rid_slv_o;
  logic [AXI_DATA_INP_WIDTH_EXT-1:0] rdata_slv_o;
  logic [1:0] rresp_slv_o;
  logic rlast_slv_o;
  logic [AXI_USER_WIDTH_PMS-1:0] ruser_slv_o;
  logic rvalid_slv_o;
  logic rready_slv_i;  // Inout signals are split into input, output and enables

  //
  // Master interfaces
  //

  //I2C
  logic out_i2c0_vrm_mst_scl_o;
  logic out_i2c0_vrm_mst_sda_o;
  logic out_i2c0_vrm_mst_alert_o;

  logic oe_i2c0_vrm_mst_scl_o;
  logic oe_i2c0_vrm_mst_sda_o;
  logic oe_i2c0_vrm_mst_alert_o;

  logic in_i2c0_vrm_mst_scl_i;
  logic in_i2c0_vrm_mst_sda_i;
  logic in_i2c0_vrm_mst_alert_i;

  logic out_i2c1_vrm_mst_scl_o;
  logic out_i2c1_vrm_mst_sda_o;
  logic out_i2c1_vrm_mst_alert_o;

  logic oe_i2c1_vrm_mst_scl_o;
  logic oe_i2c1_vrm_mst_sda_o;
  logic oe_i2c1_vrm_mst_alert_o;

  logic in_i2c1_vrm_mst_scl_i;
  logic in_i2c1_vrm_mst_sda_i;
  logic in_i2c1_vrm_mst_alert_i;

  logic out_i2c2_vrm_mst_scl_o;
  logic out_i2c2_vrm_mst_sda_o;
  logic out_i2c2_vrm_mst_alert_o;

  logic oe_i2c2_vrm_mst_scl_o;
  logic oe_i2c2_vrm_mst_sda_o;
  logic oe_i2c2_vrm_mst_alert_o;

  logic in_i2c2_vrm_mst_scl_i;
  logic in_i2c2_vrm_mst_sda_i;
  logic in_i2c2_vrm_mst_alert_i;

  logic out_i2c3_vrm_mst_scl_o;
  logic out_i2c3_vrm_mst_sda_o;
  logic out_i2c3_vrm_mst_alert_o;

  logic oe_i2c3_vrm_mst_scl_o;
  logic oe_i2c3_vrm_mst_sda_o;
  logic oe_i2c3_vrm_mst_alert_o;

  logic in_i2c3_vrm_mst_scl_i;
  logic in_i2c3_vrm_mst_sda_i;
  logic in_i2c3_vrm_mst_alert_i;

  logic out_i2c4_vrm_mst_scl_o;
  logic out_i2c4_vrm_mst_sda_o;
  logic out_i2c4_vrm_mst_alert_o;

  logic oe_i2c4_vrm_mst_scl_o;
  logic oe_i2c4_vrm_mst_sda_o;
  logic oe_i2c4_vrm_mst_alert_o;

  logic in_i2c4_vrm_mst_scl_i;
  logic in_i2c4_vrm_mst_sda_i;
  logic in_i2c4_vrm_mst_alert_i;

  logic out_i2cc_vrm_mst_scl_o;
  logic out_i2cc_vrm_mst_sda_o;
  logic out_i2cc_vrm_mst_alert_o;

  logic oe_i2cc_vrm_mst_scl_o;
  logic oe_i2cc_vrm_mst_sda_o;
  logic oe_i2cc_vrm_mst_alert_o;

  logic in_i2cc_vrm_mst_scl_i;
  logic in_i2cc_vrm_mst_sda_i;
  logic in_i2cc_vrm_mst_alert_i;

  logic out_i2c6_rtc_mst_scl_o;
  logic out_i2c6_rtc_mst_sda_o;
  logic out_i2c6_rtc_mst_alert_o;

  logic oe_i2c6_rtc_mst_scl_o;
  logic oe_i2c6_rtc_mst_sda_o;
  logic oe_i2c6_rtc_mst_alert_o;

  logic in_i2c6_rtc_mst_scl_i;
  logic in_i2c6_rtc_mst_sda_i;
  logic in_i2c6_rtc_mst_alert_i;

  logic out_i2c7_bmc_slv_scl_o;
  logic out_i2c7_bmc_slv_sda_o;

  logic oe_i2c7_bmc_slv_scl_o;
  logic oe_i2c7_bmc_slv_sda_o;

  logic in_i2c7_bmc_slv_scl_i;
  logic in_i2c7_bmc_slv_sda_i;

  logic out_i2c8_os_mst_scl_o;
  logic out_i2c8_os_mst_sda_o;
  logic out_i2c8_os_mst_alert_o;

  logic oe_i2c8_os_mst_scl_o;
  logic oe_i2c8_os_mst_sda_o;
  logic oe_i2c8_os_mst_alert_o;

  logic in_i2c8_os_mst_scl_i;
  logic in_i2c8_os_mst_sda_i;
  logic in_i2c8_os_mst_alert_i;

  logic out_i2c9_pcie_pnp_mst_scl_o;
  logic out_i2c9_pcie_pnp_mst_sda_o;
  logic out_i2c9_pcie_pnp_mst_alert_o;

  logic oe_i2c9_pcie_pnp_mst_scl_o;
  logic oe_i2c9_pcie_pnp_mst_sda_o;
  logic oe_i2c9_pcie_pnp_mst_alert_o;

  logic in_i2c9_pcie_pnp_mst_scl_i;
  logic in_i2c9_pcie_pnp_mst_sda_i;
  logic in_i2c9_pcie_pnp_mst_alert_i;

  logic out_i2ca_bios_mst_scl_o;
  logic out_i2ca_bios_mst_sda_o;
  logic out_i2ca_bios_mst_alert_o;

  logic oe_i2ca_bios_mst_scl_o;
  logic oe_i2ca_bios_mst_sda_o;
  logic oe_i2ca_bios_mst_alert_o;

  logic in_i2ca_bios_mst_scl_i;
  logic in_i2ca_bios_mst_sda_i;
  logic in_i2ca_bios_mst_alert_i;

  logic out_i2cb_bmc_mst_scl_o;
  logic out_i2cb_bmc_mst_sda_o;
  logic out_i2cb_bmc_mst_alert_o;

  logic oe_i2cb_bmc_mst_scl_o;
  logic oe_i2cb_bmc_mst_sda_o;
  logic oe_i2cb_bmc_mst_alert_o;

  logic in_i2cb_bmc_mst_scl_i;
  logic in_i2cb_bmc_mst_sda_i;
  logic in_i2cb_bmc_mst_alert_i;

  //SPI
  logic in_qspi_flash_mst_csn0_i;
  logic in_qspi_flash_mst_csn1_i;
  logic in_qspi_flash_mst_sck_i;
  logic [3:0] in_qspi_flash_mst_sdio_i;

  logic out_qspi_flash_mst_csn0_o;
  logic out_qspi_flash_mst_csn1_o;
  logic out_qspi_flash_mst_sck_o;
  logic [3:0] out_qspi_flash_mst_sdio_o;

  logic oe_qspi_flash_mst_csn0_o;
  logic oe_qspi_flash_mst_csn1_o;
  logic oe_qspi_flash_mst_sck_o;
  logic [3:0] oe_qspi_flash_mst_sdio_o;

  logic in_spi0_vrm_mst_csn0_i;
  logic in_spi0_vrm_mst_csn1_i;
  logic in_spi0_vrm_mst_sck_i;
  logic in_spi0_vrm_mst_si_i;
  logic in_spi0_vrm_mst_so_i;

  logic out_spi0_vrm_mst_csn0_o;
  logic out_spi0_vrm_mst_csn1_o;
  logic out_spi0_vrm_mst_sck_o;
  logic out_spi0_vrm_mst_si_o;
  logic out_spi0_vrm_mst_so_o;

  logic oe_spi0_vrm_mst_csn0_o;
  logic oe_spi0_vrm_mst_csn1_o;
  logic oe_spi0_vrm_mst_sck_o;
  logic oe_spi0_vrm_mst_si_o;
  logic oe_spi0_vrm_mst_so_o;

  logic in_spi1_vrm_mst_csn0_i;
  logic in_spi1_vrm_mst_csn1_i;
  logic in_spi1_vrm_mst_sck_i;
  logic in_spi1_vrm_mst_si_i;
  logic in_spi1_vrm_mst_so_i;

  logic out_spi1_vrm_mst_csn0_o;
  logic out_spi1_vrm_mst_csn1_o;
  logic out_spi1_vrm_mst_sck_o;
  logic out_spi1_vrm_mst_si_o;
  logic out_spi1_vrm_mst_so_o;

  logic oe_spi1_vrm_mst_csn0_o;
  logic oe_spi1_vrm_mst_csn1_o;
  logic oe_spi1_vrm_mst_sck_o;
  logic oe_spi1_vrm_mst_si_o;
  logic oe_spi1_vrm_mst_so_o;

  logic in_spi2_vrm_mst_csn0_i;
  logic in_spi2_vrm_mst_csn1_i;
  logic in_spi2_vrm_mst_sck_i;
  logic in_spi2_vrm_mst_si_i;
  logic in_spi2_vrm_mst_so_i;

  logic out_spi2_vrm_mst_csn0_o;
  logic out_spi2_vrm_mst_csn1_o;
  logic out_spi2_vrm_mst_sck_o;
  logic out_spi2_vrm_mst_si_o;
  logic out_spi2_vrm_mst_so_o;

  logic oe_spi2_vrm_mst_csn0_o;
  logic oe_spi2_vrm_mst_csn1_o;
  logic oe_spi2_vrm_mst_sck_o;
  logic oe_spi2_vrm_mst_si_o;
  logic oe_spi2_vrm_mst_so_o;

  logic in_spi3_vrm_mst_csn_i;
  logic in_spi3_vrm_mst_sck_i;
  logic in_spi3_vrm_mst_si_i;
  logic in_spi3_vrm_mst_so_i;

  logic out_spi3_vrm_mst_csn_o;
  logic out_spi3_vrm_mst_sck_o;
  logic out_spi3_vrm_mst_si_o;
  logic out_spi3_vrm_mst_so_o;

  logic oe_spi3_vrm_mst_csn_o;
  logic oe_spi3_vrm_mst_sck_o;
  logic oe_spi3_vrm_mst_si_o;
  logic oe_spi3_vrm_mst_so_o;

  logic in_spi4_vrm_mst_csn_i;
  logic in_spi4_vrm_mst_sck_i;
  logic in_spi4_vrm_mst_si_i;
  logic in_spi4_vrm_mst_so_i;

  logic out_spi4_vrm_mst_csn_o;
  logic out_spi4_vrm_mst_sck_o;
  logic out_spi4_vrm_mst_si_o;
  logic out_spi4_vrm_mst_so_o;

  logic oe_spi4_vrm_mst_csn_o;
  logic oe_spi4_vrm_mst_sck_o;
  logic oe_spi4_vrm_mst_si_o;
  logic oe_spi4_vrm_mst_so_o;

  logic in_spi6_vrm_mst_csn_i;
  logic in_spi6_vrm_mst_sck_i;
  logic in_spi6_vrm_mst_si_i;
  logic in_spi6_vrm_mst_so_i;

  logic out_spi6_vrm_mst_csn_o;
  logic out_spi6_vrm_mst_sck_o;
  logic out_spi6_vrm_mst_si_o;
  logic out_spi6_vrm_mst_so_o;

  logic oe_spi6_vrm_mst_csn_o;
  logic oe_spi6_vrm_mst_sck_o;
  logic oe_spi6_vrm_mst_si_o;
  logic oe_spi6_vrm_mst_so_o;

  //
  // Internally multiplexed interfaces
  //

  //I2C
  logic out_i2c5_intr_sckt_scl_o;
  logic out_i2c5_intr_sckt_sda_o;
  logic out_i2c5_intr_sckt_alert_o;

  logic oe_i2c5_intr_sckt_scl_o;
  logic oe_i2c5_intr_sckt_sda_o;
  logic oe_i2c5_intr_sckt_alert_o;

  logic in_i2c5_intr_sckt_scl_i;
  logic in_i2c5_intr_sckt_sda_i;
  logic in_i2c5_intr_sckt_alert_i;

  //SPI
  logic in_spi5_intr_sckt_csn_i;
  logic in_spi5_intr_sckt_sck_i;
  logic in_spi5_intr_sckt_si_i;
  logic in_spi5_intr_sckt_so_i;
  logic in_spi5_intr_sckt_alert_i;

  logic out_spi5_intr_sckt_csn_o;
  logic out_spi5_intr_sckt_sck_o;
  logic out_spi5_intr_sckt_si_o;
  logic out_spi5_intr_sckt_so_o;
  logic out_spi5_intr_sckt_alert_o;

  logic oe_spi5_intr_sckt_csn_o;
  logic oe_spi5_intr_sckt_sck_o;
  logic oe_spi5_intr_sckt_si_o;
  logic oe_spi5_intr_sckt_so_o;
  logic oe_spi5_intr_sckt_alert_o;

  //UART
  logic in_uart1_rxd_i;
  logic in_uart1_txd_i;

  logic out_uart1_rxd_o;
  logic out_uart1_txd_o;

  logic oe_uart1_rxd_o;
  logic oe_uart1_txd_o;

  // GPIOs

  logic s_out_slp_s3_l;
  logic s_out_slp_s4_l;
  logic s_out_slp_s5_l;
  logic s_out_sys_reset_l;
  logic s_out_sys_rsmrst_l;
  logic s_out_sys_pwr_btn_l;
  logic s_out_sys_pwrgd_in;
  logic s_out_sys_wake_l;
  logic s_out_cpu_pwrgd_out;
  logic [1:0] s_out_cpu_throttle;
  logic s_out_cpu_thermtrip_l;
  logic [3:0] s_out_cpu_errcode;
  logic s_out_cpu_reset_out_l;
  logic [1:0] s_out_cpu_socket_id;
  logic [3:0] s_out_cpu_strap;

  logic s_oe_slp_s3_l;
  logic s_oe_slp_s4_l;
  logic s_oe_slp_s5_l;
  logic s_oe_sys_reset_l;
  logic s_oe_sys_rsmrst_l;
  logic s_oe_sys_pwr_btn_l;
  logic s_oe_sys_pwrgd_in;
  logic s_oe_sys_wake_l;
  logic s_oe_cpu_pwrgd_out;
  logic [1:0] s_oe_cpu_throttle;
  logic s_oe_cpu_thermtrip_l;
  logic [3:0] s_oe_cpu_errcode;
  logic s_oe_cpu_reset_out_l;
  logic [1:0] s_oe_cpu_socket_id;
  logic [3:0] s_oe_cpu_strap;

  logic s_in_slp_s3_l;
  logic s_in_slp_s4_l;
  logic s_in_slp_s5_l;
  logic s_in_sys_reset_l;
  logic s_in_sys_rsmrst_l;
  logic s_in_sys_pwr_btn_l;
  logic s_in_sys_pwrgd_in;
  logic s_in_sys_wake_l;
  logic s_in_cpu_pwrgd_out;
  logic [1:0] s_in_cpu_throttle;
  logic s_in_cpu_thermtrip_l;
  logic [3:0] s_in_cpu_errcode;
  logic s_in_cpu_reset_out_l;
  logic [1:0] s_in_cpu_socket_id;
  logic [3:0] s_in_cpu_strap;

  // Packed signals for the in/out/enable signals of control-pulp

  logic [31:0][5:0] s_pad_cfg;

  logic [N_SPI-1:0][3:0] s_out_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_out_qspi_csn;
  logic [N_SPI-1:0][1:0] s_out_qspi_csn_pad;
  logic [N_SPI-1:0] s_out_qspi_sck;
  logic [N_UART-1:0] s_out_uart_rx;
  logic [N_UART-1:0] s_out_uart_tx;
  logic [N_I2C-1:0] s_out_i2c_sda;
  logic [N_I2C-1:0] s_out_i2c_scl;

  logic [N_I2C_SLV-1:0] s_out_i2c_slv_sda;
  logic [N_I2C_SLV-1:0] s_out_i2c_slv_scl;


  logic [N_SPI-1:0][3:0] s_in_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_in_qspi_csn;
  logic [N_SPI-1:0][1:0] s_in_qspi_csn_pad;
  logic [N_SPI-1:0] s_in_qspi_sck;
  logic [N_UART-1:0] s_in_uart_rx;
  logic [N_UART-1:0] s_in_uart_tx;
  logic [N_I2C-1:0] s_in_i2c_sda;
  logic [N_I2C-1:0] s_in_i2c_scl;

  logic [N_I2C_SLV-1:0] s_in_i2c_slv_sda;
  logic [N_I2C_SLV-1:0] s_in_i2c_slv_scl;


  logic [N_SPI-1:0][3:0] s_oe_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_oe_qspi_csn;
  logic [N_SPI-1:0][1:0] s_oe_qspi_csn_pad;
  logic [N_SPI-1:0] s_oe_qspi_sck;
  logic [N_UART-1:0] s_oe_uart_rx;
  logic [N_UART-1:0] s_oe_uart_tx;
  logic [N_I2C-1:0] s_oe_i2c_sda;
  logic [N_I2C-1:0] s_oe_i2c_scl;

  logic [N_I2C_SLV-1:0] s_oe_i2c_slv_sda;
  logic [N_I2C_SLV-1:0] s_oe_i2c_slv_scl;


  //
  //OTHER PAD FRAME SIGNALS
  //

  logic s_soc_clk;

  logic s_jtag_tck;
  logic s_jtag_tdi;
  logic s_jtag_tdo;
  logic s_jtag_tms;
  logic s_jtag_trst;


  // System wires for the padframe-like inout signal used in the testbench

  // the w_/s_ prefixes are used to mean wire/tri-type and logic-type (respectively)

  logic s_rst_n = 1'b0;

  logic s_clk_ref;

  // SPI n°5 and n°0 share the same wires to test inter-socket facility
  tri [N_SPI-2:0][3:0] w_spi_master_sdio;
  tri [N_SPI-2:0][1:0] w_spi_master_csn;
  tri [N_SPI-2:0] w_spi_master_sck;

  tri w_spi_intr_sckt_csn;

  tri [3:0] w_spi_dpi_sdio;
  tri [1:0] w_spi_dpi_csn;
  tri w_spi_dpi_sck;

  wire [N_I2C-1:0] w_i2c_scl;
  wire [N_I2C-1:0] w_i2c_sda;

  wire [N_I2C_SLV-1:0] w_i2c_slv_scl;
  wire [N_I2C_SLV-1:0] w_i2c_slv_sda;

  logic [1:0] s_padmode_spi_master = SPI_STD;

  tri [N_UART-1:0] w_uart_rx;
  tri [N_UART-1:0] w_uart_tx;

  wire w_jtag_trst;
  wire w_jtag_tck;
  wire w_jtag_tdi;
  wire w_jtag_tms;
  wire w_jtag_tdo;


  logic s_trstn = 1'b0;
  logic s_tck = 1'b0;
  logic s_tdi = 1'b0;
  logic s_tms = 1'b0;
  logic s_tdo;

  wire w_slp_s3;
  wire w_slp_s4;
  wire w_slp_s5;
  wire w_sys_reset;
  wire w_sys_rsmrst;
  wire w_sys_pwr_btn;
  wire w_sys_pwrgd_in;
  wire w_sys_wake;
  wire w_cpu_pwrgd_out;
  wire w_cpu_throttle_0;
  wire w_cpu_throttle_1;
  wire w_cpu_thermtrip;
  wire w_cpu_errcode_0;
  wire w_cpu_errcode_1;
  wire w_cpu_errcode_2;
  wire w_cpu_errcode_3;
  wire w_cpu_reset_out_n;
  wire w_cpu_socket_id_0;
  wire w_cpu_socket_id_1;
  wire w_cpu_strap_0;
  wire w_cpu_strap_1;
  wire w_cpu_strap_2;
  wire w_cpu_strap_3;

  logic s_sys_pwr_btn = 1'b0;

  logic       bootsel_valid      = 1'b0;
  logic [1:0] bootsel            = 2'b0;
  logic       fc_fetch_en_valid  = 1'b0;
  logic       fc_fetch_en        = 1'b0;

  // Serial Link
  logic [D2D_NUM_CHANNELS-1:0] d2d_clk_out;
  logic [D2D_NUM_CHANNELS-1:0] d2d_clk_in;
  logic [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_in;
  logic [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_out;

  //
  // Timing format
  //

  initial begin : timing_format
    $timeformat(-9, 0, "ns", 9);
  end : timing_format

  // JTAG signals to sim pad
  assign w_jtag_trst   = s_trstn;
  assign w_jtag_tck    = s_tck;
  assign w_jtag_tdi    = s_tdi;
  assign w_jtag_tms    = s_tms;
  assign s_tdo         = w_jtag_tdo;

  // Control PWR_BTN GPIO for ACPI test
  assign w_sys_pwr_btn = s_sys_pwr_btn;

  // Control I2C slave signals
  logic sdaOm;
  logic sclOm;  //output master
  logic sdaIm;
  logic sclIm;  // input master
  assign (highz1, strong0) w_i2c_slv_scl[0] = sclOm;
  assign (highz1, strong0) w_i2c_slv_sda[0] = sdaOm;
  assign                   sdaIm            = w_i2c_slv_sda[0];
  assign                   sclIm            = w_i2c_slv_scl[0];

  // Control external interrupts
  logic scg_irq, scp_irq, scp_secure_irq;
  logic [71:0] mbox_irq, mbox_secure_irq;


  //
  // Simulation pad-frame
  //

  tb_pad_frame_top i_tb_pad_frame_top (
    .pad_cfg_i  (s_pad_cfg),
    .jtag_tdo_i (s_jtag_tdo),
    .jtag_tck_o (s_jtag_tck),
    .jtag_tdi_o (s_jtag_tdi),
    .jtag_tms_o (s_jtag_tms),
    .jtag_trst_o(s_jtag_trst),

    .oe_qspi_sdio_i(s_oe_qspi_sdio),
    .oe_qspi_csn_i (s_oe_qspi_csn_pad),
    .oe_qspi_sck_i (s_oe_qspi_sck),

    .oe_uart_rx_i(s_oe_uart_rx),
    .oe_uart_tx_i(s_oe_uart_tx),

    .oe_i2c0_sda_i   (s_oe_i2c_sda[0]),
    .oe_i2c0_scl_i   (s_oe_i2c_scl[0]),
    .oe_i2c1_sda_i   (s_oe_i2c_sda[1]),
    .oe_i2c1_scl_i   (s_oe_i2c_scl[1]),
    .oe_i2c2_sda_i   (s_oe_i2c_sda[2]),
    .oe_i2c2_scl_i   (s_oe_i2c_scl[2]),
    .oe_i2c3_sda_i   (s_oe_i2c_sda[3]),
    .oe_i2c3_scl_i   (s_oe_i2c_scl[3]),
    .oe_i2c4_sda_i   (s_oe_i2c_sda[4]),
    .oe_i2c4_scl_i   (s_oe_i2c_scl[4]),
    .oe_i2c5_sda_i   (s_oe_i2c_sda[5]),
    .oe_i2c5_scl_i   (s_oe_i2c_scl[5]),
    .oe_i2c6_sda_i   (s_oe_i2c_sda[6]),
    .oe_i2c6_scl_i   (s_oe_i2c_scl[6]),
    .oe_i2c7_sda_i   (s_oe_i2c_sda[7]),
    .oe_i2c7_scl_i   (s_oe_i2c_scl[7]),
    .oe_i2c8_sda_i   (s_oe_i2c_sda[8]),
    .oe_i2c8_scl_i   (s_oe_i2c_scl[8]),
    .oe_i2c9_sda_i   (s_oe_i2c_sda[9]),
    .oe_i2c9_scl_i   (s_oe_i2c_scl[9]),
    .oe_i2c10_sda_i  (s_oe_i2c_sda[10]),
    .oe_i2c10_scl_i  (s_oe_i2c_scl[10]),
    .oe_i2c11_sda_i  (s_oe_i2c_sda[11]),
    .oe_i2c11_scl_i  (s_oe_i2c_scl[11]),
    .oe_i2c_slv_sda_i(s_oe_i2c_slv_sda),
    .oe_i2c_slv_scl_i(s_oe_i2c_slv_scl),

    .out_qspi_sdio_i(s_out_qspi_sdio),
    .out_qspi_csn_i (s_out_qspi_csn_pad),
    .out_qspi_sck_i (s_out_qspi_sck),
    .out_uart_rx_i  (s_out_uart_rx),
    .out_uart_tx_i  (s_out_uart_tx),

    .out_i2c0_sda_i   (s_out_i2c_sda[0]),
    .out_i2c0_scl_i   (s_out_i2c_scl[0]),
    .out_i2c1_sda_i   (s_out_i2c_sda[1]),
    .out_i2c1_scl_i   (s_out_i2c_scl[1]),
    .out_i2c2_sda_i   (s_out_i2c_sda[2]),
    .out_i2c2_scl_i   (s_out_i2c_scl[2]),
    .out_i2c3_sda_i   (s_out_i2c_sda[3]),
    .out_i2c3_scl_i   (s_out_i2c_scl[3]),
    .out_i2c4_sda_i   (s_out_i2c_sda[4]),
    .out_i2c4_scl_i   (s_out_i2c_scl[4]),
    .out_i2c5_sda_i   (s_out_i2c_sda[5]),
    .out_i2c5_scl_i   (s_out_i2c_scl[5]),
    .out_i2c6_sda_i   (s_out_i2c_sda[6]),
    .out_i2c6_scl_i   (s_out_i2c_scl[6]),
    .out_i2c7_sda_i   (s_out_i2c_sda[7]),
    .out_i2c7_scl_i   (s_out_i2c_scl[7]),
    .out_i2c8_sda_i   (s_out_i2c_sda[8]),
    .out_i2c8_scl_i   (s_out_i2c_scl[8]),
    .out_i2c9_sda_i   (s_out_i2c_sda[9]),
    .out_i2c9_scl_i   (s_out_i2c_scl[9]),
    .out_i2c10_sda_i  (s_out_i2c_sda[10]),
    .out_i2c10_scl_i  (s_out_i2c_scl[10]),
    .out_i2c11_sda_i  (s_out_i2c_sda[11]),
    .out_i2c11_scl_i  (s_out_i2c_scl[11]),
    .out_i2c_slv_sda_i(s_out_i2c_slv_sda),
    .out_i2c_slv_scl_i(s_out_i2c_slv_scl),

    .in_qspi_sdio_o(s_in_qspi_sdio),
    .in_qspi_csn_o (s_in_qspi_csn_pad),
    .in_qspi_sck_o (s_in_qspi_sck),
    .in_uart_rx_o  (s_in_uart_rx),
    .in_uart_tx_o  (s_in_uart_tx),

    .in_i2c0_sda_o   (s_in_i2c_sda[0]),
    .in_i2c0_scl_o   (s_in_i2c_scl[0]),
    .in_i2c1_sda_o   (s_in_i2c_sda[1]),
    .in_i2c1_scl_o   (s_in_i2c_scl[1]),
    .in_i2c2_sda_o   (s_in_i2c_sda[2]),
    .in_i2c2_scl_o   (s_in_i2c_scl[2]),
    .in_i2c3_sda_o   (s_in_i2c_sda[3]),
    .in_i2c3_scl_o   (s_in_i2c_scl[3]),
    .in_i2c4_sda_o   (s_in_i2c_sda[4]),
    .in_i2c4_scl_o   (s_in_i2c_scl[4]),
    .in_i2c5_sda_o   (s_in_i2c_sda[5]),
    .in_i2c5_scl_o   (s_in_i2c_scl[5]),
    .in_i2c6_sda_o   (s_in_i2c_sda[6]),
    .in_i2c6_scl_o   (s_in_i2c_scl[6]),
    .in_i2c7_sda_o   (s_in_i2c_sda[7]),
    .in_i2c7_scl_o   (s_in_i2c_scl[7]),
    .in_i2c8_sda_o   (s_in_i2c_sda[8]),
    .in_i2c8_scl_o   (s_in_i2c_scl[8]),
    .in_i2c9_sda_o   (s_in_i2c_sda[9]),
    .in_i2c9_scl_o   (s_in_i2c_scl[9]),
    .in_i2c10_sda_o  (s_in_i2c_sda[10]),
    .in_i2c10_scl_o  (s_in_i2c_scl[10]),
    .in_i2c11_sda_o  (s_in_i2c_sda[11]),
    .in_i2c11_scl_o  (s_in_i2c_scl[11]),
    .in_i2c_slv_sda_o(s_in_i2c_slv_sda),
    .in_i2c_slv_scl_o(s_in_i2c_slv_scl),


    // GPIOs

    .out_slp_s3_l_i       (s_out_slp_s3_l),
    .out_slp_s4_l_i       (s_out_slp_s4_l),
    .out_slp_s5_l_i       (s_out_slp_s5_l),
    .out_sys_reset_l_i    (s_out_sys_reset_l),
    .out_sys_rsmrst_l_i   (s_out_sys_rsmrst_l),
    .out_sys_pwr_btn_l_i  (s_out_sys_pwr_btn_l),
    .out_sys_pwrgd_in_i   (s_out_sys_pwrgd_in),
    .out_sys_wake_l_i     (s_out_sys_wake_l),
    .out_cpu_pwrgd_out_i  (s_out_cpu_pwrgd_out),
    .out_cpu_throttle_i   (s_out_cpu_throttle),
    .out_cpu_thermtrip_l_i(s_out_cpu_thermtrip_l),
    .out_cpu_errcode_i    (s_out_cpu_errcode),
    .out_cpu_reset_out_l_i(s_out_cpu_reset_out_l),
    .out_cpu_socket_id_i  (s_out_cpu_socket_id),
    .out_cpu_strap_i      (s_out_cpu_strap),

    .oe_slp_s3_l_i       (s_oe_slp_s3_l),
    .oe_slp_s4_l_i       (s_oe_slp_s4_l),
    .oe_slp_s5_l_i       (s_oe_slp_s5_l),
    .oe_sys_reset_l_i    (s_oe_sys_reset_l),
    .oe_sys_rsmrst_l_i   (s_oe_sys_rsmrst_l),
    .oe_sys_pwr_btn_l_i  (s_oe_sys_pwr_btn_l),
    .oe_sys_pwrgd_in_i   (s_oe_sys_pwrgd_in),
    .oe_sys_wake_l_i     (s_oe_sys_wake_l),
    .oe_cpu_pwrgd_out_i  (s_oe_cpu_pwrgd_out),
    .oe_cpu_throttle_i   (s_oe_cpu_throttle),
    .oe_cpu_thermtrip_l_i(s_oe_cpu_thermtrip_l),
    .oe_cpu_errcode_i    (s_oe_cpu_errcode),
    .oe_cpu_reset_out_l_i(s_oe_cpu_reset_out_l),
    .oe_cpu_socket_id_i  (s_oe_cpu_socket_id),
    .oe_cpu_strap_i      (s_oe_cpu_strap),

    .in_slp_s3_l_o       (s_in_slp_s3_l),
    .in_slp_s4_l_o       (s_in_slp_s4_l),
    .in_slp_s5_l_o       (s_in_slp_s5_l),
    .in_sys_reset_l_o    (s_in_sys_reset_l),
    .in_sys_rsmrst_l_o   (s_in_sys_rsmrst_l),
    .in_sys_pwr_btn_l_o  (s_in_sys_pwr_btn_l),
    .in_sys_pwrgd_in_o   (s_in_sys_pwrgd_in),
    .in_sys_wake_l_o     (s_in_sys_wake_l),
    .in_cpu_pwrgd_out_o  (s_in_cpu_pwrgd_out),
    .in_cpu_throttle_o   (s_in_cpu_throttle),
    .in_cpu_thermtrip_l_o(s_in_cpu_thermtrip_l),
    .in_cpu_errcode_o    (s_in_cpu_errcode),
    .in_cpu_reset_out_l_o(s_in_cpu_reset_out_l),
    .in_cpu_socket_id_o  (s_in_cpu_socket_id),
    .in_cpu_strap_o      (s_in_cpu_strap),

    //EXT CHIP to PAD (previously pulp.sv top-level ports)
    .pad_qspi_sdio(w_spi_master_sdio),
    .pad_qspi_csn (w_spi_master_csn),
    .pad_qspi_sck (w_spi_master_sck),

    .pad_spi_intr_sckt_sdio(w_spi_master_sdio[0]),
    .pad_spi_intr_sckt_csn ({w_spi_master_csn[0][0], w_spi_master_csn[0][1]}),
    .pad_spi_intr_sckt_sck (w_spi_master_sck[0]),

    .pad_spi_dpi_sdio(w_spi_dpi_sdio),
    .pad_spi_dpi_csn (w_spi_dpi_csn),
    .pad_spi_dpi_sck (w_spi_dpi_sck),

    .pad_uart_rx(w_uart_tx),
    .pad_uart_tx(w_uart_rx),

    .pad_i2c0_sda   (w_i2c_sda[0]),
    .pad_i2c0_scl   (w_i2c_scl[0]),
    .pad_i2c1_sda   (w_i2c_sda[1]),
    .pad_i2c1_scl   (w_i2c_scl[1]),
    .pad_i2c2_sda   (w_i2c_sda[2]),
    .pad_i2c2_scl   (w_i2c_scl[2]),
    .pad_i2c3_sda   (w_i2c_sda[3]),
    .pad_i2c3_scl   (w_i2c_scl[3]),
    .pad_i2c4_sda   (w_i2c_sda[4]),
    .pad_i2c4_scl   (w_i2c_scl[4]),
    .pad_i2c5_sda   (w_i2c_sda[5]),
    .pad_i2c5_scl   (w_i2c_scl[5]),
    .pad_i2c6_sda   (w_i2c_sda[6]),
    .pad_i2c6_scl   (w_i2c_scl[6]),
    .pad_i2c7_sda   (w_i2c_sda[7]),
    .pad_i2c7_scl   (w_i2c_scl[7]),
    .pad_i2c8_sda   (w_i2c_sda[8]),
    .pad_i2c8_scl   (w_i2c_scl[8]),
    .pad_i2c9_sda   (w_i2c_sda[9]),
    .pad_i2c9_scl   (w_i2c_scl[9]),
    .pad_i2c10_sda  (w_i2c_sda[10]),
    .pad_i2c10_scl  (w_i2c_scl[10]),
    .pad_i2c11_sda  (w_i2c_sda[11]),
    .pad_i2c11_scl  (w_i2c_scl[11]),
    .pad_i2c_slv_sda(w_i2c_slv_sda),
    .pad_i2c_slv_scl(w_i2c_slv_scl),

    // GPIOs
    .pad_slp_s3         (w_slp_s3),
    .pad_slp_s4         (w_slp_s4),
    .pad_slp_s5         (w_slp_s5),
    .pad_sys_reset      (w_sys_reset),
    .pad_sys_rsmrst     (w_sys_rsmrst),
    .pad_sys_pwr_btn    (w_sys_pwr_btn),
    .pad_sys_pwrgd_in   (w_sys_pwrgd_in),
    .pad_sys_wake       (w_sys_wake),
    .pad_cpu_pwrgd_out  (w_cpu_pwrgd_out),
    .pad_cpu_throttle_0 (w_cpu_throttle_0),
    .pad_cpu_throttle_1 (w_cpu_throttle_1),
    .pad_cpu_thermtrip  (w_cpu_thermtrip),
    .pad_cpu_errcode_0  (w_cpu_errcode_0),
    .pad_cpu_errcode_1  (w_cpu_errcode_1),
    .pad_cpu_errcode_2  (w_cpu_errcode_2),
    .pad_cpu_errcode_3  (w_cpu_errcode_3),
    .pad_cpu_reset_out_n(w_cpu_reset_out_n),
    .pad_cpu_socket_id_0(w_cpu_socket_id_0),
    .pad_cpu_socket_id_1(w_cpu_socket_id_1),
    .pad_cpu_strap_0    (w_cpu_strap_0),
    .pad_cpu_strap_1    (w_cpu_strap_1),
    .pad_cpu_strap_2    (w_cpu_strap_2),
    .pad_cpu_strap_3    (w_cpu_strap_3),

    // JTAG
    .pad_jtag_tck (w_jtag_tck),
    .pad_jtag_tdi (w_jtag_tdi),
    .pad_jtag_tdo (w_jtag_tdo),
    .pad_jtag_tms (w_jtag_tms),
    .pad_jtag_trst(w_jtag_trst)
  );


  // Assign a subset of chip select signals from spi to pad frame
  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_oe
    assign s_oe_qspi_csn_pad[i] = s_oe_qspi_csn[i][1:0];
  end

  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_out
    assign s_out_qspi_csn_pad[i] = s_out_qspi_csn[i][1:0];
  end

  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_in
    assign s_in_qspi_csn[i][1:0] = s_in_qspi_csn_pad[i];
    assign s_in_qspi_csn[i][3:2] = 2'b11;
  end

// DPI bridge to DPI models
`ifdef USE_DPI
  CTRL ctrl ();
  JTAG jtag ();
  UART uart ();
  CPI cpi ();
  QSPI qspi_0 ();
  QSPI_CS qspi_0_csn[0:1] ();
  GPIO gpio_22 ();

  assign s_rst_dpi_n       = ~ctrl.reset;
  assign w_uart_tx[0]      = uart.tx;
  assign uart.rx           = w_uart_rx[0];
  assign w_spi_dpi_sdio[0] = qspi_0.data_0_out;
  assign qspi_0.data_0_in  = w_spi_dpi_sdio[0];
  assign w_spi_dpi_sdio[1] = qspi_0.data_1_out;
  assign qspi_0.data_1_in  = w_spi_dpi_sdio[1];
  assign w_spi_dpi_sdio[2] = qspi_0.data_2_out;
  assign qspi_0.data_2_in  = w_spi_dpi_sdio[2];
  assign w_spi_dpi_sdio[3] = qspi_0.data_3_out;
  assign qspi_0.data_3_in  = w_spi_dpi_sdio[3];
  assign qspi_0.sck        = w_spi_dpi_sck;
  assign qspi_0_csn[0].csn = w_spi_dpi_csn[0];
  assign qspi_0_csn[1].csn = w_spi_dpi_csn[1];

  initial begin
    automatic tb_driver::tb_driver i_tb_driver = new;
    qspi_0.data_0_out = 'bz;
    qspi_0.data_1_out = 'bz;
    qspi_0.data_2_out = 'bz;
    qspi_0.data_3_out = 'bz;

    i_tb_driver.register_qspim_itf(0, qspi_0, qspi_0_csn);
    i_tb_driver.register_uart_itf(0, uart);
    i_tb_driver.register_jtag_itf(0, jtag);
    i_tb_driver.register_cpi_itf(0, cpi);
    i_tb_driver.register_ctrl_itf(0, ctrl);
    i_tb_driver.register_gpio_itf(22, gpio_22);
    i_tb_driver.build_from_json(CONFIG_FILE);
  end
`endif  //  `ifdef USE_DPI

  // SPI flash model (not open-source, from Spansion)
`ifdef TARGET_FLASH_VIP
  for (genvar i = 0; i < N_SPI - 1; i++) begin : gen_vip_spi_mem
    s25fs256s #(
      .TimingModel  ("S25FS256SAGMFI000_F_30pF"),
      .mem_file_name("./vectors/qspi_stim.slm"),
      .UserPreload  ((LOAD_L2 == "STANDALONE") ? 1 : 0)
    ) i_spi_flash_csn (
      .SI      (w_spi_master_sdio[i][0]),
      .SO      (w_spi_master_sdio[i][1]),
      .SCK     (w_spi_master_sck[i]),
      .CSNeg   (w_spi_master_csn[i][0]),
      .WPNeg   (w_spi_master_sdio[i][2]),
      .RESETNeg(w_spi_master_sdio[i][3])
    );
  end  // block: gen_vip_spi_mem
`endif


  // Assign to the chip select of the inter-socket VIP memory the pad_spi_intr_sckt_csn[0]
  // if the inter-socket peripheral acts as a master (when out_spi5_intr_sckt_csn_o goes to '0'
  // to select the VIP memory)
  assign w_spi_intr_sckt_csn = out_spi5_intr_sckt_csn_o ? 1'bz : w_spi_master_csn[0][1];

  // SPI flash model for inter-socket test
`ifdef TARGET_FLASH_VIP
  s25fs256s #(
    .TimingModel  ("S25FS256SAGMFI000_F_30pF"),
    .mem_file_name("./vectors/qspi_stim.slm"),
    .UserPreload  ((LOAD_L2 == "STANDALONE") ? 1 : 0)
  ) i_spi_flash_csn (
    .SI      (w_spi_master_sdio[0][0]),
    .SO      (w_spi_master_sdio[0][1]),
    .SCK     (w_spi_master_sck[0]),
    .CSNeg   (w_spi_intr_sckt_csn),
    .WPNeg   (w_spi_master_sdio[0][2]),
    .RESETNeg(w_spi_master_sdio[0][3])
  );
`endif

  // I2C memory models
`ifdef TARGET_I2C_VIP
  for (genvar i = 0; i < N_I2C; i++) begin : gen_vip_i2c_mem
    M24FC1025 i_i2c_mem (
      .A0   (1'b0),
      .A1   (1'b0),
      .A2   (1'b1),
      .WP   (1'b0),
      .SDA  (w_i2c_sda[i]),
      .SCL  (w_i2c_scl[i]),
      .RESET(1'b0)
    );
  end
`endif

  // I2C Pullups
  for (genvar i = 0; i < N_I2C; i++) begin : gen_pullup_i2c_scl
    pullup scl_pullup_i (w_i2c_scl[i]);
  end

  for (genvar i = 0; i < N_I2C; i++) begin : gen_pullup_i2c_sda
    pullup sda_pullup_i (w_i2c_sda[i]);
  end

  // I2C alert
  assign in_i2c0_vrm_mst_alert_i = 1'b0;
  assign in_i2c1_vrm_mst_alert_i = 1'b0;
  assign in_i2c2_vrm_mst_alert_i = 1'b0;
  assign in_i2c3_vrm_mst_alert_i = 1'b0;
  assign in_i2c4_vrm_mst_alert_i = 1'b0;
  assign in_i2cc_vrm_mst_alert_i = 1'b0;
  assign in_i2c8_os_mst_alert_i = 1'b0;
  assign in_i2c9_pcie_pnp_mst_alert_i = 1'b0;
  assign in_i2ca_bios_mst_alert_i = 1'b0;
  assign in_i2cb_bmc_mst_alert_i = 1'b0;
  assign in_i2c5_intr_sckt_alert_i = 1'b0;
  assign in_spi5_intr_sckt_alert_i = 1'b0;
  assign in_i2c6_rtc_mst_alert_i = 1'b0;

  // UART receiver
  for (genvar i = 0; i < N_UART; i++) begin : uart_sim_gen
    // UART receiver and sender
    uart_sim #(
      .BAUD_RATE(BAUDRATE),
      .PARITY_EN(0)
    ) i_uart_sim (
      .rx   (w_uart_rx[i]),
      .rx_en(uart_tb_rx_en),
      .tx   (w_uart_tx[i])
    );
  end


  // Define AXI types shortcuts
  // from/to nci_cp_top
  typedef logic [AXI_ID_INP_WIDTH_EXT-1:0] axi_id_inp_ext_t;
  typedef logic [AXI_ID_OUP_WIDTH_EXT-1:0] axi_id_oup_ext_t;
  typedef logic [AXI_USER_WIDTH_EXT-1:0] axi_user_ext_t;
  typedef logic [AXI_DATA_INP_WIDTH_EXT-1:0] axi_data_inp_ext_t;
  typedef logic [AXI_STRB_INP_WIDTH_EXT-1:0] axi_strb_inp_ext_t;
  typedef logic [AXI_DATA_OUP_WIDTH_EXT-1:0] axi_data_oup_ext_t;
  typedef logic [AXI_STRB_OUP_WIDTH_EXT-1:0] axi_strb_oup_ext_t;
  typedef logic [AXI_ADDR_WIDTH_EXT-1:0] axi_addr_ext_t;

  // AXI structs

  // nci_cp_top Master
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_inp_ext_t, axi_data_inp_ext_t, axi_strb_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_inp_ext_t, axi_data_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_inp_ext_t, axi_aw_inp_ext_t, axi_w_inp_ext_t, axi_ar_inp_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_inp_ext_t, axi_b_inp_ext_t, axi_r_inp_ext_t);

  // nci_cp_top Slave
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_oup_ext_t, axi_data_oup_ext_t, axi_strb_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_ext_t, axi_data_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_ext_t, axi_aw_oup_ext_t, axi_w_oup_ext_t, axi_ar_oup_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_ext_t, axi_b_oup_ext_t, axi_r_oup_ext_t);

  // nci_cp_top Master
  axi_req_inp_ext_t from_ext_req;
  axi_resp_inp_ext_t from_ext_resp;
  // nci_cp_top Slave
  axi_req_oup_ext_t to_ext_req;
  axi_resp_oup_ext_t to_ext_resp;

  // AXI mux inputs (slaves): control-pulp AXI mst ([0]) and axi_sim_driver ([1])
  axi_req_oup_ext_t [1:0] from_mux_req;
  axi_resp_oup_ext_t [1:0] from_mux_resp;

  // AXI mux output (master): to sim mem
  // After AXI mux, ID(out) = ID(in) + $clog2(#SLAVES)
  typedef logic [AXI_ID_OUP_WIDTH_EXT:0] axi_id_oup_mux_t;

  // nci_cp_top Master to sim mem
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_oup_mux_t, axi_addr_ext_t, axi_id_oup_mux_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_oup_mux_t, axi_id_oup_mux_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_oup_mux_t, axi_addr_ext_t, axi_id_oup_mux_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_mux_t, axi_data_oup_ext_t, axi_id_oup_mux_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_mux_t, axi_aw_oup_mux_t, axi_w_oup_ext_t, axi_ar_oup_mux_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_mux_t, axi_b_oup_mux_t, axi_r_oup_mux_t);

  axi_req_oup_mux_t to_sim_mem_req;
  axi_resp_oup_mux_t to_sim_mem_resp;


  //
  // DUT
  //
`ifndef PS_SIM // rtl simulation
  pms_top #(
    .CORE_TYPE (CORE_TYPE),
    .USE_FPU   (RISCY_FPU),
    .SIM_STDOUT(SIM_STDOUT),
    .BEHAV_MEM (BEHAV_MEM),
    .MACRO_ROM (MACRO_ROM),
    .USE_CLUSTER (USE_CLUSTER),

    .N_L2_BANKS(pms_top_pkg::N_L2_BANKS),
    .N_L2_BANKS_PRI(pms_top_pkg::N_L2_BANKS_PRI),
    .L2_BANK_SIZE(pms_top_pkg::L2_BANK_SIZE),
    .N_L1_BANKS(pms_top_pkg::N_L1_BANKS),
    .L1_BANK_SIZE(pms_top_pkg::L1_BANK_SIZE),

    .N_SOC_PERF_COUNTERS(16),  // for RTL/FPGA 16 perf counters one for each event
    .N_CLUST_PERF_COUNTERS(16),
    .N_I2C(pms_top_pkg::N_I2C),
    .N_I2C_SLV(pms_top_pkg::N_I2C_SLV),
    .N_SPI(pms_top_pkg::N_SPI),
    .N_UART(pms_top_pkg::N_UART),

    // D2D link
    .USE_D2D (USE_D2D),
    .USE_D2D_DELAY_LINE (USE_D2D_DELAY_LINE),
    .D2D_NUM_CHANNELS (D2D_NUM_CHANNELS),
    .D2D_NUM_LANES (D2D_NUM_LANES),

    .AXI_DATA_INP_WIDTH_EXT(AXI_DATA_INP_WIDTH_EXT),
    .AXI_DATA_OUP_WIDTH_EXT(AXI_DATA_OUP_WIDTH_EXT),
    .AXI_ID_OUP_WIDTH_EXT  (AXI_ID_OUP_WIDTH_EXT),
    .AXI_ID_INP_WIDTH_EXT  (AXI_ID_INP_WIDTH_EXT)
  )
`else // post-synthesis simulation (top-level tech agnostic)
  pms_top_CORE_TYPE0_USE_FPU1_PULP_XPULP1_MACRO_ROM0_USE_CLUSTER1_DMA_TYPE1_SIM_STDOUT0_BEHAV_MEM0_N_SOC_PERF_COUNTERS1_N_CLUST_PERF_COUNTERS1
`endif
    i_dut (

    // AXI ports to external, flattened

    // AXI Master to nci_cp_top
    .awid_mst_o    (awid_mst_o),
    .awaddr_mst_o  (awaddr_mst_o),
    .awlen_mst_o   (awlen_mst_o),
    .awsize_mst_o  (awsize_mst_o),
    .awburst_mst_o (awburst_mst_o),
    .awlock_mst_o  (awlock_mst_o),
    .awcache_mst_o (awcache_mst_o),
    .awprot_mst_o  (awprot_mst_o),
    .awqos_mst_o   (awqos_mst_o),
    .awregion_mst_o(awregion_mst_o),
    .aw_atop_mst_o (aw_atop_mst_o),
    .awuser_mst_o  (awuser_mst_o),
    .awvalid_mst_o (awvalid_mst_o),
    .awready_mst_i (awready_mst_i),

    .wdata_mst_o (wdata_mst_o),
    .wstrb_mst_o (wstrb_mst_o),
    .wlast_mst_o (wlast_mst_o),
    .wuser_mst_o (wuser_mst_o),
    .wvalid_mst_o(wvalid_mst_o),
    .wready_mst_i(wready_mst_i),

    .bid_mst_i   (bid_mst_i),
    .bresp_mst_i (bresp_mst_i),
    .buser_mst_i (buser_mst_i),
    .bvalid_mst_i(bvalid_mst_i),
    .bready_mst_o(bready_mst_o),

    .arid_mst_o    (arid_mst_o),
    .araddr_mst_o  (araddr_mst_o),
    .arlen_mst_o   (arlen_mst_o),
    .arsize_mst_o  (arsize_mst_o),
    .arburst_mst_o (arburst_mst_o),
    .arlock_mst_o  (arlock_mst_o),
    .arcache_mst_o (arcache_mst_o),
    .arprot_mst_o  (arprot_mst_o),
    .arqos_mst_o   (arqos_mst_o),
    .arregion_mst_o(arregion_mst_o),
    .aruser_mst_o  (aruser_mst_o),
    .arvalid_mst_o (arvalid_mst_o),
    .arready_mst_i (arready_mst_i),

    .rid_mst_i   (rid_mst_i),
    .rdata_mst_i (rdata_mst_i),
    .rresp_mst_i (rresp_mst_i),
    .rlast_mst_i (rlast_mst_i),
    .ruser_mst_i (ruser_mst_i),
    .rvalid_mst_i(rvalid_mst_i),
    .rready_mst_o(rready_mst_o),


    // AXI Slave from nci_cp_top
    .awid_slv_i    (awid_slv_i),
    .awaddr_slv_i  (awaddr_slv_i),
    .awlen_slv_i   (awlen_slv_i),
    .awsize_slv_i  (awsize_slv_i),
    .awburst_slv_i (awburst_slv_i),
    .awlock_slv_i  (awlock_slv_i),
    .awcache_slv_i (awcache_slv_i),
    .awprot_slv_i  (awprot_slv_i),
    .awqos_slv_i   (awqos_slv_i),
    .awregion_slv_i(awregion_slv_i),
    .aw_atop_slv_i (aw_atop_slv_i),
    .awuser_slv_i  (awuser_slv_i),
    .awvalid_slv_i (awvalid_slv_i),
    .awready_slv_o (awready_slv_o),

    .wdata_slv_i (wdata_slv_i),
    .wstrb_slv_i (wstrb_slv_i),
    .wlast_slv_i (wlast_slv_i),
    .wuser_slv_i (wuser_slv_i),
    .wvalid_slv_i(wvalid_slv_i),
    .wready_slv_o(wready_slv_o),

    .bid_slv_o   (bid_slv_o),
    .bresp_slv_o (bresp_slv_o),
    .buser_slv_o (buser_slv_o),
    .bvalid_slv_o(bvalid_slv_o),
    .bready_slv_i(bready_slv_i),

    .arid_slv_i    (arid_slv_i),
    .araddr_slv_i  (araddr_slv_i),
    .arlen_slv_i   (arlen_slv_i),
    .arsize_slv_i  (arsize_slv_i),
    .arburst_slv_i (arburst_slv_i),
    .arlock_slv_i  (arlock_slv_i),
    .arcache_slv_i (arcache_slv_i),
    .arprot_slv_i  (arprot_slv_i),
    .arqos_slv_i   (arqos_slv_i),
    .arregion_slv_i(arregion_slv_i),
    .aruser_slv_i  (aruser_slv_i),
    .arvalid_slv_i (arvalid_slv_i),
    .arready_slv_o (arready_slv_o),

    .rid_slv_o   (rid_slv_o),
    .rdata_slv_o (rdata_slv_o),
    .rresp_slv_o (rresp_slv_o),
    .rlast_slv_o (rlast_slv_o),
    .ruser_slv_o (ruser_slv_o),
    .rvalid_slv_o(rvalid_slv_o),
    .rready_slv_i(rready_slv_i),

    .d2d_clk_i  (d2d_clk_in),
    .d2d_data_i (d2d_data_in),
    .d2d_clk_o  (d2d_clk_out),
    .d2d_data_o (d2d_data_out),

    // soc: on-pmu internal peripherals

    .pad_cfg_o  (s_pad_cfg),
    .ref_clk_i  (s_clk_ref),
    .sys_clk_i  (s_clk_ref),   // TODO: fix this clock should be 600 MhZ
    .soc_clk_o  (s_soc_clk),
    .test_clk_i ('0),
    .dft_test_mode_i ('0),
    .dft_cg_enable_i ('0),
    .rst_ni     (s_rst_n),
    .jtag_tdo_o (s_jtag_tdo),
    .jtag_tck_i (s_jtag_tck),
    .jtag_tdi_i (s_jtag_tdi),
    .jtag_tms_i (s_jtag_tms),
    .jtag_trst_i(s_jtag_trst),

    .wdt_alert_o      (),
    .wdt_alert_clear_i(1'b0),

    .scg_irq_i        (scg_irq),
    .scp_irq_i        (scp_irq),
    .scp_secure_irq_i (scp_secure_irq),
    .mbox_irq_i       (mbox_irq),
    .mbox_secure_irq_i(mbox_secure_irq),


    // Inout signals are split into input, output and enables

    //I2C
    .out_i2c0_vrm_mst_scl_o  (out_i2c0_vrm_mst_scl_o),
    .out_i2c0_vrm_mst_sda_o  (out_i2c0_vrm_mst_sda_o),
    .out_i2c0_vrm_mst_alert_o(out_i2c0_vrm_mst_alert_o),

    .oe_i2c0_vrm_mst_scl_o  (oe_i2c0_vrm_mst_scl_o),
    .oe_i2c0_vrm_mst_sda_o  (oe_i2c0_vrm_mst_sda_o),
    .oe_i2c0_vrm_mst_alert_o(oe_i2c0_vrm_mst_alert_o),

    .in_i2c0_vrm_mst_scl_i  (in_i2c0_vrm_mst_scl_i),
    .in_i2c0_vrm_mst_sda_i  (in_i2c0_vrm_mst_sda_i),
    .in_i2c0_vrm_mst_alert_i(in_i2c0_vrm_mst_alert_i),

    .out_i2c1_vrm_mst_scl_o  (out_i2c1_vrm_mst_scl_o),
    .out_i2c1_vrm_mst_sda_o  (out_i2c1_vrm_mst_sda_o),
    .out_i2c1_vrm_mst_alert_o(out_i2c1_vrm_mst_alert_o),

    .oe_i2c1_vrm_mst_scl_o  (oe_i2c1_vrm_mst_scl_o),
    .oe_i2c1_vrm_mst_sda_o  (oe_i2c1_vrm_mst_sda_o),
    .oe_i2c1_vrm_mst_alert_o(oe_i2c1_vrm_mst_alert_o),

    .in_i2c1_vrm_mst_scl_i  (in_i2c1_vrm_mst_scl_i),
    .in_i2c1_vrm_mst_sda_i  (in_i2c1_vrm_mst_sda_i),
    .in_i2c1_vrm_mst_alert_i(in_i2c1_vrm_mst_alert_i),

    .out_i2c2_vrm_mst_scl_o  (out_i2c2_vrm_mst_scl_o),
    .out_i2c2_vrm_mst_sda_o  (out_i2c2_vrm_mst_sda_o),
    .out_i2c2_vrm_mst_alert_o(out_i2c2_vrm_mst_alert_o),

    .oe_i2c2_vrm_mst_scl_o  (oe_i2c2_vrm_mst_scl_o),
    .oe_i2c2_vrm_mst_sda_o  (oe_i2c2_vrm_mst_sda_o),
    .oe_i2c2_vrm_mst_alert_o(oe_i2c2_vrm_mst_alert_o),

    .in_i2c2_vrm_mst_scl_i  (in_i2c2_vrm_mst_scl_i),
    .in_i2c2_vrm_mst_sda_i  (in_i2c2_vrm_mst_sda_i),
    .in_i2c2_vrm_mst_alert_i(in_i2c2_vrm_mst_alert_i),

    .out_i2c3_vrm_mst_scl_o  (out_i2c3_vrm_mst_scl_o),
    .out_i2c3_vrm_mst_sda_o  (out_i2c3_vrm_mst_sda_o),
    .out_i2c3_vrm_mst_alert_o(out_i2c3_vrm_mst_alert_o),

    .oe_i2c3_vrm_mst_scl_o  (oe_i2c3_vrm_mst_scl_o),
    .oe_i2c3_vrm_mst_sda_o  (oe_i2c3_vrm_mst_sda_o),
    .oe_i2c3_vrm_mst_alert_o(oe_i2c3_vrm_mst_alert_o),

    .in_i2c3_vrm_mst_scl_i  (in_i2c3_vrm_mst_scl_i),
    .in_i2c3_vrm_mst_sda_i  (in_i2c3_vrm_mst_sda_i),
    .in_i2c3_vrm_mst_alert_i(in_i2c3_vrm_mst_alert_i),

    .out_i2c4_vrm_mst_scl_o  (out_i2c4_vrm_mst_scl_o),
    .out_i2c4_vrm_mst_sda_o  (out_i2c4_vrm_mst_sda_o),
    .out_i2c4_vrm_mst_alert_o(out_i2c4_vrm_mst_alert_o),

    .oe_i2c4_vrm_mst_scl_o  (oe_i2c4_vrm_mst_scl_o),
    .oe_i2c4_vrm_mst_sda_o  (oe_i2c4_vrm_mst_sda_o),
    .oe_i2c4_vrm_mst_alert_o(oe_i2c4_vrm_mst_alert_o),

    .in_i2c4_vrm_mst_scl_i  (in_i2c4_vrm_mst_scl_i),
    .in_i2c4_vrm_mst_sda_i  (in_i2c4_vrm_mst_sda_i),
    .in_i2c4_vrm_mst_alert_i(in_i2c4_vrm_mst_alert_i),

    .out_i2cc_vrm_mst_scl_o  (out_i2cc_vrm_mst_scl_o),
    .out_i2cc_vrm_mst_sda_o  (out_i2cc_vrm_mst_sda_o),
    .out_i2cc_vrm_mst_alert_o(out_i2cc_vrm_mst_alert_o),

    .oe_i2cc_vrm_mst_scl_o  (oe_i2cc_vrm_mst_scl_o),
    .oe_i2cc_vrm_mst_sda_o  (oe_i2cc_vrm_mst_sda_o),
    .oe_i2cc_vrm_mst_alert_o(oe_i2cc_vrm_mst_alert_o),

    .in_i2cc_vrm_mst_scl_i  (in_i2cc_vrm_mst_scl_i),
    .in_i2cc_vrm_mst_sda_i  (in_i2cc_vrm_mst_sda_i),
    .in_i2cc_vrm_mst_alert_i(in_i2cc_vrm_mst_alert_i),

    .out_i2c6_rtc_mst_scl_o  (out_i2c6_rtc_mst_scl_o),
    .out_i2c6_rtc_mst_sda_o  (out_i2c6_rtc_mst_sda_o),
    .out_i2c6_rtc_mst_alert_o(out_i2c6_rtc_mst_alert_o),

    .oe_i2c6_rtc_mst_scl_o  (oe_i2c6_rtc_mst_scl_o),
    .oe_i2c6_rtc_mst_sda_o  (oe_i2c6_rtc_mst_sda_o),
    .oe_i2c6_rtc_mst_alert_o(oe_i2c6_rtc_mst_alert_o),

    .in_i2c6_rtc_mst_scl_i  (in_i2c6_rtc_mst_scl_i),
    .in_i2c6_rtc_mst_sda_i  (in_i2c6_rtc_mst_sda_i),
    .in_i2c6_rtc_mst_alert_i(in_i2c6_rtc_mst_alert_i),

    .out_i2c7_bmc_slv_scl_o(out_i2c7_bmc_slv_scl_o),
    .out_i2c7_bmc_slv_sda_o(out_i2c7_bmc_slv_sda_o),

    .oe_i2c7_bmc_slv_scl_o(oe_i2c7_bmc_slv_scl_o),
    .oe_i2c7_bmc_slv_sda_o(oe_i2c7_bmc_slv_sda_o),

    .in_i2c7_bmc_slv_scl_i(in_i2c7_bmc_slv_scl_i),
    .in_i2c7_bmc_slv_sda_i(in_i2c7_bmc_slv_sda_i),

    .out_i2c8_os_mst_scl_o  (out_i2c8_os_mst_scl_o),
    .out_i2c8_os_mst_sda_o  (out_i2c8_os_mst_sda_o),
    .out_i2c8_os_mst_alert_o(out_i2c8_os_mst_alert_o),

    .oe_i2c8_os_mst_scl_o  (oe_i2c8_os_mst_scl_o),
    .oe_i2c8_os_mst_sda_o  (oe_i2c8_os_mst_sda_o),
    .oe_i2c8_os_mst_alert_o(oe_i2c8_os_mst_alert_o),

    .in_i2c8_os_mst_scl_i  (in_i2c8_os_mst_scl_i),
    .in_i2c8_os_mst_sda_i  (in_i2c8_os_mst_sda_i),
    .in_i2c8_os_mst_alert_i(in_i2c8_os_mst_alert_i),

    .out_i2c9_pcie_pnp_mst_scl_o  (out_i2c9_pcie_pnp_mst_scl_o),
    .out_i2c9_pcie_pnp_mst_sda_o  (out_i2c9_pcie_pnp_mst_sda_o),
    .out_i2c9_pcie_pnp_mst_alert_o(out_i2c9_pcie_pnp_mst_alert_o),

    .oe_i2c9_pcie_pnp_mst_scl_o  (oe_i2c9_pcie_pnp_mst_scl_o),
    .oe_i2c9_pcie_pnp_mst_sda_o  (oe_i2c9_pcie_pnp_mst_sda_o),
    .oe_i2c9_pcie_pnp_mst_alert_o(oe_i2c9_pcie_pnp_mst_alert_o),

    .in_i2c9_pcie_pnp_mst_scl_i  (in_i2c9_pcie_pnp_mst_scl_i),
    .in_i2c9_pcie_pnp_mst_sda_i  (in_i2c9_pcie_pnp_mst_sda_i),
    .in_i2c9_pcie_pnp_mst_alert_i(in_i2c9_pcie_pnp_mst_alert_i),

    .out_i2ca_bios_mst_scl_o  (out_i2ca_bios_mst_scl_o),
    .out_i2ca_bios_mst_sda_o  (out_i2ca_bios_mst_sda_o),
    .out_i2ca_bios_mst_alert_o(out_i2ca_bios_mst_alert_o),

    .oe_i2ca_bios_mst_scl_o  (oe_i2ca_bios_mst_scl_o),
    .oe_i2ca_bios_mst_sda_o  (oe_i2ca_bios_mst_sda_o),
    .oe_i2ca_bios_mst_alert_o(oe_i2ca_bios_mst_alert_o),

    .in_i2ca_bios_mst_scl_i  (in_i2ca_bios_mst_scl_i),
    .in_i2ca_bios_mst_sda_i  (in_i2ca_bios_mst_sda_i),
    .in_i2ca_bios_mst_alert_i(in_i2ca_bios_mst_alert_i),

    .out_i2cb_bmc_mst_scl_o  (out_i2cb_bmc_mst_scl_o),
    .out_i2cb_bmc_mst_sda_o  (out_i2cb_bmc_mst_sda_o),
    .out_i2cb_bmc_mst_alert_o(out_i2cb_bmc_mst_alert_o),

    .oe_i2cb_bmc_mst_scl_o  (oe_i2cb_bmc_mst_scl_o),
    .oe_i2cb_bmc_mst_sda_o  (oe_i2cb_bmc_mst_sda_o),
    .oe_i2cb_bmc_mst_alert_o(oe_i2cb_bmc_mst_alert_o),

    .in_i2cb_bmc_mst_scl_i  (in_i2cb_bmc_mst_scl_i),
    .in_i2cb_bmc_mst_sda_i  (in_i2cb_bmc_mst_sda_i),
    .in_i2cb_bmc_mst_alert_i(in_i2cb_bmc_mst_alert_i),

    //SPI
    .in_qspi_flash_mst_csn0_i(in_qspi_flash_mst_csn0_i),
    .in_qspi_flash_mst_csn1_i(in_qspi_flash_mst_csn1_i),
    .in_qspi_flash_mst_sck_i (in_qspi_flash_mst_sck_i),
    .in_qspi_flash_mst_sdio_i(in_qspi_flash_mst_sdio_i),

    .out_qspi_flash_mst_csn0_o(out_qspi_flash_mst_csn0_o),
    .out_qspi_flash_mst_csn1_o(out_qspi_flash_mst_csn1_o),
    .out_qspi_flash_mst_sck_o (out_qspi_flash_mst_sck_o),
    .out_qspi_flash_mst_sdio_o(out_qspi_flash_mst_sdio_o),

    .oe_qspi_flash_mst_csn0_o(oe_qspi_flash_mst_csn0_o),
    .oe_qspi_flash_mst_csn1_o(oe_qspi_flash_mst_csn1_o),
    .oe_qspi_flash_mst_sck_o (oe_qspi_flash_mst_sck_o),
    .oe_qspi_flash_mst_sdio_o(oe_qspi_flash_mst_sdio_o),

    .in_spi0_vrm_mst_csn0_i(in_spi0_vrm_mst_csn0_i),
    .in_spi0_vrm_mst_csn1_i(in_spi0_vrm_mst_csn1_i),
    .in_spi0_vrm_mst_sck_i (in_spi0_vrm_mst_sck_i),
    .in_spi0_vrm_mst_si_i  (in_spi0_vrm_mst_si_i),
    .in_spi0_vrm_mst_so_i  (in_spi0_vrm_mst_so_i),

    .out_spi0_vrm_mst_csn0_o(out_spi0_vrm_mst_csn0_o),
    .out_spi0_vrm_mst_csn1_o(out_spi0_vrm_mst_csn1_o),
    .out_spi0_vrm_mst_sck_o (out_spi0_vrm_mst_sck_o),
    .out_spi0_vrm_mst_si_o  (out_spi0_vrm_mst_si_o),
    .out_spi0_vrm_mst_so_o  (out_spi0_vrm_mst_so_o),

    .oe_spi0_vrm_mst_csn0_o(oe_spi0_vrm_mst_csn0_o),
    .oe_spi0_vrm_mst_csn1_o(oe_spi0_vrm_mst_csn1_o),
    .oe_spi0_vrm_mst_sck_o (oe_spi0_vrm_mst_sck_o),
    .oe_spi0_vrm_mst_si_o  (oe_spi0_vrm_mst_si_o),
    .oe_spi0_vrm_mst_so_o  (oe_spi0_vrm_mst_so_o),

    .in_spi1_vrm_mst_csn0_i(in_spi1_vrm_mst_csn0_i),
    .in_spi1_vrm_mst_csn1_i(in_spi1_vrm_mst_csn1_i),
    .in_spi1_vrm_mst_sck_i (in_spi1_vrm_mst_sck_i),
    .in_spi1_vrm_mst_si_i  (in_spi1_vrm_mst_si_i),
    .in_spi1_vrm_mst_so_i  (in_spi1_vrm_mst_so_i),

    .out_spi1_vrm_mst_csn0_o(out_spi1_vrm_mst_csn0_o),
    .out_spi1_vrm_mst_csn1_o(out_spi1_vrm_mst_csn1_o),
    .out_spi1_vrm_mst_sck_o (out_spi1_vrm_mst_sck_o),
    .out_spi1_vrm_mst_si_o  (out_spi1_vrm_mst_si_o),
    .out_spi1_vrm_mst_so_o  (out_spi1_vrm_mst_so_o),

    .oe_spi1_vrm_mst_csn0_o(oe_spi1_vrm_mst_csn0_o),
    .oe_spi1_vrm_mst_csn1_o(oe_spi1_vrm_mst_csn1_o),
    .oe_spi1_vrm_mst_sck_o (oe_spi1_vrm_mst_sck_o),
    .oe_spi1_vrm_mst_si_o  (oe_spi1_vrm_mst_si_o),
    .oe_spi1_vrm_mst_so_o  (oe_spi1_vrm_mst_so_o),

    .in_spi2_vrm_mst_csn0_i(in_spi2_vrm_mst_csn0_i),
    .in_spi2_vrm_mst_csn1_i(in_spi2_vrm_mst_csn1_i),
    .in_spi2_vrm_mst_sck_i (in_spi2_vrm_mst_sck_i),
    .in_spi2_vrm_mst_si_i  (in_spi2_vrm_mst_si_i),
    .in_spi2_vrm_mst_so_i  (in_spi2_vrm_mst_so_i),

    .out_spi2_vrm_mst_csn0_o(out_spi2_vrm_mst_csn0_o),
    .out_spi2_vrm_mst_csn1_o(out_spi2_vrm_mst_csn1_o),
    .out_spi2_vrm_mst_sck_o (out_spi2_vrm_mst_sck_o),
    .out_spi2_vrm_mst_si_o  (out_spi2_vrm_mst_si_o),
    .out_spi2_vrm_mst_so_o  (out_spi2_vrm_mst_so_o),

    .oe_spi2_vrm_mst_csn0_o(oe_spi2_vrm_mst_csn0_o),
    .oe_spi2_vrm_mst_csn1_o(oe_spi2_vrm_mst_csn1_o),
    .oe_spi2_vrm_mst_sck_o (oe_spi2_vrm_mst_sck_o),
    .oe_spi2_vrm_mst_si_o  (oe_spi2_vrm_mst_si_o),
    .oe_spi2_vrm_mst_so_o  (oe_spi2_vrm_mst_so_o),

    .in_spi3_vrm_mst_csn_i(in_spi3_vrm_mst_csn_i),
    .in_spi3_vrm_mst_sck_i(in_spi3_vrm_mst_sck_i),
    .in_spi3_vrm_mst_si_i (in_spi3_vrm_mst_si_i),
    .in_spi3_vrm_mst_so_i (in_spi3_vrm_mst_so_i),

    .out_spi3_vrm_mst_csn_o(out_spi3_vrm_mst_csn_o),
    .out_spi3_vrm_mst_sck_o(out_spi3_vrm_mst_sck_o),
    .out_spi3_vrm_mst_si_o (out_spi3_vrm_mst_si_o),
    .out_spi3_vrm_mst_so_o (out_spi3_vrm_mst_so_o),

    .oe_spi3_vrm_mst_csn_o(oe_spi3_vrm_mst_csn_o),
    .oe_spi3_vrm_mst_sck_o(oe_spi3_vrm_mst_sck_o),
    .oe_spi3_vrm_mst_si_o (oe_spi3_vrm_mst_si_o),
    .oe_spi3_vrm_mst_so_o (oe_spi3_vrm_mst_so_o),

    .in_spi4_vrm_mst_csn_i(in_spi4_vrm_mst_csn_i),
    .in_spi4_vrm_mst_sck_i(in_spi4_vrm_mst_sck_i),
    .in_spi4_vrm_mst_si_i (in_spi4_vrm_mst_si_i),
    .in_spi4_vrm_mst_so_i (in_spi4_vrm_mst_so_i),

    .out_spi4_vrm_mst_csn_o(out_spi4_vrm_mst_csn_o),
    .out_spi4_vrm_mst_sck_o(out_spi4_vrm_mst_sck_o),
    .out_spi4_vrm_mst_si_o (out_spi4_vrm_mst_si_o),
    .out_spi4_vrm_mst_so_o (out_spi4_vrm_mst_so_o),

    .oe_spi4_vrm_mst_csn_o(oe_spi4_vrm_mst_csn_o),
    .oe_spi4_vrm_mst_sck_o(oe_spi4_vrm_mst_sck_o),
    .oe_spi4_vrm_mst_si_o (oe_spi4_vrm_mst_si_o),
    .oe_spi4_vrm_mst_so_o (oe_spi4_vrm_mst_so_o),

    .in_spi6_vrm_mst_csn_i(in_spi6_vrm_mst_csn_i),
    .in_spi6_vrm_mst_sck_i(in_spi6_vrm_mst_sck_i),
    .in_spi6_vrm_mst_si_i (in_spi6_vrm_mst_si_i),
    .in_spi6_vrm_mst_so_i (in_spi6_vrm_mst_so_i),

    .out_spi6_vrm_mst_csn_o(out_spi6_vrm_mst_csn_o),
    .out_spi6_vrm_mst_sck_o(out_spi6_vrm_mst_sck_o),
    .out_spi6_vrm_mst_si_o (out_spi6_vrm_mst_si_o),
    .out_spi6_vrm_mst_so_o (out_spi6_vrm_mst_so_o),

    .oe_spi6_vrm_mst_csn_o(oe_spi6_vrm_mst_csn_o),
    .oe_spi6_vrm_mst_sck_o(oe_spi6_vrm_mst_sck_o),
    .oe_spi6_vrm_mst_si_o (oe_spi6_vrm_mst_si_o),
    .oe_spi6_vrm_mst_so_o (oe_spi6_vrm_mst_so_o),

    //UART
    .in_uart1_rxd_i(in_uart1_rxd_i),
    .in_uart1_txd_i(in_uart1_txd_i),

    .out_uart1_rxd_o(out_uart1_rxd_o),
    .out_uart1_txd_o(out_uart1_txd_o),

    .oe_uart1_rxd_o(oe_uart1_rxd_o),
    .oe_uart1_txd_o(oe_uart1_txd_o),


    // Internally multiplexed interfaces

    //I2C
    .out_i2c5_intr_sckt_scl_o  (out_i2c5_intr_sckt_scl_o),
    .out_i2c5_intr_sckt_sda_o  (out_i2c5_intr_sckt_sda_o),
    .out_i2c5_intr_sckt_alert_o(out_i2c5_intr_sckt_alert_o),

    .oe_i2c5_intr_sckt_scl_o  (oe_i2c5_intr_sckt_scl_o),
    .oe_i2c5_intr_sckt_sda_o  (oe_i2c5_intr_sckt_sda_o),
    .oe_i2c5_intr_sckt_alert_o(oe_i2c5_intr_sckt_alert_o),

    .in_i2c5_intr_sckt_scl_i  (in_i2c5_intr_sckt_scl_i),
    .in_i2c5_intr_sckt_sda_i  (in_i2c5_intr_sckt_sda_i),
    .in_i2c5_intr_sckt_alert_i(in_i2c5_intr_sckt_alert_i),

    //SPI
    .in_spi5_intr_sckt_csn_i  (in_spi5_intr_sckt_csn_i),
    .in_spi5_intr_sckt_sck_i  (in_spi5_intr_sckt_sck_i),
    .in_spi5_intr_sckt_si_i   (in_spi5_intr_sckt_si_i),
    .in_spi5_intr_sckt_so_i   (in_spi5_intr_sckt_so_i),
    .in_spi5_intr_sckt_alert_i(in_spi5_intr_sckt_alert_i),

    .out_spi5_intr_sckt_csn_o  (out_spi5_intr_sckt_csn_o),
    .out_spi5_intr_sckt_sck_o  (out_spi5_intr_sckt_sck_o),
    .out_spi5_intr_sckt_si_o   (out_spi5_intr_sckt_si_o),
    .out_spi5_intr_sckt_so_o   (out_spi5_intr_sckt_so_o),
    .out_spi5_intr_sckt_alert_o(out_spi5_intr_sckt_alert_o),

    .oe_spi5_intr_sckt_csn_o  (oe_spi5_intr_sckt_csn_o),
    .oe_spi5_intr_sckt_sck_o  (oe_spi5_intr_sckt_sck_o),
    .oe_spi5_intr_sckt_si_o   (oe_spi5_intr_sckt_si_o),
    .oe_spi5_intr_sckt_so_o   (oe_spi5_intr_sckt_so_o),
    .oe_spi5_intr_sckt_alert_o(oe_spi5_intr_sckt_alert_o),

    // ACPI GPIOs signals
    .out_slp_s3_l_o       (s_out_slp_s3_l),
    .out_slp_s4_l_o       (s_out_slp_s4_l),
    .out_slp_s5_l_o       (s_out_slp_s5_l),
    .out_sys_reset_l_o    (s_out_sys_reset_l),
    .out_sys_rsmrst_l_o   (s_out_sys_rsmrst_l),
    .out_sys_pwr_btn_l_o  (s_out_sys_pwr_btn_l),
    .out_sys_pwrgd_in_o   (s_out_sys_pwrgd_in),
    .out_sys_wake_l_o     (s_out_sys_wake_l),
    .out_cpu_pwrgd_out_o  (s_out_cpu_pwrgd_out),
    .out_cpu_throttle_o   (s_out_cpu_throttle),
    .out_cpu_thermtrip_l_o(s_out_cpu_thermtrip_l),
    .out_cpu_errcode_o    (s_out_cpu_errcode),
    .out_cpu_reset_out_l_o(s_out_cpu_reset_out_l),
    .out_cpu_socket_id_o  (s_out_cpu_socket_id),
    .out_cpu_strap_o      (s_out_cpu_strap),

    .oe_slp_s3_l_o       (s_oe_slp_s3_l),
    .oe_slp_s4_l_o       (s_oe_slp_s4_l),
    .oe_slp_s5_l_o       (s_oe_slp_s5_l),
    .oe_sys_reset_l_o    (s_oe_sys_reset_l),
    .oe_sys_rsmrst_l_o   (s_oe_sys_rsmrst_l),
    .oe_sys_pwr_btn_l_o  (s_oe_sys_pwr_btn_l),
    .oe_sys_pwrgd_in_o   (s_oe_sys_pwrgd_in),
    .oe_sys_wake_l_o     (s_oe_sys_wake_l),
    .oe_cpu_pwrgd_out_o  (s_oe_cpu_pwrgd_out),
    .oe_cpu_throttle_o   (s_oe_cpu_throttle),
    .oe_cpu_thermtrip_l_o(s_oe_cpu_thermtrip_l),
    .oe_cpu_errcode_o    (s_oe_cpu_errcode),
    .oe_cpu_reset_out_l_o(s_oe_cpu_reset_out_l),
    .oe_cpu_socket_id_o  (s_oe_cpu_socket_id),
    .oe_cpu_strap_o      (s_oe_cpu_strap),

    .in_slp_s3_l_i       (s_in_slp_s3_l),
    .in_slp_s4_l_i       (s_in_slp_s4_l),
    .in_slp_s5_l_i       (s_in_slp_s5_l),
    .in_sys_reset_l_i    (s_in_sys_reset_l),
    .in_sys_rsmrst_l_i   (s_in_sys_rsmrst_l),
    .in_sys_pwr_btn_l_i  (s_in_sys_pwr_btn_l),
    .in_sys_pwrgd_in_i   (s_in_sys_pwrgd_in),
    .in_sys_wake_l_i     (s_in_sys_wake_l),
    .in_cpu_pwrgd_out_i  (s_in_cpu_pwrgd_out),
    .in_cpu_throttle_i   (s_in_cpu_throttle),
    .in_cpu_thermtrip_l_i(s_in_cpu_thermtrip_l),
    .in_cpu_errcode_i    (s_in_cpu_errcode),
    .in_cpu_reset_out_l_i(s_in_cpu_reset_out_l),
    .in_cpu_socket_id_i  (s_in_cpu_socket_id),
    .in_cpu_strap_i      (s_in_cpu_strap),

    // Bootmode selection, fetch_enable signals
    .bootsel_valid_i    (bootsel_valid),
    .bootsel_i          (bootsel),
    .fc_fetch_en_valid_i(fc_fetch_en_valid),
    .fc_fetch_en_i      (fc_fetch_en)
  );

  // Wrap flatten ports to ease use in TB

  //I2C
  `I2C_WRAP_STRUCT(i2c0_vrm_mst, i2c, 0);
  `I2C_WRAP_STRUCT(i2c1_vrm_mst, i2c, 1);
  `I2C_WRAP_STRUCT(i2c2_vrm_mst, i2c, 2);
  `I2C_WRAP_STRUCT(i2c3_vrm_mst, i2c, 3);
  `I2C_WRAP_STRUCT(i2c4_vrm_mst, i2c, 4);
  `I2C_WRAP_STRUCT(i2c5_intr_sckt, i2c, 5);  // to connect to the MUX
  `I2C_WRAP_STRUCT(i2c6_rtc_mst, i2c, 6);
  `I2C_WRAP_STRUCT(i2c8_os_mst, i2c, 7);
  `I2C_WRAP_STRUCT(i2c9_pcie_pnp_mst, i2c, 8);
  `I2C_WRAP_STRUCT(i2ca_bios_mst, i2c, 9);
  `I2C_WRAP_STRUCT(i2cb_bmc_mst, i2c, 10);
  `I2C_WRAP_STRUCT(i2cc_vrm_mst, i2c, 11);

  // I2C SLAVE
  `I2C_WRAP_STRUCT(i2c7_bmc_slv, i2c_slv, 0);

  //SPI
  `SPI_WRAP_STRUCT2(spi0_vrm_mst, qspi, 0);
  `SPI_WRAP_STRUCT2(spi1_vrm_mst, qspi, 1);
  `SPI_WRAP_STRUCT2(spi2_vrm_mst, qspi, 2);
  `SPI_WRAP_STRUCT1(spi3_vrm_mst, qspi, 3);
  `SPI_WRAP_STRUCT1(spi4_vrm_mst, qspi, 4);
  `SPI_WRAP_STRUCT1(spi5_intr_sckt, qspi, 5);
  `SPI_WRAP_STRUCT1(spi6_vrm_mst, qspi, 6);
  `QSPI_WRAP_STRUCT(qspi_flash_mst, qspi, 7);

  //UART
  assign in_uart1_rxd_i   = s_in_uart_rx[0];
  assign in_uart1_txd_i   = s_in_uart_tx[0];

  assign s_out_uart_rx[0] = out_uart1_rxd_o;
  assign s_out_uart_tx[0] = out_uart1_txd_o;

  assign s_oe_uart_rx[0]  = oe_uart1_rxd_o;
  assign s_oe_uart_tx[0]  = oe_uart1_txd_o;

  // AXI4 - D2D arbitration

  if (USE_D2D) begin : gen_d2d
    localparam int unsigned RegAddrWidth = 32;
    localparam int unsigned RegDataWidth = 32;
    localparam int unsigned RegStrbWidth = RegDataWidth / 8;

    // regbus types
    typedef logic [RegAddrWidth-1:0] cfg_addr_t;
    typedef logic [RegDataWidth-1:0] cfg_data_t;
    typedef logic [RegStrbWidth-1:0] cfg_strb_t;

    // regbus req/resp
    `REG_BUS_TYPEDEF_ALL(cfg, cfg_addr_t, cfg_data_t, cfg_strb_t)
    cfg_req_t cfg_req_tb;
    cfg_rsp_t cfg_resp_tb;

    // D2D link
    serial_link_wrapper #(
      .axi_req_t  (axi_req_inp_ext_t),
      .axi_rsp_t  (axi_resp_inp_ext_t),
      .aw_chan_t  (axi_aw_inp_ext_t),
      .ar_chan_t  (axi_ar_inp_ext_t),
      .r_chan_t   (axi_r_inp_ext_t),
      .w_chan_t   (axi_w_inp_ext_t),
      .b_chan_t   (axi_b_inp_ext_t),
      .cfg_req_t  (cfg_req_t),
      .cfg_rsp_t  (cfg_rsp_t),
      .NumChannels(D2D_NUM_CHANNELS),
      .NumLanes   (D2D_NUM_LANES),
      .NumCredits (D2D_NUM_CREDITS),
      .MaxClkDiv  (1024),
      .UseDelayLine (USE_D2D_DELAY_LINE)
    ) i_d2d_link_tb (
      .clk_i         (s_soc_clk),
      .rst_ni        (s_rst_n),
      .clk_sl_i      (s_soc_clk),
      .rst_sl_ni     (s_rst_n),
      .clk_reg_i     (s_soc_clk),
      .rst_reg_ni    (s_rst_n),
      .testmode_i    ('0),
      .axi_in_req_i  (from_ext_req),
      .axi_in_rsp_o  (from_ext_resp),
      .axi_out_req_o (to_ext_req),
      .axi_out_rsp_i (to_ext_resp),
      .cfg_req_i     ('0),
      .cfg_rsp_o     (),
      .ddr_rcv_clk_i (d2d_clk_out),
      .ddr_rcv_clk_o (d2d_clk_in),
      .ddr_i         (d2d_data_out),
      .ddr_o         (d2d_data_in),
      .isolated_i    ('0 ),
      .isolate_o     (   ),
      .clk_ena_o     (   ),
      .reset_no      (   )
    );
  end else begin : gen_no_d2d
    // Wrap exploded master to struct master
    `AXI_WRAP_MASTER_STRUCT(to_ext_req, to_ext_resp, mst);

    // Explode struct slave to exploded slave
    `AXI_EXPLODE_SLAVE_STRUCT(from_ext_req, from_ext_resp, slv);
  end

  // Configurable AXI delayer - delays AXI handshake on each AXI channel by a fixed amount of clock cycles

  localparam int unsigned FixedDelayInput = 0;
  localparam int unsigned FixedDelayOutput = 0;
  localparam int unsigned StallRandomInput = 0;
  localparam int unsigned StallRandomOutput = 0;

  // control-pulp to EXT direction
  axi_delayer #(
    .aw_chan_t        (axi_aw_oup_ext_t),
    .w_chan_t         (axi_w_oup_ext_t),
    .b_chan_t         (axi_b_oup_ext_t),
    .ar_chan_t        (axi_ar_oup_ext_t),
    .r_chan_t         (axi_r_oup_ext_t),
    .axi_req_t        (axi_req_oup_ext_t),
    .axi_resp_t       (axi_resp_oup_ext_t),
    .FixedDelayInput  (FixedDelayInput),
    .FixedDelayOutput (FixedDelayOutput),
    .StallRandomInput (StallRandomInput),
    .StallRandomOutput(StallRandomOutput)
  ) i_axi_delayer_ps2pl (
    .clk_i     (s_soc_clk),
    .rst_ni    (s_rst_n),
    .slv_req_i (to_ext_req),
    .slv_resp_o(to_ext_resp),
    .mst_req_o (from_mux_req[0]),
    .mst_resp_i(from_mux_resp[0])
  );


  // Test control_pulp master port (to_nci_cp_top) with a simulation memory
  axi_sim_mem #(
    .AddrWidth(AXI_ADDR_WIDTH_EXT),
    .DataWidth(AXI_DATA_OUP_WIDTH_EXT),
    .IdWidth  (AXI_ID_OUP_WIDTH_EXT + 1),
    .UserWidth(AXI_USER_WIDTH_EXT),
    .axi_req_t(axi_req_oup_mux_t),
    .axi_rsp_t(axi_resp_oup_mux_t),
    .ApplDelay(5000ps),
    .AcqDelay (10000ps)
  ) i_axi_sim_ext (
    .clk_i    (s_soc_clk),
    .rst_ni   (s_rst_n),
    .axi_req_i(to_sim_mem_req),
    .axi_rsp_o(to_sim_mem_resp)
  );

  // AXI mux to allow multiple external AXI drivers towards AXI simulation memory
  axi_mux #(
    .SlvAxiIDWidth(AXI_ID_OUP_WIDTH_EXT),
    .slv_aw_chan_t(axi_aw_oup_ext_t),
    .mst_aw_chan_t(axi_aw_oup_mux_t),
    .w_chan_t     (axi_w_oup_ext_t),
    .slv_b_chan_t (axi_b_oup_ext_t),
    .mst_b_chan_t (axi_b_oup_mux_t),
    .slv_ar_chan_t(axi_ar_oup_ext_t),
    .mst_ar_chan_t(axi_ar_oup_mux_t),
    .slv_r_chan_t (axi_r_oup_ext_t),
    .mst_r_chan_t (axi_r_oup_mux_t),
    .slv_req_t    (axi_req_oup_ext_t),
    .slv_resp_t   (axi_resp_oup_ext_t),
    .mst_req_t    (axi_req_oup_mux_t),
    .mst_resp_t   (axi_resp_oup_mux_t),
    .NoSlvPorts   (2),
    .MaxWTrans    (1),
    .FallThrough  (1'b1)
  ) i_axi_mux (
    .clk_i      (s_soc_clk),
    .rst_ni     (s_rst_n),
    .test_i     (1'b0),
    .slv_reqs_i (from_mux_req),
    .slv_resps_o(from_mux_resp),
    .mst_req_o  (to_sim_mem_req),
    .mst_resp_i (to_sim_mem_resp)
  );

  // Very basic doorbell modules, one for each interrupt line (external + clint)
  logic db_trigger_scg = 1'b0;
  logic db_trigger_scp = 1'b0;
  logic db_trigger_scp_secure = 1'b0;
  logic db_scg_irq;
  logic db_scp_irq;
  logic db_scp_secure_irq;
  logic [71:0] db_trigger_mbox = '0;
  logic [71:0] db_trigger_mbox_secure = '0;
  logic [71:0] db_mbox_irq;
  logic [71:0] db_mbox_secure_irq;
  // logic [31:0] db_trigger_clint;
  // logic [31:0] db_clint_irq;

  // Wrap trigger signals in one array
  logic [255:0] db_trigger = {
    {77{1'b0}},  // 77 (systemverilog has default:0 but that doesn't work reliably)
    db_trigger_mbox_secure,  // 72
    db_trigger_mbox,  // 72
    db_trigger_scp_secure,  // 1
    db_trigger_scp,  // 1
    db_trigger_scg  // 1
  };

  // Assign firing interrupt from doorbells to pms_top
  assign scg_irq         = db_scg_irq;
  assign scp_irq         = db_scp_irq;
  assign scp_secure_irq  = db_scp_secure_irq;
  assign mbox_irq        = db_mbox_irq;
  assign mbox_secure_irq = db_mbox_secure_irq;

  doorbell i_doorbell_scg (
    .clk_i       (s_clk_ref),
    .rst_ni      (s_rst_n),
    .db_trigger_i(db_trigger[0]),
    .irq_o       (db_scg_irq)
  );

  doorbell i_doorbell_scp (
    .clk_i       (s_clk_ref),
    .rst_ni      (s_rst_n),
    .db_trigger_i(db_trigger[1]),
    .irq_o       (db_scp_irq)
  );

  doorbell i_doorbell_scp_sec (
    .clk_i       (s_clk_ref),
    .rst_ni      (s_rst_n),
    .db_trigger_i(db_trigger[2]),
    .irq_o       (db_scp_secure_irq)
  );

  for (genvar i = 0; i < 72; i++) begin : doorbell_mbox_irq
    doorbell i_doorbell_mbox (
      .clk_i       (s_clk_ref),
      .rst_ni      (s_rst_n),
      .db_trigger_i(db_trigger[i+3]),
      .irq_o       (db_mbox_irq[i])
    );

    doorbell i_doorbell_mbox_sec (
      .clk_i       (s_clk_ref),
      .rst_ni      (s_rst_n),
      .db_trigger_i(db_trigger[i+75]),
      .irq_o       (db_mbox_secure_irq[i])
    );
  end


  //
  // Clock
  //

  tb_clk_gen #(
    .CLK_PERIOD(REF_CLK_PERIOD)
  ) i_ref_clk_gen (
    .clk_o(s_clk_ref)
  );

  //
  // AXI W/R: driver tasks
  //

  `define wait_for(signal) \
  do \
    @(posedge s_soc_clk); \
  while (!signal);

  task ext_write_mem(input control_pulp_pkg::axi_addr_ext_t addr,
                     input control_pulp_pkg::axi_data_oup_ext_t data, output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "ext_write_mem: unaligned 64-bit access");
    from_mux_req[1].aw.id     = '0;
    from_mux_req[1].aw.addr   = addr;
    from_mux_req[1].aw.len    = '0;
    from_mux_req[1].aw.size   = $clog2(control_pulp_pkg::AXI_STRB_OUP_WIDTH_PMS);
    from_mux_req[1].aw.burst  = axi_pkg::BURST_INCR;
    from_mux_req[1].aw.lock   = 1'b0;
    from_mux_req[1].aw.cache  = '0;
    from_mux_req[1].aw.prot   = '0;
    from_mux_req[1].aw.qos    = '0;
    from_mux_req[1].aw.region = '0;
    from_mux_req[1].aw.atop   = '0;
    from_mux_req[1].aw.user   = '0;
    from_mux_req[1].aw_valid  = 1'b1;
    `wait_for(from_mux_resp[1].aw_ready)
    from_mux_req[1].aw_valid = 1'b0;
    from_mux_req[1].w.data   = data;
    from_mux_req[1].w.strb   = '1;
    from_mux_req[1].w.last   = 1'b1;
    from_mux_req[1].w.user   = '0;
    from_mux_req[1].w_valid  = 1'b1;
    `wait_for(from_mux_resp[1].w_ready)
    from_mux_req[1].w_valid = 1'b0;
    from_mux_req[1].b_ready = 1'b1;
    `wait_for(from_mux_resp[1].b_valid)
    resp                    = from_mux_resp[1].b.resp;
    from_mux_req[1].b_ready = 1'b0;
  endtask

  task ext_write_mem32(input control_pulp_pkg::axi_addr_ext_t addr,
                     input logic [31:0] data, output axi_pkg::resp_t resp);
    from_mux_req[1].aw.id     = '0;
    from_mux_req[1].aw.addr   = addr;
    from_mux_req[1].aw.len    = '0;
    from_mux_req[1].aw.size   = $clog2(control_pulp_pkg::AXI_STRB_OUP_WIDTH_PMS);
    from_mux_req[1].aw.burst  = axi_pkg::BURST_INCR;
    from_mux_req[1].aw.lock   = 1'b0;
    from_mux_req[1].aw.cache  = '0;
    from_mux_req[1].aw.prot   = '0;
    from_mux_req[1].aw.qos    = '0;
    from_mux_req[1].aw.region = '0;
    from_mux_req[1].aw.atop   = '0;
    from_mux_req[1].aw.user   = '0;
    from_mux_req[1].aw_valid  = 1'b1;
    `wait_for(from_mux_resp[1].aw_ready)
    from_mux_req[1].aw_valid = 1'b0;
    from_mux_req[1].w.data   = (addr[2]) ? {data, 32'h0} : {32'h0, data};
    from_mux_req[1].w.strb   = (addr[2]) ? 8'hf0 : 8'h0f;
    from_mux_req[1].w.last   = 1'b1;
    from_mux_req[1].w.user   = '0;
    from_mux_req[1].w_valid  = 1'b1;
    `wait_for(from_mux_resp[1].w_ready)
    from_mux_req[1].w_valid = 1'b0;
    from_mux_req[1].b_ready = 1'b1;
    `wait_for(from_mux_resp[1].b_valid)
    resp                    = from_mux_resp[1].b.resp;
    from_mux_req[1].b_ready = 1'b0;
  endtask

  task write_to_pulp(input axi_addr_ext_t addr, input axi_data_inp_ext_t data,
                     output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "write_to_pulp: unaligned 64-bit access");
    from_ext_req.aw.id     = '0;
    from_ext_req.aw.addr   = addr;
    from_ext_req.aw.len    = '0;
    from_ext_req.aw.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ext_req.aw.lock   = 1'b0;
    from_ext_req.aw.cache  = '0;
    from_ext_req.aw.prot   = '0;
    from_ext_req.aw.qos    = '0;
    from_ext_req.aw.region = '0;
    from_ext_req.aw.atop   = '0;
    from_ext_req.aw.user   = '0;
    from_ext_req.aw_valid  = 1'b1;
    `wait_for(from_ext_resp.aw_ready)
    from_ext_req.aw_valid = 1'b0;
    from_ext_req.w.data   = data;
    from_ext_req.w.strb   = '1;
    from_ext_req.w.last   = 1'b1;
    from_ext_req.w.user   = '0;
    from_ext_req.w_valid  = 1'b1;
    `wait_for(from_ext_resp.w_ready)
    from_ext_req.w_valid = 1'b0;
    from_ext_req.b_ready = 1'b1;
    `wait_for(from_ext_resp.b_valid)
    resp                 = from_ext_resp.b.resp;
    from_ext_req.b_ready = 1'b0;
  endtask  // write_to_pulp

  task write_to_pulp32(input axi_addr_ext_t addr, input logic [31:0] data,
                       output axi_pkg::resp_t resp);
    from_ext_req.aw.id     = '0;
    from_ext_req.aw.addr   = addr;
    from_ext_req.aw.len    = '0;
    from_ext_req.aw.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ext_req.aw.lock   = 1'b0;
    from_ext_req.aw.cache  = '0;
    from_ext_req.aw.prot   = '0;
    from_ext_req.aw.qos    = '0;
    from_ext_req.aw.region = '0;
    from_ext_req.aw.atop   = '0;
    from_ext_req.aw.user   = '0;
    from_ext_req.aw_valid  = 1'b1;
    `wait_for(from_ext_resp.aw_ready)
    from_ext_req.aw_valid = 1'b0;
    from_ext_req.w.data   = (addr[2]) ? {data, 32'h0} : {32'h0, data};
    from_ext_req.w.strb   = (addr[2]) ? 8'hf0 : 8'h0f;
    from_ext_req.w.last   = 1'b1;
    from_ext_req.w.user   = '0;
    from_ext_req.w_valid  = 1'b1;
    `wait_for(from_ext_resp.w_ready)
    from_ext_req.w_valid = 1'b0;
    from_ext_req.b_ready = 1'b1;
    `wait_for(from_ext_resp.b_valid)
    resp                 = from_ext_resp.b.resp;
    from_ext_req.b_ready = 1'b0;
  endtask  // write_to_pulp32

  task ext_read_mem(input control_pulp_pkg::axi_addr_ext_t addr,
                    output control_pulp_pkg::axi_data_oup_ext_t data, output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "ext_read_mem: unaligned 64-bit access");
    from_mux_req[1].ar.id     = '0;
    from_mux_req[1].ar.addr   = addr;
    from_mux_req[1].ar.len    = '0;
    from_mux_req[1].ar.size   = $clog2(control_pulp_pkg::AXI_STRB_OUP_WIDTH_PMS);
    from_mux_req[1].ar.burst  = axi_pkg::BURST_INCR;
    from_mux_req[1].ar.lock   = 1'b0;
    from_mux_req[1].ar.cache  = '0;
    from_mux_req[1].ar.prot   = '0;
    from_mux_req[1].ar.qos    = '0;
    from_mux_req[1].ar.region = '0;
    from_mux_req[1].ar.user   = '0;
    from_mux_req[1].ar_valid  = 1'b1;
    `wait_for(from_mux_resp[1].ar_ready)
    from_mux_req[1].ar_valid = 1'b0;
    from_mux_req[1].r_ready  = 1'b1;
    `wait_for(from_mux_resp[1].r_valid)
    data                    = from_mux_resp[1].r.data;
    resp                    = from_mux_resp[1].r.resp;
    from_mux_req[1].r_ready = 1'b0;
  endtask  // ext_read_mem

  task ext_read_mem32(input control_pulp_pkg::axi_addr_ext_t addr,
                    output logic [31:0] data, output axi_pkg::resp_t resp);
    from_mux_req[1].ar.id     = '0;
    from_mux_req[1].ar.addr   = addr;
    from_mux_req[1].ar.len    = '0;
    from_mux_req[1].ar.size   = $clog2($bits(data)/8);
    from_mux_req[1].ar.burst  = axi_pkg::BURST_INCR;
    from_mux_req[1].ar.lock   = 1'b0;
    from_mux_req[1].ar.cache  = '0;
    from_mux_req[1].ar.prot   = '0;
    from_mux_req[1].ar.qos    = '0;
    from_mux_req[1].ar.region = '0;
    from_mux_req[1].ar.user   = '0;
    from_mux_req[1].ar_valid  = 1'b1;
    `wait_for(from_mux_resp[1].ar_ready)
    from_mux_req[1].ar_valid = 1'b0;
    from_mux_req[1].r_ready  = 1'b1;
    `wait_for(from_mux_resp[1].r_valid)
    data                    = from_mux_resp[1].r.data;
    resp                    = from_mux_resp[1].r.resp;
    from_mux_req[1].r_ready = 1'b0;
  endtask  // ext_read_mem

  task read_from_pulp(input axi_addr_ext_t addr, output axi_data_inp_ext_t data,
                      output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "read_from_pulp: unaligned 64-bit access");
    from_ext_req.ar.id     = '0;
    from_ext_req.ar.addr   = addr;
    from_ext_req.ar.len    = '0;
    from_ext_req.ar.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ext_req.ar.lock   = 1'b0;
    from_ext_req.ar.cache  = '0;
    from_ext_req.ar.prot   = '0;
    from_ext_req.ar.qos    = '0;
    from_ext_req.ar.region = '0;
    from_ext_req.ar.user   = '0;
    from_ext_req.ar_valid  = 1'b1;
    `wait_for(from_ext_resp.ar_ready)
    from_ext_req.ar_valid = 1'b0;
    from_ext_req.r_ready  = 1'b1;
    `wait_for(from_ext_resp.r_valid)
    data                 = from_ext_resp.r.data;
    resp                 = from_ext_resp.r.resp;
    from_ext_req.r_ready = 1'b0;
  endtask  // read_from_pulp

  task read_from_pulp32(input axi_addr_ext_t addr, output logic [31:0] data,
                        output axi_pkg::resp_t resp);
    from_ext_req.ar.id     = '0;
    from_ext_req.ar.addr   = addr;
    from_ext_req.ar.len    = '0;
    from_ext_req.ar.size   = $clog2($bits(data)/8);
    from_ext_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ext_req.ar.lock   = 1'b0;
    from_ext_req.ar.cache  = '0;
    from_ext_req.ar.prot   = '0;
    from_ext_req.ar.qos    = '0;
    from_ext_req.ar.region = '0;
    from_ext_req.ar.user   = '0;
    from_ext_req.ar_valid  = 1'b1;
    `wait_for(from_ext_resp.ar_ready)
    from_ext_req.ar_valid = 1'b0;
    from_ext_req.r_ready  = 1'b1;
    `wait_for(from_ext_resp.r_valid)
    data                 = from_ext_resp.r.data;
    resp                 = from_ext_resp.r.resp;
    from_ext_req.r_ready = 1'b0;
  endtask  // read_from_pulp32

  task axi_assert(input string error_msg, input axi_pkg::resp_t resp, output int exit_status);
    assert (resp == axi_pkg::RESP_OKAY)
    else begin
      $error(error_msg);
      exit_status = EXIT_FAIL;
    end
  endtask  // axi_assert


  //
  // AXI Boot: driver tasks
  //

  // Init AXI driver
  task init_axi_driver;
    from_ext_req     = '{default: '0};
    from_mux_req[1]  = '{default: '0};
  endtask  // init_axi_driver

  // Read entry point from commandline
  task read_entry_point(output logic [31:0] begin_l2_instr);
    int entry_point;
    if ($value$plusargs("ENTRY_POINT=%h", entry_point)) begin_l2_instr = entry_point;
    else begin_l2_instr = 32'h1C000880;
    $display("[TB  ] %t - Entry point is set to 0x%h", $realtime, begin_l2_instr);
  endtask  // read_entry_point

  // Apply reset
  task apply_rstn;
    $display("[TB  ] %t - Asserting hard reset and jtag reset", $realtime);
    s_rst_n = 1'b0;
    #1us
      // Release reset
      $display(
        "[TB  ] %t - Releasing hard reset and jtag reset", $realtime);
    s_rst_n = 1'b1;
  endtask  // apply_rstn

  // Select bootmode
  task axi_select_bootmode(input logic [31:0] bootmode);
    automatic axi_pkg::resp_t resp;
    automatic axi_data_inp_ext_t data;

    $display("[TB  ] %t - Write bootmode to bootsel register", $realtime);
    write_to_pulp32(SOC_CTRL_BOOTSEL_ADDR, bootmode, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB  ] %t - Read bootmode from bootsel register", $realtime);
    read_from_pulp32(SOC_CTRL_BOOTSEL_ADDR, data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // axi_select_bootmode

  task axi_load_binary;
    automatic axi_pkg::resp_t resp;
    automatic string stim_path, srec_path;

    automatic axi_addr_ext_t axi_addr32;
    automatic axi_data_inp_ext_t data, axi_data64;
    automatic logic [95:0] stimuli[$];

    automatic srec_record_t records[$];
    automatic logic [31:0] entrypoint;

    $display("[TB  ] %t - Load binary into L2 via AXI slave port", $realtime);

    // Check if stimuli exist
    if ($value$plusargs("stimuli=%s", stim_path)) begin
      $display("[TB  ] %t - Loading custom stimuli from %s", $realtime, stim_path);
      load_stim(stim_path, stimuli);
    end else if ($value$plusargs("srec=%s", srec_path)) begin
      $display("[TB  ] %t - Loading srec from %s", $realtime, srec_path);
      srec_read(srec_path, records);
      srec_records_to_stimuli(records, stimuli, entrypoint);
      if (!$test$plusargs("srec_ignore_entry"))
        axi_write_entry_point(entrypoint);
    end else begin
      $display("[TB  ] %t - Loading default stimuli from ./vectors/stim.txt", $realtime);
      load_stim("./vectors/stim.txt", stimuli);
    end

    // Load binary
    for (int num_stim = 0; num_stim < stimuli.size; num_stim++) begin
      // @(posedge s_soc_clk); TODO: check if this is really useful
      axi_addr32 = stimuli[num_stim][95:64]; // assign 32 bit address
      axi_data64 = stimuli[num_stim][63:0];  // assign 64 bit data

      if (num_stim % 128 == 0)
        $display("[TB  ] %t - Write burst @%h for 1024 bytes", $realtime, axi_addr32);

      write_to_pulp(axi_addr32, axi_data64, resp);
      axi_assert("write", resp, exit_status);

      read_from_pulp(axi_addr32, data, resp);
      axi_assert("read", resp, exit_status);
    end  // while (!$feof(stim_fd))
  endtask  // axi_load_binary

  task axi_write_entry_point(input logic [31:0] begin_l2_instr);
    automatic axi_pkg::resp_t resp;
    automatic axi_data_inp_ext_t data;

    $display("[TB  ] %t - Write entry point into boot address register (reset vector): 0x%h @ %s",
             $realtime, begin_l2_instr, "32'h1A104004");
    write_to_pulp32(SOC_CTRL_BOOT_ADDR, begin_l2_instr, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB  ] %t - Read entry point into boot address register (reset vector): 0x%h @ %s",
             $realtime, begin_l2_instr, "32'h1A104004");
    read_from_pulp32(SOC_CTRL_BOOT_ADDR, data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // axi_write_entry_point

  task axi_write_fetch_enable();
    automatic axi_pkg::resp_t resp;
    automatic axi_data_inp_ext_t data;

    $display("[TB  ] %t - Write 1 to fetch enable register", $realtime);
    write_to_pulp32(SOC_CTRL_FETCH_EN_ADDR, 32'h0000_0001, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB  ] %t - Read 1 from fetch enable register", $realtime);
    read_from_pulp32(SOC_CTRL_FETCH_EN_ADDR, data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // axi_write_fetch_enable

  task axi_wait_for_eoc(output int exit_status);
    automatic axi_pkg::resp_t resp;
    automatic logic [31:0] rdata;

    // wait for end of computation signal
    $display("[TB  ] %t - Waiting for end of computation", $realtime);

    rdata = 0;
    while (rdata[31] == 0) begin
      read_from_pulp32(SOC_CTRL_CORE_STATUS_ADDR, rdata, resp);
      axi_assert("read", resp, exit_status);
      #50us;
    end

    if (rdata[30:0] == 0) exit_status = EXIT_SUCCESS;
    else exit_status = EXIT_FAIL;
    $display("[TB  ] %t - Exit status: %d, Received status core: 0x%h", $realtime, exit_status,
             rdata[30:0]);
  endtask  // axi_wait_for_eoc

  task enable_uart_rx;
    uart_tb_rx_en = 1'b1;
  endtask  // enable_uart_rx


  //
  // JTAG for riscv-dbg tap and pulp tap
  //

  jtag_pkg::test_mode_if_t test_mode_if = new;
  jtag_pkg::debug_mode_if_t debug_mode_if = new;
  pulp_tap_pkg::pulp_tap_if_soc_t pulp_tap = new;

  task jtag_reset();
    jtag_pkg::jtag_reset(s_tck, s_tms, s_trstn, s_tdi);
    jtag_pkg::jtag_softreset(s_tck, s_tms, s_trstn, s_tdi);
    #5us;
  endtask // jtag_reset

  task jtag_smoke_tests(input logic [31:0] scratch_mem);
    automatic logic [255:0][31:0] jtag_data;

    jtag_pkg::jtag_bypass_test(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    #5us;

    jtag_pkg::jtag_get_idcode(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    #5us;

    //test if the PULP tap che write to the L2
    pulp_tap.init(s_tck, s_tms, s_trstn, s_tdi);

    $display("[TB  ] %t - Init PULP TAP", $realtime);

    pulp_tap.write32(scratch_mem, 1, 32'hABBAABBA, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    $display("[TB  ] %t - Write32 PULP TAP", $realtime);

    #50us;
    pulp_tap.read32(scratch_mem, 1, jtag_data, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    if (jtag_data[0] != 32'hABBAABBA)
      $display("[JTAG] %t - R/W test of L2 failed: %h != %h", $realtime, jtag_data[0], 32'hABBAABBA);
    else $display("[JTAG] %t - R/W test of L2 succeeded", $realtime);
  endtask // jtag_selftests

  task jtag_load_binary(input logic [31:0] entrypoint);
    automatic string stim_path, srec_path;
    automatic logic [95:0] stimuli[$];

    automatic string jtag_boot_conf;
    automatic string jtag_tap_type;
    automatic logic [255:0][31:0] jtag_data;

    automatic srec_record_t records[$];
    automatic logic [31:0] srec_entrypoint;

    // Check if stimuli exist
    if ($value$plusargs("stimuli=%s", stim_path)) begin
      $display("[TB  ] %t - Loading custom stimuli from %s", $realtime, stim_path);
      load_stim(stim_path, stimuli);
    end else if ($value$plusargs("srec=%s", srec_path)) begin
      $display("[TB  ] %t - Loading srec from %s", $realtime, srec_path);
      srec_read(srec_path, records);
      srec_records_to_stimuli(records, stimuli, srec_entrypoint);
      if (!$test$plusargs("srec_ignore_entry"))
        entrypoint = srec_entrypoint;
    end else begin
      $display("[TB  ] %t - Loading default stimuli from ./vectors/stim.txt", $realtime);
      load_stim("./vectors/stim.txt", stimuli);
    end

    // From here on starts the actual jtag booting

    // We need our core the fetching and running from the bootrom. We can do
    // that by either driving the bootsel and fetch_enable signals or by using
    // the pulp/riscv tap to write to the corresponding memory mapped registers.
    if (!$value$plusargs("jtag_boot_conf=%s", jtag_boot_conf))
      jtag_boot_conf = "mm"; // default memory mapped

    if (jtag_boot_conf == "mm") begin
      $display("[TB  ] %t - Configuration boot through memory mapped registers", $realtime);
      $display("[TB  ] %t - Write 1 (jtag) to bootsel register", $realtime);
      pulp_tap.write32(SOC_CTRL_BOOTSEL_ADDR, 1, 32'h0000_0001, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

      $display("[TB  ] %t - Write 1 to fetch enable register", $realtime);
      pulp_tap.write32(SOC_CTRL_FETCH_EN_ADDR, 1, 32'h0000_0001, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    end else if (jtag_boot_conf == "pads") begin
      $display("[TB  ] %t - Configuration boot through pads", $realtime);
      bootsel_valid      = 1'b1;
      bootsel            = 2'b1; // jtag mode
      fc_fetch_en_valid  = 1'b1;
      fc_fetch_en        = 1'b1;
    end else begin
      $fatal(1, "Unknown boot configuration +jtag_boot_conf=%s", jtag_boot_conf);
    end

    // Setup debug module and hart, halt hart and set dpc (return point
    // for boot).
    // Halting the fc hart transfers control of the program execution to
    // the debug module. This might take a bit until the debug request
    // signal is propagated so meanwhile the core is executing stuff
    // from the bootrom. For jtag booting (what we are doing right now),
    // bootsel is low so the code that is being executed in said bootrom
    // is only a busy wait or wfi until the debug unit grabs control.
    debug_mode_if.init_dmi_access(s_tck, s_tms, s_trstn, s_tdi);

    debug_mode_if.set_dmactive(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    debug_mode_if.set_hartsel(FC_CORE_ID, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    $display("[TB  ] %t - Halting the Core", $realtime);
    debug_mode_if.halt_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    $display("[TB  ] %t - Writing the boot address into dpc", $realtime);
    debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC, entrypoint, s_tck, s_tms, s_trstn,
                                         s_tdi, s_tdo);

    $display("[TB  ] %t - Loading L2", $realtime);
    if (!$value$plusargs("jtag_load_tap=%s", jtag_tap_type))
      jtag_tap_type = "pulp"; // default

    if (jtag_tap_type == "riscv") begin
      // use debug module to load binary
      debug_mode_if.load_L2(num_stim, stimuli, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    end else if (jtag_tap_type == "pulp") begin
      // use pulp tap to load binary, put debug module in bypass
      pulp_tap_pkg::load_L2(num_stim, stimuli, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    end else begin
      $fatal(1, "Unknown tap type +jtag_load_tap=%s", jtag_tap_type);
    end

    //write bootaddress
    #50us;
    $display("[TB  ] %t - Write boot address into reset vector: 0x%h @ 0x%h",
             $realtime, entrypoint, SOC_CTRL_BOOT_ADDR);
    pulp_tap.write32(SOC_CTRL_BOOT_ADDR, 1, entrypoint, s_tck, s_tms, s_trstn,
      s_tdi, s_tdo);
    #50us;

  endtask // jtag_load_binary

  // if we were debugging we have to hand back to control to the hart to resume
  // execution
  task jtag_resume_hart();
    // configure for debug module dmi access again
    debug_mode_if.init_dmi_access(s_tck, s_tms, s_trstn, s_tdi);

    // we have set dpc and loaded the binary, we can go now
    $display("[TB  ] %t - Resuming the CORE", $realtime);
    debug_mode_if.resume_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
  endtask // jtag_resume_hart

  task jtag_wait_for_eoc(output int exit_status);
    automatic logic [255:0][31:0] jtag_data;
    automatic int read_count;

    // enable sb access for subsequent readMem calls
    debug_mode_if.set_sbreadonaddr(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    // wait for end of computation signal
    $display("[TB  ] %t - Waiting for end of computation", $realtime);

    jtag_data[0] = 0;
    while (jtag_data[0][31] == 0) begin
      // every 10th loop iteration, clear the debug module's SBA unit CSR to make
      // sure there's no error blocking our reads. Sometimes a TCDM read
      // request issued by the debug module takes longer than it takes
      // for the read request to the debug module to arrive and it
      // stores an error in the SBCS register. By clearing it
      // periodically we make sure the test can terminate.
      // This is obviously a bit hacky
      if (read_count % 10 == 0) begin
        debug_mode_if.clear_sbcserrors(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
      end
      debug_mode_if.readMem(SOC_CTRL_CORE_STATUS_ADDR, jtag_data[0], s_tck, s_tms,
                            s_trstn, s_tdi, s_tdo);
      read_count++;
      #50us;
    end

    if (jtag_data[0][30:0] == 0) exit_status = EXIT_SUCCESS;
    else exit_status = EXIT_FAIL;
    $display("[TB  ] %t - Exit status: %d, Received status core: 0x%h", $realtime, exit_status, jtag_data[0][30:0]);
  endtask // jtag_wait_for_eoc

  task jtag_dm_tests(input logic [31:0] entrypoint);
    automatic string jtag_boot_conf;
    automatic logic error;
    automatic int num_err;

    error   = 1'b0;
    num_err = 0;

    // We need our core the fetching and running from the bootrom. We can do
    // that by either driving the bootsel and fetch_enable signals or by using
    // the pulp/riscv tap to write to the corresponding memory mapped registers.
    if (!$value$plusargs("jtag_boot_conf=%s", jtag_boot_conf))
      jtag_boot_conf = "mm"; // default memory mapped

    if (jtag_boot_conf == "mm") begin
      $display("[TB  ] %t - Configuration boot through memory mapped registers", $realtime);
      $display("[TB  ] %t - Write 1 (jtag) to bootsel register", $realtime);
      pulp_tap.write32(SOC_CTRL_BOOTSEL_ADDR, 1, 32'h0000_0001, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

      $display("[TB  ] %t - Write 1 to fetch enable register", $realtime);
      pulp_tap.write32(SOC_CTRL_FETCH_EN_ADDR, 1, 32'h0000_0001, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    end else if (jtag_boot_conf == "pads") begin
      $display("[TB  ] %t - Configuration boot through pads", $realtime);
      bootsel_valid      = 1'b1;
      bootsel            = 2'b1; // jtag mode
      fc_fetch_en_valid  = 1'b1;
      fc_fetch_en        = 1'b1;
    end else begin
      $fatal(1, "Unknown boot configuration +jtag_boot_conf=%s", jtag_boot_conf);
    end

    // Setup debug module and hart, halt hart and set dpc (return point
    // for boot).
    // Halting the fc hart transfers control of the program execution to
    // the debug module. This might take a bit until the debug request
    // signal is propagated so meanwhile the core is executing stuff
    // from the bootrom. For jtag booting (what we are doing right now),
    // bootsel is low so the code that is being executed in said bootrom
    // is only a busy wait or wfi until the debug unit grabs control.
    debug_mode_if.init_dmi_access(s_tck, s_tms, s_trstn, s_tdi);

    debug_mode_if.set_dmactive(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    debug_mode_if.set_hartsel(FC_CORE_ID, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    $display("[TB  ] %t - Halting the Core", $realtime);
    debug_mode_if.halt_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    $display("[TB  ] %t - Writing the boot address into dpc", $realtime);
    debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC, entrypoint, s_tck, s_tms, s_trstn,
                                         s_tdi, s_tdo);

    debug_mode_if.run_dm_tests(FC_CORE_ID, entrypoint, error, num_err, s_tck, s_tms,
                              s_trstn, s_tdi, s_tdo);
    // we don't have any program to load so we finish the testing
    if (num_err == 0) begin
      exit_status = EXIT_SUCCESS;
    end else begin
      exit_status = EXIT_FAIL;
      $error("Debug Module: %d tests failed", num_err);
    end

    $stop;
  endtask // jtag_dm_tests

  //
  // FW simulation loop tasks
  //

  // TODO: improve this task
  task fw_fill_sim_mem(output int exit_status, input int num_stim,
                       input control_pulp_pkg::axi_addr_ext_t addr,
                       input control_pulp_pkg::axi_data_oup_ext_t w_data);
    automatic axi_pkg::resp_t resp;
    automatic control_pulp_pkg::axi_data_oup_ext_t r_data;
    if (num_stim % 256 == 0) begin
      $display("[EPI ] %t - Write burst @%h for 1024 bytes, filled %d of %d KiB", $realtime, addr,
               (num_stim * 4) / 1024, (1000 * 4) / 1024);
    end

    ext_write_mem32(addr, w_data, resp);
    axi_assert("write", resp, exit_status);

    ext_read_mem32(addr, r_data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // fill_sim_mem


  //
  // ACPI: driver tasks
  //

  task acpi_power_on();
    $display("[TB  ] %t - Start POWER UP (S5 -> S0)", $realtime);
    $display("[TB  ] %t - Short pulse on PWR_BTN", $realtime);
    s_sys_pwr_btn = 1'b0;
    #1000us s_sys_pwr_btn = 1'b1;
  endtask  // acpi_power_on

  task acpi_forced_power_down();
    $display("[TB  ] %t - Start forced POWER DOWN (S0 -> S5)", $realtime);
    $display("[TB  ] %t - Long pulse on PWR_BTN", $realtime);
    s_sys_pwr_btn = 1'b0;
    #5000us s_sys_pwr_btn = 1'b1;
  endtask  // acpi_forced_power_down


  //
  // Load stim task
  //

  task load_stim(input string stim, output logic [95:0] stimuli[$]);
    int ret;
    logic [95:0] rdata;
    stim_fd = $fopen(stim, "r");

    if (stim_fd == 0)
      $fatal(1, "Could not open stimuli file!");

    while (!$feof(stim_fd)) begin
      ret = $fscanf(stim_fd, "%h\n", rdata);
      stimuli.push_back(rdata);
    end

    $fclose(stim_fd);
  endtask  // load_stim


  //
  // I2C slave: driver tasks
  //

  task i2c_slv_read_slv_address(input int stim_fd, output logic [7:0] addr_i2c_slv);
    automatic int ret_code;
    ret_code = $fscanf(stim_fd, "%h\n", addr_i2c_slv);
    $display("[I2CS] %t - I2C Slave Address: %h", $realtime, addr_i2c_slv[7:1]);
  endtask  // i2c_slv_read_slv_address

  task i2c_slv_start;
    i2c_pkg::i2c_start(sdaOm, sclOm);
  endtask  // i2c_slv_start

  task i2c_slv_write_byte(input logic [7:0] data);
    i2c_pkg::i2c_write_byte(data, sdaOm, sclOm);
  endtask  // i2c_slv_write_byte

  task i2c_slv_read_ack(output int exit_status);
    automatic logic ack;
    i2c_pkg::i2c_read_ack(ack, sdaIm, sclIm, sdaOm, sclOm);
    assert (ack === 1'b1)
    else begin
      $error("[I2CS] %t - i2c nack received", $realtime);
      exit_status = EXIT_FAIL;
    end
  endtask  // i2c_slv_read_ack

  task i2c_slv_send_data_stream(input int stim_fd, output int exit_status);
    automatic int ret_code;
    automatic logic ack;
    automatic logic [7:0] data;

    while (!$feof(stim_fd)) begin
      ret_code = $fscanf(stim_fd, "%h\n", data);
      $display("[I2CS] %t - Write byte %h", $realtime, data);
      i2c_slv_write_byte(data);
      i2c_slv_read_ack(exit_status);
    end  // while (!$feof(stim_fd))
  endtask  // i2c_slv_send_data_stream

  task i2c_slv_stop;
    i2c_pkg::i2c_stop(sdaOm, sclOm);
  endtask  // i2c_slv_stop


  //
  // Interrupts control: driver tasks
  //

  task db_trigger_irq(input logic [255:0] mask);
    db_trigger &= '0;  // make sure the irq array is zero
    db_trigger |= mask;
  endtask  // ext_irq_trigger

endmodule

//-----------------------------------------------------------------------------
// Title         : Example module to instantiate pad frame in Control PULP
//-----------------------------------------------------------------------------
// File          : example_pad_frame_inst.sv
//-----------------------------------------------------------------------------
// Description :
// Auto-generated example module that instantiates the pad frame for FPGA
// emulation environment
//-----------------------------------------------------------------------------
// Copyright (C) 2013-2021 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//-----------------------------------------------------------------------------

module example_module #(
  // INPUT PARAMETERS
) (
  // INPUTS AND OUTPUTS SIGNALS/PADS
);

  // Inout signals are split into input, output and enables

  // ENABLE SIGNALS TO THE PADS
  logic            s_oe_i2c0_vrm_mst_sda;
  logic            s_oe_i2c0_vrm_mst_scl;
  logic            s_oe_i2c0_vrm_mst_alert;
  logic            s_oe_i2c1_vrm_mst_sda;
  logic            s_oe_i2c1_vrm_mst_scl;
  logic            s_oe_i2c1_vrm_mst_alert;
  logic            s_oe_i2c2_vrm_mst_sda;
  logic            s_oe_i2c2_vrm_mst_scl;
  logic            s_oe_i2c2_vrm_mst_alert;
  logic            s_oe_i2c3_vrm_mst_sda;
  logic            s_oe_i2c3_vrm_mst_scl;
  logic            s_oe_i2c3_vrm_mst_alert;
  logic            s_oe_i2cc_vrm_mst_sda;
  logic            s_oe_i2cc_vrm_mst_scl;
  logic            s_oe_i2cc_vrm_mst_alert;
  logic            s_oe_i2c6_rtc_mst_sda;
  logic            s_oe_i2c6_rtc_mst_scl;
  logic            s_oe_i2c6_rtc_mst_alert;
  logic            s_oe_i2c8_os_mst_sda;
  logic            s_oe_i2c8_os_mst_scl;
  logic            s_oe_i2c8_os_mst_alert;
  logic            s_oe_i2c9_pcie_pnp_mst_sda;
  logic            s_oe_i2c9_pcie_pnp_mst_scl;
  logic            s_oe_i2c9_pcie_pnp_mst_alert;
  logic            s_oe_i2ca_bios_mst_sda;
  logic            s_oe_i2ca_bios_mst_scl;
  logic            s_oe_i2ca_bios_mst_alert;
  logic            s_oe_i2c7_bmc_slv_sda;
  logic            s_oe_i2c7_bmc_slv_scl;
  logic            s_oe_i2c5_intr_sckt_sda;
  logic            s_oe_i2c5_intr_sckt_scl;
  logic            s_oe_i2c5_intr_sckt_alert;
  logic            s_oe_spi0_vrm_mst_sck;
  logic            s_oe_spi0_vrm_mst_si;
  logic            s_oe_spi0_vrm_mst_so;
  logic            s_oe_spi1_vrm_mst_sck;
  logic            s_oe_spi1_vrm_mst_si;
  logic            s_oe_spi1_vrm_mst_so;
  logic            s_oe_spi2_vrm_mst_sck;
  logic            s_oe_spi2_vrm_mst_si;
  logic            s_oe_spi2_vrm_mst_so;
  logic            s_oe_spi3_vrm_mst_sck;
  logic            s_oe_spi3_vrm_mst_si;
  logic            s_oe_spi3_vrm_mst_so;
  logic            s_oe_qspi_flash_mst_csn0;
  logic            s_oe_qspi_flash_mst_sck;
  logic [3:0]      s_oe_qspi_flash_mst_sdio;
  logic            s_oe_spi5_intr_sckt_csn;
  logic            s_oe_spi5_intr_sckt_sck;
  logic            s_oe_spi5_intr_sckt_so;
  logic            s_oe_spi5_intr_sckt_si;
  logic            s_oe_uart1_rxd;
  logic            s_oe_uart1_txd;
  logic            s_oe_slp_s3_l;
  logic            s_oe_slp_s4_l;
  logic            s_oe_slp_s5_l;
  logic            s_oe_sys_reset_l;
  logic            s_oe_sys_rsmrst_l;
  logic            s_oe_sys_pwrgd_in;
  logic            s_oe_sys_pwr_btn_l;
  logic            s_oe_cpu_pwrgd_out;
  logic [1:0]      s_oe_cpu_throttle;
  logic            s_oe_cpu_thermtrip_l;
  logic [3:0]      s_oe_cpu_errcode;
  logic            s_oe_cpu_reset_out_l;
  logic [1:0]      s_oe_cpu_socket_id;
  logic [3:0]      s_oe_cpu_strap;

  // INPUTS SIGNALS TO THE PADS
  logic            s_in_i2c0_vrm_mst_sda;
  logic            s_in_i2c0_vrm_mst_scl;
  logic            s_in_i2c0_vrm_mst_alert;
  logic            s_in_i2c1_vrm_mst_sda;
  logic            s_in_i2c1_vrm_mst_scl;
  logic            s_in_i2c1_vrm_mst_alert;
  logic            s_in_i2c2_vrm_mst_sda;
  logic            s_in_i2c2_vrm_mst_scl;
  logic            s_in_i2c2_vrm_mst_alert;
  logic            s_in_i2c3_vrm_mst_sda;
  logic            s_in_i2c3_vrm_mst_scl;
  logic            s_in_i2c3_vrm_mst_alert;
  logic            s_in_i2cc_vrm_mst_sda;
  logic            s_in_i2cc_vrm_mst_scl;
  logic            s_in_i2cc_vrm_mst_alert;
  logic            s_in_i2c6_rtc_mst_sda;
  logic            s_in_i2c6_rtc_mst_scl;
  logic            s_in_i2c6_rtc_mst_alert;
  logic            s_in_i2c8_os_mst_sda;
  logic            s_in_i2c8_os_mst_scl;
  logic            s_in_i2c8_os_mst_alert;
  logic            s_in_i2c9_pcie_pnp_mst_sda;
  logic            s_in_i2c9_pcie_pnp_mst_scl;
  logic            s_in_i2c9_pcie_pnp_mst_alert;
  logic            s_in_i2ca_bios_mst_sda;
  logic            s_in_i2ca_bios_mst_scl;
  logic            s_in_i2ca_bios_mst_alert;
  logic            s_in_i2c7_bmc_slv_sda;
  logic            s_in_i2c7_bmc_slv_scl;
  logic            s_in_i2c5_intr_sckt_sda;
  logic            s_in_i2c5_intr_sckt_scl;
  logic            s_in_i2c5_intr_sckt_alert;
  logic            s_in_spi0_vrm_mst_sck;
  logic            s_in_spi0_vrm_mst_si;
  logic            s_in_spi0_vrm_mst_so;
  logic            s_in_spi1_vrm_mst_sck;
  logic            s_in_spi1_vrm_mst_si;
  logic            s_in_spi1_vrm_mst_so;
  logic            s_in_spi2_vrm_mst_sck;
  logic            s_in_spi2_vrm_mst_si;
  logic            s_in_spi2_vrm_mst_so;
  logic            s_in_spi3_vrm_mst_sck;
  logic            s_in_spi3_vrm_mst_si;
  logic            s_in_spi3_vrm_mst_so;
  logic            s_in_qspi_flash_mst_csn0;
  logic            s_in_qspi_flash_mst_sck;
  logic [3:0]      s_in_qspi_flash_mst_sdio;
  logic            s_in_spi5_intr_sckt_csn;
  logic            s_in_spi5_intr_sckt_sck;
  logic            s_in_spi5_intr_sckt_so;
  logic            s_in_spi5_intr_sckt_si;
  logic            s_in_uart1_rxd;
  logic            s_in_uart1_txd;
  logic            s_in_slp_s3_l;
  logic            s_in_slp_s4_l;
  logic            s_in_slp_s5_l;
  logic            s_in_sys_reset_l;
  logic            s_in_sys_rsmrst_l;
  logic            s_in_sys_pwrgd_in;
  logic            s_in_sys_pwr_btn_l;
  logic            s_in_cpu_pwrgd_out;
  logic [1:0]      s_in_cpu_throttle;
  logic            s_in_cpu_thermtrip_l;
  logic [3:0]      s_in_cpu_errcode;
  logic            s_in_cpu_reset_out_l;
  logic [1:0]      s_in_cpu_socket_id;
  logic [3:0]      s_in_cpu_strap;

  // SIGNALS FROM THE PADS
  logic            s_out_i2c0_vrm_mst_sda;
  logic            s_out_i2c0_vrm_mst_scl;
  logic            s_out_i2c0_vrm_mst_alert;
  logic            s_out_i2c1_vrm_mst_sda;
  logic            s_out_i2c1_vrm_mst_scl;
  logic            s_out_i2c1_vrm_mst_alert;
  logic            s_out_i2c2_vrm_mst_sda;
  logic            s_out_i2c2_vrm_mst_scl;
  logic            s_out_i2c2_vrm_mst_alert;
  logic            s_out_i2c3_vrm_mst_sda;
  logic            s_out_i2c3_vrm_mst_scl;
  logic            s_out_i2c3_vrm_mst_alert;
  logic            s_out_i2cc_vrm_mst_sda;
  logic            s_out_i2cc_vrm_mst_scl;
  logic            s_out_i2cc_vrm_mst_alert;
  logic            s_out_i2c6_rtc_mst_sda;
  logic            s_out_i2c6_rtc_mst_scl;
  logic            s_out_i2c6_rtc_mst_alert;
  logic            s_out_i2c8_os_mst_sda;
  logic            s_out_i2c8_os_mst_scl;
  logic            s_out_i2c8_os_mst_alert;
  logic            s_out_i2c9_pcie_pnp_mst_sda;
  logic            s_out_i2c9_pcie_pnp_mst_scl;
  logic            s_out_i2c9_pcie_pnp_mst_alert;
  logic            s_out_i2ca_bios_mst_sda;
  logic            s_out_i2ca_bios_mst_scl;
  logic            s_out_i2ca_bios_mst_alert;
  logic            s_out_i2c7_bmc_slv_sda;
  logic            s_out_i2c7_bmc_slv_scl;
  logic            s_out_i2c5_intr_sckt_sda;
  logic            s_out_i2c5_intr_sckt_scl;
  logic            s_out_i2c5_intr_sckt_alert;
  logic            s_out_spi0_vrm_mst_sck;
  logic            s_out_spi0_vrm_mst_si;
  logic            s_out_spi0_vrm_mst_so;
  logic            s_out_spi1_vrm_mst_sck;
  logic            s_out_spi1_vrm_mst_si;
  logic            s_out_spi1_vrm_mst_so;
  logic            s_out_spi2_vrm_mst_sck;
  logic            s_out_spi2_vrm_mst_si;
  logic            s_out_spi2_vrm_mst_so;
  logic            s_out_spi3_vrm_mst_sck;
  logic            s_out_spi3_vrm_mst_si;
  logic            s_out_spi3_vrm_mst_so;
  logic            s_out_qspi_flash_mst_csn0;
  logic            s_out_qspi_flash_mst_sck;
  logic [3:0]      s_out_qspi_flash_mst_sdio;
  logic            s_out_spi5_intr_sckt_csn;
  logic            s_out_spi5_intr_sckt_sck;
  logic            s_out_spi5_intr_sckt_so;
  logic            s_out_spi5_intr_sckt_si;
  logic            s_out_uart1_rxd;
  logic            s_out_uart1_txd;
  logic            s_out_slp_s3_l;
  logic            s_out_slp_s4_l;
  logic            s_out_slp_s5_l;
  logic            s_out_sys_reset_l;
  logic            s_out_sys_rsmrst_l;
  logic            s_out_sys_pwrgd_in;
  logic            s_out_sys_pwr_btn_l;
  logic            s_out_cpu_pwrgd_out;
  logic [1:0]      s_out_cpu_throttle;
  logic            s_out_cpu_thermtrip_l;
  logic [3:0]      s_out_cpu_errcode;
  logic            s_out_cpu_reset_out_l;
  logic [1:0]      s_out_cpu_socket_id;
  logic [3:0]      s_out_cpu_strap;


  // Instantiate pad_frame for chip-like inout signals
  pad_frame_fpga i_pad_frame (
    // OUTPUT ENABLE SIGNALS TO THE PADS
    .oe_i2c0_vrm_mst_sda_i ( s_oe_i2c0_vrm_mst_sda ),
    .oe_i2c0_vrm_mst_scl_i ( s_oe_i2c0_vrm_mst_scl ),
    .oe_i2c0_vrm_mst_alert_i ( s_oe_i2c0_vrm_mst_alert ),
    .oe_i2c1_vrm_mst_sda_i ( s_oe_i2c1_vrm_mst_sda ),
    .oe_i2c1_vrm_mst_scl_i ( s_oe_i2c1_vrm_mst_scl ),
    .oe_i2c1_vrm_mst_alert_i ( s_oe_i2c1_vrm_mst_alert ),
    .oe_i2c2_vrm_mst_sda_i ( s_oe_i2c2_vrm_mst_sda ),
    .oe_i2c2_vrm_mst_scl_i ( s_oe_i2c2_vrm_mst_scl ),
    .oe_i2c2_vrm_mst_alert_i ( s_oe_i2c2_vrm_mst_alert ),
    .oe_i2c3_vrm_mst_sda_i ( s_oe_i2c3_vrm_mst_sda ),
    .oe_i2c3_vrm_mst_scl_i ( s_oe_i2c3_vrm_mst_scl ),
    .oe_i2c3_vrm_mst_alert_i ( s_oe_i2c3_vrm_mst_alert ),
    .oe_i2cc_vrm_mst_sda_i ( s_oe_i2cc_vrm_mst_sda ),
    .oe_i2cc_vrm_mst_scl_i ( s_oe_i2cc_vrm_mst_scl ),
    .oe_i2cc_vrm_mst_alert_i ( s_oe_i2cc_vrm_mst_alert ),
    .oe_i2c6_rtc_mst_sda_i ( s_oe_i2c6_rtc_mst_sda ),
    .oe_i2c6_rtc_mst_scl_i ( s_oe_i2c6_rtc_mst_scl ),
    .oe_i2c6_rtc_mst_alert_i ( s_oe_i2c6_rtc_mst_alert ),
    .oe_i2c8_os_mst_sda_i ( s_oe_i2c8_os_mst_sda ),
    .oe_i2c8_os_mst_scl_i ( s_oe_i2c8_os_mst_scl ),
    .oe_i2c8_os_mst_alert_i ( s_oe_i2c8_os_mst_alert ),
    .oe_i2c9_pcie_pnp_mst_sda_i ( s_oe_i2c9_pcie_pnp_mst_sda ),
    .oe_i2c9_pcie_pnp_mst_scl_i ( s_oe_i2c9_pcie_pnp_mst_scl ),
    .oe_i2c9_pcie_pnp_mst_alert_i ( s_oe_i2c9_pcie_pnp_mst_alert ),
    .oe_i2ca_bios_mst_sda_i ( s_oe_i2ca_bios_mst_sda ),
    .oe_i2ca_bios_mst_scl_i ( s_oe_i2ca_bios_mst_scl ),
    .oe_i2ca_bios_mst_alert_i ( s_oe_i2ca_bios_mst_alert ),
    .oe_i2c7_bmc_slv_sda_i ( s_oe_i2c7_bmc_slv_sda ),
    .oe_i2c7_bmc_slv_scl_i ( s_oe_i2c7_bmc_slv_scl ),
    .oe_i2c5_intr_sckt_sda_i ( s_oe_i2c5_intr_sckt_sda ),
    .oe_i2c5_intr_sckt_scl_i ( s_oe_i2c5_intr_sckt_scl ),
    .oe_i2c5_intr_sckt_alert_i ( s_oe_i2c5_intr_sckt_alert ),
    .oe_spi0_vrm_mst_sck_i ( s_oe_spi0_vrm_mst_sck ),
    .oe_spi0_vrm_mst_si_i ( s_oe_spi0_vrm_mst_si ),
    .oe_spi0_vrm_mst_so_i ( s_oe_spi0_vrm_mst_so ),
    .oe_spi1_vrm_mst_sck_i ( s_oe_spi1_vrm_mst_sck ),
    .oe_spi1_vrm_mst_si_i ( s_oe_spi1_vrm_mst_si ),
    .oe_spi1_vrm_mst_so_i ( s_oe_spi1_vrm_mst_so ),
    .oe_spi2_vrm_mst_sck_i ( s_oe_spi2_vrm_mst_sck ),
    .oe_spi2_vrm_mst_si_i ( s_oe_spi2_vrm_mst_si ),
    .oe_spi2_vrm_mst_so_i ( s_oe_spi2_vrm_mst_so ),
    .oe_spi3_vrm_mst_sck_i ( s_oe_spi3_vrm_mst_sck ),
    .oe_spi3_vrm_mst_si_i ( s_oe_spi3_vrm_mst_si ),
    .oe_spi3_vrm_mst_so_i ( s_oe_spi3_vrm_mst_so ),
    .oe_qspi_flash_mst_csn0_i ( s_oe_qspi_flash_mst_csn0 ),
    .oe_qspi_flash_mst_sck_i ( s_oe_qspi_flash_mst_sck ),
    .oe_qspi_flash_mst_sdio_i ( s_oe_qspi_flash_mst_sdio ),
    .oe_spi5_intr_sckt_csn_i ( s_oe_spi5_intr_sckt_csn ),
    .oe_spi5_intr_sckt_sck_i ( s_oe_spi5_intr_sckt_sck ),
    .oe_spi5_intr_sckt_so_i ( s_oe_spi5_intr_sckt_so ),
    .oe_spi5_intr_sckt_si_i ( s_oe_spi5_intr_sckt_si ),
    .oe_uart1_rxd_i ( s_oe_uart1_rxd ),
    .oe_uart1_txd_i ( s_oe_uart1_txd ),
    .oe_slp_s3_l_i ( s_oe_slp_s3_l ),
    .oe_slp_s4_l_i ( s_oe_slp_s4_l ),
    .oe_slp_s5_l_i ( s_oe_slp_s5_l ),
    .oe_sys_reset_l_i ( s_oe_sys_reset_l ),
    .oe_sys_rsmrst_l_i ( s_oe_sys_rsmrst_l ),
    .oe_sys_pwrgd_in_i ( s_oe_sys_pwrgd_in ),
    .oe_sys_pwr_btn_l_i ( s_oe_sys_pwr_btn_l ),
    .oe_cpu_pwrgd_out_i ( s_oe_cpu_pwrgd_out ),
    .oe_cpu_throttle_i ( s_oe_cpu_throttle ),
    .oe_cpu_thermtrip_l_i ( s_oe_cpu_thermtrip_l ),
    .oe_cpu_errcode_i ( s_oe_cpu_errcode ),
    .oe_cpu_reset_out_l_i ( s_oe_cpu_reset_out_l ),
    .oe_cpu_socket_id_i ( s_oe_cpu_socket_id ),
    .oe_cpu_strap_i ( s_oe_cpu_strap ),

    // INPUTS SIGNALS TO THE PADS
    .in_i2c0_vrm_mst_sda_o ( s_in_i2c0_vrm_mst_sda ),
    .in_i2c0_vrm_mst_scl_o ( s_in_i2c0_vrm_mst_scl ),
    .in_i2c0_vrm_mst_alert_o ( s_in_i2c0_vrm_mst_alert ),
    .in_i2c1_vrm_mst_sda_o ( s_in_i2c1_vrm_mst_sda ),
    .in_i2c1_vrm_mst_scl_o ( s_in_i2c1_vrm_mst_scl ),
    .in_i2c1_vrm_mst_alert_o ( s_in_i2c1_vrm_mst_alert ),
    .in_i2c2_vrm_mst_sda_o ( s_in_i2c2_vrm_mst_sda ),
    .in_i2c2_vrm_mst_scl_o ( s_in_i2c2_vrm_mst_scl ),
    .in_i2c2_vrm_mst_alert_o ( s_in_i2c2_vrm_mst_alert ),
    .in_i2c3_vrm_mst_sda_o ( s_in_i2c3_vrm_mst_sda ),
    .in_i2c3_vrm_mst_scl_o ( s_in_i2c3_vrm_mst_scl ),
    .in_i2c3_vrm_mst_alert_o ( s_in_i2c3_vrm_mst_alert ),
    .in_i2cc_vrm_mst_sda_o ( s_in_i2cc_vrm_mst_sda ),
    .in_i2cc_vrm_mst_scl_o ( s_in_i2cc_vrm_mst_scl ),
    .in_i2cc_vrm_mst_alert_o ( s_in_i2cc_vrm_mst_alert ),
    .in_i2c6_rtc_mst_sda_o ( s_in_i2c6_rtc_mst_sda ),
    .in_i2c6_rtc_mst_scl_o ( s_in_i2c6_rtc_mst_scl ),
    .in_i2c6_rtc_mst_alert_o ( s_in_i2c6_rtc_mst_alert ),
    .in_i2c8_os_mst_sda_o ( s_in_i2c8_os_mst_sda ),
    .in_i2c8_os_mst_scl_o ( s_in_i2c8_os_mst_scl ),
    .in_i2c8_os_mst_alert_o ( s_in_i2c8_os_mst_alert ),
    .in_i2c9_pcie_pnp_mst_sda_o ( s_in_i2c9_pcie_pnp_mst_sda ),
    .in_i2c9_pcie_pnp_mst_scl_o ( s_in_i2c9_pcie_pnp_mst_scl ),
    .in_i2c9_pcie_pnp_mst_alert_o ( s_in_i2c9_pcie_pnp_mst_alert ),
    .in_i2ca_bios_mst_sda_o ( s_in_i2ca_bios_mst_sda ),
    .in_i2ca_bios_mst_scl_o ( s_in_i2ca_bios_mst_scl ),
    .in_i2ca_bios_mst_alert_o ( s_in_i2ca_bios_mst_alert ),
    .in_i2c7_bmc_slv_sda_o ( s_in_i2c7_bmc_slv_sda ),
    .in_i2c7_bmc_slv_scl_o ( s_in_i2c7_bmc_slv_scl ),
    .in_i2c5_intr_sckt_sda_o ( s_in_i2c5_intr_sckt_sda ),
    .in_i2c5_intr_sckt_scl_o ( s_in_i2c5_intr_sckt_scl ),
    .in_i2c5_intr_sckt_alert_o ( s_in_i2c5_intr_sckt_alert ),
    .in_spi0_vrm_mst_sck_o ( s_in_spi0_vrm_mst_sck ),
    .in_spi0_vrm_mst_si_o ( s_in_spi0_vrm_mst_si ),
    .in_spi0_vrm_mst_so_o ( s_in_spi0_vrm_mst_so ),
    .in_spi1_vrm_mst_sck_o ( s_in_spi1_vrm_mst_sck ),
    .in_spi1_vrm_mst_si_o ( s_in_spi1_vrm_mst_si ),
    .in_spi1_vrm_mst_so_o ( s_in_spi1_vrm_mst_so ),
    .in_spi2_vrm_mst_sck_o ( s_in_spi2_vrm_mst_sck ),
    .in_spi2_vrm_mst_si_o ( s_in_spi2_vrm_mst_si ),
    .in_spi2_vrm_mst_so_o ( s_in_spi2_vrm_mst_so ),
    .in_spi3_vrm_mst_sck_o ( s_in_spi3_vrm_mst_sck ),
    .in_spi3_vrm_mst_si_o ( s_in_spi3_vrm_mst_si ),
    .in_spi3_vrm_mst_so_o ( s_in_spi3_vrm_mst_so ),
    .in_qspi_flash_mst_csn0_o ( s_in_qspi_flash_mst_csn0 ),
    .in_qspi_flash_mst_sck_o ( s_in_qspi_flash_mst_sck ),
    .in_qspi_flash_mst_sdio_o ( s_in_qspi_flash_mst_sdio ),
    .in_spi5_intr_sckt_csn_o ( s_in_spi5_intr_sckt_csn ),
    .in_spi5_intr_sckt_sck_o ( s_in_spi5_intr_sckt_sck ),
    .in_spi5_intr_sckt_so_o ( s_in_spi5_intr_sckt_so ),
    .in_spi5_intr_sckt_si_o ( s_in_spi5_intr_sckt_si ),
    .in_uart1_rxd_o ( s_in_uart1_rxd ),
    .in_uart1_txd_o ( s_in_uart1_txd ),
    .in_slp_s3_l_o ( s_in_slp_s3_l ),
    .in_slp_s4_l_o ( s_in_slp_s4_l ),
    .in_slp_s5_l_o ( s_in_slp_s5_l ),
    .in_sys_reset_l_o ( s_in_sys_reset_l ),
    .in_sys_rsmrst_l_o ( s_in_sys_rsmrst_l ),
    .in_sys_pwrgd_in_o ( s_in_sys_pwrgd_in ),
    .in_sys_pwr_btn_l_o ( s_in_sys_pwr_btn_l ),
    .in_cpu_pwrgd_out_o ( s_in_cpu_pwrgd_out ),
    .in_cpu_throttle_o ( s_in_cpu_throttle ),
    .in_cpu_thermtrip_l_o ( s_in_cpu_thermtrip_l ),
    .in_cpu_errcode_o ( s_in_cpu_errcode ),
    .in_cpu_reset_out_l_o ( s_in_cpu_reset_out_l ),
    .in_cpu_socket_id_o ( s_in_cpu_socket_id ),
    .in_cpu_strap_o ( s_in_cpu_strap ),

    // OUTPUT SIGNALS FROM THE PADS
    .out_i2c0_vrm_mst_sda_i ( s_out_i2c0_vrm_mst_sda ),
    .out_i2c0_vrm_mst_scl_i ( s_out_i2c0_vrm_mst_scl ),
    .out_i2c0_vrm_mst_alert_i ( s_out_i2c0_vrm_mst_alert ),
    .out_i2c1_vrm_mst_sda_i ( s_out_i2c1_vrm_mst_sda ),
    .out_i2c1_vrm_mst_scl_i ( s_out_i2c1_vrm_mst_scl ),
    .out_i2c1_vrm_mst_alert_i ( s_out_i2c1_vrm_mst_alert ),
    .out_i2c2_vrm_mst_sda_i ( s_out_i2c2_vrm_mst_sda ),
    .out_i2c2_vrm_mst_scl_i ( s_out_i2c2_vrm_mst_scl ),
    .out_i2c2_vrm_mst_alert_i ( s_out_i2c2_vrm_mst_alert ),
    .out_i2c3_vrm_mst_sda_i ( s_out_i2c3_vrm_mst_sda ),
    .out_i2c3_vrm_mst_scl_i ( s_out_i2c3_vrm_mst_scl ),
    .out_i2c3_vrm_mst_alert_i ( s_out_i2c3_vrm_mst_alert ),
    .out_i2cc_vrm_mst_sda_i ( s_out_i2cc_vrm_mst_sda ),
    .out_i2cc_vrm_mst_scl_i ( s_out_i2cc_vrm_mst_scl ),
    .out_i2cc_vrm_mst_alert_i ( s_out_i2cc_vrm_mst_alert ),
    .out_i2c6_rtc_mst_sda_i ( s_out_i2c6_rtc_mst_sda ),
    .out_i2c6_rtc_mst_scl_i ( s_out_i2c6_rtc_mst_scl ),
    .out_i2c6_rtc_mst_alert_i ( s_out_i2c6_rtc_mst_alert ),
    .out_i2c8_os_mst_sda_i ( s_out_i2c8_os_mst_sda ),
    .out_i2c8_os_mst_scl_i ( s_out_i2c8_os_mst_scl ),
    .out_i2c8_os_mst_alert_i ( s_out_i2c8_os_mst_alert ),
    .out_i2c9_pcie_pnp_mst_sda_i ( s_out_i2c9_pcie_pnp_mst_sda ),
    .out_i2c9_pcie_pnp_mst_scl_i ( s_out_i2c9_pcie_pnp_mst_scl ),
    .out_i2c9_pcie_pnp_mst_alert_i ( s_out_i2c9_pcie_pnp_mst_alert ),
    .out_i2ca_bios_mst_sda_i ( s_out_i2ca_bios_mst_sda ),
    .out_i2ca_bios_mst_scl_i ( s_out_i2ca_bios_mst_scl ),
    .out_i2ca_bios_mst_alert_i ( s_out_i2ca_bios_mst_alert ),
    .out_i2c7_bmc_slv_sda_i ( s_out_i2c7_bmc_slv_sda ),
    .out_i2c7_bmc_slv_scl_i ( s_out_i2c7_bmc_slv_scl ),
    .out_i2c5_intr_sckt_sda_i ( s_out_i2c5_intr_sckt_sda ),
    .out_i2c5_intr_sckt_scl_i ( s_out_i2c5_intr_sckt_scl ),
    .out_i2c5_intr_sckt_alert_i ( s_out_i2c5_intr_sckt_alert ),
    .out_spi0_vrm_mst_sck_i ( s_out_spi0_vrm_mst_sck ),
    .out_spi0_vrm_mst_si_i ( s_out_spi0_vrm_mst_si ),
    .out_spi0_vrm_mst_so_i ( s_out_spi0_vrm_mst_so ),
    .out_spi1_vrm_mst_sck_i ( s_out_spi1_vrm_mst_sck ),
    .out_spi1_vrm_mst_si_i ( s_out_spi1_vrm_mst_si ),
    .out_spi1_vrm_mst_so_i ( s_out_spi1_vrm_mst_so ),
    .out_spi2_vrm_mst_sck_i ( s_out_spi2_vrm_mst_sck ),
    .out_spi2_vrm_mst_si_i ( s_out_spi2_vrm_mst_si ),
    .out_spi2_vrm_mst_so_i ( s_out_spi2_vrm_mst_so ),
    .out_spi3_vrm_mst_sck_i ( s_out_spi3_vrm_mst_sck ),
    .out_spi3_vrm_mst_si_i ( s_out_spi3_vrm_mst_si ),
    .out_spi3_vrm_mst_so_i ( s_out_spi3_vrm_mst_so ),
    .out_qspi_flash_mst_csn0_i ( s_out_qspi_flash_mst_csn0 ),
    .out_qspi_flash_mst_sck_i ( s_out_qspi_flash_mst_sck ),
    .out_qspi_flash_mst_sdio_i ( s_out_qspi_flash_mst_sdio ),
    .out_spi5_intr_sckt_csn_i ( s_out_spi5_intr_sckt_csn ),
    .out_spi5_intr_sckt_sck_i ( s_out_spi5_intr_sckt_sck ),
    .out_spi5_intr_sckt_so_i ( s_out_spi5_intr_sckt_so ),
    .out_spi5_intr_sckt_si_i ( s_out_spi5_intr_sckt_si ),
    .out_uart1_rxd_i ( s_out_uart1_rxd ),
    .out_uart1_txd_i ( s_out_uart1_txd ),
    .out_slp_s3_l_i ( s_out_slp_s3_l ),
    .out_slp_s4_l_i ( s_out_slp_s4_l ),
    .out_slp_s5_l_i ( s_out_slp_s5_l ),
    .out_sys_reset_l_i ( s_out_sys_reset_l ),
    .out_sys_rsmrst_l_i ( s_out_sys_rsmrst_l ),
    .out_sys_pwrgd_in_i ( s_out_sys_pwrgd_in ),
    .out_sys_pwr_btn_l_i ( s_out_sys_pwr_btn_l ),
    .out_cpu_pwrgd_out_i ( s_out_cpu_pwrgd_out ),
    .out_cpu_throttle_i ( s_out_cpu_throttle ),
    .out_cpu_thermtrip_l_i ( s_out_cpu_thermtrip_l ),
    .out_cpu_errcode_i ( s_out_cpu_errcode ),
    .out_cpu_reset_out_l_i ( s_out_cpu_reset_out_l ),
    .out_cpu_socket_id_i ( s_out_cpu_socket_id ),
    .out_cpu_strap_i ( s_out_cpu_strap ),

    // EXT CHIP TP                 PADS
    .pad_pmb_vr1_pms0_sda ( pad_pmb_vr1_pms0_sda ),
    .pad_pmb_vr1_pms0_scl ( pad_pmb_vr1_pms0_scl ),
    .pad_pmb_vr1_pms0_alert_n ( pad_pmb_vr1_pms0_alert_n ),
    .pad_pmb_vr2_pms0_sda ( pad_pmb_vr2_pms0_sda ),
    .pad_pmb_vr2_pms0_scl ( pad_pmb_vr2_pms0_scl ),
    .pad_pmb_vr2_pms0_alert_n ( pad_pmb_vr2_pms0_alert_n ),
    .pad_pmb_vr3_pms0_sda ( pad_pmb_vr3_pms0_sda ),
    .pad_pmb_vr3_pms0_scl ( pad_pmb_vr3_pms0_scl ),
    .pad_pmb_vr3_pms0_alert_n ( pad_pmb_vr3_pms0_alert_n ),
    .pad_pmb_pol1_pms0_sda ( pad_pmb_pol1_pms0_sda ),
    .pad_pmb_pol1_pms0_scl ( pad_pmb_pol1_pms0_scl ),
    .pad_pmb_pol1_pms0_alert_n ( pad_pmb_pol1_pms0_alert_n ),
    .pad_pmb_ibc_pms0_sda ( pad_pmb_ibc_pms0_sda ),
    .pad_pmb_ibc_pms0_scl ( pad_pmb_ibc_pms0_scl ),
    .pad_pmb_ibc_pms0_alert_n ( pad_pmb_ibc_pms0_alert_n ),
    .pad_i2c2_pms0_sda ( pad_i2c2_pms0_sda ),
    .pad_i2c2_pms0_scl ( pad_i2c2_pms0_scl ),
    .pad_i2c2_pms0_smbalert_n ( pad_i2c2_pms0_smbalert_n ),
    .pad_i2c3_pms0_sda ( pad_i2c3_pms0_sda ),
    .pad_i2c3_pms0_scl ( pad_i2c3_pms0_scl ),
    .pad_i2c3_pms0_smbalert_n ( pad_i2c3_pms0_smbalert_n ),
    .pad_i2c4_pms0_sda ( pad_i2c4_pms0_sda ),
    .pad_i2c4_pms0_scl ( pad_i2c4_pms0_scl ),
    .pad_i2c4_pms0_smbalert_n ( pad_i2c4_pms0_smbalert_n ),
    .pad_i2c5_pms0_sda ( pad_i2c5_pms0_sda ),
    .pad_i2c5_pms0_scl ( pad_i2c5_pms0_scl ),
    .pad_i2c5_pms0_smbalert_n ( pad_i2c5_pms0_smbalert_n ),
    .pad_i2c6_pms0_slv_sda ( pad_i2c6_pms0_slv_sda ),
    .pad_i2c6_pms0_slv_scl ( pad_i2c6_pms0_slv_scl ),
    .pad_i2c7_pms0_sda ( pad_i2c7_pms0_sda ),
    .pad_i2c7_pms0_scl ( pad_i2c7_pms0_scl ),
    .pad_pms0_pms1_smbalert_n ( pad_pms0_pms1_smbalert_n ),
    .pad_pms_avs_clk_vr1 ( pad_pms_avs_clk_vr1 ),
    .pad_pms_avs_mdata_vr1 ( pad_pms_avs_mdata_vr1 ),
    .pad_pms_avs_sdata_vr1 ( pad_pms_avs_sdata_vr1 ),
    .pad_pms_avs_clk_vr2 ( pad_pms_avs_clk_vr2 ),
    .pad_pms_avs_mdata_vr2 ( pad_pms_avs_mdata_vr2 ),
    .pad_pms_avs_sdata_vr2 ( pad_pms_avs_sdata_vr2 ),
    .pad_pms_avs_clk_vr3 ( pad_pms_avs_clk_vr3 ),
    .pad_pms_avs_mdata_vr3 ( pad_pms_avs_mdata_vr3 ),
    .pad_pms_avs_sdata_vr3 ( pad_pms_avs_sdata_vr3 ),
    .pad_pms_avs_clk_ibc ( pad_pms_avs_clk_ibc ),
    .pad_pms_avs_mdata_ibc ( pad_pms_avs_mdata_ibc ),
    .pad_pms_avs_sdata_ibc ( pad_pms_avs_sdata_ibc ),
    .pad_pms_bios_spi_cs0_n ( pad_pms_bios_spi_cs0_n ),
    .pad_pms_bios_spi_clk ( pad_pms_bios_spi_clk ),
    .pad_pms_bios_spi_io0 ( pad_pms_bios_spi_io0 ),
    .pad_pms_bios_spi_io1 ( pad_pms_bios_spi_io1 ),
    .pad_pms_bios_spi_io2 ( pad_pms_bios_spi_io2 ),
    .pad_pms_bios_spi_io3 ( pad_pms_bios_spi_io3 ),
    .pad_pms0_pms1_spi_cs_n ( pad_pms0_pms1_spi_cs_n ),
    .pad_pms0_pms1_spi_clk ( pad_pms0_pms1_spi_clk ),
    .pad_pms0_pms1_spi_miso ( pad_pms0_pms1_spi_miso ),
    .pad_pms0_pms1_spi_mosi ( pad_pms0_pms1_spi_mosi ),
    .pad_uart1_pms0_rxd ( pad_uart1_pms0_rxd ),
    .pad_uart1_pms0_txd ( pad_uart1_pms0_txd ),
    .pad_pms0_slp_s3_n ( pad_pms0_slp_s3_n ),
    .pad_pms0_slp_s4_n ( pad_pms0_slp_s4_n ),
    .pad_pms0_slp_s5_n ( pad_pms0_slp_s5_n ),
    .pad_pms0_sys_reset_n ( pad_pms0_sys_reset_n ),
    .pad_pms0_sys_rsmrst_n ( pad_pms0_sys_rsmrst_n ),
    .pad_pms0_sys_pwgd_in ( pad_pms0_sys_pwgd_in ),
    .pad_pms0_pwr_btn_n ( pad_pms0_pwr_btn_n ),
    .pad_pms0_pwgd_out ( pad_pms0_pwgd_out ),
    .pad_pms0_throttle_0 ( pad_pms0_throttle_0 ),
    .pad_pms0_throttle_1 ( pad_pms0_throttle_1 ),
    .pad_pms0_thermtrip_n ( pad_pms0_thermtrip_n ),
    .pad_pms0_errcode_0 ( pad_pms0_errcode_0 ),
    .pad_pms0_errcode_1 ( pad_pms0_errcode_1 ),
    .pad_pms0_errcode_2 ( pad_pms0_errcode_2 ),
    .pad_pms0_errcode_3 ( pad_pms0_errcode_3 ),
    .pad_pms0_reset_out_n ( pad_pms0_reset_out_n ),
    .pad_pms0_socket_id_0 ( pad_pms0_socket_id_0 ),
    .pad_pms0_socket_id_1 ( pad_pms0_socket_id_1 ),
    .pad_pms0_strap_0 ( pad_pms0_strap_0 ),
    .pad_pms0_strap_1 ( pad_pms0_strap_1 ),
    .pad_pms0_strap_2 ( pad_pms0_strap_2 ),
    .pad_pms0_strap_3 ( pad_pms0_strap_3 ),

    .pad_cfg_i ( s_pad_cfg )
  );

endmodule

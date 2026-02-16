//-----------------------------------------------------------------------------
// Title         : PAD frame for Control PULP, FPGA environment
//-----------------------------------------------------------------------------
// File          : pad_frame_fpga.sv
//-----------------------------------------------------------------------------
// Description :
// Auto-generated pad frame from gen_pads.py
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

module pad_frame_fpga import control_pulp_pkg::*; (

  // OUTPUT ENABLE SIGNALS TO THE PADS
  input logic             oe_i2c0_vrm_mst_sda_i,
  input logic             oe_i2c0_vrm_mst_scl_i,
  input logic             oe_i2c0_vrm_mst_alert_i,
  input logic             oe_i2c1_vrm_mst_sda_i,
  input logic             oe_i2c1_vrm_mst_scl_i,
  input logic             oe_i2c1_vrm_mst_alert_i,
  input logic             oe_i2c2_vrm_mst_sda_i,
  input logic             oe_i2c2_vrm_mst_scl_i,
  input logic             oe_i2c2_vrm_mst_alert_i,
  input logic             oe_i2c3_vrm_mst_sda_i,
  input logic             oe_i2c3_vrm_mst_scl_i,
  input logic             oe_i2c3_vrm_mst_alert_i,
  input logic             oe_i2cc_vrm_mst_sda_i,
  input logic             oe_i2cc_vrm_mst_scl_i,
  input logic             oe_i2cc_vrm_mst_alert_i,
  input logic             oe_i2c6_rtc_mst_sda_i,
  input logic             oe_i2c6_rtc_mst_scl_i,
  input logic             oe_i2c6_rtc_mst_alert_i,
  input logic             oe_i2c8_os_mst_sda_i,
  input logic             oe_i2c8_os_mst_scl_i,
  input logic             oe_i2c8_os_mst_alert_i,
  input logic             oe_i2c9_pcie_pnp_mst_sda_i,
  input logic             oe_i2c9_pcie_pnp_mst_scl_i,
  input logic             oe_i2c9_pcie_pnp_mst_alert_i,
  input logic             oe_i2ca_bios_mst_sda_i,
  input logic             oe_i2ca_bios_mst_scl_i,
  input logic             oe_i2ca_bios_mst_alert_i,
  input logic             oe_i2c7_bmc_slv_sda_i,
  input logic             oe_i2c7_bmc_slv_scl_i,
  input logic             oe_i2c5_intr_sckt_sda_i,
  input logic             oe_i2c5_intr_sckt_scl_i,
  input logic             oe_i2c5_intr_sckt_alert_i,
  input logic             oe_spi0_vrm_mst_sck_i,
  input logic             oe_spi0_vrm_mst_si_i,
  input logic             oe_spi0_vrm_mst_so_i,
  input logic             oe_spi1_vrm_mst_sck_i,
  input logic             oe_spi1_vrm_mst_si_i,
  input logic             oe_spi1_vrm_mst_so_i,
  input logic             oe_spi2_vrm_mst_sck_i,
  input logic             oe_spi2_vrm_mst_si_i,
  input logic             oe_spi2_vrm_mst_so_i,
  input logic             oe_spi3_vrm_mst_sck_i,
  input logic             oe_spi3_vrm_mst_si_i,
  input logic             oe_spi3_vrm_mst_so_i,
  input logic             oe_qspi_flash_mst_csn0_i,
  input logic             oe_qspi_flash_mst_sck_i,
  input logic [3:0]       oe_qspi_flash_mst_sdio_i,
  input logic             oe_spi5_intr_sckt_csn_i,
  input logic             oe_spi5_intr_sckt_sck_i,
  input logic             oe_spi5_intr_sckt_so_i,
  input logic             oe_spi5_intr_sckt_si_i,
  input logic             oe_uart1_rxd_i,
  input logic             oe_uart1_txd_i,
  input logic             oe_slp_s3_l_i,
  input logic             oe_slp_s4_l_i,
  input logic             oe_slp_s5_l_i,
  input logic             oe_sys_reset_l_i,
  input logic             oe_sys_rsmrst_l_i,
  input logic             oe_sys_pwrgd_in_i,
  input logic             oe_sys_pwr_btn_l_i,
  input logic             oe_cpu_pwrgd_out_i,
  input logic [1:0]       oe_cpu_throttle_i,
  input logic             oe_cpu_thermtrip_l_i,
  input logic [3:0]       oe_cpu_errcode_i,
  input logic             oe_cpu_reset_out_l_i,
  input logic [1:0]       oe_cpu_socket_id_i,
  input logic [3:0]       oe_cpu_strap_i,

  // INPUTS SIGNALS FROM THE PADS
  output logic            in_i2c0_vrm_mst_sda_o,
  output logic            in_i2c0_vrm_mst_scl_o,
  output logic            in_i2c0_vrm_mst_alert_o,
  output logic            in_i2c1_vrm_mst_sda_o,
  output logic            in_i2c1_vrm_mst_scl_o,
  output logic            in_i2c1_vrm_mst_alert_o,
  output logic            in_i2c2_vrm_mst_sda_o,
  output logic            in_i2c2_vrm_mst_scl_o,
  output logic            in_i2c2_vrm_mst_alert_o,
  output logic            in_i2c3_vrm_mst_sda_o,
  output logic            in_i2c3_vrm_mst_scl_o,
  output logic            in_i2c3_vrm_mst_alert_o,
  output logic            in_i2cc_vrm_mst_sda_o,
  output logic            in_i2cc_vrm_mst_scl_o,
  output logic            in_i2cc_vrm_mst_alert_o,
  output logic            in_i2c6_rtc_mst_sda_o,
  output logic            in_i2c6_rtc_mst_scl_o,
  output logic            in_i2c6_rtc_mst_alert_o,
  output logic            in_i2c8_os_mst_sda_o,
  output logic            in_i2c8_os_mst_scl_o,
  output logic            in_i2c8_os_mst_alert_o,
  output logic            in_i2c9_pcie_pnp_mst_sda_o,
  output logic            in_i2c9_pcie_pnp_mst_scl_o,
  output logic            in_i2c9_pcie_pnp_mst_alert_o,
  output logic            in_i2ca_bios_mst_sda_o,
  output logic            in_i2ca_bios_mst_scl_o,
  output logic            in_i2ca_bios_mst_alert_o,
  output logic            in_i2c7_bmc_slv_sda_o,
  output logic            in_i2c7_bmc_slv_scl_o,
  output logic            in_i2c5_intr_sckt_sda_o,
  output logic            in_i2c5_intr_sckt_scl_o,
  output logic            in_i2c5_intr_sckt_alert_o,
  output logic            in_spi0_vrm_mst_sck_o,
  output logic            in_spi0_vrm_mst_si_o,
  output logic            in_spi0_vrm_mst_so_o,
  output logic            in_spi1_vrm_mst_sck_o,
  output logic            in_spi1_vrm_mst_si_o,
  output logic            in_spi1_vrm_mst_so_o,
  output logic            in_spi2_vrm_mst_sck_o,
  output logic            in_spi2_vrm_mst_si_o,
  output logic            in_spi2_vrm_mst_so_o,
  output logic            in_spi3_vrm_mst_sck_o,
  output logic            in_spi3_vrm_mst_si_o,
  output logic            in_spi3_vrm_mst_so_o,
  output logic            in_qspi_flash_mst_csn0_o,
  output logic            in_qspi_flash_mst_sck_o,
  output logic [3:0]      in_qspi_flash_mst_sdio_o,
  output logic            in_spi5_intr_sckt_csn_o,
  output logic            in_spi5_intr_sckt_sck_o,
  output logic            in_spi5_intr_sckt_so_o,
  output logic            in_spi5_intr_sckt_si_o,
  output logic            in_uart1_rxd_o,
  output logic            in_uart1_txd_o,
  output logic            in_slp_s3_l_o,
  output logic            in_slp_s4_l_o,
  output logic            in_slp_s5_l_o,
  output logic            in_sys_reset_l_o,
  output logic            in_sys_rsmrst_l_o,
  output logic            in_sys_pwrgd_in_o,
  output logic            in_sys_pwr_btn_l_o,
  output logic            in_cpu_pwrgd_out_o,
  output logic [1:0]      in_cpu_throttle_o,
  output logic            in_cpu_thermtrip_l_o,
  output logic [3:0]      in_cpu_errcode_o,
  output logic            in_cpu_reset_out_l_o,
  output logic [1:0]      in_cpu_socket_id_o,
  output logic [3:0]      in_cpu_strap_o,

  // OUTPUT SIGNALS TO THE PADS
  input logic             out_i2c0_vrm_mst_sda_i,
  input logic             out_i2c0_vrm_mst_scl_i,
  input logic             out_i2c0_vrm_mst_alert_i,
  input logic             out_i2c1_vrm_mst_sda_i,
  input logic             out_i2c1_vrm_mst_scl_i,
  input logic             out_i2c1_vrm_mst_alert_i,
  input logic             out_i2c2_vrm_mst_sda_i,
  input logic             out_i2c2_vrm_mst_scl_i,
  input logic             out_i2c2_vrm_mst_alert_i,
  input logic             out_i2c3_vrm_mst_sda_i,
  input logic             out_i2c3_vrm_mst_scl_i,
  input logic             out_i2c3_vrm_mst_alert_i,
  input logic             out_i2cc_vrm_mst_sda_i,
  input logic             out_i2cc_vrm_mst_scl_i,
  input logic             out_i2cc_vrm_mst_alert_i,
  input logic             out_i2c6_rtc_mst_sda_i,
  input logic             out_i2c6_rtc_mst_scl_i,
  input logic             out_i2c6_rtc_mst_alert_i,
  input logic             out_i2c8_os_mst_sda_i,
  input logic             out_i2c8_os_mst_scl_i,
  input logic             out_i2c8_os_mst_alert_i,
  input logic             out_i2c9_pcie_pnp_mst_sda_i,
  input logic             out_i2c9_pcie_pnp_mst_scl_i,
  input logic             out_i2c9_pcie_pnp_mst_alert_i,
  input logic             out_i2ca_bios_mst_sda_i,
  input logic             out_i2ca_bios_mst_scl_i,
  input logic             out_i2ca_bios_mst_alert_i,
  input logic             out_i2c7_bmc_slv_sda_i,
  input logic             out_i2c7_bmc_slv_scl_i,
  input logic             out_i2c5_intr_sckt_sda_i,
  input logic             out_i2c5_intr_sckt_scl_i,
  input logic             out_i2c5_intr_sckt_alert_i,
  input logic             out_spi0_vrm_mst_sck_i,
  input logic             out_spi0_vrm_mst_si_i,
  input logic             out_spi0_vrm_mst_so_i,
  input logic             out_spi1_vrm_mst_sck_i,
  input logic             out_spi1_vrm_mst_si_i,
  input logic             out_spi1_vrm_mst_so_i,
  input logic             out_spi2_vrm_mst_sck_i,
  input logic             out_spi2_vrm_mst_si_i,
  input logic             out_spi2_vrm_mst_so_i,
  input logic             out_spi3_vrm_mst_sck_i,
  input logic             out_spi3_vrm_mst_si_i,
  input logic             out_spi3_vrm_mst_so_i,
  input logic             out_qspi_flash_mst_csn0_i,
  input logic             out_qspi_flash_mst_sck_i,
  input logic [3:0]       out_qspi_flash_mst_sdio_i,
  input logic             out_spi5_intr_sckt_csn_i,
  input logic             out_spi5_intr_sckt_sck_i,
  input logic             out_spi5_intr_sckt_so_i,
  input logic             out_spi5_intr_sckt_si_i,
  input logic             out_uart1_rxd_i,
  input logic             out_uart1_txd_i,
  input logic             out_slp_s3_l_i,
  input logic             out_slp_s4_l_i,
  input logic             out_slp_s5_l_i,
  input logic             out_sys_reset_l_i,
  input logic             out_sys_rsmrst_l_i,
  input logic             out_sys_pwrgd_in_i,
  input logic             out_sys_pwr_btn_l_i,
  input logic             out_cpu_pwrgd_out_i,
  input logic [1:0]       out_cpu_throttle_i,
  input logic             out_cpu_thermtrip_l_i,
  input logic [3:0]       out_cpu_errcode_i,
  input logic             out_cpu_reset_out_l_i,
  input logic [1:0]       out_cpu_socket_id_i,
  input logic [3:0]       out_cpu_strap_i,

  input logic             out_doorbell,
  input logic             out_completion,


  // PMB PADS INOUT WIRES
  inout wire              pad_pmb_vr1_pms0_sda,
  inout wire              pad_pmb_vr1_pms0_scl,
  inout wire              pad_pmb_vr1_pms0_alert_n,
  inout wire              pad_pmb_vr2_pms0_sda,
  inout wire              pad_pmb_vr2_pms0_scl,
  inout wire              pad_pmb_vr2_pms0_alert_n,
  inout wire              pad_pmb_vr3_pms0_sda,
  inout wire              pad_pmb_vr3_pms0_scl,
  inout wire              pad_pmb_vr3_pms0_alert_n,
  inout wire              pad_pmb_pol1_pms0_sda,
  inout wire              pad_pmb_pol1_pms0_scl,
  inout wire              pad_pmb_pol1_pms0_alert_n,
  inout wire              pad_pmb_ibc_pms0_sda,
  inout wire              pad_pmb_ibc_pms0_scl,
  inout wire              pad_pmb_ibc_pms0_alert_n,

  // I2C PADS INOUT WIRES
  inout wire              pad_i2c2_pms0_sda,
  inout wire              pad_i2c2_pms0_scl,
  inout wire              pad_i2c2_pms0_smbalert_n,
  inout wire              pad_i2c3_pms0_sda,
  inout wire              pad_i2c3_pms0_scl,
  inout wire              pad_i2c3_pms0_smbalert_n,
  inout wire              pad_i2c4_pms0_sda,
  inout wire              pad_i2c4_pms0_scl,
  inout wire              pad_i2c4_pms0_smbalert_n,
  inout wire              pad_i2c5_pms0_sda,
  inout wire              pad_i2c5_pms0_scl,
  inout wire              pad_i2c5_pms0_smbalert_n,
  inout wire              pad_i2c6_pms0_slv_sda,
  inout wire              pad_i2c6_pms0_slv_scl,

  // AVS PADS INOUT WIRES
  inout wire              pad_pms_avs_clk_vr1,
  inout wire              pad_pms_avs_mdata_vr1,
  inout wire              pad_pms_avs_sdata_vr1,
  inout wire              pad_pms_avs_clk_vr2,
  inout wire              pad_pms_avs_mdata_vr2,
  inout wire              pad_pms_avs_sdata_vr2,
  inout wire              pad_pms_avs_clk_vr3,
  inout wire              pad_pms_avs_mdata_vr3,
  inout wire              pad_pms_avs_sdata_vr3,
  inout wire              pad_pms_avs_clk_ibc,
  inout wire              pad_pms_avs_mdata_ibc,
  inout wire              pad_pms_avs_sdata_ibc,

  // QSPI PADS INOUT WIRES
  inout wire              pad_pms_bios_spi_cs0_n,
  inout wire              pad_pms_bios_spi_clk,
  inout wire              pad_pms_bios_spi_io0,
  inout wire              pad_pms_bios_spi_io1,
  inout wire              pad_pms_bios_spi_io2,
  inout wire              pad_pms_bios_spi_io3,

  // INTER SOCKET PADS INOUT WIRES
  inout wire              pad_i2c7_pms0_sda,
  inout wire              pad_i2c7_pms0_scl,
  inout wire              pad_pms0_pms1_smbalert_n,
  inout wire              pad_pms0_pms1_spi_cs_n,
  inout wire              pad_pms0_pms1_spi_clk,
  inout wire              pad_pms0_pms1_spi_miso,
  inout wire              pad_pms0_pms1_spi_mosi,

  // GPIO PADS INOUT WIRES
  inout wire              pad_pms0_slp_s3_n,
  inout wire              pad_pms0_slp_s4_n,
  inout wire              pad_pms0_slp_s5_n,
  inout wire              pad_pms0_sys_reset_n,
  inout wire              pad_pms0_sys_rsmrst_n,
  inout wire              pad_pms0_sys_pwgd_in,
  inout wire              pad_pms0_pwr_btn_n,
  inout wire              pad_pms0_pwgd_out,
  inout wire              pad_pms0_throttle_0,
  inout wire              pad_pms0_throttle_1,
  inout wire              pad_pms0_thermtrip_n,
  inout wire              pad_pms0_errcode_0,
  inout wire              pad_pms0_errcode_1,
  inout wire              pad_pms0_errcode_2,
  inout wire              pad_pms0_errcode_3,
  inout wire              pad_pms0_reset_out_n,
  inout wire              pad_pms0_socket_id_0,
  inout wire              pad_pms0_socket_id_1,
  inout wire              pad_pms0_strap_0,
  inout wire              pad_pms0_strap_1,
  inout wire              pad_pms0_strap_2,
  inout wire              pad_pms0_strap_3,

  // UART PADS INOUT WIRES
  inout wire              pad_uart1_pms0_rxd,
  inout wire              pad_uart1_pms0_txd,

  inout wire              pad_bootsel0,
  inout wire              pad_bootsel1,
  inout wire              pad_bootsel_valid,
  inout wire              pad_fc_fetch_en,
  inout wire              pad_fc_fetch_en_valid,

  inout wire              pad_doorbell_irq,
  inout wire              pad_completion_irq,

  output logic [1:0]      bootsel_o, 
  output logic            bootsel_valid_o,
  output logic            fc_fetch_en_o,
  output logic            fc_fetch_en_valid_o,

  input logic [31:0][5:0] pad_cfg_i
);

  // PMB PADS INSTANCES
  pad_functional_pu padinst_pmb_vr1_pms0_sda( .OEN(~oe_i2c0_vrm_mst_sda_i ), .I(out_i2c0_vrm_mst_sda_i ), .O(in_i2c0_vrm_mst_sda_o ), .PAD(pad_pmb_vr1_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr1_pms0_scl( .OEN(~oe_i2c0_vrm_mst_scl_i ), .I(out_i2c0_vrm_mst_scl_i ), .O(in_i2c0_vrm_mst_scl_o ), .PAD(pad_pmb_vr1_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr1_pms0_alert_n( .OEN(~oe_i2c0_vrm_mst_alert_i ), .I(out_i2c0_vrm_mst_alert_i ), .O(in_i2c0_vrm_mst_alert_o ), .PAD(pad_pmb_vr1_pms0_alert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr2_pms0_sda( .OEN(~oe_i2c1_vrm_mst_sda_i ), .I(out_i2c1_vrm_mst_sda_i ), .O(in_i2c1_vrm_mst_sda_o ), .PAD(pad_pmb_vr2_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr2_pms0_scl( .OEN(~oe_i2c1_vrm_mst_scl_i ), .I(out_i2c1_vrm_mst_scl_i ), .O(in_i2c1_vrm_mst_scl_o ), .PAD(pad_pmb_vr2_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr2_pms0_alert_n( .OEN(~oe_i2c1_vrm_mst_alert_i ), .I(out_i2c1_vrm_mst_alert_i ), .O(in_i2c1_vrm_mst_alert_o ), .PAD(pad_pmb_vr2_pms0_alert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr3_pms0_sda( .OEN(~oe_i2c2_vrm_mst_sda_i ), .I(out_i2c2_vrm_mst_sda_i ), .O(in_i2c2_vrm_mst_sda_o ), .PAD(pad_pmb_vr3_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr3_pms0_scl( .OEN(~oe_i2c2_vrm_mst_scl_i ), .I(out_i2c2_vrm_mst_scl_i ), .O(in_i2c2_vrm_mst_scl_o ), .PAD(pad_pmb_vr3_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_vr3_pms0_alert_n( .OEN(~oe_i2c2_vrm_mst_alert_i ), .I(out_i2c2_vrm_mst_alert_i ), .O(in_i2c2_vrm_mst_alert_o ), .PAD(pad_pmb_vr3_pms0_alert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_pol1_pms0_sda( .OEN(~oe_i2c3_vrm_mst_sda_i ), .I(out_i2c3_vrm_mst_sda_i ), .O(in_i2c3_vrm_mst_sda_o ), .PAD(pad_pmb_pol1_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_pol1_pms0_scl( .OEN(~oe_i2c3_vrm_mst_scl_i ), .I(out_i2c3_vrm_mst_scl_i ), .O(in_i2c3_vrm_mst_scl_o ), .PAD(pad_pmb_pol1_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_pol1_pms0_alert_n( .OEN(~oe_i2c3_vrm_mst_alert_i ), .I(out_i2c3_vrm_mst_alert_i ), .O(in_i2c3_vrm_mst_alert_o ), .PAD(pad_pmb_pol1_pms0_alert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_ibc_pms0_sda( .OEN(~oe_i2cc_vrm_mst_sda_i ), .I(out_i2cc_vrm_mst_sda_i ), .O(in_i2cc_vrm_mst_sda_o ), .PAD(pad_pmb_ibc_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_ibc_pms0_scl( .OEN(~oe_i2cc_vrm_mst_scl_i ), .I(out_i2cc_vrm_mst_scl_i ), .O(in_i2cc_vrm_mst_scl_o ), .PAD(pad_pmb_ibc_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pmb_ibc_pms0_alert_n( .OEN(~oe_i2cc_vrm_mst_alert_i ), .I(out_i2cc_vrm_mst_alert_i ), .O(in_i2cc_vrm_mst_alert_o ), .PAD(pad_pmb_ibc_pms0_alert_n ), .PEN(1'b0 ));

  // I2C PADS INSTANCES
  pad_functional_pu padinst_i2c2_pms0_sda( .OEN(~oe_i2c6_rtc_mst_sda_i ), .I(out_i2c6_rtc_mst_sda_i ), .O(in_i2c6_rtc_mst_sda_o ), .PAD(pad_i2c2_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c2_pms0_scl( .OEN(~oe_i2c6_rtc_mst_scl_i ), .I(out_i2c6_rtc_mst_scl_i ), .O(in_i2c6_rtc_mst_scl_o ), .PAD(pad_i2c2_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c2_pms0_smbalert_n( .OEN(~oe_i2c6_rtc_mst_alert_i ), .I(out_i2c6_rtc_mst_alert_i ), .O(in_i2c6_rtc_mst_alert_o ), .PAD(pad_i2c2_pms0_smbalert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c3_pms0_sda( .OEN(~oe_i2c8_os_mst_sda_i ), .I(out_i2c8_os_mst_sda_i ), .O(in_i2c8_os_mst_sda_o ), .PAD(pad_i2c3_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c3_pms0_scl( .OEN(~oe_i2c8_os_mst_scl_i ), .I(out_i2c8_os_mst_scl_i ), .O(in_i2c8_os_mst_scl_o ), .PAD(pad_i2c3_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c3_pms0_smbalert_n( .OEN(~oe_i2c8_os_mst_alert_i ), .I(out_i2c8_os_mst_alert_i ), .O(in_i2c8_os_mst_alert_o ), .PAD(pad_i2c3_pms0_smbalert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c4_pms0_sda( .OEN(~oe_i2c9_pcie_pnp_mst_sda_i ), .I(out_i2c9_pcie_pnp_mst_sda_i ), .O(in_i2c9_pcie_pnp_mst_sda_o ), .PAD(pad_i2c4_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c4_pms0_scl( .OEN(~oe_i2c9_pcie_pnp_mst_scl_i ), .I(out_i2c9_pcie_pnp_mst_scl_i ), .O(in_i2c9_pcie_pnp_mst_scl_o ), .PAD(pad_i2c4_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c4_pms0_smbalert_n( .OEN(~oe_i2c9_pcie_pnp_mst_alert_i ), .I(out_i2c9_pcie_pnp_mst_alert_i ), .O(in_i2c9_pcie_pnp_mst_alert_o ), .PAD(pad_i2c4_pms0_smbalert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c5_pms0_sda( .OEN(~oe_i2ca_bios_mst_sda_i ), .I(out_i2ca_bios_mst_sda_i ), .O(in_i2ca_bios_mst_sda_o ), .PAD(pad_i2c5_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c5_pms0_scl( .OEN(~oe_i2ca_bios_mst_scl_i ), .I(out_i2ca_bios_mst_scl_i ), .O(in_i2ca_bios_mst_scl_o ), .PAD(pad_i2c5_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c5_pms0_smbalert_n( .OEN(~oe_i2ca_bios_mst_alert_i ), .I(out_i2ca_bios_mst_alert_i ), .O(in_i2ca_bios_mst_alert_o ), .PAD(pad_i2c5_pms0_smbalert_n ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c6_pms0_slv_sda( .OEN(~oe_i2c7_bmc_slv_sda_i ), .I(out_i2c7_bmc_slv_sda_i ), .O(in_i2c7_bmc_slv_sda_o ), .PAD(pad_i2c6_pms0_slv_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c6_pms0_slv_scl( .OEN(~oe_i2c7_bmc_slv_scl_i ), .I(out_i2c7_bmc_slv_scl_i ), .O(in_i2c7_bmc_slv_scl_o ), .PAD(pad_i2c6_pms0_slv_scl ), .PEN(1'b0 ));

  // AVS PADS INSTANCES
  pad_functional_pd padinst_pms_avs_clk_vr1( .OEN(~oe_spi0_vrm_mst_sck_i ), .I(out_spi0_vrm_mst_sck_i ), .O(in_spi0_vrm_mst_sck_o ), .PAD(pad_pms_avs_clk_vr1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_mdata_vr1( .OEN(~oe_spi0_vrm_mst_si_i ), .I(out_spi0_vrm_mst_si_i ), .O(in_spi0_vrm_mst_si_o ), .PAD(pad_pms_avs_mdata_vr1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_sdata_vr1( .OEN(~oe_spi0_vrm_mst_so_i ), .I(out_spi0_vrm_mst_so_i ), .O(in_spi0_vrm_mst_so_o ), .PAD(pad_pms_avs_sdata_vr1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_clk_vr2( .OEN(~oe_spi1_vrm_mst_sck_i ), .I(out_spi1_vrm_mst_sck_i ), .O(in_spi1_vrm_mst_sck_o ), .PAD(pad_pms_avs_clk_vr2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_mdata_vr2( .OEN(~oe_spi1_vrm_mst_si_i ), .I(out_spi1_vrm_mst_si_i ), .O(in_spi1_vrm_mst_si_o ), .PAD(pad_pms_avs_mdata_vr2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_sdata_vr2( .OEN(~oe_spi1_vrm_mst_so_i ), .I(out_spi1_vrm_mst_so_i ), .O(in_spi1_vrm_mst_so_o ), .PAD(pad_pms_avs_sdata_vr2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_clk_vr3( .OEN(~oe_spi2_vrm_mst_sck_i ), .I(out_spi2_vrm_mst_sck_i ), .O(in_spi2_vrm_mst_sck_o ), .PAD(pad_pms_avs_clk_vr3 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_mdata_vr3( .OEN(~oe_spi2_vrm_mst_si_i ), .I(out_spi2_vrm_mst_si_i ), .O(in_spi2_vrm_mst_si_o ), .PAD(pad_pms_avs_mdata_vr3 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_sdata_vr3( .OEN(~oe_spi2_vrm_mst_so_i ), .I(out_spi2_vrm_mst_so_i ), .O(in_spi2_vrm_mst_so_o ), .PAD(pad_pms_avs_sdata_vr3 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_clk_ibc( .OEN(~oe_spi3_vrm_mst_sck_i ), .I(out_spi3_vrm_mst_sck_i ), .O(in_spi3_vrm_mst_sck_o ), .PAD(pad_pms_avs_clk_ibc ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_mdata_ibc( .OEN(~oe_spi3_vrm_mst_si_i ), .I(out_spi3_vrm_mst_si_i ), .O(in_spi3_vrm_mst_si_o ), .PAD(pad_pms_avs_mdata_ibc ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_avs_sdata_ibc( .OEN(~oe_spi3_vrm_mst_so_i ), .I(out_spi3_vrm_mst_so_i ), .O(in_spi3_vrm_mst_so_o ), .PAD(pad_pms_avs_sdata_ibc ), .PEN(1'b0 ));

  // QSPI PADS INSTANCES
  pad_functional_pd padinst_pms_bios_spi_cs0_n( .OEN(~oe_qspi_flash_mst_csn0_i ), .I(out_qspi_flash_mst_csn0_i ), .O(in_qspi_flash_mst_csn0_o ), .PAD(pad_pms_bios_spi_cs0_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_bios_spi_clk( .OEN(~oe_qspi_flash_mst_sck_i ), .I(out_qspi_flash_mst_sck_i ), .O(in_qspi_flash_mst_sck_o ), .PAD(pad_pms_bios_spi_clk ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_bios_spi_io0( .OEN(~oe_qspi_flash_mst_sdio_i[0] ), .I(out_qspi_flash_mst_sdio_i[0] ), .O(in_qspi_flash_mst_sdio_o[0] ), .PAD(pad_pms_bios_spi_io0 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_bios_spi_io1( .OEN(~oe_qspi_flash_mst_sdio_i[1] ), .I(out_qspi_flash_mst_sdio_i[1] ), .O(in_qspi_flash_mst_sdio_o[1] ), .PAD(pad_pms_bios_spi_io1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_bios_spi_io2( .OEN(~oe_qspi_flash_mst_sdio_i[2] ), .I(out_qspi_flash_mst_sdio_i[2] ), .O(in_qspi_flash_mst_sdio_o[2] ), .PAD(pad_pms_bios_spi_io2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms_bios_spi_io3( .OEN(~oe_qspi_flash_mst_sdio_i[3] ), .I(out_qspi_flash_mst_sdio_i[3] ), .O(in_qspi_flash_mst_sdio_o[3] ), .PAD(pad_pms_bios_spi_io3 ), .PEN(1'b0 ));

  // INTER SOCKET PADS INSTANCES
  pad_functional_pu padinst_i2c7_pms0_sda( .OEN(~oe_i2c5_intr_sckt_sda_i ), .I(out_i2c5_intr_sckt_sda_i ), .O(in_i2c5_intr_sckt_sda_o ), .PAD(pad_i2c7_pms0_sda ), .PEN(1'b0 ));
  pad_functional_pu padinst_i2c7_pms0_scl( .OEN(~oe_i2c5_intr_sckt_scl_i ), .I(out_i2c5_intr_sckt_scl_i ), .O(in_i2c5_intr_sckt_scl_o ), .PAD(pad_i2c7_pms0_scl ), .PEN(1'b0 ));
  pad_functional_pu padinst_pms0_pms1_smbalert_n( .OEN(~oe_i2c5_intr_sckt_alert_i ), .I(out_i2c5_intr_sckt_alert_i ), .O(in_i2c5_intr_sckt_alert_o ), .PAD(pad_pms0_pms1_smbalert_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_spi_pms0_pms1_spi_cs_n( .OEN(~oe_spi5_intr_sckt_csn_i ), .I(out_spi5_intr_sckt_csn_i ), .O(in_spi5_intr_sckt_csn_o ), .PAD(pad_pms0_pms1_spi_cs_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_spi_pms0_pms1_spi_clk( .OEN(~oe_spi5_intr_sckt_sck_i ), .I(out_spi5_intr_sckt_sck_i ), .O(in_spi5_intr_sckt_sck_o ), .PAD(pad_pms0_pms1_spi_clk ), .PEN(1'b0 ));
  pad_functional_pd padinst_spi_pms0_pms1_spi_miso( .OEN(~oe_spi5_intr_sckt_so_i ), .I(out_spi5_intr_sckt_so_i ), .O(in_spi5_intr_sckt_so_o ), .PAD(pad_pms0_pms1_spi_miso ), .PEN(1'b0 ));
  pad_functional_pd padinst_spi_pms0_pms1_spi_mosi( .OEN(~oe_spi5_intr_sckt_si_i ), .I(out_spi5_intr_sckt_si_i ), .O(in_spi5_intr_sckt_si_o ), .PAD(pad_pms0_pms1_spi_mosi ), .PEN(1'b0 ));

  // GPIO PADS INSTANCES
  pad_functional_pd padinst_pms0_slp_s3_n( .OEN(~oe_slp_s3_l_i ), .I(out_slp_s3_l_i ), .O(in_slp_s3_l_o ), .PAD(pad_pms0_slp_s3_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_slp_s4_n( .OEN(~oe_slp_s4_l_i ), .I(out_slp_s4_l_i ), .O(in_slp_s4_l_o ), .PAD(pad_pms0_slp_s4_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_slp_s5_n( .OEN(~oe_slp_s5_l_i ), .I(out_slp_s5_l_i ), .O(in_slp_s5_l_o ), .PAD(pad_pms0_slp_s5_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_sys_reset_n( .OEN(~oe_sys_reset_l_i ), .I(out_sys_reset_l_i ), .O(in_sys_reset_l_o ), .PAD(pad_pms0_sys_reset_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_sys_rsmrst_n( .OEN(~oe_sys_rsmrst_l_i ), .I(out_sys_rsmrst_l_i ), .O(in_sys_rsmrst_l_o ), .PAD(pad_pms0_sys_rsmrst_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_sys_pwgd_in( .OEN(~oe_sys_pwrgd_in_i ), .I(out_sys_pwrgd_in_i ), .O(in_sys_pwrgd_in_o ), .PAD(pad_pms0_sys_pwgd_in ), .PEN(1'b0 ));
  pad_functional_pu padinst_pms0_pwr_btn_n( .OEN(~oe_sys_pwr_btn_l_i ), .I(out_sys_pwr_btn_l_i ), .O(in_sys_pwr_btn_l_o ), .PAD(pad_pms0_pwr_btn_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_pwgd_out( .OEN(~oe_cpu_pwrgd_out_i ), .I(out_cpu_pwrgd_out_i ), .O(in_cpu_pwrgd_out_o ), .PAD(pad_pms0_pwgd_out ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_throttle_0( .OEN(~oe_cpu_throttle_i[0] ), .I(out_cpu_throttle_i[0] ), .O(in_cpu_throttle_o[0] ), .PAD(pad_pms0_throttle_0 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_throttle_1( .OEN(~oe_cpu_throttle_i[1] ), .I(out_cpu_throttle_i[1] ), .O(in_cpu_throttle_o[1] ), .PAD(pad_pms0_throttle_1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_thermtrip_n( .OEN(~oe_cpu_thermtrip_l_i ), .I(out_cpu_thermtrip_l_i ), .O(in_cpu_thermtrip_l_o ), .PAD(pad_pms0_thermtrip_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_errcode_0( .OEN(~oe_cpu_errcode_i[0] ), .I(out_cpu_errcode_i[0] ), .O(in_cpu_errcode_o[0] ), .PAD(pad_pms0_errcode_0 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_errcode_1( .OEN(~oe_cpu_errcode_i[1] ), .I(out_cpu_errcode_i[1] ), .O(in_cpu_errcode_o[1] ), .PAD(pad_pms0_errcode_1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_errcode_2( .OEN(~oe_cpu_errcode_i[2] ), .I(out_cpu_errcode_i[2] ), .O(in_cpu_errcode_o[2] ), .PAD(pad_pms0_errcode_2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_errcode_3( .OEN(~oe_cpu_errcode_i[3] ), .I(out_cpu_errcode_i[3] ), .O(in_cpu_errcode_o[3] ), .PAD(pad_pms0_errcode_3 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_reset_out_n( .OEN(~oe_cpu_reset_out_l_i ), .I(out_cpu_reset_out_l_i ), .O(in_cpu_reset_out_l_o ), .PAD(pad_pms0_reset_out_n ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_socket_id_0( .OEN(~oe_cpu_socket_id_i[0] ), .I(out_cpu_socket_id_i[0] ), .O(in_cpu_socket_id_o[0] ), .PAD(pad_pms0_socket_id_0 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_socket_id_1( .OEN(~oe_cpu_socket_id_i[1] ), .I(out_cpu_socket_id_i[1] ), .O(in_cpu_socket_id_o[1] ), .PAD(pad_pms0_socket_id_1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_strap_0( .OEN(~oe_cpu_strap_i[0] ), .I(out_cpu_strap_i[0] ), .O(in_cpu_strap_o[0] ), .PAD(pad_pms0_strap_0 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_strap_1( .OEN(~oe_cpu_strap_i[1] ), .I(out_cpu_strap_i[1] ), .O(in_cpu_strap_o[1] ), .PAD(pad_pms0_strap_1 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_strap_2( .OEN(~oe_cpu_strap_i[2] ), .I(out_cpu_strap_i[2] ), .O(in_cpu_strap_o[2] ), .PAD(pad_pms0_strap_2 ), .PEN(1'b0 ));
  pad_functional_pd padinst_pms0_strap_3( .OEN(~oe_cpu_strap_i[3] ), .I(out_cpu_strap_i[3] ), .O(in_cpu_strap_o[3] ), .PAD(pad_pms0_strap_3 ), .PEN(1'b0 ));

  // UART PADS INSTANCES (We actually have only one UART, but the interface name is "uart1" in ATOS)
  pad_functional_pu padinst_uart1_pms0_rxd( .OEN(~oe_uart1_rxd_i ), .I(out_uart1_rxd_i ), .O(in_uart1_rxd_o ), .PAD(pad_uart1_pms0_rxd ), .PEN(1'b0 ));
  pad_functional_pu padinst_uart1_pms0_txd( .OEN(~oe_uart1_txd_i ), .I(out_uart1_txd_i ), .O(in_uart1_txd_o ), .PAD(pad_uart1_pms0_txd ), .PEN(1'b0 ));


  // BOOT SELECTION SIGNALS
  pad_functional_pd padinst_pad_bootsel0          ( .OEN(1'b1), .I(), .O(bootsel_o[0]),         .PAD(pad_bootsel0), .PEN(1'b0 ));
  pad_functional_pd padinst_pad_bootsel1          ( .OEN(1'b1), .I(), .O(bootsel_o[1]),         .PAD(pad_bootsel1), .PEN(1'b0 ));
  pad_functional_pd padinst_pad_bootsel_valid     ( .OEN(1'b1), .I(), .O(bootsel_valid_o),      .PAD(pad_bootsel_valid), .PEN(1'b0 ));
  pad_functional_pd padinst_pad_fc_fetch_en       ( .OEN(1'b1), .I(), .O(fc_fetch_en_o),        .PAD(pad_fc_fetch_en), .PEN(1'b0 ));
  pad_functional_pd padinst_pad_fc_fetch_en_valid ( .OEN(1'b1), .I(), .O(fc_fetch_en_valid_o),  .PAD(pad_fc_fetch_en_valid), .PEN(1'b0 ));

  // TEST INTERRUPT SIGNALS
  pad_functional_pd padinst_pad_doorbell_irq       ( .OEN(1'b0), .I(out_doorbell), .O(),        .PAD(pad_doorbell_irq), .PEN(1'b0 ));
  pad_functional_pd padinst_pad_completion_irq     ( .OEN(1'b0), .I(out_completion), .O(),      .PAD(pad_completion_irq), .PEN(1'b0 ));

endmodule

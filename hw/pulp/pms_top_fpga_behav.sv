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

// This is the top-level module for the pms port on FPGA (simulation)
// It uses behavioral (`tc_sram`) memories and the clocking strategy of the ASIC top-level

module pms_top_fpga_behav (

  // PS slave
  output [ 5:0]           ps_slv_aw_id_o,
  output [ 48:0]          ps_slv_aw_addr_o,
  output [ 7:0]           ps_slv_aw_len_o,
  output [ 2:0]           ps_slv_aw_size_o,
  output [ 1:0]           ps_slv_aw_burst_o,
  output                  ps_slv_aw_lock_o,
  output [ 3:0]           ps_slv_aw_cache_o,
  output [ 2:0]           ps_slv_aw_prot_o,
  output [ 3:0]           ps_slv_aw_qos_o,
  output [ 5:0]           ps_slv_aw_atop_o,
  output                  ps_slv_aw_user_o, //1 bit
  output                  ps_slv_aw_valid_o,
  input                   ps_slv_aw_ready_i,
  output [ 63:0]          ps_slv_w_data_o,
  output [ 7:0]           ps_slv_w_strb_o,
  output                  ps_slv_w_last_o,
  output                  ps_slv_w_valid_o,
  input                   ps_slv_w_ready_i,
  input  [ 5:0]           ps_slv_b_id_i,
  input  [ 1:0]           ps_slv_b_resp_i,
  input                   ps_slv_b_valid_i,
  output                  ps_slv_b_ready_o,
  output [ 5:0]           ps_slv_ar_id_o,
  output [ 48:0]          ps_slv_ar_addr_o,
  output [ 7:0]           ps_slv_ar_len_o,
  output [ 2:0]           ps_slv_ar_size_o,
  output [ 1:0]           ps_slv_ar_burst_o,
  output                  ps_slv_ar_lock_o,
  output [ 3:0]           ps_slv_ar_cache_o,
  output [ 2:0]           ps_slv_ar_prot_o,
  output [ 3:0]           ps_slv_ar_qos_o,
  output                  ps_slv_ar_user_o, //1 bit
  output                  ps_slv_ar_valid_o,
  input                   ps_slv_ar_ready_i,
  input  [ 5:0]           ps_slv_r_id_i,
  input  [ 63:0]          ps_slv_r_data_i,
  input  [ 1:0]           ps_slv_r_resp_i,
  input                   ps_slv_r_last_i,
  input                   ps_slv_r_valid_i,
  output                  ps_slv_r_ready_o,

  // PS master
  input  [ 15:0]          ps_mst_aw_id_i,
  input  [ 39:0]          ps_mst_aw_addr_i,
  input  [ 7:0]           ps_mst_aw_len_i,
  input  [ 2:0]           ps_mst_aw_size_i,
  input  [ 1:0]           ps_mst_aw_burst_i,
  input                   ps_mst_aw_lock_i,
  input  [ 3:0]           ps_mst_aw_cache_i,
  input  [ 2:0]           ps_mst_aw_prot_i,
  input  [ 3:0]           ps_mst_aw_qos_i,
  input  [ 5:0]           ps_mst_aw_atop_i,
  input  [15:0]           ps_mst_aw_user_i, //16 bit
  input                   ps_mst_aw_valid_i,
  output                  ps_mst_aw_ready_o,
  input  [ 63:0]          ps_mst_w_data_i,
  input  [ 7:0]           ps_mst_w_strb_i,
  input                   ps_mst_w_last_i,
  input                   ps_mst_w_valid_i,
  output                  ps_mst_w_ready_o,
  output [ 15:0]          ps_mst_b_id_o,
  output [ 1:0]           ps_mst_b_resp_o,
  output                  ps_mst_b_valid_o,
  input                   ps_mst_b_ready_i,
  input  [ 15:0]          ps_mst_ar_id_i,
  input  [ 39:0]          ps_mst_ar_addr_i,
  input  [ 7:0]           ps_mst_ar_len_i,
  input  [ 2:0]           ps_mst_ar_size_i,
  input  [ 1:0]           ps_mst_ar_burst_i,
  input                   ps_mst_ar_lock_i,
  input  [ 3:0]           ps_mst_ar_cache_i,
  input  [ 2:0]           ps_mst_ar_prot_i,
  input  [ 3:0]           ps_mst_ar_qos_i,
  input  [ 15:0]          ps_mst_ar_user_i, //16 bit
  input                   ps_mst_ar_valid_i,
  output                  ps_mst_ar_ready_o,
  output [ 15:0]          ps_mst_r_id_o,
  output [ 63:0]          ps_mst_r_data_o,
  output [ 1:0]           ps_mst_r_resp_o,
  output                  ps_mst_r_last_o,
  output                  ps_mst_r_valid_o,
  input                   ps_mst_r_ready_i,

  input wire              ref_clk,
  input wire              sys_clk,
  input wire              pad_reset,

  //output soc_clk
  output wire             soc_clk_o,

  // JTAG
  output wire             jtag_tdo_o,
  input wire              jtag_tck_i,
  input wire              jtag_tdi_i,
  input wire              jtag_tms_i,
  input wire              jtag_trst_i,

  // EXT CHIP TP          PADS

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
  inout wire              pad_uart1_pms0_txd

);

  // SIM_STDOUT default is:
  // * `0` for FPGA implementation
  // * `1` for FPGA RTL simulation
  // We use `rtl/pulp/control_pulp_txilzu9eg_vivado.v` for FPGA RTL simulation
  localparam int unsigned SIM_STDOUT = 1;

  // BEHAV_MEM default is:
  // * `0` for FPGA implementation, where we use Xilinx IPs
  // * `1` for FPGA RTL simulation
  // We use `rtl/pulp/control_pulp_txilzu9eg_vivado.v` for FPGA RTL simulation
  localparam int unsigned BEHAV_MEM = 1;

  // FPGA_MEM default is:
  // * `0` for FPGA RTL simulation, where we use behavioral memory model to simulate the FPGA top-level wrapper
  // * `1` for FPGA implementation, where we use Xilinx IPs
  // We use `fpga/control_pulp_txilzu9eg/rtl/control_pulp_txilzu9eg_vivado.v` for FPGA implementation
  localparam int unsigned FPGA_MEM = 0;

  // MACRO_ROM default is:
  // * `0` for both FPGA implementation and FPGA RTL simulation
  // We use `rtl/pulp/control_pulp_txilzu9eg_vivado.v` for FPGA RTL simulation
  localparam int unsigned MACRO_ROM = 0;

  // USE_CLUSTER default is 1
  localparam int unsigned USE_CLUSTER = 1;

  // DMA_TYPE default is:
  // * `1` for idma (new)
  // alternative is `0` for mchan (legacy)
  localparam int unsigned DMA_TYPE = 1;

 control_pulp_fpga #(
    .CORE_TYPE(0),
    .RISCY_FPU(1),
    .USE_HWPE(0),
    .SIM_STDOUT(SIM_STDOUT),
    .BEHAV_MEM(BEHAV_MEM),
    .FPGA_MEM(FPGA_MEM),
    .MACRO_ROM(MACRO_ROM),
    .USE_CLUSTER(USE_CLUSTER),
    .DMA_TYPE(DMA_TYPE)
  ) i_control_pulp_fpga (

    // PS slave
    .ps_slv_aw_id_o            ( ps_slv_aw_id_o            ),
    .ps_slv_aw_addr_o          ( ps_slv_aw_addr_o          ),
    .ps_slv_aw_len_o           ( ps_slv_aw_len_o           ),
    .ps_slv_aw_size_o          ( ps_slv_aw_size_o          ),
    .ps_slv_aw_burst_o         ( ps_slv_aw_burst_o         ),
    .ps_slv_aw_lock_o          ( ps_slv_aw_lock_o          ),
    .ps_slv_aw_cache_o         ( ps_slv_aw_cache_o         ),
    .ps_slv_aw_prot_o          ( ps_slv_aw_prot_o          ),
    .ps_slv_aw_qos_o           ( ps_slv_aw_qos_o           ),
    .ps_slv_aw_region_o        (                           ),
    .ps_slv_aw_atop_o          ( ps_slv_aw_atop_o          ),
    .ps_slv_aw_user_o          ( ps_slv_aw_user_o          ),
    .ps_slv_aw_valid_o         ( ps_slv_aw_valid_o         ),
    .ps_slv_aw_ready_i         ( ps_slv_aw_ready_i         ),
    .ps_slv_w_data_o           ( ps_slv_w_data_o           ),
    .ps_slv_w_strb_o           ( ps_slv_w_strb_o           ),
    .ps_slv_w_last_o           ( ps_slv_w_last_o           ),
    .ps_slv_w_user_o           (                           ),
    .ps_slv_w_valid_o          ( ps_slv_w_valid_o          ),
    .ps_slv_w_ready_i          ( ps_slv_w_ready_i          ),
    .ps_slv_b_id_i             ( ps_slv_b_id_i             ),
    .ps_slv_b_resp_i           ( ps_slv_b_resp_i           ),
    .ps_slv_b_user_i           (                           ),
    .ps_slv_b_valid_i          ( ps_slv_b_valid_i          ),
    .ps_slv_b_ready_o          ( ps_slv_b_ready_o          ),
    .ps_slv_ar_id_o            ( ps_slv_ar_id_o            ),
    .ps_slv_ar_addr_o          ( ps_slv_ar_addr_o          ),
    .ps_slv_ar_len_o           ( ps_slv_ar_len_o           ),
    .ps_slv_ar_size_o          ( ps_slv_ar_size_o          ),
    .ps_slv_ar_burst_o         ( ps_slv_ar_burst_o         ),
    .ps_slv_ar_lock_o          ( ps_slv_ar_lock_o          ),
    .ps_slv_ar_cache_o         ( ps_slv_ar_cache_o         ),
    .ps_slv_ar_prot_o          ( ps_slv_ar_prot_o          ),
    .ps_slv_ar_qos_o           ( ps_slv_ar_qos_o           ),
    .ps_slv_ar_region_o        (                           ),
    .ps_slv_ar_user_o          ( ps_slv_ar_user_o          ),
    .ps_slv_ar_valid_o         ( ps_slv_ar_valid_o         ),
    .ps_slv_ar_ready_i         ( ps_slv_ar_ready_i         ),
    .ps_slv_r_id_i             ( ps_slv_r_id_i             ),
    .ps_slv_r_data_i           ( ps_slv_r_data_i           ),
    .ps_slv_r_resp_i           ( ps_slv_r_resp_i           ),
    .ps_slv_r_last_i           ( ps_slv_r_last_i           ),
    .ps_slv_r_user_i           (                           ),
    .ps_slv_r_valid_i          ( ps_slv_r_valid_i          ),
    .ps_slv_r_ready_o          ( ps_slv_r_ready_o          ),

    // PS master
    .ps_mst_aw_id_i            ( ps_mst_aw_id_i            ),
    .ps_mst_aw_addr_i          ( ps_mst_aw_addr_i          ),
    .ps_mst_aw_len_i           ( ps_mst_aw_len_i           ),
    .ps_mst_aw_size_i          ( ps_mst_aw_size_i          ),
    .ps_mst_aw_burst_i         ( ps_mst_aw_burst_i         ),
    .ps_mst_aw_lock_i          ( ps_mst_aw_lock_i          ),
    .ps_mst_aw_cache_i         ( ps_mst_aw_cache_i         ),
    .ps_mst_aw_prot_i          ( ps_mst_aw_prot_i          ),
    .ps_mst_aw_qos_i           ( ps_mst_aw_qos_i           ),
    .ps_mst_aw_region_i        (                           ),
    .ps_mst_aw_atop_i          ( ps_mst_aw_atop_i          ),
    .ps_mst_aw_user_i          ( ps_mst_aw_user_i          ),
    .ps_mst_aw_valid_i         ( ps_mst_aw_valid_i         ),
    .ps_mst_aw_ready_o         ( ps_mst_aw_ready_o         ),
    .ps_mst_w_data_i           ( ps_mst_w_data_i           ),
    .ps_mst_w_strb_i           ( ps_mst_w_strb_i           ),
    .ps_mst_w_last_i           ( ps_mst_w_last_i           ),
    .ps_mst_w_user_i           (                           ),
    .ps_mst_w_valid_i          ( ps_mst_w_valid_i          ),
    .ps_mst_w_ready_o          ( ps_mst_w_ready_o          ),
    .ps_mst_b_id_o             ( ps_mst_b_id_o             ),
    .ps_mst_b_resp_o           ( ps_mst_b_resp_o           ),
    .ps_mst_b_user_o           (                           ),
    .ps_mst_b_valid_o          ( ps_mst_b_valid_o          ),
    .ps_mst_b_ready_i          ( ps_mst_b_ready_i          ),
    .ps_mst_ar_id_i            ( ps_mst_ar_id_i            ),
    .ps_mst_ar_addr_i          ( ps_mst_ar_addr_i          ),
    .ps_mst_ar_len_i           ( ps_mst_ar_len_i           ),
    .ps_mst_ar_size_i          ( ps_mst_ar_size_i          ),
    .ps_mst_ar_burst_i         ( ps_mst_ar_burst_i         ),
    .ps_mst_ar_lock_i          ( ps_mst_ar_lock_i          ),
    .ps_mst_ar_cache_i         ( ps_mst_ar_cache_i         ),
    .ps_mst_ar_prot_i          ( ps_mst_ar_prot_i          ),
    .ps_mst_ar_qos_i           ( ps_mst_ar_qos_i           ),
    .ps_mst_ar_region_i        (                           ),
    .ps_mst_ar_user_i          ( ps_mst_ar_user_i          ),
    .ps_mst_ar_valid_i         ( ps_mst_ar_valid_i         ),
    .ps_mst_ar_ready_o         ( ps_mst_ar_ready_o         ),
    .ps_mst_r_id_o             ( ps_mst_r_id_o             ),
    .ps_mst_r_data_o           ( ps_mst_r_data_o           ),
    .ps_mst_r_resp_o           ( ps_mst_r_resp_o           ),
    .ps_mst_r_last_o           ( ps_mst_r_last_o           ),
    .ps_mst_r_user_o           (                           ),
    .ps_mst_r_valid_o          ( ps_mst_r_valid_o          ),
    .ps_mst_r_ready_i          ( ps_mst_r_ready_i          ),

    .soc_clk_o                 ( soc_clk_o                 ), // clocks SoC, AXI

    .ref_clk_i                 ( ref_clk                   ),
    .sys_clk_i                 ( sys_clk                   ), // unconnected for FPGA
    .rst_ni                    ( pad_reset                 ), //active_low
    .bootsel_valid_i           ( 1'b0                      ), //0 -> memory-mapped reg
    .bootsel_i                 ( 2'b0                      ), //has no effect if bootsel_valid == 0
    .fc_fetch_en_valid_i       ( 1'b0                      ), //0 -> memory-mapped reg
    .fc_fetch_en_i             ( 1'b0                      ), //has no effect if fetch_en_valid == 0

    .jtag_tdo_o,
    .jtag_tck_i,
    .jtag_tdi_i,
    .jtag_tms_i,
    .jtag_trst_i,

     // Ignore watchdog timer
    .wdt_alert_o               (),
    .wdt_alert_clear_i         ( 1'b0                      ),

    // EXT CHIP TP                 PADS
    .pad_pmb_vr1_pms0_sda          ( pad_pmb_vr1_pms0_sda          ),
    .pad_pmb_vr1_pms0_scl          ( pad_pmb_vr1_pms0_scl          ),
    .pad_pmb_vr1_pms0_alert_n      ( pad_pmb_vr1_pms0_alert_n      ),
    .pad_pmb_vr2_pms0_sda          ( pad_pmb_vr2_pms0_sda          ),
    .pad_pmb_vr2_pms0_scl          ( pad_pmb_vr2_pms0_scl          ),
    .pad_pmb_vr2_pms0_alert_n      ( pad_pmb_vr2_pms0_alert_n      ),
    .pad_pmb_vr3_pms0_sda          ( pad_pmb_vr3_pms0_sda          ),
    .pad_pmb_vr3_pms0_scl          ( pad_pmb_vr3_pms0_scl          ),
    .pad_pmb_vr3_pms0_alert_n      ( pad_pmb_vr3_pms0_alert_n      ),
    .pad_pmb_pol1_pms0_sda         ( pad_pmb_pol1_pms0_sda         ),
    .pad_pmb_pol1_pms0_scl         ( pad_pmb_pol1_pms0_scl         ),
    .pad_pmb_pol1_pms0_alert_n     ( pad_pmb_pol1_pms0_alert_n     ),
    .pad_pmb_ibc_pms0_sda          ( pad_pmb_ibc_pms0_sda          ),
    .pad_pmb_ibc_pms0_scl          ( pad_pmb_ibc_pms0_scl          ),
    .pad_pmb_ibc_pms0_alert_n      ( pad_pmb_ibc_pms0_alert_n      ),
    .pad_i2c2_pms0_sda             ( pad_i2c2_pms0_sda             ),
    .pad_i2c2_pms0_scl             ( pad_i2c2_pms0_scl             ),
    .pad_i2c2_pms0_smbalert_n      ( pad_i2c2_pms0_smbalert_n      ),
    .pad_i2c3_pms0_sda             ( pad_i2c3_pms0_sda             ),
    .pad_i2c3_pms0_scl             ( pad_i2c3_pms0_scl             ),
    .pad_i2c3_pms0_smbalert_n      ( pad_i2c3_pms0_smbalert_n      ),
    .pad_i2c4_pms0_sda             ( pad_i2c4_pms0_sda             ),
    .pad_i2c4_pms0_scl             ( pad_i2c4_pms0_scl             ),
    .pad_i2c4_pms0_smbalert_n      ( pad_i2c4_pms0_smbalert_n      ),
    .pad_i2c5_pms0_sda             ( pad_i2c5_pms0_sda             ),
    .pad_i2c5_pms0_scl             ( pad_i2c5_pms0_scl             ),
    .pad_i2c5_pms0_smbalert_n      ( pad_i2c5_pms0_smbalert_n      ),
    .pad_i2c6_pms0_slv_sda         ( pad_i2c6_pms0_slv_sda         ),
    .pad_i2c6_pms0_slv_scl         ( pad_i2c6_pms0_slv_scl         ),
    .pad_i2c7_pms0_sda             ( pad_i2c7_pms0_sda             ),
    .pad_i2c7_pms0_scl             ( pad_i2c7_pms0_scl             ),
    .pad_pms0_pms1_smbalert_n      ( pad_pms0_pms1_smbalert_n      ),
    .pad_pms_avs_clk_vr1           ( pad_pms_avs_clk_vr1           ),
    .pad_pms_avs_mdata_vr1         ( pad_pms_avs_mdata_vr1         ),
    .pad_pms_avs_sdata_vr1         ( pad_pms_avs_sdata_vr1         ),
    .pad_pms_avs_clk_vr2           ( pad_pms_avs_clk_vr2           ),
    .pad_pms_avs_mdata_vr2         ( pad_pms_avs_mdata_vr2         ),
    .pad_pms_avs_sdata_vr2         ( pad_pms_avs_sdata_vr2         ),
    .pad_pms_avs_clk_vr3           ( pad_pms_avs_clk_vr3           ),
    .pad_pms_avs_mdata_vr3         ( pad_pms_avs_mdata_vr3         ),
    .pad_pms_avs_sdata_vr3         ( pad_pms_avs_sdata_vr3         ),
    .pad_pms_avs_clk_ibc           ( pad_pms_avs_clk_ibc           ),
    .pad_pms_avs_mdata_ibc         ( pad_pms_avs_mdata_ibc         ),
    .pad_pms_avs_sdata_ibc         ( pad_pms_avs_sdata_ibc         ),
    .pad_pms_bios_spi_cs0_n        ( pad_pms_bios_spi_cs0_n        ),
    .pad_pms_bios_spi_clk          ( pad_pms_bios_spi_clk          ),
    .pad_pms_bios_spi_io0          ( pad_pms_bios_spi_io0          ),
    .pad_pms_bios_spi_io1          ( pad_pms_bios_spi_io1          ),
    .pad_pms_bios_spi_io2          ( pad_pms_bios_spi_io2          ),
    .pad_pms_bios_spi_io3          ( pad_pms_bios_spi_io3          ),
    .pad_pms0_pms1_spi_cs_n        ( pad_pms0_pms1_spi_cs_n        ),
    .pad_pms0_pms1_spi_clk         ( pad_pms0_pms1_spi_clk         ),
    .pad_pms0_pms1_spi_miso        ( pad_pms0_pms1_spi_miso        ),
    .pad_pms0_pms1_spi_mosi        ( pad_pms0_pms1_spi_mosi        ),
    .pad_uart1_pms0_rxd            ( pad_uart1_pms0_rxd            ),
    .pad_uart1_pms0_txd            ( pad_uart1_pms0_txd            ),
    .pad_pms0_slp_s3_n             ( pad_pms0_slp_s3_n             ),
    .pad_pms0_slp_s4_n             ( pad_pms0_slp_s4_n             ),
    .pad_pms0_slp_s5_n             ( pad_pms0_slp_s5_n             ),
    .pad_pms0_sys_reset_n          ( pad_pms0_sys_reset_n          ),
    .pad_pms0_sys_rsmrst_n         ( pad_pms0_sys_rsmrst_n         ),
    .pad_pms0_sys_pwgd_in          ( pad_pms0_sys_pwgd_in          ),
    .pad_pms0_pwr_btn_n            ( pad_pms0_pwr_btn_n            ),
    .pad_pms0_pwgd_out             ( pad_pms0_pwgd_out             ),
    .pad_pms0_throttle_0           ( pad_pms0_throttle_0           ),
    .pad_pms0_throttle_1           ( pad_pms0_throttle_1           ),
    .pad_pms0_thermtrip_n          ( pad_pms0_thermtrip_n          ),
    .pad_pms0_errcode_0            ( pad_pms0_errcode_0            ),
    .pad_pms0_errcode_1            ( pad_pms0_errcode_1            ),
    .pad_pms0_errcode_2            ( pad_pms0_errcode_2            ),
    .pad_pms0_errcode_3            ( pad_pms0_errcode_3            ),
    .pad_pms0_reset_out_n          ( pad_pms0_reset_out_n          ),
    .pad_pms0_socket_id_0          ( pad_pms0_socket_id_0          ),
    .pad_pms0_socket_id_1          ( pad_pms0_socket_id_1          ),
    .pad_pms0_strap_0              ( pad_pms0_strap_0              ),
    .pad_pms0_strap_1              ( pad_pms0_strap_1              ),
    .pad_pms0_strap_2              ( pad_pms0_strap_2              ),
    .pad_pms0_strap_3              ( pad_pms0_strap_3              )

);

endmodule

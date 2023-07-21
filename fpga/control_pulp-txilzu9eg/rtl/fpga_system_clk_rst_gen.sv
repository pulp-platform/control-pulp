// Copyright 2023 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// This module generates the clocks for ControlPULP in different use-cases:
// 1. External clocks: two external clocks generates soc, cluster, peripheral and
//    timer clocks.
//    Used with ControlPULP  IP.

// 2. External clocks, FPGA map: a reference clock feeds Xilinx clock generators,
//    which generate soc, cluster, periph and timer clocks.
//    Used for ControlPULP on FPGA.

`include "pulp_soc_defines.sv"

module fpga_system_clk_rst_gen (
  input logic  sys_clk_i,
  input logic  ref_clk_i,
  input logic  clk_sel_i,

  input logic  rstn_glob_i,
  output logic rstn_soc_sync_o,
  output logic rstn_cluster_sync_o,

  input logic  test_mode_i,

  APB_BUS.Slave apb_slave,

  output logic clk_soc_o,
  output logic clk_per_o,
  output logic clk_slow_o,  // 32 kHz reference for timer
  output logic clk_cluster_o
);

  logic s_clk_soc;
  logic s_clk_per;
  logic s_clk_cluster;
  logic s_clk_slow;

  logic s_clk_for_soc;
  logic s_clk_for_per;
  logic s_clk_for_cluster;
  logic s_clk_for_slow;

  logic s_rstn_soc;

  logic s_rstn_soc_sync;
  logic s_rstn_cluster_sync;


  // FPGA clock generation

  // Use FPGA dependent clock generation module for both clocks
  // For the FPGA port we remove the clock multiplexers since it doesn't make
  // much sense to clock the circuit directly with the board reference clock
  // (e.g. 200MHz for genesys2 board).

  fpga_clk_gen i_fpga_clk_gen (
    .ref_clk_i,
    .rstn_glob_i,
    .soc_clk_o(s_clk_for_soc),
    .per_clk_o(s_clk_for_per)
  );

  // Don't use the supplied clock directly for the FPGA target. On some boards
  // the reference clock is a very fast (e.g. 200MHz) clock that cannot be used
  // directly as the "slow_clk". Therefore we slow it down if a FPGA/board
  // dependent module fpga_slow_clk_gen. Dividing the fast reference clock
  // internally instead of doing so in the toplevel prevents unecessary clock
  // division just to generate a faster clock once again in the SoC and
  // Peripheral clock PLLs in soc_domain.sv. Instead all PLL use directly the
  // board reference clock as input.

  fpga_slow_clk_gen i_slow_clk_gen (
    .rst_ni    (rstn_glob_i),
    .ref_clk_i (ref_clk_i),
    .slow_clk_o(s_clk_slow)
  );


  assign s_clk_soc     = s_clk_for_soc;
  assign s_clk_cluster = s_clk_for_soc;  // We use the same clock for FC and Cluster on FPGA
  assign s_clk_per     = s_clk_for_per;


  // Reset just routed through
  assign s_rstn_soc          = rstn_glob_i;
  assign s_rstn_soc_sync     = s_rstn_soc;
  assign s_rstn_cluster_sync = s_rstn_soc;

  // Output assignment
  assign clk_soc_o           = s_clk_soc;
  assign clk_per_o           = s_clk_per;
  assign clk_cluster_o       = s_clk_cluster;
  assign clk_slow_o          = s_clk_slow;

  assign rstn_soc_sync_o     = s_rstn_soc_sync;
  assign rstn_cluster_sync_o = s_rstn_cluster_sync;

endmodule  // system_clk_rst_gen

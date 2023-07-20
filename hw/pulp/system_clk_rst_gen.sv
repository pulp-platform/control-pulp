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
//    timer clocks via clock dividers.
//    Used with ControlPULP  IP.

// 2. External clocks, FPGA map: a reference clock feeds Xilinx clock generators,
//    which generate soc, cluster, periph and timer clocks.
//    Used for ControlPULP on FPGA.

`include "pulp_soc_defines.sv"

module system_clk_rst_gen (
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

  logic clk_soc;
  logic clk_per;
  logic clk_cluster;
  logic clk_slow;
  logic clk_for_slow;


  logic rstn_soc;
  logic rstn_soc_sync;
  logic rstn_cluster_sync;


  // Clock generation with external clocks

`ifndef SYNTHESIS
`ifdef DEBUG_CLK_RST_GEN
    //synopsys translate_off
    freq_meter #(.FLL_NAME("soc_freq"),     .MAX_SAMPLE(4096)) SOC_METER (.clk(s_clk_for_soc));
    freq_meter #(.FLL_NAME("per_freq"),     .MAX_SAMPLE(4096)) PER_METER (.clk(s_clk_for_per));
    freq_meter #(.FLL_NAME("cluster_freq"), .MAX_SAMPLE(4096)) CLUSTER_METER (.clk(s_clk_for_cluster));
    //synopsys translate_on
`endif
`endif

`ifndef SYNTHESIS
  // Make sure we are not using FLLs
  assert property (@(posedge sys_clk_i)
        !(apb_slave.psel == 1'b1
         && apb_slave.penable == 1'b1
         && (apb_slave.paddr[11:0] >= 12'h0 && apb_slave.paddr[11:0] <= 12'h30)))
  else $info("[system_clk_rst_gen]  %t - Detected legacy FLL program request", $time);

  // Make sure we are not programming clkdiv (removed)
  assert property (@(posedge sys_clk_i)
        !(apb_slave.psel == 1'b1
         && apb_slave.penable == 1'b1
         && (apb_slave.paddr[11:0] >= 12'hf00 && apb_slave.paddr[11:0] <= 12'hf10)))
  else $info("[system_clk_rst_gen]  %t - Detected legacy CLKDIV program request", $time);

`endif

  assign apb_slave.prdata  = '0;
  assign apb_slave.pready = 1'b1;

  // We don't support pslverr. At some point this should be routed to an
  // interrupt.
  assign apb_slave.pslverr = 1'b0;


  // ref_clk -> divider -> 32 Khz timer clock
  // fixed division by integer factor
  clk_div #(
    .RATIO(3125)  // TODO: ADJUST RATIO to match ref clk
                  // 100 Mhz / 32 Khz = 3125
  ) i_clk_div_timer (
    .clk_i     (ref_clk_i),
    .rst_ni    (rstn_glob_i),
    .testmode_i(test_mode_i),
    .en_i      (1'b1),           // TODO: maybe we can map this to reg
    .clk_o     (clk_for_slow)
  );

  // Allow clock muxing if dividers are faulty: ref_clk passthrough
  pulp_clock_mux2 i_clk_mux_soc (
    .clk0_i   (sys_clk_i),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (clk_soc)
  );

  // No muxing required since we need a stable clock for the peripherals
  assign clk_per = ref_clk_i;

  pulp_clock_mux2 i_clk_mux_cluster (
    .clk0_i   (sys_clk_i),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (clk_cluster)
  );

  pulp_clock_mux2 i_clk_mux_slow (
    .clk0_i   (clk_for_slow),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (clk_slow)
  );

  // Reset synchronization
  assign rstn_soc = rstn_glob_i;

  rstgen i_soc_rstgen (
    .clk_i (clk_soc_o),
    .rst_ni(rstn_soc),
    .test_mode_i,
    .rst_no (rstn_soc_sync),  // to be used by logic clocked with ref clock in AO domain
    .init_no()                // not used
  );


  rstgen i_cluster_rstgen (
    .clk_i (clk_cluster_o),
    .rst_ni(rstn_soc),
    .test_mode_i,
    .rst_no (rstn_cluster_sync),  // to be used by logic clocked with ref clock in AO domain
    .init_no()                    // not used
  );

  // Output assignment
  assign clk_soc_o           = clk_soc;
  assign clk_per_o           = clk_per;
  assign clk_cluster_o       = clk_cluster;
  assign clk_slow_o          = clk_slow;

  assign rstn_soc_sync_o     = rstn_soc_sync;
  assign rstn_cluster_sync_o = rstn_cluster_sync;

endmodule  // system_clk_rst_gen

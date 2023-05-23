// Copyright 2018 ETH Zurich and University of Bologna.
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

module system_clk_rst_gen #(
  parameter int unsigned USE_CLUSTER = 1
)
(
  input logic  sys_clk_i,
  input logic  ref_clk_i,
  input logic  test_clk_i,
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


  // Clocks
`ifndef PULP_FPGA_EMUL

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

  // Make sure we are not using FLLs
`ifndef SYNTHESIS
  assert property (@(posedge sys_clk_i)
        !(apb_slave.psel == 1'b1
         && apb_slave.penable == 1'b1
         && (apb_slave.paddr[11:0] >= 12'h0 && apb_slave.paddr[11:0] <= 12'h30)))
  else $info("[system_clk_rst_gen]  %t - Detected legacy FLL program request", $time);
`endif

  typedef enum logic [1:0] {
    SOC_APB_IDLE,
    SOC_APB_REQ,
    SOC_APB_ACK,
    SOC_APB_READY
  } from_soc_state_e;

  from_soc_state_e from_soc_state_q, from_soc_state_d;

  logic four_req;
  logic four_ack;

  logic [7:0]
    soc_pwdata_q,
    soc_pwdata_d,
    soc_prdata_q,
    soc_prdata_d,
    soc_clk_div,
    cluster_clk_div,
    periph_clk_div;
  logic soc_pwrite_q, soc_pwrite_d;
  logic [11:0] soc_paddr_q, soc_paddr_d;

  // Accept the APB request in the soc clock domain and do a four-phase
  // handshake (req, ack) with the state machine doing the communication with
  // the clock dividers which live in the sys clock domain. These clock
  // domains are synchronous so we don't need to deal with metastability,
  // just that we might miss transactions due to the different sampling rate
  // of signals


  // Note that the apb requests that are incoming are not fully apb compliant:
  // they raise penable concurrently with psel/pwrite/pwdata instead of
  // delying it by one cycle. This forces us to start or logic only when psel
  // and penable are concurrently asserted.
  always_comb begin
    // Note: Don't use default assignments for four_req, instead do the
    // assignment in the states. This is because some simulators, while
    // executing the always_comb block, treat the default assignment and the
    // subsequent (potential) override of the value in the state as "event"
    // that wakes other always_comb blocks that are sensitive to it. If you
    // do this default assignment state in two always_comb blocks then you
    // get a "fake" combinatory loop.
    // four_req = 1'b0; <- tl;dr: don't do this

    soc_pwdata_d     = soc_pwdata_q;
    soc_pwrite_d     = soc_pwrite_q;
    soc_paddr_d      = soc_paddr_q;

    from_soc_state_d = from_soc_state_q;
    apb_slave.pready = 1'b0;

    unique case (from_soc_state_q)
      SOC_APB_IDLE: begin
        four_req = 1'b0;
        if (apb_slave.psel && apb_slave.penable) begin
          // sample apb request
          from_soc_state_d = SOC_APB_REQ;
          soc_pwdata_d     = apb_slave.pwdata[7:0];  // clock div supports
                                                     // 8 bit div value
          soc_pwrite_d     = apb_slave.pwrite;
          soc_paddr_d      = apb_slave.paddr[11:0];  //
        end
      end
      SOC_APB_REQ: begin
        four_req = 1'b1;
        if (four_ack) from_soc_state_d = SOC_APB_ACK;
      end
      SOC_APB_ACK: begin
        four_req = 1'b0;
        if (!four_ack) from_soc_state_d = SOC_APB_READY;
      end
      SOC_APB_READY: begin
        four_req         = 1'b0;
        apb_slave.pready = 1'b1;  // pulse for one cycle
        from_soc_state_d = SOC_APB_IDLE;
      end
      default: four_req = 1'b0;
    endcase  // unique case (from_soc_state_q)
  end

  // in soc clock domain
  always_ff @(posedge clk_soc_o, negedge rstn_glob_i) begin
    if (!rstn_glob_i) begin
      from_soc_state_q <= SOC_APB_IDLE;
      soc_pwdata_q     <= '0;
      soc_prdata_q     <= '0;
      soc_pwrite_q     <= '0;
      soc_paddr_q      <= '0;
    end else begin
      from_soc_state_q <= from_soc_state_d;
      soc_pwdata_q     <= soc_pwdata_d;
      soc_prdata_q     <= soc_prdata_d;
      soc_pwrite_q     <= soc_pwrite_d;
      soc_paddr_q      <= soc_paddr_d;
    end
  end


  // global address map
  // CLK_CTRL_START_ADDR      32'h1A10_0000
  // CLK_CTRL_END_ADDR        32'h1A10_0FFF
  // register offsets
  // 12'f00 - soc clk div value
  // 12'f08 - cluster clk div value
  // 12'f10 - periph clk div value

  logic soc_div_access, soc_div_valid, soc_div_ready;
  logic cluster_div_access, cluster_div_valid, cluster_div_ready;
  logic periph_div_access, periph_div_valid, periph_div_ready;
  logic dummy_access;

  typedef enum logic [1:0] {
    CLK_DIV_IDLE,
    CLK_DIV_REQ,
    CLK_DIV_ACK
  } clk_div_state_e;

  clk_div_state_e clk_div_state_q, clk_div_state_d;

  // address decoder
  always_comb begin
    soc_div_access     = 1'b0;
    cluster_div_access = 1'b0;
    periph_div_access  = 1'b0;

    dummy_access       = 1'b0;

    if (apb_slave.psel && apb_slave.penable) begin
      unique case (apb_slave.paddr[11:0])
        12'hf00: soc_div_access = 1'b1;
        12'hf08:
          if (USE_CLUSTER)
            cluster_div_access = 1'b1;
          else
            dummy_access = 1'b1;
        12'hf10: periph_div_access = 1'b1;
        default: dummy_access = 1'b1;  // slverr is not supported so we
                                       // have to complete any write
                                       // request.
      endcase  // unique case (apb_slave.paddr)
    end
  end

  // Access clock dividers. This is the other part of the four phase handshake
  // that lives in the soc clock domain.
  always_comb begin
    soc_div_valid     = 1'b0;
    cluster_div_valid = 1'b0;
    periph_div_valid  = 1'b0;

    soc_prdata_d      = '0;

    clk_div_state_d   = clk_div_state_q;

    unique case (clk_div_state_q)
      CLK_DIV_IDLE: begin
        four_ack = 1'b0;

        if (four_req) clk_div_state_d = CLK_DIV_REQ;
      end
      CLK_DIV_REQ: begin
        four_ack = 1'b0;

        if (soc_pwrite_q) begin
          // handle writes
          if (soc_div_access) soc_div_valid = 1'b1;
          if (cluster_div_access) cluster_div_valid = 1'b1;
          if (periph_div_access) periph_div_valid = 1'b1;

          if (soc_div_ready || cluster_div_ready || periph_div_ready || dummy_access)
            clk_div_state_d = CLK_DIV_ACK;
        end else begin  // if (soc_pwrite_q)
          // handle reads
          if (soc_div_access) soc_prdata_d = soc_clk_div;
          else if (cluster_div_access) soc_prdata_d = cluster_clk_div;
          else if (periph_div_access) soc_prdata_d = periph_clk_div;

          clk_div_state_d = CLK_DIV_ACK;
        end
      end
      CLK_DIV_ACK: begin
        four_ack = 1'b1;

        if (!four_req) clk_div_state_d = CLK_DIV_IDLE;
      end
      default: four_ack = 1'b0;
    endcase  // unique case (clk_div_state_q)
  end

  // in sys clock domain
  always_ff @(posedge sys_clk_i, negedge rstn_glob_i) begin
    if (!rstn_glob_i) begin
      clk_div_state_q <= CLK_DIV_IDLE;
    end else begin
      clk_div_state_q <= clk_div_state_d;
    end
  end

  assign apb_slave.prdata  = soc_prdata_q;

  // We don't support pslverr. At some point this should be routed to an
  // interrupt.
  assign apb_slave.pslverr = 1'b0;


  // sys_clk -> divider -> soc
  clock_divider #(
    .DIV_INIT   (0),
    .BYPASS_INIT(1)
  ) i_soc_clk_divider (
    .clk_i           (sys_clk_i),
    .rstn_i          (rstn_glob_i),
    .test_mode_i     (test_mode_i),
    .clk_gate_async_i(1'b1),           // TODO: maybe we can map this to reg
    .clk_div_data_i  (soc_pwdata_q),
    .clk_div_valid_i (soc_div_valid),
    .clk_div_ack_o   (soc_div_ready),
    .clk_div_data_o  (soc_clk_div),
    .clk_o           (s_clk_for_soc)
  );

  if (USE_CLUSTER) begin
  // sys_clk -> divider -> cluster
  clock_divider #(
    .DIV_INIT   (0),
    .BYPASS_INIT(1)
  ) i_cluster_clk_divider (
    .clk_i           (sys_clk_i),
    .rstn_i          (rstn_glob_i),
    .test_mode_i     (test_mode_i),
    .clk_gate_async_i(1'b1),               // TODO: maybe we map this to reg
    .clk_div_data_i  (soc_pwdata_q),
    .clk_div_valid_i (cluster_div_valid),
    .clk_div_ack_o   (cluster_div_ready),
    .clk_div_data_o  (cluster_clk_div),
    .clk_o           (s_clk_for_cluster)
  );
  end // else: !if(USE_CLUSTER)

  // ref_clk -> divider -> peripherals
  clock_divider #(
    .DIV_INIT   (0),
    .BYPASS_INIT(1)
  ) i_periph_clk_divider (
    .clk_i           (ref_clk_i),
    .rstn_i          (rstn_glob_i),
    .test_mode_i     (test_mode_i),
    .clk_gate_async_i(1'b1),              // TODO: maybe we map this to reg
    .clk_div_data_i  (soc_pwdata_q),      // 8 bit might not be enough for periph
    .clk_div_valid_i (periph_div_valid),
    .clk_div_ack_o   (periph_div_ready),
    .clk_div_data_o  (periph_clk_div),
    .clk_o           (s_clk_for_per)
  );

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
    .clk_o     (s_clk_for_slow)
  );

  // Allow clock muxing if dividers are faulty: ref_clk passthrough
  pulp_clock_mux2 clk_mux_soc_i (
    .clk0_i   (s_clk_for_soc),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (s_clk_soc)
  );

  pulp_clock_mux2 clk_mux_per_i (
    .clk0_i   (s_clk_for_per),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (s_clk_per)
  );

  pulp_clock_mux2 clk_mux_cluster_i (
    .clk0_i   (s_clk_for_cluster),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (s_clk_cluster)
  );

  pulp_clock_mux2 clk_mux_slow_i (
    .clk0_i   (s_clk_for_slow),
    .clk1_i   (ref_clk_i),
    .clk_sel_i,
    .clk_o    (s_clk_slow)
  );

`else  // !`ifndef PULP_FPGA_EMUL

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

  //Don't use the supplied clock directly for the FPGA target. On some boards
  //the reference clock is a very fast (e.g. 200MHz) clock that cannot be used
  //directly as the "slow_clk". Therefore we slow it down if a FPGA/board
  //dependent module fpga_slow_clk_gen. Dividing the fast reference clock
  //internally instead of doing so in the toplevel prevents unecessary clock
  //division just to generate a faster clock once again in the SoC and
  //Peripheral clock PLLs in soc_domain.sv. Instead all PLL use directly the
  //board reference clock as input.

  fpga_slow_clk_gen i_slow_clk_gen (
    .rst_ni    (rstn_glob_i),
    .ref_clk_i (ref_clk_i),
    .slow_clk_o(s_clk_slow)
  );


  assign s_clk_soc     = s_clk_for_soc;
  assign s_clk_cluster = s_clk_for_soc;  // We use the same clock for FC and Cluster on FPGA
  assign s_clk_per     = s_clk_for_per;

`endif  // !`ifndef PULP_FPGA_EMUL

  // Reset
  assign s_rstn_soc = rstn_glob_i;

`ifndef PULP_FPGA_EMUL
  rstgen i_soc_rstgen (
    .clk_i (clk_soc_o),
    .rst_ni(s_rstn_soc),

    .test_mode_i(test_mode_i),

    .rst_no (s_rstn_soc_sync),  //to be used by logic clocked with ref clock in AO domain
    .init_no()                  //not used
  );
`else
  assign s_rstn_soc_sync = s_rstn_soc;
`endif


`ifndef PULP_FPGA_EMUL
  rstgen i_cluster_rstgen (
    .clk_i (clk_cluster_o),
    .rst_ni(s_rstn_soc),

    .test_mode_i(test_mode_i),

    .rst_no (s_rstn_cluster_sync),  //to be used by logic clocked with ref clock in AO domain
    .init_no()                      //not used
  );
`else
  assign s_rstn_cluster_sync = s_rstn_soc;
`endif

  // Output assignment
  assign clk_soc_o           = s_clk_soc;
  assign clk_per_o           = s_clk_per;
  assign clk_cluster_o       = s_clk_cluster;
  assign clk_slow_o          = s_clk_slow;

  assign rstn_soc_sync_o     = s_rstn_soc_sync;
  assign rstn_cluster_sync_o = s_rstn_cluster_sync;

endmodule  // system_clk_rst_gen

// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Antonio Mastrandrea (a.mastrandrea@unibo.it)

module wdt #(
  parameter APB_ADDR_WIDTH = 12
) (
  input logic                      clk_i,
  input logic                      rst_ni,

  // single cycle pulse when wdt overflows (edge sensitive interrupt)
  output logic                     wdt_rst_o,
  // sticky alert when wdt overflow
  output logic                     alert_o,
  // clear sticky alert
  input logic                      alert_clear_i,

  input logic                      hclk_i,
  input logic                      hreset_ni,
  input logic [APB_ADDR_WIDTH-1:0] paddr_i,
  input logic [31:0]               pwdata_i,
  input logic                      pwrite_i,
  input logic                      psel_i,
  input logic                      penable_i,
  output logic [31:0]              prdata_o,
  output logic                     pready_o,
  output logic                     pslverr_o
);

  // registers
  localparam logic [APB_ADDR_WIDTH-1:0] CONFIG_WDT    = 4'h0;
  localparam logic [APB_ADDR_WIDTH-1:0] INIT_VALUE    = 4'h4;
  localparam logic [APB_ADDR_WIDTH-1:0] COUNTER_VALUE = 4'h8;
  localparam logic [APB_ADDR_WIDTH-1:0] ALERT_WDT     = 4'hc;

  // config register
  localparam int unsigned ENABLE_BIT      = 'd0;
  localparam int unsigned CLEAR_BIT       = 'd1;
  localparam int unsigned CLK_SELECT_BIT  = 'd2;
  localparam int unsigned SCALER_BIT      = 'd3;

  // alert register (read or alert_clear signal clears)
  localparam int unsigned ALERT_BIT       = 'd0;

  logic [31:0] init_value;
  logic        enable;
  logic        clear;
  logic        alert_clear, read_alert_clear;
  logic [31:0] outv;
  logic        out_ovf;

  // SCALER TODO

  // counter
  counter_wdt i_counter_wdt (
    .clk_i,
    .rst_ni,
    .init_value_i    ( init_value ),
    .enable_i        ( enable     ),
    .clear_i         ( clear      ),
    .counter_value_o ( outv       )
  );

  // overflow detect
  ovf_detect i_ovf_detect (
    .clk_i,
    .rst_ni,
    .pres_counter_i  ( outv       ),
    .ovfwdt_o        ( out_ovf    )
  );


  assign wdt_rst_o = out_ovf;

  logic        apb_write;
  logic        apb_read;
  logic [3:0]  apb_addr;
  logic [31:0] reg_config;
  logic [31:0] reg_init_value;
  logic [31:0] reg_counter;
  logic [0:0]  reg_alert;

  assign apb_write = psel_i && penable_i && pwrite_i;
  assign apb_read  = psel_i && penable_i && !pwrite_i;

  assign apb_addr  = paddr_i[3:0];

  assign reg_counter = outv;
  assign init_value  = reg_init_value;

  assign enable      = reg_config[ENABLE_BIT];
  assign clear       = reg_config[CLEAR_BIT];

  assign alert_clear = alert_clear_i || read_alert_clear;
  assign alert_o     = reg_alert[ALERT_BIT];

  // write
  always_ff @(posedge hclk_i, negedge hreset_ni) begin
    if (~hreset_ni) begin
      reg_config         <= 32'b0; // <-- wdt disable, clear = 0; clk_select =0; scaler = 0;
      reg_init_value     <= 32'h1;
      reg_alert          <= '0;
    end else begin
      if (reg_config[CLEAR_BIT]) begin
        reg_config[CLEAR_BIT] <= 1'b0;
      end

      if (apb_write) begin
        unique case (apb_addr)
          CONFIG_WDT: reg_config     <= pwdata_i;
          INIT_VALUE: reg_init_value <= pwdata_i;
          ALERT_WDT:  reg_alert      <= pwdata_i[0];
          default:;
        endcase
      end

      // clear alert
      if (alert_clear)
        reg_alert[ALERT_BIT] <= 1'b0;

      // sticky alert with high priorty
      if (out_ovf)
        reg_alert[ALERT_BIT] <= 1'b1;
    end
  end

  // read
  always_comb begin
    prdata_o         = '0;
    read_alert_clear = 1'b0;

    if (apb_read) begin
      unique case (apb_addr)
        CONFIG_WDT:    prdata_o = reg_config;
        INIT_VALUE:    prdata_o = reg_init_value;
        COUNTER_VALUE: prdata_o = reg_counter;
        ALERT_WDT: begin
          prdata_o         = 32'(reg_alert);
          read_alert_clear = 1'b1;
        end
        default:       prdata_o = 32'b0;
      endcase
    end
  end

  assign pready_o     = 1'b1;
  assign pslverr_o    = 1'b0;

endmodule

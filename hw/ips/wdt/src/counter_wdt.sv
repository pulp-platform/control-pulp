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

module counter_wdt (
  input logic         clk_i,
  input logic         rst_ni,
  input logic [31:0]  init_value_i,
  input logic         enable_i,
  input logic         clear_i,
  output logic [31:0] counter_value_o
);

  logic [31:0] count;
  logic [31:0] count_mem;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni)
      count_mem <=  32'b0;
    else
      count_mem <= count;
  end

  always_comb begin
    count = count_mem;
    if (clear_i) begin
      count = init_value_i;
    end else begin
      if (enable_i) begin
        count = count_mem + 1;
      end
    end
  end

  assign counter_value_o = count_mem;
endmodule

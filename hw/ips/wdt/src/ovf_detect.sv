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

module ovf_detect (
  input logic        clk_i,
  input logic        rst_ni,
  input logic [31:0] pres_counter_i,
  output logic       ovfwdt_o
);

  logic past_counter;
  logic past2_counter;
  logic ovfwdt_int;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      past_counter  <= 1'b0;
      past2_counter <= 1'b0;
    end else begin
      if (pres_counter_i == 32'hffff_ffff) begin
        past_counter  <= 1'b1;
      end
      if (pres_counter_i == 32'h0000_0000 && past_counter) begin
        past2_counter <= 1'b1;
      end
      if (past_counter && past2_counter) begin
        past_counter  <= 1'b0;
        past2_counter <= 1'b0;
      end
    end
  end


  always_comb begin
    if (past_counter && past2_counter) begin
      ovfwdt_int = 1'b1;
    end else begin
      ovfwdt_int = 1'b0;
    end
  end

  assign ovfwdt_o = ovfwdt_int;
endmodule

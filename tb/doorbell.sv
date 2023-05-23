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

// Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

/* This module mimics the behaviour of a doorbel register
 * It reads a trigger signal and fires an interrupt line accordingly
 * The trigger signal is set in testbench for control-pulp
 * In a real system, it is the value written by the caller in the doorbell register
 */

module doorbell (
  input clk_i,
  input rst_ni,
  input db_trigger_i,
  output irq_o
);

  logic irq_d, irq_q;
  typedef enum logic [1:0] {
    IDLE,
    RING
  } irq_state_e;

  irq_state_e irq_state_d, irq_state_q;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (rst_ni == 1'b0) begin
      irq_q       <= 1'b0;
      irq_state_q <= IDLE;
    end else begin
      irq_q       <= irq_d;
      irq_state_q <= irq_state_d;
    end
  end

  always_comb begin
    irq_d       = 1'b0;  // default: No Interrupt
    irq_state_d = irq_state_q;

    unique case (irq_state_q)
      // we are ready to hand off interrupts
      IDLE:
      if (db_trigger_i) irq_state_d = RING;
      else begin
        irq_state_d = IDLE;
        irq_d       = 1'b0;
      end
      RING: begin
        irq_d = 1'b1;
        if (~db_trigger_i) begin
          irq_state_d = IDLE;
          irq_d       = 1'b0;
        end
      end
      default: irq_state_d = IDLE;
    endcase  // unique case (irq_state_q)
  end  // always_comb

  assign irq_o = irq_q;

endmodule

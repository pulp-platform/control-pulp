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

module i2csend (
    input logic clk_i,
    input logic rst_ni,

    input logic clki2c_i,

    input logic enable_i,
    input logic [7:0] inB_i,
    input logic active_i,

    output logic bitout_o,

    output logic endsendbyte_o
);

  logic delSCL, SCL;
  logic negedgeclki2c;
  logic posedgeclki2c;

  logic endsendbyte;

  enum logic [3:0] {
    SEND,
    WAIT
  }
      CurSt, NexSt;



  assign endsendbyte_o = endsendbyte;

  assign SCL = clki2c_i;

  //negedge i2c clock
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      negedgeclki2c <= 1'b0;

    end else begin
      negedgeclki2c <= delSCL & ~SCL;  //          _____
      // detect        \______
    end
  end


  //posedge i2c clock
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      posedgeclki2c <= 1'b0;

    end else begin
      posedgeclki2c <= ~delSCL & SCL;  //                ______
      // detect   _____/
    end
  end


  // old clk i2c
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      delSCL <= 1'b0;
    end else begin

      delSCL <= SCL;
    end
  end


  logic [7:0] byte2send;
  logic [5:0] count;

  logic bitoutNEW;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      byte2send <= 8'b0;
      count <= 0;
      endsendbyte <= 1'b0;
    end else begin
      if (enable_i) begin
        byte2send <= inB_i;
        count <= 0;
      end else if (CurSt == SEND && posedgeclki2c) begin
        byte2send <= {byte2send[6:0], 1'b0};
        if (count < 8) begin
          count <= count + 1;
        end else begin
          count <= 0;
          endsendbyte <= 1'b1;
        end
      end else begin
        endsendbyte <= 1'b0;
      end
    end
  end

  //
  always_comb begin
    //CurSt,NexSt
    NexSt = CurSt;
    if (active_i) begin
      NexSt = SEND;
    end
    if (endsendbyte) begin
      NexSt = WAIT;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      CurSt <= WAIT;
    end else begin
      CurSt <= NexSt;
    end
  end



  always_comb begin
    bitoutNEW = bitout_o;
    if (CurSt == SEND) begin
      if (negedgeclki2c) begin
        bitoutNEW = byte2send[7];
      end
    end else begin
      bitoutNEW = 1'b0;
    end

  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      bitout_o <= 8'b0;
    end else begin
      bitout_o <= bitoutNEW;
    end
  end

endmodule

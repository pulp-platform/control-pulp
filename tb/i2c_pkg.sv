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


package i2c_pkg;
  parameter CLK_I2C = 1us;  //1 MHz

  task automatic i2c_wait_half(input int cycles);
    #((CLK_I2C / 2) * cycles);
  endtask

  task automatic i2c_wait_quarter(input int cycles);
    #((CLK_I2C / 4) * cycles);
  endtask

  task automatic i2c_wait_sixteenth(input int cycles);
    #((CLK_I2C / 8) * cycles);
  endtask

  task automatic i2c_start(ref logic sda, ref logic scl);
    sda = 1'b1;
    scl = 1'b1;
    i2c_wait_half(1);
    sda = 1'b0;
    i2c_wait_half(1);
    scl = 1'b0;
  endtask

  task automatic i2c_stop(ref logic sda, ref logic scl);
    scl = 1'b0;
    i2c_wait_quarter(1);
    sda = 1'b0;
    i2c_wait_quarter(1);
    scl = 1'b1;
    i2c_wait_quarter(1);
    sda = 1'b1;
    i2c_wait_quarter(1);
  endtask

  task automatic i2c_write_byte(input logic [7:0] datain, ref logic sda, ref logic scl);
    for (int i = 0; i < 8; i = i + 1) begin
      scl = 1'b0;
      i2c_wait_quarter(1);
      sda = datain[7-i];
      i2c_wait_quarter(1);
      scl = 1'b1;
      i2c_wait_half(1);
    end
  endtask

  task automatic i2c_read_byte(output logic [7:0] dataout, ref logic sda, ref logic scl);
    for (int i = 0; i < 8; i = i + 1) begin
      scl = 1'b0;
      i2c_wait_half(1);
      scl = 1'b1;
      i2c_wait_quarter(1);
      dataout[7-i] = sda;
      i2c_wait_quarter(1);
    end
  endtask


  task automatic i2c_read_ack(output logic ack,
                              ref logic sda_i,  // resolved from actual sda bus value
                              ref logic scl_i, ref logic sda,  // driver from this pkg
                              ref logic scl);
    sda = 1'b1;
    scl = 1'b0;
    i2c_wait_half(1);
    scl = 1'b1;
    ack = ~sda_i;
    i2c_wait_half(1);
  endtask

endpackage

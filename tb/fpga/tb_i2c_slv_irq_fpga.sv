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
// Corrado Bonfanti <corrado.bonfanti@unibo.it>

// Test structure:
// I2C slave driver writes a stream of data into pms's L2
// pms dumps L2 content and check for correctness

import "DPI-C" function string getenv(input string env_name);

module tb_i2c_slv_irq_fpga;

  // DUT and useful tasks
  fixture_pms_top_fpga fixt_pms_fpga ();

  logic [31:0] entry_point;
  int exit_status;

  logic [7:0] i2c_slv_addr, i2c_slv_data;
  int stim_fd, ret_code;

  `define wait_for(signal) \
  do \
    @(posedge fixt_pms_fpga.s_soc_clk); \
  while (!signal);

  // pms on FPGA boot driver process (AXI)
  initial begin : axi_boot_process

    // Init AXI driver
    fixt_pms_fpga.init_axi_driver();

    // Read entry point (different for pulp-runtime/freertos)
    fixt_pms_fpga.read_entry_point(entry_point);

    // Reset pms
    fixt_pms_fpga.apply_rstn();

    #5us;

    // Enable uart rx
    fixt_pms_fpga.enable_uart_rx();

    // Select bootmode
    fixt_pms_fpga.axi_select_bootmode(32'h0000_0003);

    #5us;

    // Load binary into L2
    fixt_pms_fpga.axi_load_binary();

    // Write entry point into boot address register
    fixt_pms_fpga.axi_write_entry_point(entry_point);

    // Assert fetch enable through CSRs
    fixt_pms_fpga.axi_write_fetch_enable();

    #500us;

    // Wait for EOC
    fixt_pms_fpga.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: axi_boot_process


  // I2C slv driver process
  initial begin : i2c_slv_process
    // Wait for the main code application to set the interrupt enable flag of the I2C slave
    // R3 register
    `wait_for(
      fixt_pms_fpga.i_dut.i_control_pulp_fpga.i_control_pulp.i_soc_domain.pulp_soc_i.soc_peripherals_i.i_axi_apb_i2c_slave_bmc.reg_3[0]);

    // Load i2c slv stimuli
    fixt_pms_fpga.load_stim(
      {getenv("PWD"), "/../../../../../rtl/tb/simvectors/i2c_slv/stim_i2c_slv.txt"}, stim_fd);

    // Read slv address
    fixt_pms_fpga.i2c_slv_read_slv_address(stim_fd, i2c_slv_addr);

    // Start condition
    fixt_pms_fpga.i2c_slv_start();

    // Write slave address
    fixt_pms_fpga.i2c_slv_write_byte(i2c_slv_addr);

    // Read ack
    fixt_pms_fpga.i2c_slv_read_ack(exit_status);

    // Send stream of data and read ack for each
    fixt_pms_fpga.i2c_slv_send_data_stream(stim_fd, exit_status);

    // Stop condition
    fixt_pms_fpga.i2c_slv_stop();

    // Close file and finish i2c slv process
    $fclose(stim_fd);
    $display("[I2C_SLAVE TB] %t - I2C slave driver process completed", $realtime);
  end  // block: i2c_slv_process

endmodule  // tb_i2c_slv_irq_fpga

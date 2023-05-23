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

module tb_avs_fpga;

  // DUT and useful tasks
  fixture_pms_top_fpga fixt_pms_fpga ();

  logic [31:0] entry_point;
  int exit_status;

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

  assign fixt_pms_fpga.s_avs_mode = fixt_pms_fpga.i_dut.i_control_pulp_fpga.i_control_pulp.i_soc_domain.pulp_soc_i.soc_peripherals_i.i_udma.i_spim_gen[0].i_spim.u_reg_if.r_avs;

  // Detection of AVS start condition
  always_ff @(posedge fixt_pms_fpga.w_avs_clk, negedge fixt_pms_fpga.w_rst_n) begin
    if (fixt_pms_fpga.w_rst_n == 1'b0) begin
      fixt_pms_fpga.s_avs_start = 1'b0;
    end else if (fixt_pms_fpga.s_avs_mode == 1'b1) begin // Move on only if AVS mode is set (s_avs_mode is not
      // synchronized with avs clk, but here in testbench simulation is not a problem)
      avs_pkg::avs_start_condition(.avs_clk(fixt_pms_fpga.s_avs_clk),
                                   .avs_mdata(fixt_pms_fpga.s_avs_mdata),
                                   .avs_start(fixt_pms_fpga.s_avs_start));
    end
  end

  // Process to handle the received frames and to request a read operation from AVS master
  always_ff @(posedge fixt_pms_fpga.w_avs_clk, negedge fixt_pms_fpga.w_rst_n) begin
    if (fixt_pms_fpga.w_rst_n == 1'b0) begin
      fixt_pms_fpga.s_avs_sdata = 1'b1;
    end else if (fixt_pms_fpga.s_avs_start == 1'b1) begin // Start after detecting AVS start condition
      fixt_pms_fpga.s_avs_sdata = 1'b1;
      avs_pkg::avs_handle_frame(.avs_clk(fixt_pms_fpga.s_avs_clk),
                                .avs_mdata(fixt_pms_fpga.s_avs_mdata),
                                .avs_sdata(fixt_pms_fpga.s_avs_sdata));
      avs_pkg::avs_read_req(.avs_clk(fixt_pms_fpga.s_avs_clk),
                            .avs_sdata(fixt_pms_fpga.s_avs_sdata));
    end
  end

endmodule

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
// * Testbench used for testing clic priority/level semantic
// * External driver triggers two interrupt lines (#30 and #31, regular clint interrupts) concurrently
// * The test `tests/control-pulp-tests/clic/clic-prio-level-semantic.c` verifies
//   the clic ability to catch the highest priority, highest level interrupt among those pending

module tb_clic_prio_semantic;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int exit_status;
  logic [255:0] irq_mask = {256{1'b0}};

  // pms boot driver process (AXI)
  initial begin : axi_boot_process

    // Init AXI driver
    fixt_pms.init_axi_driver();

    // Read entry point (different for pulp-runtime/freertos)
    fixt_pms.read_entry_point(entry_point);

    // Reset pms
    fixt_pms.apply_rstn();

    #5us;

    // Enable uart rx
    fixt_pms.enable_uart_rx();

    // Select bootmode
    fixt_pms.axi_select_bootmode(32'h0000_0003);

    #5us;

    // Load binary into L2
    fixt_pms.axi_load_binary();

    // Write entry point into boot address register
    fixt_pms.axi_write_entry_point(entry_point);

    // Assert fetch enable through CSRs
    fixt_pms.axi_write_fetch_enable();

    #500us;

    // Wait for EOC
    fixt_pms.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: axi_boot_process

  // external process to concurrently set external interrupt lines
  initial begin : trigger_irq_process

    axi_pkg::resp_t resp;
    control_pulp_pkg::axi_data_inp_ext_t data, notifier;
    control_pulp_pkg::axi_addr_ext_t axi_addr32;

    #6us;

    fixt_pms.ext_write_mem(32'h2000_0000, 32'h0, resp);  //TODO initialize memory with 0s properly!

    if (fixt_pms.s_rst_n == 1'b1) begin

      notifier = 0;
      while (notifier[0] == 0) begin
        fixt_pms.ext_read_mem(32'h2000_0000, notifier, resp);
        fixt_pms.axi_assert("read", resp, exit_status);
        #10ns;
      end

      // Program has notified the tb, trigger interrupt lines
      if (notifier[0] == 1) begin
        $display("[TB] %t - Trigger interrupts", $realtime);
        irq_mask[1:0] = 2'b11;
        fixt_pms.db_trigger_irq(irq_mask);
      end
    end  // if (fixt_pms.s_rst_n == 1'b1)
  end  // block: trigger_irq_process

endmodule

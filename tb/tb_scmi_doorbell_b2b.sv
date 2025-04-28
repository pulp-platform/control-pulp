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

// Test structure:
// * Testbench used for testing external interrupts firing with SCMI messages in b2b
//  * - Caller waits for channel to be free (polling, no completion interrupt from callee with our design)
//  * - Caller sets flag (0 => polling from callee, 1 => interrupt to callee)
//  * - Caller writes header message to shared memory area
//  * - Caller sets channel as busy (channel.status = 0)
//  * - Caller sends interrupt to callee to notify the change in channel status (no callee polling)


module tb_scmi_doorbell_b2b;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int   exit_status;
  int   msg_cnt = 0;
  logic [pms_top_pkg::NUM_EXT_INTERRUPTS-1:0] irq_mask = {(pms_top_pkg::NUM_EXT_INTERRUPTS){1'b0}};

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

  // external process for scmi-b2b tests
  always begin : scmi_b2b_process
    axi_pkg::resp_t resp;
    control_pulp_pkg::axi_data_inp_ext_t data, channel_status;
    control_pulp_pkg::axi_addr_ext_t axi_addr32;

    #6us;

    axi_addr32 = 32'h2000_0000 + 32'h20 * msg_cnt;
    fixt_pms.ext_write_mem(axi_addr32 + 32'h4, 32'h0,
                           resp);  //TODO initialize memory with 0s properly!

    if (fixt_pms.s_rst_n == 1'b1) begin

      channel_status = 0;
      $display("[TB] %t - Caller waits for channel to be free (channel.status = 1)", $realtime);
      while (channel_status[0] == 0) begin
        fixt_pms.ext_read_mem(axi_addr32 + 32'h4, channel_status, resp);
        fixt_pms.axi_assert("read", resp, exit_status);
      end

      // Sanity check that the channel is free for caller
      if (channel_status[0] == 1) begin
        $display("[TB] %t - Channel is free for caller", $realtime);

        $display("[TB] %t - Caller sets flag to 1, callee notified via interrupt", $realtime);
        fixt_pms.ext_write_mem(axi_addr32 + 32'h10, 32'h1, resp);
        fixt_pms.axi_assert("write", resp, exit_status);

        $display("[TB] %t - Caller writes header message to shared memory area", $realtime);
        fixt_pms.ext_write_mem(axi_addr32 + 32'h18, 32'h0108_4000,
                               resp);  // Message is base protocol (id: 0x10) command
        fixt_pms.axi_assert("write", resp, exit_status);

        $display("[TB] %t - Caller sets channel as busy (channel.status = 0)", $realtime);
        fixt_pms.ext_write_mem(axi_addr32 + 32'h4, 32'h0,
                               resp);  // Message is base protocol (id: 0x10) command
        fixt_pms.axi_assert("write", resp, exit_status);

        $display("[TB] %t - Caller rings doorbell", $realtime);
        irq_mask[msg_cnt] = 1'b1;
        fixt_pms.db_trigger_irq(irq_mask);

        #1us fixt_pms.db_trigger_irq('0);

        msg_cnt += 1;

      end  // if (channel_status[0] == 1)
    end  // if (fixt_pms.s_rst_n == 1'b1)
  end  // block: scmi_b2b_process

endmodule

// Copyright 2022 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module tb_sw_jtag;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int exit_status;

  // pms jtag boot
  initial begin

    // Init AXI driver
    fixt_pms.init_axi_driver();

    // Read entry point (different for pulp-runtime/freertos)
    fixt_pms.read_entry_point(entry_point);

    // Reset pms
    fixt_pms.apply_rstn();

    #5us;

    // Enable uart rx
    fixt_pms.enable_uart_rx();


    fixt_pms.jtag_reset();

    // test if the jtag works
    fixt_pms.jtag_smoke_tests(entry_point);

    // Load firmware over jtag
    fixt_pms.jtag_load_binary(entry_point);

    // resume execution
    fixt_pms.jtag_resume_hart();

    // Wait for EOC
    fixt_pms.jtag_wait_for_eoc(exit_status);

    $stop;

  end

endmodule

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

// Test structure:
// Power ON: ACPI driver asserts PWR_BTN - short pulse, pms transitions S5->S0
// (Forced) Power OFF: ACPI driver asserts PWR_BTN - long press, pms transtions S0->S5

module tb_acpi_fpga;

  // DUT and useful tasks
  fixture_pms_top_fpga fixt_pms_fpga ();

  logic [31:0] entry_point;
  int exit_status;
  logic is_fetch_en;

  // pms on FPGA boot driver process (AXI)
  initial begin : axi_boot_process

    is_fetch_en = 1'b0;
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
    is_fetch_en = 1'b1;

    #500us;

    // Wait for EOC
    fixt_pms_fpga.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: axi_boot_process


  // ACPI driver process
  initial begin : acpi_process
    wait (is_fetch_en == 1'b1);

    // GPIO initialization
    #500us

      // Start Power on/down
      fixt_pms_fpga.acpi_power_on();
    #2000us fixt_pms_fpga.acpi_forced_power_down();

    #3000us

      // Repeat Power on/down sequence a second time
      fixt_pms_fpga.acpi_power_on();
    #2000us fixt_pms_fpga.acpi_forced_power_down();

    #10000us

      // End simulation in this process,
      // since code on PULP will execute forever
      $stop;
  end  // block: acpi_process

endmodule

// Copyright 2023 ETH Zurich
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// SPDX-License-Identifier: Apache-2.0

// Robert Balas <balasr@iis.ee.ethz.ch>
// Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>

module tb_sw;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point = 32'b0;
  int          exit_status = 0;

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

    // Load binary into L2
    fixt_pms.axi_load_binary();

    // Select bootmode
    fixt_pms.axi_select_bootmode(32'h0000_0003);

    // Write entry point into boot address register
    fixt_pms.axi_write_entry_point(entry_point);

    // Assert fetch enable through CSRs
    fixt_pms.axi_write_fetch_enable();

    #500us;

    // Wait for EOC
    fixt_pms.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: axi_boot_process

endmodule

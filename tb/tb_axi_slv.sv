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
// Directed verification (_dv): excite AXI transactions manually or write/read stream of data from a file
// TODO: Random verification (_rv): Use AXI randomizers to generate random AXI transactions and stress the test

module tb_axi_slv;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  int exit_status, stim_fd, ret_code;

  initial begin : axi_slv_process_dv

    control_pulp_pkg::axi_data_inp_ext_t data;

    control_pulp_pkg::axi_data_inp_ext_t data_i;
    control_pulp_pkg::axi_addr_ext_t addr_i;

    axi_pkg::resp_t resp;

    // Init AXI driver
    fixt_pms.init_axi_driver();

    // Reset pms
    fixt_pms.apply_rstn();

    #5us;

    ///////////////////////////
    // Directed verification //
    ///////////////////////////

    // L2 address range from external view:
    //   start: 1C00_0000
    //   end: 1C08_0000

    // First and last address check

    $display("[TB] %t - Write to first address", $realtime);
    fixt_pms.write_to_pulp(32'h1C00_0000, 64'h0000_0000_cafe_cafe, resp);
    fixt_pms.axi_assert("write", resp, exit_status);

    $display("[TB] %t - Read from first address", $realtime);
    fixt_pms.read_from_pulp(32'h1C00_0000, data, resp);
    fixt_pms.axi_assert("read", resp, exit_status);

    $display("[TB] %t - Write to last address", $realtime);
    fixt_pms.write_to_pulp(32'h1C08_0000, 64'h0000_0000_cafe_dead, resp);
    fixt_pms.axi_assert("write", resp, exit_status);

    $display("[TB] %t - Read from last address", $realtime);
    fixt_pms.read_from_pulp(32'h1C08_0000, data, resp);
    fixt_pms.axi_assert("read", resp, exit_status);

    #1us;

    // Probe range test
    // increment_aligned: 0x800
    // increment_unaligned: 0x801

    #5us;

    // Load stimuli from file
    stim_fd = $fopen("../tb/simvectors/axi_slv/stimuli_aligned_asic.txt", "r");
    if (!stim_fd)
      $fatal(1, "Could not open stimuli file!");

    while (!$feof(stim_fd)) begin
      //@(posedge i_dut.i_control_pulp_structs.i_soc_domain.pulp_soc_i.s_soc_clk);
      ret_code = $fscanf(stim_fd, "%h,%h\n", addr_i, data_i);

      $display("[TB] %t - Write to address %h", $realtime, addr_i);
      fixt_pms.write_to_pulp(addr_i, data_i, resp);
      fixt_pms.axi_assert("write", resp, exit_status);

      $display("[TB] %t - Read from address %h", $realtime, addr_i);
      fixt_pms.read_from_pulp(addr_i, data, resp);
      fixt_pms.axi_assert("read", resp, exit_status);
    end

    $fclose(stim_fd);

    $stop;

  end  // block: axi_slv_process

  // TODO: random verification

endmodule

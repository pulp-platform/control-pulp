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
// Preload AXI simulation memory with FW-specific data that should come from the controlled (EPI Rhea chip) model
// FW reads those values and computes according to control policy
// Loop is **not** closed since there is no interaction between pms and any controlled system

module tb_fw;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int exit_status;

  // EPI model stimuli

  logic [65:0] stimuli_freq2comp_out[144037-1:0];
  logic [65:0] stimuli_temp_out[144037-1:0];
  logic [65:0] stimuli_pwr_meas_out[4002-1:0];
  logic [65:0] stimuli_wl_out[144037-1:0];
  logic [65:0] stimuli_tfreq_out[145-1:0];
  logic [65:0] stimuli_pwr_budget_out[13-1:0];
  logic [65:0] stimuli_bind_out[73-1:0];

  control_pulp_pkg::axi_data_inp_ext_t axi_data64;
  control_pulp_pkg::axi_addr_ext_t axi_addr32;

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

    // Read FW-specific stimuli
    $readmemh("../../tb/simvectors/fw/freq_to_compare_out.txt", stimuli_freq2comp_out);
    $readmemh("../../tb/simvectors/fw/temperature_out.txt", stimuli_temp_out);
    $readmemh("../../tb/simvectors/fw/power_measured_out.txt", stimuli_pwr_meas_out);
    $readmemh("../../tb/simvectors/fw/wl_measure_out.txt", stimuli_wl_out);
    $readmemh("../../tb/simvectors/fw/target_freq_out.txt", stimuli_tfreq_out);
    $readmemh("../../tb/simvectors/fw/power_budget_out.txt", stimuli_pwr_budget_out);
    $readmemh("../../tb/simvectors/fw/core_bindings_out.txt", stimuli_bind_out);

    /*
      // Golden frequency to compare (from a Matlab model)
      $display("Fill sim mem with golden frequency data");
      for (int num_stim=0; num_stim<=144036; num_stim++) begin

//        @(posedge s_soc_clk);

        axi_addr32      = stimuli_freq2comp_out[num_stim][65:32];   // assign 32 bit address
        axi_data64      = stimuli_freq2comp_out[num_stim][31:0];    // assign 32 bit data

        fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
      end // for (int num_stim=0; num_stim<=14399; num_stim++)

*/

    // Temperature
    $display("Fill sim mem with temperature data");
    for (int num_stim = 0; num_stim <= 1000; num_stim++) begin
      axi_addr32 = stimuli_temp_out[num_stim][65:32];  // assign 32 bit address
      axi_data64 = stimuli_temp_out[num_stim][31:0];  // assign 32 bit data

      fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
    end

    /*
      // Power measured
      $display("Fill sim mem with power data");
      for (int num_stim=0; num_stim<=4001; num_stim++) begin
        axi_addr32      = stimuli_pwr_meas_out[num_stim][65:32];   // assign 32 bit address
        axi_data64      = stimuli_pwr_meas_out[num_stim][31:0];    // assign 32 bit data

        fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
      end // for (int num_stim=0; num_stim<=16004; num_stim++)

*/
    // WL measured
    $display("Fill sim mem with WL data");
    for (int num_stim = 0; num_stim <= 1000; num_stim++) begin
      axi_addr32 = stimuli_wl_out[num_stim][65:32];  // assign 32 bit address
      axi_data64 = stimuli_wl_out[num_stim][31:0];  // assign 32 bit data

      fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
    end

    // Target frequency
    $display("Fill sim mem with target frequency data");
    for (int num_stim = 0; num_stim <= 144; num_stim++) begin
      axi_addr32 = stimuli_tfreq_out[num_stim][65:32];  // assign 32 bit address
      axi_data64 = stimuli_tfreq_out[num_stim][31:0];  // assign 32 bit data

      fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
    end

    // Power budget
    $display("Fill sim mem with power budget data");
    for (int num_stim = 0; num_stim <= 12; num_stim++) begin
      axi_addr32 = stimuli_pwr_budget_out[num_stim][65:32];  // assign 32 bit address
      axi_data64 = stimuli_pwr_budget_out[num_stim][31:0];  // assign 32 bit data

      fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
    end

    // Core binding
    $display("Fill sim mem with core binding data");
    for (int num_stim = 0; num_stim <= 72; num_stim++) begin
      axi_addr32 = stimuli_bind_out[num_stim][65:32];  // assign 32 bit address
      axi_data64 = stimuli_bind_out[num_stim][31:0];  // assign 32 bit data

      fixt_pms.fw_fill_sim_mem(exit_status, num_stim, axi_addr32, axi_data64);
    end


    #5us;

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

endmodule

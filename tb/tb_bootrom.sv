// Copyright 2021 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//
// Author: Robert Balas <balasr@iis.ee.ethz.ch>
//
// Test the fallback (forth) boot mode
//

module tb_bootrom;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int exit_status;

  string prog = "-1 .\n\
: emit    0 sys ;\n\
: .       1 sys ;\n\
: tell    2 sys ;\n\
\n\
: !    0 !! ;\n\
: @    0 @@ ;\n\
: ,    0 ,, ;\n\
: #    0 ## ;\n\
\n\
: [ 0 compiling ! ; immediate\n\
: ] 1 compiling ! ;\n\
: postpone 1 _postpone ! ; immediate\n\
\n\
: over 1 pick ;\n\
: +!   dup @ rot + swap ! ;\n\
: inc  1 swap +! ;\n\
: dec  -1 swap +! ;\n\
: <    - <0 ;\n\
: >    swap < ;\n\
: <=   over over >r >r < r> r> = + ;\n\
: >=   swap <= ;\n\
: =0   0 = ;\n\
: not  =0 ;\n\
: !=   = not ;\n\
: cr   10 emit ;\n\
: ..   dup . ;\n\
: here h @ ;\n\
-0x80000000 0x1a1040a0 p!\n\
";

  logic [31:0] core_status;
  assign core_status = fixt_pms.i_dut.i_control_pulp.i_soc_domain.pulp_soc_i.soc_peripherals_i.i_apb_soc_ctrl.r_corestatus;

  // pms boot driver process (AXI)
  initial begin : bootrom_test_process

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
    fixt_pms.axi_select_bootmode(32'h0000_0000);

    #5us;

    // Assert fetch enable through CSRs
    fixt_pms.axi_write_fetch_enable();

    #5us;

    // wait for forth to be booted up (estimated 280k cyles)
    #(fixt_pms.REF_CLK_PERIOD * 280000);
    $display("[TB] %t - Starting to feed data over UART", $realtime);

    // feed forth shell commands over uart
    while (1) begin
      static int cnt = 0;
      static int j = 0;

      while (cnt < prog.len()) begin
        fixt_pms.uart_sim_gen[0].i_uart_sim.send_char(prog.getc(cnt));
        // pause a bit after sending a line
        if (prog.getc(cnt) == "\n")
          for (j = 0; j < 15; j++) fixt_pms.uart_sim_gen[0].i_uart_sim.wait_symbol();
        cnt++;
      end
    end  // while (1)

    // Wait for EOC
    fixt_pms.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: bootrom_test_process

  // check for exit
  initial begin
    exit_status = fixt_pms.EXIT_FAIL;

    wait (fixt_pms.s_rst_n === 1'b1);

    // poll core status for exit
    while (core_status[31] === 1'b0) #50us;

    // for simulator
    if (core_status[30:0] === 0) exit_status = fixt_pms.EXIT_SUCCESS;
    else exit_status = fixt_pms.EXIT_FAIL;

    $display("[TB] %t - exit with status 0x%h", $realtime, core_status[30:0]);

    $stop;
  end

endmodule

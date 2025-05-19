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
// Test the forth into uart boot
//

module tb_uart_boot;

  // DUT and useful tasks
  fixture_pms_top fixt_pms ();

  logic [31:0] entry_point;
  int exit_status;

  // minimal program
  // - '3 sys ;' tell forth to boot from uart
  // - The rest is a srec dump of a minimal assembly program that just tries to
  // write zero into the exit register (see tests/control-pulp-tests/minimal-asm)

  // min:     file format elf32-littleriscv
  //
  //
  // Disassembly of section .text:
  //
  // 1c000880 <_start>:
  // 1c000880:       00001197                auipc   gp,0x1
  // 1c000884:       83418193                addi    gp,gp,-1996 # 1c0010b4 <__global_pointer$>
  // 1c000888:       81018113                addi    sp,gp,-2032 # 1c0008c4 <__stack_top>
  // 1c00088c:       4502                    lw      a0,0(sp)
  // 1c00088e:       004c                    addi    a1,sp,4
  // 1c000890:       4601                    li      a2,0
  // 1c000892:       2019                    jal     1c000898 <main>
  // 1c000894:       a021                    j       1c00089c <exit>
  //
  // 1c000896 <_fini>:
  // 1c000896:       8082                    ret
  //
  // 1c000898 <main>:
  // 1c000898:       4501                    li      a0,0
  // 1c00089a:       8082                    ret
  //
  // 1c00089c <exit>:
  // 1c00089c:       1a1042b7                lui     t0,0x1a104
  // 1c0008a0:       0a028293                addi    t0,t0,160 # 1a1040a0 <__stack_size+0x1a10409c>
  // 1c0008a4:       80000537                lui     a0,0x80000
  // 1c0008a8:       00a2a023                sw      a0,0(t0)
  // 1c0008ac:       10500073                wfi
  // 1c0008b0:       b7f5                    j       1c00089c <exit>
  //
  // 1c0008b2 <_endtext>:
  //         ...

  string prog = "\n\
3 sys ;\n\
S00B00006D696E2E73726563D5\n\
S3151C00088097110000938141831381018102454C001D\n\
S3151C0008900146192021A0828001458280B742101A88\n\
S3151C0008A09382020A3705008023A0A2007300501011\n\
S3091C0008B0F5B7000076\n\
S7051C00088056\n\
";

  logic [31:0] core_status;
  assign core_status = fixt_pms.i_dut.i_control_pulp.i_soc_domain.pulp_soc_i.soc_peripherals_i.i_apb_soc_ctrl.r_corestatus;

  initial begin
    // feed forth shell commands over uart
    automatic int cnt = 0;
    automatic int j = 0;

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

    while (cnt < prog.len()) begin
      fixt_pms.uart_sim_gen[0].i_uart_sim.send_char(prog.getc(cnt));
      cnt++;
    end

    forever @(posedge fixt_pms.s_clk_ref);
  end

  // check for exit
  initial begin
    exit_status = fixt_pms.EXIT_FAIL;

    wait (fixt_pms.s_rst_n === 1'b1);

    // poll core status for exit
    while (core_status[31] === 1'b0) #50us;

    // for simulator
    if (core_status[30:0] === 0) exit_status = fixt_pms.EXIT_SUCCESS;
    else exit_status = fixt_pms.EXIT_FAIL;

    // waiting a bit for uart to complete writing
    #(fixt_pms.REF_CLK_PERIOD * 3000);

    $display("[TB] %t - exit with status 0x%h", $realtime, core_status[30:0]);

    $stop;
  end

endmodule

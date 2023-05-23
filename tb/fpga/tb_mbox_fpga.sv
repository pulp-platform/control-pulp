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
// * Testbench used for testing external interrupts firing with SCMI messages in b2b
//  * - Caller waits for channel to be free (polling, no completion interrupt from callee with our design)
//  * - Caller sets flag (0 => polling from callee, 1 => interrupt to callee)
//  * - Caller writes header message to shared memory area
//  * - Caller sets channel as busy (channel.status = 0)
//  * - Caller sends interrupt to callee to notify the change in channel status (no callee polling)


module tb_mbox_fpga;

  // DUT and useful tasks
  fixture_pms_top_fpga fixt_pms_fpga ();

  logic [31:0] entry_point;
  int exit_status;
  logic end_load='0;

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
    
    //enable mailbox write process


    end_load='1;
    #500us;

    // Wait for EOC
    fixt_pms_fpga.axi_wait_for_eoc(exit_status);

    $stop;

  end  // block: axi_boot_process

  // external process for scmi tests
  /*
    general message header format:
    bits[31:28]   reserved, must be zero   4b
    bits[27:18]   token                    10b
    bits[17:10]   protocol_id              8b
    bits[9:8]     message_type             2b
    bits[7:0]     message_id               8b

    protocol version command for Base protocol, protocol version command
    token=0x0
    protocol_id=0x10
    message_type=0x0 (all commands have this type)
    message_id=0x0

    Return values for Base protocol, protocol version command
    int32 status 
    int32 version   0x20000

    shared memory area layout
    FIELD         BYTES
    reserv.       0x4
    ch. status    0x4
    reserv.       0x8
    length        0x4
    header        0x4
    payload       N 
  */

  always begin : scmi_process
    axi_pkg::resp_t resp;
    control_pulp_pkg::axi_data_inp_ext_t data, channel_status;
    control_pulp_pkg::axi_addr_ext_t axi_addr32;

    wait(end_load=='1);//assuming channel 0 free

    axi_addr32=32'h0000_0000;
    data=32'hCAFE_CAFE;
    $display("[TB] %t - writing to C000_0000",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);

    // flags: bits[31:1] must be zero, bit[0] set to 0 to disable completion interrupt
    axi_addr32=32'hA600_0010;
    data=32'h0000_0000;
    $display("[TB] %t - writing flags",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);

    // length: 4 bytes of header plus 4 of payload
    axi_addr32=32'hA600_0014;
    data=32'h0000_0008;
    $display("[TB] %t - writing length",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);

    // header
    axi_addr32=32'hA600_0018;
    data=32'h0000_4000;
    $display("[TB] %t - writing header",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);

    // payload
    axi_addr32=32'hA600_001c;
    data=32'hCAFE_CAFE;
    $display("[TB] %t - writing payload",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);

    // mark channel as busy
    axi_addr32=32'hA600_0004;
    data=32'h0000_0000;
    $display("[TB] %t - mark channel status ad busy",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);
    
    // ring the doorbell
    axi_addr32=32'hA600_0020;
    data=32'h0000_0001;
    $display("[TB] %t - writing to mailbox doorbell register",$realtime);
    @(posedge fixt_pms_fpga.s_soc_clk);
    fixt_pms_fpga.write_to_pulp32(axi_addr32, data, resp);
    #1000us;
  end
endmodule

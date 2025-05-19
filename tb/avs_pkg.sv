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

// Corrado Bonfanti <corrado.bonfanti@unibo.it>

  // Cmd: Command code that determines the action that the master requires
  `define CMD_WR_COMMIT  2'b00
  `define CMD_WR_HOLD    2'b01
  `define CMD_RESERVED   2'b10
  `define CMD_READ       2'b11

  // CmdGroup: Qualifier to distinguish between two groups of data types
  `define FULL_DEFINED   1'b0 // fully defined AVSBus data types
  `define MANUFACTORY    1'b1 // for manufacturer-specific data types

  // CmdDataType: Type of data to which <Cmd> applies. For <CmdGroup> = 0b, the data types are:
  `define VLT_RAIL       4'b0000 // Target rail voltage.
  `define VLT_RATE_RAIL  4'b0001 // Target rail Vout transition rate.
  `define CURR_RAIL      4'b0010 // Rail current (read only).
  `define TEMP_RAIL      4'b0011 // Rail temperature (read only).
  `define RST_VOLT_RAIL  4'b0100 // Reset rail voltage to default value (write only).
  `define PWR_MODE_RAIL  4'b0101 // Rail power mode.
  // 0110b to 1101b: Reserved command data types.
  `define AVS_STATUS     4'b1110 // AVSBus Status
  `define AVS_VERS       4'b1111 // AVSBus Version
  // For <CmdGroup> = 1b the definition of the data types is found
  // in the device's product literature.

  // 20Mhz AVS CLK -> This is wrong
  `define AVS_SEMIPERIOD 10ns
  `define AVS_PERIOD     20ns

package automatic avs_pkg;
  parameter int unsigned LENGTH_MES         = 29;
  parameter int unsigned LENGTH_DIV         = 4;
  parameter int unsigned LENGTH_FRAME       = LENGTH_MES + LENGTH_DIV-1; // 32
  // Number of fully defined AVSBus data types
  parameter int unsigned NUM_TYPES          = 16;
  parameter int unsigned NUM_TYPES_WIDTH    = $clog2(NUM_TYPES);
  // Total instances number of a command data type on a device
  parameter int unsigned NUM_DEV_INST       = 16;
  parameter int unsigned NUM_DEV_INST_WIDTH = $clog2(NUM_DEV_INST);
  // Currently used number of instances
  parameter int unsigned USED_DEV_INST      = 1;
  // AVS status depth
  parameter int unsigned STATUS_WIDTH       = 5;

  // CRC generator polynomial
  parameter logic [LENGTH_DIV-2:0] CRC_GEN  = 4'b1011;

  // AVS instances data
  int                              avs_data[NUM_TYPES_WIDTH-1:0][NUM_DEV_INST_WIDTH-1:0];
  // AVS internal status register
  logic [STATUS_WIDTH-1:0]         slv_status;

  task automatic avs_read_req;
    ref logic avs_sdata;
    ref logic avs_clk;
    // Wait for an arbitrary amount of time (here the frame length) before requesting
    // a read operation
    for (int i = 0; i < LENGTH_FRAME; i++) begin
      #`AVS_PERIOD;
    end
    $display("[AVS SLAVE] SEND READ REQUEST");
    avs_sdata = 1'b0;
  endtask // avs_read_req

  task automatic avs_start_condition;
    ref logic avs_mdata;
    ref logic avs_start;
    ref logic avs_clk;

    // Sample the mdata using the falling edge of the AVS clock signal (protocol spec.)
    @(negedge avs_clk);
    if (avs_mdata == 1'b0) begin
      @(negedge avs_clk);
      if (avs_mdata == 1'b1) begin
        avs_start = 1'b1; // Setting to '1' during the falling edge of the AVS clock
        @(negedge avs_clk);
        avs_start = 1'b0; // "start" stays high for only one cycle
        for (int i = 0; i < LENGTH_FRAME - 3; i++) begin // It waits until the end of the frame
        //(32bits - 2bits of start condition and 1 avs cycle to set start low again)
          @(negedge avs_clk);
        end
      end
    end

  endtask // avs_start_condition

  task automatic avs_handle_frame;
    ref logic                      avs_mdata;
    ref logic                      avs_sdata;
    ref logic                      avs_clk;

    logic [1:0]                    avs_mst_cmd;
    logic                          avs_mst_cmd_group;
    logic [NUM_TYPES_WIDTH-1:0]    avs_mst_cmd_data_type;
    logic [NUM_DEV_INST_WIDTH-1:0] avs_mst_sel;
    logic [15:0]                   avs_mst_cmd_data;
    logic [LENGTH_DIV-2:0]         avs_mst_crc;


    avs_frame_fields(
      avs_clk,
      avs_mdata,
      avs_mst_cmd,
      avs_mst_cmd_group,
      avs_mst_cmd_data_type,
      avs_mst_sel,
      avs_mst_cmd_data,
      avs_mst_crc
    );

    if (avs_mst_cmd == `CMD_WR_COMMIT) begin
     $display("[AVS SLAVE] HANDLE WRITE FROM AVS MASTER");
     avs_write_commit (
        .avs_clk               ( avs_clk               ),
        .avs_mst_cmd           ( avs_mst_cmd           ),
        .avs_mst_cmd_group     ( avs_mst_cmd_group     ),
        .avs_mst_cmd_data_type ( avs_mst_cmd_data_type ),
        .avs_mst_sel           ( avs_mst_sel           ),
        .avs_mst_cmd_data      ( avs_mst_cmd_data      ),
        .avs_mst_crc           ( avs_mst_crc           ),
        .avs_sdata             ( avs_sdata             )
       );
    // TODO: else if (avs_mst_cmd == `CMD_WR_HOLD) begin
    // (PMBus-specification-part-3, pg. 23)

    end else if (avs_mst_cmd == `CMD_READ) begin
     $display("[AVS SLAVE] HANDLE READ FROM AVS MASTER");
     avs_read (
        .avs_clk               ( avs_clk               ),
        .avs_mst_cmd           ( avs_mst_cmd           ),
        .avs_mst_cmd_group     ( avs_mst_cmd_group     ),
        .avs_mst_cmd_data_type ( avs_mst_cmd_data_type ),
        .avs_mst_sel           ( avs_mst_sel           ),
        .avs_mst_crc           ( avs_mst_crc           ),
        .avs_sdata             ( avs_sdata             )
      );
    end
  endtask // avs_handle_frame

  task automatic avs_frame_fields;
    ref logic                          avs_clk;
    ref logic                          avs_mdata;
    ref logic [1:0]                    avs_mst_cmd;
    ref logic                          avs_mst_cmd_group;
    ref logic [NUM_TYPES_WIDTH-1:0]    avs_mst_cmd_data_type;
    ref logic [NUM_DEV_INST_WIDTH-1:0] avs_mst_sel;
    ref logic [15:0]                   avs_mst_cmd_data;
    ref logic [LENGTH_DIV-2:0]         avs_mst_crc;

    // Sample the mdata using the falling edge of the AVS clock signal (protocol spec.)
    for (int i = 1; i >= 0; i--) begin
      @(negedge avs_clk);
      avs_mst_cmd[i] = avs_mdata;
    end
    @(negedge avs_clk);
    avs_mst_cmd_group = avs_mdata;
    for (int i = 3; i >= 0; i--) begin
      @(negedge avs_clk);
      avs_mst_cmd_data_type[i] = avs_mdata;
    end
    for (int i = 3; i >= 0; i--) begin
      @(negedge avs_clk);
      avs_mst_sel[i] = avs_mdata;
    end
    for (int i = 15; i >= 0; i--) begin
      @(negedge avs_clk);
      avs_mst_cmd_data[i] = avs_mdata;
    end
    for (int i = LENGTH_DIV-2; i >= 0; i--) begin
      @(negedge avs_clk);
      avs_mst_crc[i] = avs_mdata;
    end
  endtask // avs_frame_fields

  task automatic avs_write_commit;
    ref logic                            avs_sdata;
    ref logic                            avs_clk;
    input logic [1:0]                    avs_mst_cmd;
    input logic                          avs_mst_cmd_group;
    input logic [NUM_TYPES_WIDTH-1:0]    avs_mst_cmd_data_type;
    input logic [NUM_DEV_INST_WIDTH-1:0] avs_mst_sel;
    input logic [15:0]                   avs_mst_cmd_data;
    input logic [LENGTH_DIV-2:0]         avs_mst_crc;

    int                                  sel_slv_dev;
    int                                  cmd_data_type;

    logic [LENGTH_FRAME+LENGTH_DIV-2:0]  mst_subframe;
    logic [LENGTH_MES-1:0]               quotient;
    logic [LENGTH_MES-1:0]               slv_subframe;
    logic [LENGTH_DIV-2:0]               remainder;
    logic [LENGTH_DIV-2:0]               slv_crc;
    logic [1:0]                          slv_ack;
    // Reserved bits of write slave subframe
    logic [20:0]                         wr_reserved;

    sel_slv_dev   = avs_mst_sel;
    cmd_data_type = avs_mst_cmd_data_type;
    wr_reserved   = {21{1'b1}}; // All ones

    mst_subframe = {2'b01, avs_mst_cmd, avs_mst_cmd_group, avs_mst_cmd_data_type, avs_mst_sel, avs_mst_cmd_data, avs_mst_crc};

    // Check if the remainder is equal to zero
    avs_div_mod2 (
      .dividend  ( mst_subframe ),
      .divisor   ( CRC_GEN      ),
      .remainder ( remainder    ),
      .quotient  ( quotient     )
    );

    // Send sdata using the rising edge of the AVS clock signal (protocol spec.)
    if (remainder != 3'b0) begin
      slv_ack = 2'b10; // Bad CRC, no action is taken
    end else begin
      if ((cmd_data_type > `PWR_MODE_RAIL && cmd_data_type <  `AVS_STATUS ) || // Invalid data type
          (cmd_data_type == `CURR_RAIL || cmd_data_type == `TEMP_RAIL || cmd_data_type == `AVS_VERS) || // Incorrect action (Read only)
          (sel_slv_dev > USED_DEV_INST) // Invalid selector (TODO: invalid broadcast, PMBus-specification-part-3, pg. 21)
          // TODO: Incorrect data: out of range data value for a specific data type
      ) begin
        slv_ack = 2'b11; // No action is taken
      end
      // else if TODO: Good CRC, valid data (selector, data type, data value are good),
      // but no action is taken due to resource being unavailable (busy or not allocated
      // to AVSBus). (PMBus-specification-part-3, pg. 21)
      // slv_ack =2'b01;
      else begin
        slv_ack = 2'b00; // Action taken
      end
    end

    if (slv_ack == 2'b00) begin
      if (avs_mst_cmd_group == `FULL_DEFINED) begin
        avs_data[sel_slv_dev][cmd_data_type] = avs_mst_cmd_data;
      end
      // else: Manufacturer data types
    end

    // TODO: set slave status register according to AVS specifications (PMBus-specification-part-3, pg. 30)
    slv_status = '0;

    slv_subframe = {slv_ack, 1'b0, slv_status, wr_reserved};
    // Compute new crc based on the slave write subframe
    avs_crc_calc (
      .message   ( slv_subframe ),
      .divisor   ( CRC_GEN      ),
      .crc       ( slv_crc      )
    );

    // Transmit the sdata using the rising edge of the AVS clock signal (protocol spec.)
    // Send slave write subframe
    for (int i = 1; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_ack[i];
    end
    @(posedge avs_clk);
    avs_sdata = 1'b0;
    for (int i = STATUS_WIDTH-1; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_status[i];
    end
    for (int i = 20; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = wr_reserved[i];
    end
    for (int i = LENGTH_DIV-2; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_crc[i];
    end
    // Setting the SDATA value to '1' again after one AVS period(idle)
    #`AVS_PERIOD
    avs_sdata = 1'b1;
  endtask // avs_write_commit

  task automatic avs_read;
    ref logic                            avs_sdata;
    ref logic                            avs_clk;
    input logic [1:0]                    avs_mst_cmd;
    input logic                          avs_mst_cmd_group;
    input logic [NUM_TYPES_WIDTH-1:0]    avs_mst_cmd_data_type;
    input logic [NUM_DEV_INST_WIDTH-1:0] avs_mst_sel;
    input logic [LENGTH_DIV-2:0]         avs_mst_crc;

    int                                  sel_slv_dev;
    int                                  cmd_data_type;

    logic [15:0]                         slv_cmd_data;
    logic [LENGTH_FRAME+LENGTH_DIV-2:0]  mst_subframe;
    logic [LENGTH_MES-1:0]               quotient;
    logic [LENGTH_MES-1:0]               slv_subframe;
    logic [LENGTH_DIV-2:0]               remainder;
    logic [LENGTH_DIV-2:0]               slv_crc;
    logic [1:0]                          slv_ack;
    // Reserved bits of read master and slave subframes
    logic [15:0]                         rd_reserved;

    sel_slv_dev   = avs_mst_sel;
    cmd_data_type = avs_mst_cmd_data_type;
    rd_reserved   = {16{1'b1}}; // All ones

    mst_subframe = {2'b01, avs_mst_cmd, avs_mst_cmd_group, avs_mst_cmd_data_type, avs_mst_sel, rd_reserved, avs_mst_crc};

    // Check if the remainder is equal to zero
    avs_div_mod2 (
      .dividend  ( mst_subframe ),
      .divisor   ( CRC_GEN      ),
      .remainder ( remainder    ),
      .quotient  ( quotient     )
    );

    // Send sdata using the rising edge of the AVS clock signal (protocol spec.)
    if (remainder != 3'b0) begin
      slv_ack = 2'b10; // Bad CRC, no action is taken
    end else begin
      if ((sel_slv_dev > USED_DEV_INST) // Invalid selector (TODO: invalid broadcast, PMBus-specification-part-3, pg. 21)
          // TODO: Incorrect data: out of range data value for a specific data type
      ) begin
        slv_ack = 2'b11; // No action is taken
      end
      // else if TODO: Good CRC, valid data (selector, data type, data value are good),
      // but no action is taken due to resource being unavailable (busy or not allocated
      // to AVSBus). (PMBus-specification-part-3, pg. 21)
      // slv_ack =2'b01;
      else begin
        slv_ack = 2'b00; // Action taken
      end
    end

    if (slv_ack == 2'b00) begin
      if (avs_mst_cmd_group == `FULL_DEFINED) begin
        slv_cmd_data = avs_data[sel_slv_dev][cmd_data_type];
      end
      // else: Manufacturer data types
    end

    // TODO: set slave status register according to AVS specifications (PMBus-specification-part-3, pg. 30)
    slv_status = '0;

    slv_subframe = {slv_ack, 1'b0, slv_status, slv_cmd_data, rd_reserved[4:0]};
    // Compute new crc based on the slave write subframe
    avs_crc_calc (
      .message   ( slv_subframe ),
      .divisor   ( CRC_GEN      ),
      .crc       ( slv_crc      )
    );

    // Transmit the sdata using the rising edge of the AVS clock signal (protocol spec.)
    // Send slave write subframe
    for (int i = 1; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_ack[i];
    end
    @(posedge avs_clk);
    avs_sdata = 1'b0;
    for (int i = STATUS_WIDTH-1; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_status[i];
    end
    for (int i = 15; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_cmd_data[i];
    end
    for (int i = 4; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = rd_reserved[i];
    end
    for (int i = LENGTH_DIV-2; i >= 0; i--) begin
      @(posedge avs_clk);
      avs_sdata = slv_crc[i];
    end
    // Setting the SDATA value to '1' again after one AVS period(idle)
    #`AVS_PERIOD
    avs_sdata = 1'b1;
  endtask // avs_read

  // The following tasks might be declared as functions, but the future implementation
  // might also require some time control statements
  task avs_div_mod2;
    input logic [LENGTH_MES+LENGTH_DIV-2:0] dividend;
    input logic [LENGTH_DIV-1:0]            divisor;

    output logic [LENGTH_DIV-2:0]           remainder;
    output logic [LENGTH_MES-1:0]           quotient;

    int                                     temp;

    for (int i = LENGTH_MES+LENGTH_DIV-2; i >= LENGTH_DIV-1; i--) begin
      temp = i;
      if (dividend[i] == 1'b1) begin
        for (int j = LENGTH_DIV-1; j >= 0; j--) begin
          dividend[temp] = dividend[temp] ^ divisor[j];
          temp = temp-1;
        end
        quotient[i-(LENGTH_DIV-1)] = 1;
      end else begin
        quotient[i-(LENGTH_DIV-1)] = 0;
      end
      temp = i-1;
      for (int j = LENGTH_DIV-2; j >= 0; j--) begin
        remainder[j] = dividend[temp];
        temp = temp-1;
      end
    end
  endtask

  task avs_crc_calc;
    input  logic [LENGTH_MES-1:0]              message;
    input  logic [LENGTH_DIV-1:0]              divisor;

    output logic [LENGTH_DIV-2:0]              crc;

    logic [LENGTH_MES-1:0]                     quotient;
    logic [LENGTH_MES + LENGTH_DIV-2:0]        dividend;

    dividend = {message, {LENGTH_DIV-1{1'b0}}};

    avs_div_mod2 (
      .dividend  ( dividend ),
      .divisor   ( divisor  ),
      .remainder ( crc      ),
      .quotient  ( quotient )
    );

  endtask // crc_calc

endpackage // avs_pkg

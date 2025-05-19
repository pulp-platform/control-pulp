// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`define SPI_STD 2'b00
`define SPI_QUAD_TX 2'b01
`define SPI_QUAD_RX 2'b10

`define SPI_SEMIPERIOD 10ns    //10Mhz SPI CLK

`define DELAY_BETWEEN_SPI 20ns

int num_stim_i, num_exp, num_cycles, num_err = 0;  // counters for statistics

logic more_stim = 1;

logic [31:0] spi_data;
logic [31:0] spi_data_recv;
logic [31:0] spi_addr;
logic [31:0] spi_addr_old;

logic [63:0] stimuli_i[10000:0];  // array for the stimulus vectors

task spi_send_cmd_addr;
  input use_qspi;
  input [7:0] command;
  input [31:0] addr;
  begin
    if (use_qspi) begin
      for (int i = 2; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = command[4*i-1];
        w_spi_slave_sdio_int[2] = command[4*i-2];
        w_spi_slave_sdio_int[1] = command[4*i-3];
        w_spi_slave_sdio_int[0] = command[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 7; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = command[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end

    if (use_qspi) begin
      for (int i = 8; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = addr[4*i-1];
        w_spi_slave_sdio_int[2] = addr[4*i-2];
        w_spi_slave_sdio_int[1] = addr[4*i-3];
        w_spi_slave_sdio_int[0] = addr[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 31; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = addr[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
  end
endtask

task spi_send_data;
  input use_qspi;
  input [31:0] data;
  begin
    if (use_qspi) begin
      for (int i = 8; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = data[4*i-1];
        w_spi_slave_sdio_int[2] = data[4*i-2];
        w_spi_slave_sdio_int[1] = data[4*i-3];
        w_spi_slave_sdio_int[0] = data[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 31; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = data[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
  end
endtask

task spi_recv_data;
  input use_qspi;
  output [31:0] data;
  begin
    if (use_qspi) begin
      for (int i = 8; i > 0; i--) begin
        data[4*i-1] = w_spi_slave_sdio[3];
        data[4*i-2] = w_spi_slave_sdio[2];
        data[4*i-3] = w_spi_slave_sdio[1];
        data[4*i-4] = w_spi_slave_sdio[0];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 31; i >= 0; i--) begin
        data[i] = w_spi_slave_sdio[0];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
  end
endtask

task spi_load;
  input use_qspi;
  begin
    $readmemh("./slm_files/spi_stim.txt",
              stimuli_i);  // read in the stimuli_i vectors  == address_value

    spi_addr = stimuli_i[num_stim_i][63:32];  // assign address
    spi_data = stimuli_i[num_stim_i][31:0];  // assign data

    $display("[SPI] Loading Instruction RAM");
    w_spi_slave_csn_int = 1'b0;
    #100 spi_send_cmd_addr(use_qspi, 8'h2, spi_addr);

    spi_addr_old = spi_addr - 32'h4;

    while (more_stim)                        // loop until we have no more stimuli_i)
      begin
      spi_addr = stimuli_i[num_stim_i][63:32];  // assign address
      spi_data = stimuli_i[num_stim_i][31:0];  // assign data

      if (spi_addr != (spi_addr_old + 32'h4)) begin
        $display("[SPI] Prev address %h current addr %h", spi_addr_old, spi_addr);
        $display("[SPI] Loading Data RAM");
        #100 w_spi_slave_csn_int = 1'b1;
        #`DELAY_BETWEEN_SPI;
        w_spi_slave_csn_int = 1'b0;
        #100 spi_send_cmd_addr(use_qspi, 8'h2, spi_addr);
      end
      spi_send_data(use_qspi, spi_data[31:0]);

      num_stim_i   = num_stim_i + 1;  // increment stimuli_i
      spi_addr_old = spi_addr;
      if (num_stim_i > 9999 | stimuli_i[num_stim_i] === 64'bx)  // make sure we have more stimuli_i
        more_stim = 0;  // if not set variable to 0, will prevent additional stimuli_i to be applied
    end  // end while loop
    #100 w_spi_slave_csn_int = 1'b1;
    #`DELAY_BETWEEN_SPI;
  end
endtask

task spi_check;
  input use_qspi;
  begin
    num_stim_i = 0;
    more_stim  = 1;

    spi_addr   = stimuli_i[num_stim_i][63:32];  // assign address
    spi_data   = stimuli_i[num_stim_i][31:0];  // assign data

    $display("[SPI] Checking Instruction RAM");
    w_spi_slave_csn_int = 1'b0;
    #100 spi_send_cmd_addr(use_qspi, 8'hB, spi_addr);
    spi_addr_old = spi_addr - 32'h4;

    // dummy cycles
    //padmode_spi_master = use_qspi ? `SPI_QUAD_RX : `SPI_STD;
    for (int i = 33; i >= 0; i--) begin
      #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
      #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    end

    while (more_stim)                        // loop until we have no more stimuli_i)
      begin
      spi_addr = stimuli_i[num_stim_i][63:32];  // assign address
      spi_data = stimuli_i[num_stim_i][31:0];  // assign data

      if (spi_addr != (spi_addr_old + 32'h4)) begin
        $display("[SPI] Prev address %h current addr %h", spi_addr_old, spi_addr);
        $display("[SPI] Checking Data RAM");
        #100 w_spi_slave_csn_int = 1'b1;
        #`DELAY_BETWEEN_SPI;
        w_spi_slave_csn_int = 1'b0;
        //padmode_spi_master = use_qspi ? `SPI_QUAD_TX : `SPI_STD;
        #100 spi_send_cmd_addr(use_qspi, 8'hB, spi_addr);

        // dummy cycles
        //padmode_spi_master = use_qspi ? `SPI_QUAD_RX : `SPI_STD;
        for (int i = 33; i >= 0; i--) begin
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
        end
      end
      spi_recv_data(use_qspi, spi_data_recv[31:0]);

      if (spi_data_recv != spi_data)
        $display("%t: [SPI] Readback has failed, expected %X, got %X", $time, spi_data,
                 spi_data_recv);

      num_stim_i   = num_stim_i + 1;  // increment stimuli_i
      spi_addr_old = spi_addr;
      if (num_stim_i > 9999 | stimuli_i[num_stim_i] === 64'bx)  // make sure we have more stimuli_i
        more_stim = 0;  // if not set variable to 0, will prevent additional stimuli to be applied
    end  // end while loop
    #100 w_spi_slave_csn_int = 1'b1;
    #`DELAY_BETWEEN_SPI;
    //padmode_spi_master = use_qspi ? `SPI_QUAD_TX : `SPI_STD;
  end
endtask

task spi_write_reg;
  input use_qspi;
  input [7:0] command;
  input [7:0] reg_val;
  begin
    //padmode_spi_master = use_qspi ? `SPI_QUAD_TX : `SPI_STD;
    w_spi_slave_csn_int = 1'b0;
    #100;
    if (use_qspi) begin
      for (int i = 2; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = command[4*i-1];
        w_spi_slave_sdio_int[2] = command[4*i-2];
        w_spi_slave_sdio_int[1] = command[4*i-3];
        w_spi_slave_sdio_int[0] = command[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 7; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = command[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end

    if (use_qspi) begin
      for (int i = 2; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = reg_val[4*i-1];
        w_spi_slave_sdio_int[2] = reg_val[4*i-2];
        w_spi_slave_sdio_int[1] = reg_val[4*i-3];
        w_spi_slave_sdio_int[0] = reg_val[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (int i = 7; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = reg_val[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
    #100 w_spi_slave_csn_int = 1'b1;
    #`DELAY_BETWEEN_SPI;
  end
endtask

task spi_write_word;
  input use_qspi;
  input [31:0] addr;
  input [31:0] data;
  begin
    w_spi_slave_csn_int = 1'b0;
    #`DELAY_BETWEEN_SPI;
    spi_send_cmd_addr(use_qspi, 8'h2, addr);
    spi_send_data(use_qspi, data);
    #100 w_spi_slave_csn_int = 1'b1;
    #`DELAY_BETWEEN_SPI;
  end
endtask

task spi_read_nword;
  input use_qspi;
  input [31:0] addr;
  input int n;
  inout [31:0] data[];

  logic [7:0] command;
  int i;
  int j;
  begin
    command             = 8'hB;
    //padmode_spi_master = use_qspi ? `SPI_QUAD_TX : `SPI_STD;
    w_spi_slave_sck_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    w_spi_slave_csn_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    if (use_qspi) begin
      for (i = 2; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = command[4*i-1];
        w_spi_slave_sdio_int[2] = command[4*i-2];
        w_spi_slave_sdio_int[1] = command[4*i-3];
        w_spi_slave_sdio_int[0] = command[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (i = 7; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = command[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
    if (use_qspi) begin
      for (i = 8; i > 0; i--) begin
        w_spi_slave_sdio_int[3] = addr[4*i-1];
        w_spi_slave_sdio_int[2] = addr[4*i-2];
        w_spi_slave_sdio_int[1] = addr[4*i-3];
        w_spi_slave_sdio_int[0] = addr[4*i-4];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end else begin
      for (i = 31; i >= 0; i--) begin
        w_spi_slave_sdio_int[0] = addr[i];
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
        #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
      end
    end
    //padmode_spi_master = use_qspi ? `SPI_QUAD_RX : `SPI_STD;
    for (i = 32; i >= 0; i--) begin
      #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
      #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    end
    if (use_qspi) begin
      for (j = 0; j < n; j++) begin
        for (i = 8; i > 0; i--) begin
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
          data[j][4*i-1] = w_spi_slave_sdio[3];
          data[j][4*i-2] = w_spi_slave_sdio[2];
          data[j][4*i-3] = w_spi_slave_sdio[1];
          data[j][4*i-4] = w_spi_slave_sdio[0];
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
        end
      end
    end else begin
      for (j = 0; j < n; j++) begin
        for (i = 31; i >= 0; i--) begin
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 1;
          data[j][i] = w_spi_slave_sdio[1];
          #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
        end
      end
    end
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    w_spi_slave_csn_int = 1;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    #`SPI_SEMIPERIOD w_spi_slave_sck_int = 0;
    //padmode_spi_master = use_qspi ? `SPI_QUAD_TX : `SPI_STD;
  end
endtask

task spi_read_word;
  input use_qspi;
  input [31:0] addr;
  output [31:0] data;

  logic [31:0] tmp[1];
  begin
    spi_read_nword(use_qspi, addr, 1, tmp);
    data = tmp[0];
  end
endtask

task spi_write_halfword;
  input use_qspi;
  input [31:0] addr;
  input [15:0] data;

  logic [31:0] temp;
  begin
    spi_read_word(use_qspi, {addr[31:2], 2'b00}, temp);

    case (addr[1])
      1'b0: temp[15:0] = data[15:0];
      1'b1: temp[31:16] = data[15:0];
    endcase

    spi_write_word(use_qspi, {addr[31:2], 2'b00}, temp);
  end
endtask

task spi_write_byte;
  input use_qspi;
  input [31:0] addr;
  input [7:0] data;

  logic [31:0] temp;
  begin
    spi_read_word(use_qspi, {addr[31:2], 2'b00}, temp);

    case (addr[1:0])
      2'b00: temp[7:0] = data[7:0];
      2'b01: temp[15:8] = data[7:0];
      2'b10: temp[23:16] = data[7:0];
      2'b11: temp[31:24] = data[7:0];
    endcase

    spi_write_word(use_qspi, {addr[31:2], 2'b00}, temp);
  end
endtask

task spi_read_halfword;
  input use_qspi;
  input [31:0] addr;
  output [15:0] data;

  logic [31:0] temp;
  begin
    spi_read_word(use_qspi, {addr[31:2], 2'b00}, temp);

    case (addr[1])
      1'b0: data[15:0] = temp[15:0];
      1'b1: data[15:0] = temp[31:16];
    endcase
  end
endtask

task spi_read_byte;
  input use_qspi;
  input [31:0] addr;
  output [7:0] data;

  logic [31:0] temp;
  begin
    spi_read_word(use_qspi, {addr[31:2], 2'b00}, temp);

    case (addr[1:0])
      2'b00: data[7:0] = temp[7:0];
      2'b01: data[7:0] = temp[15:8];
      2'b10: data[7:0] = temp[23:16];
      2'b11: data[7:0] = temp[31:24];
    endcase
  end
endtask

task spi_enable_qpi;
  $display("[SPI] Enabling QPI mode");
  //Sets QPI mode
  spi_write_reg(0, 8'h1, 8'h1);

  //padmode_spi_master = `SPI_QUAD_TX;
endtask

// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Antonio Mastrandrea (a.mastrandrea@unibo.it)


`define CONFIG_1_I2C 4'h0  //r-w    : endianess, slave address
`define CONFIG_2_I2C 4'h4  //r-w    : L2 Base address
`define CONFIG_3_I2C 4'h8  //r-w    : configuartion

module axi_apb_i2c_slave #(
    //axi4
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_USER_WIDTH = 6,
    parameter AXI_ID_WIDTH   = 3,
    //apb
    parameter APB_ADDR_WIDTH = 12,
    //base address 
    parameter BASE_ADDRESS   = 32'h1C01_0000
) (
    //other Signal
    input logic clk_i,  // master clock
    input logic rstn_i, // asynchronous active low reset

    // I2C signals
    input  logic scl_i,
    output logic scl_o,
    output logic scl_oe, // output enable

    input  logic sda_i,
    output logic sda_o,
    output logic sda_oe, // output enable


    //interrupt:
    output logic int1_o,


    //apb
    input  logic                      HCLK_i,
    input  logic                      HRESETn_i,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR_i,
    input  logic [              31:0] PWDATA_i,
    input  logic                      PWRITE_i,
    input  logic                      PSEL_i,
    input  logic                      PENABLE_i,
    output logic [              31:0] PRDATA_o,
    output logic                      PREADY_o,
    output logic                      PSLVERR_o,

    //*******************************************************
    // AXI4 MASTER
    //*******************************************************
    input  logic                      axi_aclk_i,
    input  logic                      axi_aresetn_i,
    // WRITE ADDRESS CHANNEL
    output logic                      axi_master_aw_valid_o,
    output logic [AXI_ADDR_WIDTH-1:0] axi_master_aw_addr_o,
    output logic [               2:0] axi_master_aw_prot_o,
    output logic [               3:0] axi_master_aw_region_o,
    output logic [               7:0] axi_master_aw_len_o,
    output logic [               2:0] axi_master_aw_size_o,
    output logic [               1:0] axi_master_aw_burst_o,
    output logic                      axi_master_aw_lock_o,
    output logic [               3:0] axi_master_aw_cache_o,
    output logic [               3:0] axi_master_aw_qos_o,
    output logic [  AXI_ID_WIDTH-1:0] axi_master_aw_id_o,
    output logic [AXI_USER_WIDTH-1:0] axi_master_aw_user_o,
    input  logic                      axi_master_aw_ready_i,

    // READ ADDRESS CHANNEL
    output logic                      axi_master_ar_valid_o,
    output logic [AXI_ADDR_WIDTH-1:0] axi_master_ar_addr_o,
    output logic [               2:0] axi_master_ar_prot_o,
    output logic [               3:0] axi_master_ar_region_o,
    output logic [               7:0] axi_master_ar_len_o,
    output logic [               2:0] axi_master_ar_size_o,
    output logic [               1:0] axi_master_ar_burst_o,
    output logic                      axi_master_ar_lock_o,
    output logic [               3:0] axi_master_ar_cache_o,
    output logic [               3:0] axi_master_ar_qos_o,
    output logic [  AXI_ID_WIDTH-1:0] axi_master_ar_id_o,
    output logic [AXI_USER_WIDTH-1:0] axi_master_ar_user_o,
    input  logic                      axi_master_ar_ready_i,

    // WRITE DATA CHANNEL
    output logic                        axi_master_w_valid_o,
    output logic [  AXI_DATA_WIDTH-1:0] axi_master_w_data_o,
    output logic [AXI_DATA_WIDTH/8-1:0] axi_master_w_strb_o,
    output logic [  AXI_USER_WIDTH-1:0] axi_master_w_user_o,
    output logic                        axi_master_w_last_o,
    input  logic                        axi_master_w_ready_i,

    // READ DATA CHANNEL
    input  logic                      axi_master_r_valid_i,
    input  logic [AXI_DATA_WIDTH-1:0] axi_master_r_data_i,
    input  logic [               1:0] axi_master_r_resp_i,
    input  logic                      axi_master_r_last_i,
    input  logic [  AXI_ID_WIDTH-1:0] axi_master_r_id_i,
    input  logic [AXI_USER_WIDTH-1:0] axi_master_r_user_i,
    output logic                      axi_master_r_ready_o,

    // WRITE RESPONSE CHANNEL
    input  logic                      axi_master_b_valid_i,
    input  logic [               1:0] axi_master_b_resp_i,
    input  logic [  AXI_ID_WIDTH-1:0] axi_master_b_id_i,
    input  logic [AXI_USER_WIDTH-1:0] axi_master_b_user_i,
    output logic                      axi_master_b_ready_o
    //*******************************************************
);

  //internal signal/reg
  //TODO
  logic [31:0] data32_w;
  logic        valid_w;
  logic [ 3:0] strb_w;
  logic [31:0] address_w;

  logic [31:0] address_r;
  logic        valid_r;

  logic        lasttrans;
  logic        starti2c;

  logic        axi_int_w_ready;
  logic        axi_int_w_valid;


  // axi:
  enum logic [2:0] {
    IDLE,
    AXIADDR,
    AXIDATA,
    AXIRESP
  }
      AW_CS, AW_NS, AR_CS, AR_NS;
  logic rx_valid;
  logic start_tx;
  logic sample_axidata;
  logic tx_valid;

  logic [6:0] slv_address7b;
  logic little_end;

  //i2c slave instance
  //TODO READ
  i2cslave i_i2cslave (
      .clk_i (clk_i),
      .rst_ni(rstn_i),

      .sda_i (sda_i),
      .sda_o (sda_o),
      .sda_oe(sda_oe),

      .scl_i (scl_i),
      .scl_o (scl_o),
      .scl_oe(scl_oe),

      .data32_o(data32_w),
      .valid_o (valid_w),
      .strb_o  (strb_w),

      .address_w_o(address_w),

      .data32_i     (axi_master_r_data_i[31:0]),
      .sample_data_i(sample_axidata),

      .address_r_o  (address_r),
      .valid_r_add_o(valid_r),
	  
	  .slave_address_i(slv_address7b),
	  .little_end_i (little_end),

      .test_start(starti2c),
      .test_stop (lasttrans)
  );


  
  logic interr_int;
  logic enable_int;
  enum logic [1:0] {
    TRANSF_IDLE,
    TRANSF_RESP
  } WR_TRANSF_CS, WR_TRANSF_NS;

  //i2c slave interrupt
  
  
  
  assign int1_o = interr_int & enable_int;
  
  

  //*********************
  //     apb logic     //
  //*********************
  logic s_apb_write;
  logic [3:0] s_apb_addr;
  logic [31:0] reg_1;
  logic [31:0] reg_2;
  logic [31:0] reg_3;

  assign s_apb_write = PSEL_i && PENABLE_i && PWRITE_i;

  assign s_apb_addr  = PADDR_i[3:0];
  
  
  //assign address to i2c slave:
  assign slv_address7b = reg_1[6:0];
  
  assign little_end = reg_1[8]; //0: little endian; 1: big endian

  assign enable_int =reg_3[0];
  
  
  //write logic:
  always_ff @(posedge HCLK_i, negedge HRESETn_i) begin
    if (~HRESETn_i) begin
      reg_1     <= {23'h0,1'b0,8'b00100101};  //little endian  slave address=0x25 
      reg_2     <= BASE_ADDRESS; //32'h1C01_0000;  //32'h1a15_0000;  //0x1a15_0000 i2c_slave start address
      reg_3     <= 32'h0000_0000;  //enable interrupt 
    end else begin
      if (s_apb_write) begin
        if (s_apb_addr == `CONFIG_1_I2C) begin
          reg_1 <= PWDATA_i;
        end else if (s_apb_addr == `CONFIG_2_I2C) begin
          reg_2 <= PWDATA_i;
        end else if (s_apb_addr == `CONFIG_3_I2C) begin
          reg_3 <= PWDATA_i;
        end
      end
	  if (interr_int) begin
		reg_3[1] <= 1'b1;
	  end
/*      //test axi
      if (reg_3[1:0] == 3) begin
        reg_3[1:0] <= 0;
      end
*/    end
  end

  //read logic
  always_comb begin
    PRDATA_o = '0;
    case (s_apb_addr)
      `CONFIG_1_I2C: PRDATA_o = reg_1;
      `CONFIG_2_I2C: PRDATA_o = reg_2;
      `CONFIG_3_I2C: PRDATA_o = reg_3;
      default:       PRDATA_o = 32'b0;
    endcase
  end

  assign PREADY_o  = 1'b1;
  assign PSLVERR_o = 1'b0;


  //*********************
  //      axi logic    //
  //*********************

  //TODO:
  //




  assign rx_valid  = valid_w;
  assign start_tx  = valid_r;

  always_ff @(posedge axi_aclk_i or negedge axi_aresetn_i) begin
    if (axi_aresetn_i == 0) begin
      AW_CS <= IDLE;
      AR_CS <= IDLE;
    end else begin
      AW_CS <= AW_NS;
      AR_CS <= AR_NS;
    end
  end

  //***********************************
  //TODO:  add stream_fork
  //***********************************
  // "stream_fork" module is used to decouple AW and W channels
  stream_fork #(
      .N_OUP(2)
  ) stream_fork_i (
      .clk_i  (axi_aclk_i),
      .rst_ni (axi_aresetn_i),
      .valid_i(axi_int_w_valid),
      .ready_o(axi_int_w_ready),
      .valid_o({axi_master_w_valid_o, axi_master_aw_valid_o}),
      .ready_i({axi_master_w_ready_i, axi_master_aw_ready_i})
  );


  //write FSM
  always_comb begin
    AW_NS                = IDLE;
    axi_int_w_valid      = 1'b0;
    axi_master_b_ready_o = 1'b0;
    case (AW_CS)
      IDLE: begin
        if (rx_valid) begin
          AW_NS = AXIDATA;
        end else begin
          AW_NS = IDLE;
        end
      end
      AXIDATA: begin
        axi_int_w_valid = 1'b1;
        if (axi_int_w_ready) begin
          AW_NS = AXIRESP;
        end else AW_NS = AXIDATA;
      end
      AXIRESP: begin
        axi_master_b_ready_o = 1'b1;
        if (axi_master_b_valid_i) AW_NS = IDLE;
        else AW_NS = AXIRESP;
      end

    endcase
  end

  //read FSM
  always_comb begin
    AR_NS                 = IDLE;
    tx_valid              = 1'b0;
    axi_master_ar_valid_o = 1'b0;
    axi_master_r_ready_o  = 1'b0;
    sample_axidata        = 1'b0;

    case (AR_CS)

      IDLE: begin
        if (start_tx) begin
          AR_NS = AXIADDR;
        end else begin
          AR_NS = IDLE;
        end
      end

      AXIDATA: begin
        //it is ok?
        tx_valid = 1'b1;

        AR_NS = IDLE;
      end
      AXIADDR: begin
        axi_master_ar_valid_o = 1'b1;
        if (axi_master_ar_ready_i) AR_NS = AXIRESP;
        else AR_NS = AXIADDR;
      end

      AXIRESP: begin
        axi_master_r_ready_o = 1'b1;
        if (axi_master_r_valid_i) begin
          sample_axidata = 1'b1;
          AR_NS = AXIDATA;
        end else AR_NS = AXIRESP;
      end

    endcase
  end




  assign axi_master_aw_addr_o   = reg_2 + address_w - 32'h4;
  assign axi_master_aw_prot_o   = 'h0;
  assign axi_master_aw_region_o = 'h0;
  assign axi_master_aw_len_o    = 'h0;  // 1 trans
  assign axi_master_aw_size_o   = 3'b010;  // 4 Bytes
  assign axi_master_aw_burst_o  = 'h0;
  assign axi_master_aw_lock_o   = 'h0;
  assign axi_master_aw_cache_o  = 'h0;
  assign axi_master_aw_qos_o    = 'h0;
  assign axi_master_aw_id_o     = 'h1;
  assign axi_master_aw_user_o   = 'h0;

  assign axi_master_w_data_o    = data32_w;
  assign axi_master_w_strb_o    = strb_w;

  assign axi_master_w_user_o    = 'h0;
  assign axi_master_w_last_o    = 1'b1;


  //AXI read assign:
  assign axi_master_ar_addr_o   = reg_2 + address_r;
  assign axi_master_ar_prot_o   = 'h0;
  assign axi_master_ar_region_o = 'h0;
  assign axi_master_ar_len_o    = 'h0;  // 1 trans
  assign axi_master_ar_size_o   = 3'b010;  // 4 Bytes
  assign axi_master_ar_burst_o  = 'h0;
  assign axi_master_ar_lock_o   = 'h0;
  assign axi_master_ar_cache_o  = 'h0;
  assign axi_master_ar_qos_o    = 'h0;
  assign axi_master_ar_id_o     = 'h1;
  assign axi_master_ar_user_o   = 'h0;
  
  
  
  //interrupt routine: interr_int and lasttrans 
  
  //state machine interrupt:
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (rstn_i == 0) begin
      WR_TRANSF_CS <= TRANSF_IDLE;
    end else begin
      WR_TRANSF_CS <= WR_TRANSF_NS;
    end
  end
  
  always_comb begin
    WR_TRANSF_NS = TRANSF_IDLE;
    interr_int   = 1'b0;
    case (WR_TRANSF_CS)
	
      TRANSF_IDLE: begin
        if (lasttrans) begin
          WR_TRANSF_NS = TRANSF_RESP;
        end else begin
          WR_TRANSF_NS = TRANSF_IDLE;
        end
      end

      TRANSF_RESP: begin
        if (axi_master_b_valid_i) begin
           interr_int = 1'b1;
		   WR_TRANSF_NS = TRANSF_IDLE;
		end else begin
		   interr_int = 1'b0;
		   WR_TRANSF_NS = TRANSF_RESP;
		end
        

      end

    endcase
  end
  

endmodule

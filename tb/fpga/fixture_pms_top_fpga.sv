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


`include "axi/assign.svh"
`include "axi/typedef.svh"

//`define JTAG_BOOT  //1 for JTAG, 0 for PRELOADED. todo: change this

module fixture_pms_top_fpga;
  import pms_top_pkg::*;

  parameter CONFIG_FILE = "NONE";

  // Simulation platform parameters

  // Choose your core: 0 for RISCY, 1 for ZERORISCY
  parameter CORE_TYPE = 0;
  // if RISCY is instantiated (CORE_TYPE == 0), RISCY_FPU enables the FPU
  parameter RISCY_FPU = 1;

  // TODO: period of the system clock (600MhZ)
  // period of the external reference clock (100MhZ)
  parameter REF_CLK_PERIOD = 10ns;

  // how L2 is loaded. valid values are "JTAG" or "STANDALONE", the latter works only when USE_S25FS256S_MODEL is 1
  parameter LOAD_L2 = "PRELOADED";

  // configuration address constants
  localparam logic [31:0] SOC_CTRL_BOOT_ADDR        = 32'h1A10_4004;
  localparam logic [31:0] SOC_CTRL_FETCH_EN_ADDR    = 32'h1A10_4008;
  localparam logic [31:0] SOC_CTRL_BOOTSEL_ADDR     = 32'h1A10_40C4;
  localparam logic [31:0] SOC_CTRL_CORE_STATUS_ADDR = 32'h1A10_40A0;

  // UART baud rate in bps
  parameter BAUDRATE = 115200;

  // use frequency-locked loop to generate internal clock
  parameter USE_FLL = 1;

  // for PULP, 8 cores
  parameter NB_CORES = 8;

  // SPI standards, do not change
  parameter logic [1:0] SPI_STD = 2'b00;
  parameter logic [1:0] SPI_QUAD_TX = 2'b01;
  parameter logic [1:0] SPI_QUAD_RX = 2'b10;

  // exit
  localparam int EXIT_SUCCESS = 0;
  localparam int EXIT_FAIL = 1;
  localparam int EXIT_ERROR = -1;

  int stim_fd;
  int num_stim = 0;
  int ret_code;
  logic [95:0] stimuli;  // array for the stimulus vectors

  // Monitor boot process for AXI handshake check
  logic is_test_axi = 1'b1;
  logic is_preload = 1'b1;
  logic is_entry_point = 1'b1;
  logic is_bootaddr = 1'b1;

  logic s_jtag_trst;
  logic s_jtag_tck;
  logic s_jtag_tdi;
  logic s_jtag_tms;
  logic s_jtag_tdo;

  logic s_avs_start;
  logic s_avs_mdata;
  logic s_avs_sdata;
  logic s_avs_clk;
  logic s_avs_mode;

  wire w_slp_s3;
  wire w_slp_s4;
  wire w_slp_s5;
  wire w_sys_reset;
  wire w_sys_rsmrst;
  wire w_sys_pwr_btn;
  wire w_sys_pwrgd_in;
  wire w_sys_wake;
  wire w_cpu_pwrgd_out;
  wire w_cpu_throttle_0;
  wire w_cpu_throttle_1;
  wire w_cpu_thermtrip;
  wire w_cpu_errcode_0;
  wire w_cpu_errcode_1;
  wire w_cpu_errcode_2;
  wire w_cpu_errcode_3;
  wire w_cpu_reset_out_n;
  wire w_cpu_socket_id_0;
  wire w_cpu_socket_id_1;
  wire w_cpu_strap_0;
  wire w_cpu_strap_1;
  wire w_cpu_strap_2;
  wire w_cpu_strap_3;

  logic s_sys_pwr_btn;

  // simulation vars
  logic uart_tb_rx_en = 1'b0;

  logic dev_dpi_en = 0;

  int exit_status = EXIT_ERROR;  // modelsim exit code, will be overwritten when successfull

  logic s_rst_n = 1'b0;
  wire w_rst_n;

  logic s_clk_ref;
  wire w_clk_ref;

  tri w_uart_rx;
  tri w_uart_tx;

  wire [N_I2C-1:0] w_i2c_scl;
  wire [N_I2C-1:0] w_i2c_sda;

  wire [N_I2C_SLV-1:0] w_i2c_slv_scl;
  wire [N_I2C_SLV-1:0] w_i2c_slv_sda;

  wire w_avs_mdata;
  wire w_avs_sdata;
  wire w_avs_clk;

  // System wires for control_pulp_txilzu9eg flatten ports

  logic [15:0] ps_mst_aw_id;
  logic [39:0] ps_mst_aw_addr;
  logic [7:0] ps_mst_aw_len;
  logic [2:0] ps_mst_aw_size;
  logic [1:0] ps_mst_aw_burst;
  logic ps_mst_aw_lock;
  logic [3:0] ps_mst_aw_cache;
  logic [2:0] ps_mst_aw_prot;
  logic [3:0] ps_mst_aw_qos;
  logic [5:0] ps_mst_aw_atop;
  logic [15:0] ps_mst_aw_user;
  logic ps_mst_aw_valid;
  logic ps_mst_aw_ready;
  logic [63:0] ps_mst_w_data;
  logic [7:0] ps_mst_w_strb;
  logic ps_mst_w_last;
  logic ps_mst_w_valid;
  logic ps_mst_w_ready;
  logic [15:0] ps_mst_b_id;
  logic [1:0] ps_mst_b_resp;
  logic ps_mst_b_valid;
  logic ps_mst_b_ready;
  logic [15:0] ps_mst_ar_id;
  logic [39:0] ps_mst_ar_addr;
  logic [7:0] ps_mst_ar_len;
  logic [2:0] ps_mst_ar_size;
  logic [1:0] ps_mst_ar_burst;
  logic ps_mst_ar_lock;
  logic [3:0] ps_mst_ar_cache;
  logic [2:0] ps_mst_ar_prot;
  logic [3:0] ps_mst_ar_qos;
  logic [15:0] ps_mst_ar_user;
  logic ps_mst_ar_valid;
  logic ps_mst_ar_ready;
  logic [15:0] ps_mst_r_id;
  logic [63:0] ps_mst_r_data;
  logic [1:0] ps_mst_r_resp;
  logic ps_mst_r_last;
  logic ps_mst_r_valid;
  logic ps_mst_r_ready;


  logic [5:0] ps_slv_aw_id;
  logic [48:0] ps_slv_aw_addr;
  logic [7:0] ps_slv_aw_len;
  logic [2:0] ps_slv_aw_size;
  logic [1:0] ps_slv_aw_burst;
  logic ps_slv_aw_lock;
  logic [3:0] ps_slv_aw_cache;
  logic [2:0] ps_slv_aw_prot;
  logic [3:0] ps_slv_aw_qos;
  logic [5:0] ps_slv_aw_atop;
  logic ps_slv_aw_user;
  logic ps_slv_aw_valid;
  logic ps_slv_aw_ready;
  logic [63:0] ps_slv_w_data;
  logic [7:0] ps_slv_w_strb;
  logic ps_slv_w_last;
  logic ps_slv_w_valid;
  logic ps_slv_w_ready;
  logic [5:0] ps_slv_b_id;
  logic [1:0] ps_slv_b_resp;
  logic ps_slv_b_valid;
  logic ps_slv_b_ready;
  logic [5:0] ps_slv_ar_id;
  logic [48:0] ps_slv_ar_addr;
  logic [7:0] ps_slv_ar_len;
  logic [2:0] ps_slv_ar_size;
  logic [1:0] ps_slv_ar_burst;
  logic ps_slv_ar_lock;
  logic [3:0] ps_slv_ar_cache;
  logic [2:0] ps_slv_ar_prot;
  logic [3:0] ps_slv_ar_qos;
  logic ps_slv_ar_user;
  logic ps_slv_ar_valid;
  logic ps_slv_ar_ready;
  logic [5:0] ps_slv_r_id;
  logic [63:0] ps_slv_r_data;
  logic [1:0] ps_slv_r_resp;
  logic ps_slv_r_last;
  logic ps_slv_r_valid;
  logic ps_slv_r_ready;


  assign s_jtag_trst   = 1'b0;
  assign s_jtag_tck    = 1'b0;
  assign s_jtag_tdi    = 1'b0;
  assign s_jtag_tms    = 1'b0;

  assign w_rst_n       = s_rst_n;
  assign w_clk_ref     = s_clk_ref;

  // Control PWR_BTN GPIO for ACPI test
  assign w_sys_pwr_btn = s_sys_pwr_btn;

  // Control I2C slave signals
  logic sdaOm;
  logic sclOm;  //output master
  logic sdaIm;
  logic sclIm;  // input master
  assign (highz1, strong0) w_i2c_slv_scl[0] = sclOm;
  assign (highz1, strong0) w_i2c_slv_sda[0] = sdaOm;
  assign                   sdaIm            = w_i2c_slv_sda[0];
  assign                   sclIm            = w_i2c_slv_scl[0];

  // Control AVS signals
  assign                   s_avs_mdata      = w_avs_mdata;
  assign                   s_avs_clk        = w_avs_clk;
  assign (highz0, strong1) w_avs_sdata      = s_avs_sdata;


  // UART receiver and sender
  uart_sim #(
    .BAUD_RATE(BAUDRATE),
    .PARITY_EN(0)
  ) i_uart_sim (
    .rx   (w_uart_rx),
    .rx_en(uart_tb_rx_en),
    .tx   (w_uart_tx)
  );

  // I2C memory models
`ifdef USE_I2C_VIP
  for (genvar i = 0; i < N_I2C; i++) begin : gen_vip_i2c_mem
    M24FC1025 i_i2c_mem (
                  .A0   (1'b0),
    .A1   (1'b0),
    .A2   (1'b1),
    .WP   (1'b0),
    .SDA  (w_i2c_sda[i]),
    .SCL  (w_i2c_scl[i]),
    .RESET(1'b0)
      );
  end  // block: gen_vip_i2c_mem
`endif

  // Define axi request (req) and response (resp) type structs for wrapped master port of control_pulp_txilzu9eg, used here in axi_sim_mem

  localparam int unsigned AXI_ID_WIDTH_PS_SLV = 6;
  localparam int unsigned AXI_USER_WIDTH_PS_SLV = 1;
  localparam int unsigned AXI_DATA_WIDTH_PS_SLV = 64;
  localparam int unsigned AXI_STRB_WIDTH_PS_SLV = AXI_DATA_WIDTH_PS_SLV / 8;
  localparam int unsigned AXI_ADDR_WIDTH_PS_SLV = 49;

  typedef logic [AXI_ID_WIDTH_PS_SLV-1:0] axi_id_ps_slv_t;
  typedef logic [AXI_USER_WIDTH_PS_SLV-1:0] axi_user_ps_slv_t;
  typedef logic [AXI_DATA_WIDTH_PS_SLV-1:0] axi_data_ps_slv_t;
  typedef logic [AXI_STRB_WIDTH_PS_SLV-1:0] axi_strb_ps_slv_t;
  typedef logic [AXI_ADDR_WIDTH_PS_SLV-1:0] axi_addr_ps_slv_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_ps_slv_t, axi_addr_ps_slv_t, axi_id_ps_slv_t, axi_user_ps_slv_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_ps_slv_t, axi_data_ps_slv_t, axi_strb_ps_slv_t, axi_user_ps_slv_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_ps_slv_t, axi_id_ps_slv_t, axi_user_ps_slv_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_ps_slv_t, axi_addr_ps_slv_t, axi_id_ps_slv_t, axi_user_ps_slv_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_ps_slv_t, axi_data_ps_slv_t, axi_id_ps_slv_t, axi_user_ps_slv_t);

  `AXI_TYPEDEF_REQ_T(axi_req_ps_slv_t, axi_aw_ps_slv_t, axi_w_ps_slv_t, axi_ar_ps_slv_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_ps_slv_t, axi_b_ps_slv_t, axi_r_ps_slv_t);

  // Build PS final slave ports (after conversions)
  axi_req_ps_slv_t to_ps_req;
  axi_resp_ps_slv_t to_ps_resp;

  // Connect req/resp structs of axi_sim_mem and exploded ports of control_pulp_txilzu9eg_vivado
  // NB some signals are commented; this means that they are not present in the `_vivado.v` top-level: uncomment if needed + modify `_vivado.v` top-level

  assign to_ps_req.aw.id    = ps_slv_aw_id;
  assign to_ps_req.aw.addr  = ps_slv_aw_addr;
  assign to_ps_req.aw.len   = ps_slv_aw_len;
  assign to_ps_req.aw.size  = ps_slv_aw_size;
  assign to_ps_req.aw.burst = ps_slv_aw_burst;
  assign to_ps_req.aw.lock  = ps_slv_aw_lock;
  assign to_ps_req.aw.cache = ps_slv_aw_cache;
  assign to_ps_req.aw.prot  = ps_slv_aw_prot;
  assign to_ps_req.aw.qos   = ps_slv_aw_qos;
  //assign to_ps_req.aw.region                = ps_slv_aw_region     ;
  assign to_ps_req.aw.atop  = ps_slv_aw_atop;
  assign to_ps_req.aw.user  = ps_slv_aw_user;
  assign to_ps_req.aw_valid = ps_slv_aw_valid;
  assign ps_slv_aw_ready    = to_ps_resp.aw_ready;
  assign to_ps_req.w.data   = ps_slv_w_data;
  assign to_ps_req.w.strb   = ps_slv_w_strb;
  assign to_ps_req.w.last   = ps_slv_w_last;
  //assign to_ps_req.w.user                   = ps_slv_w_user        ;
  assign to_ps_req.w_valid  = ps_slv_w_valid;
  assign ps_slv_w_ready     = to_ps_resp.w_ready;
  assign ps_slv_b_id        = to_ps_resp.b.id;
  assign ps_slv_b_resp      = to_ps_resp.b.resp;
  //assign ps_slv_b_user                      = to_ps_resp.b.user    ;
  assign ps_slv_b_valid     = to_ps_resp.b_valid;
  assign to_ps_req.b_ready  = ps_slv_b_ready;
  assign to_ps_req.ar.id    = ps_slv_ar_id;
  assign to_ps_req.ar.addr  = ps_slv_ar_addr;
  assign to_ps_req.ar.len   = ps_slv_ar_len;
  assign to_ps_req.ar.size  = ps_slv_ar_size;
  assign to_ps_req.ar.burst = ps_slv_ar_burst;
  assign to_ps_req.ar.lock  = ps_slv_ar_lock;
  assign to_ps_req.ar.cache = ps_slv_ar_cache;
  assign to_ps_req.ar.prot  = ps_slv_ar_prot;
  assign to_ps_req.ar.qos   = ps_slv_ar_qos;
  //assign to_ps_req.ar.region                = ps_slv_ar_region     ;
  assign to_ps_req.ar.user  = ps_slv_ar_user;
  assign to_ps_req.ar_valid = ps_slv_ar_valid;
  assign ps_slv_ar_ready    = to_ps_resp.ar_ready;
  assign ps_slv_r_id        = to_ps_resp.r.id;
  assign ps_slv_r_data      = to_ps_resp.r.data;
  assign ps_slv_r_resp      = to_ps_resp.r.resp;
  assign ps_slv_r_last      = to_ps_resp.r.last;
  //assign ps_slv_r_user                      = to_ps_resp.r.user    ;
  assign ps_slv_r_valid     = to_ps_resp.r_valid;
  assign to_ps_req.r_ready  = ps_slv_r_ready;

  // Define axi request (req) and response (resp) type structs for wrapped slave port of control_pulp_txilzu9eg

  localparam int unsigned AXI_ID_WIDTH_PS_MST = 16;
  localparam int unsigned AXI_USER_WIDTH_PS_MST = 16;
  localparam int unsigned AXI_DATA_WIDTH_PS_MST = 64;
  localparam int unsigned AXI_STRB_WIDTH_PS_MST = AXI_DATA_WIDTH_PS_MST / 8;
  localparam int unsigned AXI_ADDR_WIDTH_PS_MST = 40;

  typedef logic [AXI_ID_WIDTH_PS_MST-1:0] axi_id_ps_mst_t;
  typedef logic [AXI_USER_WIDTH_PS_MST-1:0] axi_user_ps_mst_t;
  typedef logic [AXI_DATA_WIDTH_PS_MST-1:0] axi_data_ps_mst_t;
  typedef logic [AXI_STRB_WIDTH_PS_MST-1:0] axi_strb_ps_mst_t;
  typedef logic [AXI_ADDR_WIDTH_PS_MST-1:0] axi_addr_ps_mst_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_ps_mst_t, axi_addr_ps_mst_t, axi_id_ps_mst_t, axi_user_ps_mst_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_ps_mst_t, axi_data_ps_mst_t, axi_strb_ps_mst_t, axi_user_ps_mst_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_ps_mst_t, axi_id_ps_mst_t, axi_user_ps_mst_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_ps_mst_t, axi_addr_ps_mst_t, axi_id_ps_mst_t, axi_user_ps_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_ps_mst_t, axi_data_ps_mst_t, axi_id_ps_mst_t, axi_user_ps_mst_t);

  `AXI_TYPEDEF_REQ_T(axi_req_ps_mst_t, axi_aw_ps_mst_t, axi_w_ps_mst_t, axi_ar_ps_mst_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_ps_mst_t, axi_b_ps_mst_t, axi_r_ps_mst_t);

  // Build PS master
  axi_req_ps_mst_t from_ps_req;
  axi_resp_ps_mst_t from_ps_resp;

  // Connect req/resp structs of PS master (simulated here) and exploded ports of control_pulp_txilzu9eg_vivado
  // NB some signals are commented; this means that they are not present in the `_vivado.v` top-level: uncomment if needed + modify `_vivado.v` top-level

  assign ps_mst_aw_id          = from_ps_req.aw.id;
  assign ps_mst_aw_addr        = from_ps_req.aw.addr;
  assign ps_mst_aw_len         = from_ps_req.aw.len;
  assign ps_mst_aw_size        = from_ps_req.aw.size;
  assign ps_mst_aw_burst       = from_ps_req.aw.burst;
  assign ps_mst_aw_lock        = from_ps_req.aw.lock;
  assign ps_mst_aw_cache       = from_ps_req.aw.cache;
  assign ps_mst_aw_prot        = from_ps_req.aw.prot;
  assign ps_mst_aw_qos         = from_ps_req.aw.qos;
  //assign ps_mst_aw_region                         =   from_ps_req.aw.region      ;
  assign ps_mst_aw_atop        = from_ps_req.aw.atop;
  assign ps_mst_aw_user        = from_ps_req.aw.user;
  assign ps_mst_aw_valid       = from_ps_req.aw_valid;
  assign from_ps_resp.aw_ready = ps_mst_aw_ready;
  assign ps_mst_w_data         = from_ps_req.w.data;
  assign ps_mst_w_strb         = from_ps_req.w.strb;
  assign ps_mst_w_last         = from_ps_req.w.last;
  //assign ps_mst_w_user                            =   from_ps_req.w.user         ;
  assign ps_mst_w_valid        = from_ps_req.w_valid;
  assign from_ps_resp.w_ready  = ps_mst_w_ready;
  assign from_ps_resp.b.id     = ps_mst_b_id;
  assign from_ps_resp.b.resp   = ps_mst_b_resp;
  //assign from_ps_resp.b.user                      =   ps_mst_b_user              ;
  assign from_ps_resp.b_valid  = ps_mst_b_valid;
  assign ps_mst_b_ready        = from_ps_req.b_ready;
  assign ps_mst_ar_id          = from_ps_req.ar.id;
  assign ps_mst_ar_addr        = from_ps_req.ar.addr;
  assign ps_mst_ar_len         = from_ps_req.ar.len;
  assign ps_mst_ar_size        = from_ps_req.ar.size;
  assign ps_mst_ar_burst       = from_ps_req.ar.burst;
  assign ps_mst_ar_lock        = from_ps_req.ar.lock;
  assign ps_mst_ar_cache       = from_ps_req.ar.cache;
  assign ps_mst_ar_prot        = from_ps_req.ar.prot;
  assign ps_mst_ar_qos         = from_ps_req.ar.qos;
  //assign ps_mst_ar_region                         =   from_ps_req.ar.region      ;
  assign ps_mst_ar_user        = from_ps_req.ar.user;
  assign ps_mst_ar_valid       = from_ps_req.ar_valid;
  assign from_ps_resp.ar_ready = ps_mst_ar_ready;
  assign from_ps_resp.r.id     = ps_mst_r_id;
  assign from_ps_resp.r.data   = ps_mst_r_data;
  assign from_ps_resp.r.last   = ps_mst_r_last;
  assign from_ps_resp.r.resp   = ps_mst_r_resp;
  //assign from_ps_resp.r.user                      =   ps_mst_r_user              ;
  assign from_ps_resp.r_valid  = ps_mst_r_valid;
  assign ps_mst_r_ready        = from_ps_req.r_ready;

  // Instantiate control_pulp-txilzu9eg (flatten ports)
  pms_top_fpga_behav i_dut (

    // PS slave
    .ps_slv_aw_id_o   (ps_slv_aw_id),
    .ps_slv_aw_addr_o (ps_slv_aw_addr),
    .ps_slv_aw_len_o  (ps_slv_aw_len),
    .ps_slv_aw_size_o (ps_slv_aw_size),
    .ps_slv_aw_burst_o(ps_slv_aw_burst),
    .ps_slv_aw_lock_o (ps_slv_aw_lock),
    .ps_slv_aw_cache_o(ps_slv_aw_cache),
    .ps_slv_aw_prot_o (ps_slv_aw_prot),
    .ps_slv_aw_qos_o  (ps_slv_aw_qos),
    .ps_slv_aw_atop_o (ps_slv_aw_atop),   //atop
    .ps_slv_aw_user_o (ps_slv_aw_user),
    .ps_slv_aw_valid_o(ps_slv_aw_valid),
    .ps_slv_aw_ready_i(ps_slv_aw_ready),
    .ps_slv_w_data_o  (ps_slv_w_data),
    .ps_slv_w_strb_o  (ps_slv_w_strb),
    .ps_slv_w_last_o  (ps_slv_w_last),
    .ps_slv_w_valid_o (ps_slv_w_valid),
    .ps_slv_w_ready_i (ps_slv_w_ready),
    .ps_slv_b_id_i    (ps_slv_b_id),
    .ps_slv_b_resp_i  (ps_slv_b_resp),
    .ps_slv_b_valid_i (ps_slv_b_valid),
    .ps_slv_b_ready_o (ps_slv_b_ready),
    .ps_slv_ar_id_o   (ps_slv_ar_id),
    .ps_slv_ar_addr_o (ps_slv_ar_addr),
    .ps_slv_ar_len_o  (ps_slv_ar_len),
    .ps_slv_ar_size_o (ps_slv_ar_size),
    .ps_slv_ar_burst_o(ps_slv_ar_burst),
    .ps_slv_ar_lock_o (ps_slv_ar_lock),
    .ps_slv_ar_cache_o(ps_slv_ar_cache),
    .ps_slv_ar_prot_o (ps_slv_ar_prot),
    .ps_slv_ar_qos_o  (ps_slv_ar_qos),
    .ps_slv_ar_user_o (ps_slv_ar_user),
    .ps_slv_ar_valid_o(ps_slv_ar_valid),
    .ps_slv_ar_ready_i(ps_slv_ar_ready),
    .ps_slv_r_id_i    (ps_slv_r_id),
    .ps_slv_r_data_i  (ps_slv_r_data),
    .ps_slv_r_resp_i  (ps_slv_r_resp),
    .ps_slv_r_last_i  (ps_slv_r_last),
    .ps_slv_r_valid_i (ps_slv_r_valid),
    .ps_slv_r_ready_o (ps_slv_r_ready),

    // PS master
    .ps_mst_aw_id_i   (ps_mst_aw_id),
    .ps_mst_aw_addr_i (ps_mst_aw_addr),
    .ps_mst_aw_len_i  (ps_mst_aw_len),
    .ps_mst_aw_size_i (ps_mst_aw_size),
    .ps_mst_aw_burst_i(ps_mst_aw_burst),
    .ps_mst_aw_lock_i (ps_mst_aw_lock),
    .ps_mst_aw_cache_i(ps_mst_aw_cache),
    .ps_mst_aw_prot_i (ps_mst_aw_prot),
    .ps_mst_aw_qos_i  (ps_mst_aw_qos),
    .ps_mst_aw_atop_i (ps_mst_aw_atop),   //atop
    .ps_mst_aw_user_i (ps_mst_aw_user),
    .ps_mst_aw_valid_i(ps_mst_aw_valid),
    .ps_mst_aw_ready_o(ps_mst_aw_ready),
    .ps_mst_w_data_i  (ps_mst_w_data),
    .ps_mst_w_strb_i  (ps_mst_w_strb),
    .ps_mst_w_last_i  (ps_mst_w_last),
    .ps_mst_w_valid_i (ps_mst_w_valid),
    .ps_mst_w_ready_o (ps_mst_w_ready),
    .ps_mst_b_id_o    (ps_mst_b_id),
    .ps_mst_b_resp_o  (ps_mst_b_resp),
    .ps_mst_b_valid_o (ps_mst_b_valid),
    .ps_mst_b_ready_i (ps_mst_b_ready),
    .ps_mst_ar_id_i   (ps_mst_ar_id),
    .ps_mst_ar_addr_i (ps_mst_ar_addr),
    .ps_mst_ar_len_i  (ps_mst_ar_len),
    .ps_mst_ar_size_i (ps_mst_ar_size),
    .ps_mst_ar_burst_i(ps_mst_ar_burst),
    .ps_mst_ar_lock_i (ps_mst_ar_lock),
    .ps_mst_ar_cache_i(ps_mst_ar_cache),
    .ps_mst_ar_prot_i (ps_mst_ar_prot),
    .ps_mst_ar_qos_i  (ps_mst_ar_qos),
    .ps_mst_ar_user_i (ps_mst_ar_user),
    .ps_mst_ar_valid_i(ps_mst_ar_valid),
    .ps_mst_ar_ready_o(ps_mst_ar_ready),
    .ps_mst_r_id_o    (ps_mst_r_id),
    .ps_mst_r_data_o  (ps_mst_r_data),
    .ps_mst_r_resp_o  (ps_mst_r_resp),
    .ps_mst_r_last_o  (ps_mst_r_last),
    .ps_mst_r_valid_o (ps_mst_r_valid),
    .ps_mst_r_ready_i (ps_mst_r_ready),

    .soc_clk_o(s_soc_clk),  // clocks SoC, AXI

    .ref_clk    (w_clk_ref),
    .sys_clk    (w_clk_ref),
    .pad_reset  (w_rst_n),     // active_low
    .jtag_tdo_o (s_jtag_tdo),
    .jtag_tck_i (s_jtag_tck),
    .jtag_tdi_i (s_jtag_tdi),
    .jtag_tms_i (s_jtag_tms),
    .jtag_trst_i(s_jtag_trst),

    // EXT CHIP TP             PADS
    .pad_pmb_vr1_pms0_sda(w_i2c_sda[0]),  // I/O peripherals unconnected in this simulation
    .pad_pmb_vr1_pms0_scl(w_i2c_scl[0]),
    .pad_pmb_vr1_pms0_alert_n(),
    .pad_pmb_vr2_pms0_sda(w_i2c_sda[1]),
    .pad_pmb_vr2_pms0_scl(w_i2c_scl[1]),
    .pad_pmb_vr2_pms0_alert_n(),
    .pad_pmb_vr3_pms0_sda(w_i2c_sda[2]),
    .pad_pmb_vr3_pms0_scl(w_i2c_scl[2]),
    .pad_pmb_vr3_pms0_alert_n(),
    .pad_pmb_pol1_pms0_sda(w_i2c_sda[3]),
    .pad_pmb_pol1_pms0_scl(w_i2c_scl[3]),
    .pad_pmb_pol1_pms0_alert_n(),
    .pad_pmb_ibc_pms0_sda(w_i2c_sda[11]),
    .pad_pmb_ibc_pms0_scl(w_i2c_scl[11]),
    .pad_pmb_ibc_pms0_alert_n(),
    .pad_i2c2_pms0_sda(w_i2c_sda[6]),
    .pad_i2c2_pms0_scl(w_i2c_scl[6]),
    .pad_i2c2_pms0_smbalert_n(),
    .pad_i2c3_pms0_sda(w_i2c_sda[7]),
    .pad_i2c3_pms0_scl(w_i2c_scl[7]),
    .pad_i2c3_pms0_smbalert_n(),
    .pad_i2c4_pms0_sda(w_i2c_sda[8]),
    .pad_i2c4_pms0_scl(w_i2c_scl[8]),
    .pad_i2c4_pms0_smbalert_n(),
    .pad_i2c5_pms0_sda(w_i2c_sda[9]),
    .pad_i2c5_pms0_scl(w_i2c_scl[9]),
    .pad_i2c5_pms0_smbalert_n(),
    .pad_i2c7_pms0_sda(w_i2c_sda[5]),
    .pad_i2c7_pms0_scl(w_i2c_scl[5]),
    .pad_pms0_pms1_smbalert_n(),
    .pad_i2c6_pms0_slv_sda(w_i2c_slv_sda[0]),
    .pad_i2c6_pms0_slv_scl(w_i2c_slv_scl[0]),
    .pad_pms_avs_clk_vr1(w_avs_clk),
    .pad_pms_avs_mdata_vr1(w_avs_mdata),
    .pad_pms_avs_sdata_vr1(w_avs_sdata),
    .pad_pms_avs_clk_vr2(),
    .pad_pms_avs_mdata_vr2(),
    .pad_pms_avs_sdata_vr2(),
    .pad_pms_avs_clk_vr3(),
    .pad_pms_avs_mdata_vr3(),
    .pad_pms_avs_sdata_vr3(),
    .pad_pms_avs_clk_ibc(),
    .pad_pms_avs_mdata_ibc(),
    .pad_pms_avs_sdata_ibc(),
    .pad_pms_bios_spi_cs0_n(),
    .pad_pms_bios_spi_clk(),
    .pad_pms_bios_spi_io0(),
    .pad_pms_bios_spi_io1(),
    .pad_pms_bios_spi_io2(),
    .pad_pms_bios_spi_io3(),
    .pad_pms0_pms1_spi_cs_n(),
    .pad_pms0_pms1_spi_clk(),
    .pad_pms0_pms1_spi_miso(),
    .pad_pms0_pms1_spi_mosi(),
    .pad_uart1_pms0_rxd(w_uart_tx),
    .pad_uart1_pms0_txd(w_uart_rx),
    .pad_pms0_slp_s3_n(w_slp_s3),
    .pad_pms0_slp_s4_n(w_slp_s4),
    .pad_pms0_slp_s5_n(w_slp_s5),
    .pad_pms0_sys_reset_n(w_sys_reset),
    .pad_pms0_sys_rsmrst_n(w_sys_rsmrst),
    .pad_pms0_sys_pwgd_in(w_sys_pwrgd_in),
    .pad_pms0_pwr_btn_n(w_sys_pwr_btn),
    .pad_pms0_pwgd_out(w_cpu_pwrgd_out),
    .pad_pms0_throttle_0(w_cpu_throttle_0),
    .pad_pms0_throttle_1(w_cpu_throttle_1),
    .pad_pms0_thermtrip_n(w_cpu_thermtrip),
    .pad_pms0_errcode_0(w_cpu_errcode_0),
    .pad_pms0_errcode_1(w_cpu_errcode_1),
    .pad_pms0_errcode_2(w_cpu_errcode_2),
    .pad_pms0_errcode_3(w_cpu_errcode_3),
    .pad_pms0_reset_out_n(w_cpu_reset_out_n),
    .pad_pms0_socket_id_0(w_cpu_socket_id_0),
    .pad_pms0_socket_id_1(w_cpu_socket_id_1),
    .pad_pms0_strap_0(w_cpu_strap_0),
    .pad_pms0_strap_1(w_cpu_strap_1),
    .pad_pms0_strap_2(w_cpu_strap_2),
    .pad_pms0_strap_3(w_cpu_strap_3)

  );


  // Test control_pulp master ports (to_c07 or to_r07) with a simulation memory
  axi_sim_mem #(
    .AddrWidth(AXI_ADDR_WIDTH_PS_SLV),
    .DataWidth(AXI_DATA_WIDTH_PS_SLV),
    .IdWidth  (AXI_ID_WIDTH_PS_SLV),
    .UserWidth(AXI_USER_WIDTH_PS_SLV),
    .axi_req_t(axi_req_ps_slv_t),
    .axi_rsp_t(axi_resp_ps_slv_t),
    .ApplDelay(5000ps),
    .AcqDelay (10000ps)
  ) i_axi_sim_ps_slv (
    .clk_i    (s_soc_clk),
    .rst_ni   (s_rst_n),
    .axi_req_i(to_ps_req),
    .axi_rsp_o(to_ps_resp)
  );


  ///////////
  // Clock //
  ///////////

  tb_clk_gen #(.CLK_PERIOD(REF_CLK_PERIOD)) i_ref_clk_gen (.clk_o(s_clk_ref));

  initial begin : timing_format
    $timeformat(-9, 0, "ns", 9);
  end : timing_format


  ///////////////////////////
  // AXI W/R: driver tasks //
  ///////////////////////////

  `define AXI_PL_COMMON_EXT_VIEW_START_ADDR 32'h1A00_0000
  localparam logic [31:0] PL_COMMON_EXT_VIEW_START_ADDR = `AXI_PL_COMMON_EXT_VIEW_START_ADDR;

  `define AXI_PL_SPLIT_EXT_VIEW_START_ADDR_C07 32'hA000_0000
  localparam logic [31:0] PL_SPLIT_EXT_VIEW_START_ADDR_C07 = `AXI_PL_SPLIT_EXT_VIEW_START_ADDR_C07;

  `define wait_for(signal) \
  do \
    @(posedge s_soc_clk); \
  while (!signal);

  task write_to_pulp(input axi_addr_ps_mst_t addr, input axi_data_ps_mst_t data,
                     output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "write_to_pulp: unaligned 64-bit access");
    from_ps_req.aw.id     = '0;
    from_ps_req.aw.addr   = addr;
    from_ps_req.aw.len    = '0;
    from_ps_req.aw.size   = $clog2(AXI_STRB_WIDTH_PS_MST);
    from_ps_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ps_req.aw.lock   = 1'b0;
    from_ps_req.aw.cache  = '0;
    from_ps_req.aw.prot   = '0;
    from_ps_req.aw.qos    = '0;
    from_ps_req.aw.region = '0;
    from_ps_req.aw.atop   = '0;
    from_ps_req.aw.user   = '0;
    from_ps_req.aw_valid  = 1'b1;
    `wait_for(from_ps_resp.aw_ready)
    from_ps_req.aw_valid = 1'b0;
    from_ps_req.w.data   = data;
    from_ps_req.w.strb   = '1;
    from_ps_req.w.last   = 1'b1;
    from_ps_req.w.user   = '0;
    from_ps_req.w_valid  = 1'b1;
    `wait_for(from_ps_resp.w_ready)
    from_ps_req.w_valid = 1'b0;
    from_ps_req.b_ready = 1'b1;
    `wait_for(from_ps_resp.b_valid)
    resp                = from_ps_resp.b.resp;
    from_ps_req.b_ready = 1'b0;
  endtask  // write_to_pulp

  task write_to_pulp32(input axi_addr_ext_t addr, input logic [31:0] data,
                       output axi_pkg::resp_t resp);
    from_ps_req.aw.id     = '0;
    from_ps_req.aw.addr   = addr;
    from_ps_req.aw.len    = '0;
    from_ps_req.aw.size   = $clog2($bits(data)/8);
    from_ps_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ps_req.aw.lock   = 1'b0;
    from_ps_req.aw.cache  = '0;
    from_ps_req.aw.prot   = '0;
    from_ps_req.aw.qos    = '0;
    from_ps_req.aw.region = '0;
    from_ps_req.aw.atop   = '0;
    from_ps_req.aw.user   = '0;
    from_ps_req.aw_valid  = 1'b1;
    `wait_for(from_ps_resp.aw_ready)
    from_ps_req.aw_valid = 1'b0;
    from_ps_req.w.data   = (addr[2]) ? {data, 32'h0} : {32'h0, data};
    from_ps_req.w.strb   = (addr[2]) ? 8'hf0 : 8'h0f;
    from_ps_req.w.last   = 1'b1;
    from_ps_req.w.user   = '0;
    from_ps_req.w_valid  = 1'b1;
    `wait_for(from_ps_resp.w_ready)
    from_ps_req.w_valid = 1'b0;
    from_ps_req.b_ready = 1'b1;
    `wait_for(from_ps_resp.b_valid)
    resp                 = from_ps_resp.b.resp;
    from_ps_req.b_ready = 1'b0;
  endtask  // write_to_pulp32


  task read_from_pulp(input axi_addr_ps_mst_t addr, output axi_data_ps_mst_t data,
                      output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "read_from_pulp: unaligned 64-bit access");
    from_ps_req.ar.id     = '0;
    from_ps_req.ar.addr   = addr;
    from_ps_req.ar.len    = '0;
    from_ps_req.ar.size   = $clog2(AXI_STRB_WIDTH_PS_MST);
    from_ps_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ps_req.ar.lock   = 1'b0;
    from_ps_req.ar.cache  = '0;
    from_ps_req.ar.prot   = '0;
    from_ps_req.ar.qos    = '0;
    from_ps_req.ar.region = '0;
    from_ps_req.ar.user   = '0;
    from_ps_req.ar_valid  = 1'b1;
    `wait_for(from_ps_resp.ar_ready)
    from_ps_req.ar_valid = 1'b0;
    from_ps_req.r_ready  = 1'b1;
    `wait_for(from_ps_resp.r_valid)
    data                = from_ps_resp.r.data;
    resp                = from_ps_resp.r.resp;
    from_ps_req.r_ready = 1'b0;
  endtask  // read_from_pulp

  task read_from_pulp32(input axi_addr_ext_t addr, output logic [31:0] data,
                        output axi_pkg::resp_t resp);
    from_ps_req.ar.id     = '0;
    from_ps_req.ar.addr   = addr;
    from_ps_req.ar.len    = '0;
    from_ps_req.ar.size   = $clog2($bits(data)/8);
    from_ps_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ps_req.ar.lock   = 1'b0;
    from_ps_req.ar.cache  = '0;
    from_ps_req.ar.prot   = '0;
    from_ps_req.ar.qos    = '0;
    from_ps_req.ar.region = '0;
    from_ps_req.ar.user   = '0;
    from_ps_req.ar_valid  = 1'b1;
    `wait_for(from_ps_resp.ar_ready)
    from_ps_req.ar_valid = 1'b0;
    from_ps_req.r_ready  = 1'b1;
    `wait_for(from_ps_resp.r_valid)
    data                 = from_ps_resp.r.data;
    resp                 = from_ps_resp.r.resp;
    from_ps_req.r_ready  = 1'b0;
  endtask  // read_from_pulp32

  task axi_assert(input string error_msg, input axi_pkg::resp_t resp, output int exit_status);
    assert (resp == axi_pkg::RESP_OKAY)
    else begin
      $error(error_msg);
      exit_status = EXIT_FAIL;
    end
  endtask  // axi_assert

  // Convert address code to be PS compliant (shift, bit-width remap) in PS-->PL direction
  function [39:0] pl2ps_addr_remap;
    input logic [31:0] addr_pl;
    begin
      pl2ps_addr_remap = {
        {8{1'b0}}, addr_pl + (PL_SPLIT_EXT_VIEW_START_ADDR_C07 - PL_COMMON_EXT_VIEW_START_ADDR)
      };
    end
  endfunction


  ////////////////////////////
  // AXI Boot: driver tasks //
  ////////////////////////////

  // Init AXI driver
  task init_axi_driver;
    from_ps_req = '{default: '0};
  endtask  // init_axi_driver

  // Read entry point from commandline
  task read_entry_point(output logic [31:0] begin_l2_instr);
    int entry_point;
    if ($value$plusargs("ENTRY_POINT=%h", entry_point)) begin_l2_instr = entry_point;
    else begin_l2_instr = 32'h1C000880;
    $display("[TB] %t - Entry point is set to 0x%h", $realtime, begin_l2_instr);
  endtask  // read_entry_point

  // Apply reset
  task apply_rstn;
    $display("[TB] %t - Asserting hard reset and jtag reset", $realtime);
    s_rst_n = 1'b0;
    #1us
      // Release reset
      $display(
        "[TB] %t - Releasing hard reset and jtag reset", $realtime);
    s_rst_n = 1'b1;
  endtask  // apply_rstn

  // Select bootmode
  task axi_select_bootmode(input logic [31:0] bootmode);
    automatic axi_pkg::resp_t resp;
    automatic axi_data_ps_mst_t data;
    automatic axi_addr_ps_mst_t addr_ps;

    addr_ps = fixt_pms_fpga.pl2ps_addr_remap(SOC_CTRL_BOOTSEL_ADDR);

    $display("[TB] %t - Write bootmode to bootsel register", $realtime);
    write_to_pulp32(addr_ps, bootmode, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB] %t - Read bootmode from bootsel register", $realtime);
    read_from_pulp32(addr_ps, data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // axi_select_bootmode

  task axi_load_binary;
    automatic axi_pkg::resp_t resp;
    automatic int stim_fd, ret_code;
    automatic int num_stim = 0;

    automatic axi_data_ps_mst_t data;
    automatic axi_data_ps_mst_t axi_data64;
    automatic axi_addr_ps_mst_t axi_addr32_pl, axi_addr40_ps;
    automatic logic [95:0] stimuli;

    $display("[TB] %t - Load binary into L2 via AXI slave port", $realtime);

    // Check if stimuli exist
    load_stim("./vectors/stim.txt", stim_fd);

    // Load binary
    while (!$feof(stim_fd)) begin
      // @(posedge s_soc_clk); TODO: check if this is really useful
      ret_code      = $fscanf(stim_fd, "%h\n", stimuli);
      axi_addr32_pl = stimuli[95:64];  // assign 32 bit address
      axi_data64    = stimuli[63:0];  // assign 64 bit data

      // Convert address code to be PS compliant
      axi_addr40_ps = pl2ps_addr_remap(axi_addr32_pl);

      if (num_stim % 128 == 0) begin
        $display("[TB] %t - Write burst @%h for 1024 bytes", $realtime, axi_addr32_pl);
      end

      write_to_pulp(axi_addr40_ps, axi_data64, resp);
      axi_assert("write", resp, exit_status);

      read_from_pulp(axi_addr40_ps, data, resp);
      axi_assert("read", resp, exit_status);

      num_stim++;
    end  // while (!$feof(stim_fd))
  endtask  // axi_load_binary

  task axi_write_entry_point(input logic [31:0] begin_l2_instr);
    automatic axi_pkg::resp_t resp;
    automatic axi_data_ps_mst_t data;
    automatic axi_addr_ps_mst_t addr_ps;

    addr_ps = fixt_pms_fpga.pl2ps_addr_remap(SOC_CTRL_BOOT_ADDR);

    $display("[TB] %t - Write entry point into boot address register (reset vector): 0x%h @ 0x%h",
             $realtime, begin_l2_instr, SOC_CTRL_BOOT_ADDR);
    write_to_pulp32(addr_ps, begin_l2_instr, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB] %t - Read entry point into boot address register (reset vector): 0x%h @ 0x%h",
             $realtime, begin_l2_instr, SOC_CTRL_BOOT_ADDR);
    read_from_pulp32(addr_ps, data, resp);
    axi_assert("read", resp, exit_status);
  endtask  // axi_write_entry_point

  task axi_write_fetch_enable();
    automatic axi_pkg::resp_t resp;
    automatic axi_data_inp_ext_t data;
    automatic axi_addr_ps_mst_t addr_ps;

    addr_ps = fixt_pms_fpga.pl2ps_addr_remap(SOC_CTRL_FETCH_EN_ADDR);

    $display("[TB] - Write 1 to fetch enable register");
    write_to_pulp32(addr_ps, 32'h0000_0001, resp);
    axi_assert("write", resp, exit_status);

    $display("[TB] - Read 1 from fetch enable register");
    read_from_pulp32(addr_ps, data, resp);
    axi_assert("read", resp, exit_status);

  endtask  // axi_write_fetch_enable

  task axi_wait_for_eoc(output int exit_status);
    automatic axi_pkg::resp_t resp;
    automatic logic [31:0]    rdata;
    automatic axi_addr_ps_mst_t eoc_addr_ps;

    eoc_addr_ps = fixt_pms_fpga.pl2ps_addr_remap(SOC_CTRL_CORE_STATUS_ADDR);

    // wait for end of computation signal
    $display("[TB] %t - Waiting for end of computation", $realtime);

    rdata = 0;
    while (rdata[31] == 0) begin
      read_from_pulp32(eoc_addr_ps, rdata, resp);
      axi_assert("read", resp, exit_status);
      #50us;
    end

    if (rdata[30:0] == 0) exit_status = EXIT_SUCCESS;
    else exit_status = EXIT_FAIL;
    $display("[TB] %t - Exit status: %d, Received status core: 0x%h", $realtime, exit_status,
             rdata[30:0]);
  endtask  // axi_wait_for_eoc

  task enable_uart_rx;
    uart_tb_rx_en = 1'b1;
  endtask  // enable_uart_rx


  ////////////////////////
  // ACPI: driver tasks //
  ////////////////////////

  task acpi_power_on();
    $display("[TB] %t - Start POWER UP (S5 -> S0)", $realtime);
    $display("[TB] %t - Short pulse on PWR_BTN", $realtime);
    s_sys_pwr_btn = 1'b0;
    #1000us s_sys_pwr_btn = 1'b1;
  endtask  // acpi_power_on

  task acpi_forced_power_down();
    $display("[TB] %t - Start forced POWER DOWN (S0 -> S5)", $realtime);
    $display("[TB] %t - Long pulse on PWR_BTN", $realtime);
    s_sys_pwr_btn = 1'b0;
    #5000us s_sys_pwr_btn = 1'b1;
  endtask  // acpi_forced_power_down


  ////////////////////
  // Load stim task //
  ////////////////////

  task load_stim(input string stim, output int stim_fd);
    stim_fd = $fopen(stim, "r");
    if (stim_fd == 0) $fatal("Could not open stimuli file!");
  endtask  // load_stim


  /////////////////////////////
  // I2C slave: driver tasks //
  /////////////////////////////

  task i2c_slv_read_slv_address(input int stim_fd, output logic [7:0] addr_i2c_slv);
    automatic int ret_code;
    ret_code = $fscanf(stim_fd, "%h\n", addr_i2c_slv);
    $display("[I2C_SLAVE TB] %t - I2C Slave Address: %h", $realtime, addr_i2c_slv[7:1]);
  endtask  // i2c_slv_read_slv_address

  task i2c_slv_start;
    i2c_pkg::i2c_start(sdaOm, sclOm);
  endtask  // i2c_slv_start

  task i2c_slv_write_byte(input logic [7:0] data);
    i2c_pkg::i2c_write_byte(data, sdaOm, sclOm);
  endtask  // i2c_slv_write_byte

  task i2c_slv_read_ack(output int exit_status);
    automatic logic ack;
    i2c_pkg::i2c_read_ack(ack, sdaIm, sclIm, sdaOm, sclOm);
    assert (ack === 1'b1)
    else begin
      $error("[I2C_SLAVE TB] - i2c nack received");
      exit_status = EXIT_FAIL;
    end
  endtask  // i2c_slv_read_ack

  task i2c_slv_send_data_stream(input int stim_fd, output int exit_status);
    automatic int ret_code;
    automatic logic ack;
    automatic logic [7:0] data;

    while (!$feof(stim_fd)) begin
      ret_code = $fscanf(stim_fd, "%h\n", data);
      $display("[I2C_SLAVE TB] %t - Write byte %h", $realtime, data);
      i2c_slv_write_byte(data);
      i2c_slv_read_ack(exit_status);
    end  // while (!$feof(stim_fd))
  endtask  // i2c_slv_send_data_stream

  task i2c_slv_stop;
    i2c_pkg::i2c_stop(sdaOm, sclOm);
  endtask  // i2c_slv_stop

endmodule

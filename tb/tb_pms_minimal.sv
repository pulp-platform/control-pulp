// Copyright 2021 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "axi/assign.svh"
`include "axi/typedef.svh"

// Use +stimuli=path_to_stim.txt for a custom path to stim.txt
// Use +ENTRY_POINT=hex to override the entry point into the L2 (main SRAM)


module tb_pms_minimal;

  timeunit 1ps; timeprecision 1ps;

  import control_pulp_pkg::*;

  // Choose your core: 0 for RISCY others are invalid
  localparam int CORE_TYPE = 0;
  // if RISCY is instantiated (CORE_TYPE == 0), RISCY_FPU enables the FPU
  localparam int CORE_USE_FPU = 1;
  // Choose whether to enable simulation only stdout (not synthesizable)
  localparam int SIM_STDOUT = 1;
  // Choose whether to use hardwired ROM or behavioral/compiled memory macro
  // (according to BEHAV_MEM)
  localparam int MACRO_ROM = 0;
  // Choose whether to use behavioral memory models or compiled memory macros
  localparam int BEHAV_MEM = 1;

  // period of the system clock (500MhZ)
  // period of the external reference clock (100MhZ)
  localparam int SYS_CLK_PERIOD = 2ns;
  localparam int REF_CLK_PERIOD = 10ns;

  // configuration address constants
  localparam logic [31:0] SOC_CTRL_BOOT_ADDR        = 32'h1A10_4004;
  localparam logic [31:0] SOC_CTRL_FETCH_EN_ADDR    = 32'h1A10_4008;
  localparam logic [31:0] SOC_CTRL_BOOTSEL_ADDR     = 32'h1A10_40C4;
  localparam logic [31:0] SOC_CTRL_CORE_STATUS_ADDR = 32'h1A10_40A0;

  // AXI parameters
  // from/to nci_cp_top
  localparam int unsigned AXI_DATA_INP_WIDTH_EXT = 64;
  localparam int unsigned AXI_STRB_INP_WIDTH_EXT = AXI_DATA_INP_WIDTH_EXT / 8;
  localparam int unsigned AXI_DATA_OUP_WIDTH_EXT = 64;
  localparam int unsigned AXI_STRB_OUP_WIDTH_EXT = AXI_DATA_OUP_WIDTH_EXT / 8;
  localparam int unsigned AXI_ID_OUP_WIDTH_EXT = 7;
  localparam int unsigned AXI_ID_INP_WIDTH_EXT = 6;
  localparam int unsigned AXI_USER_WIDTH_EXT = 6;
  localparam int unsigned AXI_ADDR_WIDTH_EXT = 32;

  // exit
  localparam int EXIT_SUCCESS = 0;
  localparam int EXIT_FAIL = 1;
  localparam int EXIT_ERROR = -1;

  int ret_code;
  int num_stim = 0;
  int stim_fd;
  string stimuli_file;
  logic [95:0] stimuli;  // array for the stimulus vectors

  // simulation status on exit
  int exit_status;

  // AXI ports to external, flattened
  // AXI Master to nci_cp_top
  logic [AXI_ID_OUP_WIDTH_EXT-1:0] awid_mst_o;
  logic [AXI_ADDR_WIDTH_PMS-1:0] awaddr_mst_o;
  logic [7:0] awlen_mst_o;
  logic [2:0] awsize_mst_o;
  logic [1:0] awburst_mst_o;
  logic awlock_mst_o;
  logic [3:0] awcache_mst_o;
  logic [2:0] awprot_mst_o;
  logic [3:0] awqos_mst_o;
  logic [3:0] awregion_mst_o;
  logic [5:0] aw_atop_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] awuser_mst_o;
  logic awvalid_mst_o;
  logic awready_mst_i;

  logic [AXI_DATA_OUP_WIDTH_EXT-1:0] wdata_mst_o;
  logic [AXI_STRB_OUP_WIDTH_EXT-1:0] wstrb_mst_o;
  logic wlast_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] wuser_mst_o;
  logic wvalid_mst_o;
  logic wready_mst_i;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] bid_mst_i;
  logic [1:0] bresp_mst_i;
  logic [AXI_USER_WIDTH_PMS-1:0] buser_mst_i;
  logic bvalid_mst_i;
  logic bready_mst_o;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] arid_mst_o;
  logic [AXI_ADDR_WIDTH_PMS-1:0] araddr_mst_o;
  logic [7:0] arlen_mst_o;
  logic [2:0] arsize_mst_o;
  logic [1:0] arburst_mst_o;
  logic arlock_mst_o;
  logic [3:0] arcache_mst_o;
  logic [2:0] arprot_mst_o;
  logic [3:0] arqos_mst_o;
  logic [3:0] arregion_mst_o;
  logic [AXI_USER_WIDTH_PMS-1:0] aruser_mst_o;
  logic arvalid_mst_o;
  logic arready_mst_i;

  logic [AXI_ID_OUP_WIDTH_EXT-1:0] rid_mst_i;
  logic [AXI_DATA_OUP_WIDTH_EXT-1:0] rdata_mst_i;
  logic [1:0] rresp_mst_i;
  logic rlast_mst_i;
  logic [AXI_USER_WIDTH_PMS-1:0] ruser_mst_i;
  logic rvalid_mst_i;
  logic rready_mst_o;


  // AXI Slave from nci_cp_top
  logic [AXI_ID_INP_WIDTH_EXT-1:0] awid_slv_i;
  logic [AXI_ADDR_WIDTH_PMS-1:0] awaddr_slv_i;
  logic [7:0] awlen_slv_i;
  logic [2:0] awsize_slv_i;
  logic [1:0] awburst_slv_i;
  logic awlock_slv_i;
  logic [3:0] awcache_slv_i;
  logic [2:0] awprot_slv_i;
  logic [3:0] awqos_slv_i;
  logic [3:0] awregion_slv_i;
  logic [5:0] aw_atop_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] awuser_slv_i;
  logic awvalid_slv_i;
  logic awready_slv_o;

  logic [AXI_DATA_INP_WIDTH_EXT-1:0] wdata_slv_i;
  logic [AXI_STRB_INP_WIDTH_EXT-1:0] wstrb_slv_i;
  logic wlast_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] wuser_slv_i;
  logic wvalid_slv_i;
  logic wready_slv_o;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] bid_slv_o;
  logic [1:0] bresp_slv_o;
  logic [AXI_USER_WIDTH_PMS-1:0] buser_slv_o;
  logic bvalid_slv_o;
  logic bready_slv_i;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] arid_slv_i;
  logic [AXI_ADDR_WIDTH_PMS-1:0] araddr_slv_i;
  logic [7:0] arlen_slv_i;
  logic [2:0] arsize_slv_i;
  logic [1:0] arburst_slv_i;
  logic arlock_slv_i;
  logic [3:0] arcache_slv_i;
  logic [2:0] arprot_slv_i;
  logic [3:0] arqos_slv_i;
  logic [3:0] arregion_slv_i;
  logic [AXI_USER_WIDTH_PMS-1:0] aruser_slv_i;
  logic arvalid_slv_i;
  logic arready_slv_o;

  logic [AXI_ID_INP_WIDTH_EXT-1:0] rid_slv_o;
  logic [AXI_DATA_INP_WIDTH_EXT-1:0] rdata_slv_o;
  logic [1:0] rresp_slv_o;
  logic rlast_slv_o;
  logic [AXI_USER_WIDTH_PMS-1:0] ruser_slv_o;
  logic rvalid_slv_o;
  logic rready_slv_i;  // Inout signals are split into input, output and enables

  logic s_soc_clk;

  logic s_rst_n;
  logic s_clk_sys;
  logic s_clk_ref;

  logic bootsel_valid;
  logic [1:0] bootsel;

  logic fetch_en_valid;
  logic fetch_en;

  // from/to nci_cp_top
  typedef logic [AXI_ID_INP_WIDTH_EXT-1:0] axi_id_inp_ext_t;
  typedef logic [AXI_ID_OUP_WIDTH_EXT-1:0] axi_id_oup_ext_t;
  typedef logic [AXI_USER_WIDTH_EXT-1:0] axi_user_ext_t;
  typedef logic [AXI_DATA_INP_WIDTH_EXT-1:0] axi_data_inp_ext_t;
  typedef logic [AXI_STRB_INP_WIDTH_EXT-1:0] axi_strb_inp_ext_t;
  typedef logic [AXI_DATA_OUP_WIDTH_EXT-1:0] axi_data_oup_ext_t;
  typedef logic [AXI_STRB_OUP_WIDTH_EXT-1:0] axi_strb_oup_ext_t;
  typedef logic [AXI_ADDR_WIDTH_EXT-1:0] axi_addr_ext_t;

  // control_pulp module --> req/resp structs (no wrap)

  // 1. Define axi request (req) and response (resp) type structs for nci_cp_top

  // nci_cp_top Master
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_inp_ext_t, axi_data_inp_ext_t, axi_strb_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_inp_ext_t, axi_data_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_inp_ext_t, axi_aw_inp_ext_t, axi_w_inp_ext_t, axi_ar_inp_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_inp_ext_t, axi_b_inp_ext_t, axi_r_inp_ext_t);

  // nci_cp_top Slave
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_oup_ext_t, axi_data_oup_ext_t, axi_strb_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_ext_t, axi_data_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_ext_t, axi_aw_oup_ext_t, axi_w_oup_ext_t, axi_ar_oup_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_ext_t, axi_b_oup_ext_t, axi_r_oup_ext_t);

  // nci_cp_top Master
  axi_req_inp_ext_t from_ext_req;
  axi_resp_inp_ext_t from_ext_resp;
  // nci_cp_top Slave
  axi_req_oup_ext_t to_ext_req;
  axi_resp_oup_ext_t to_ext_resp;


  // Assign flatten AXI ports from control_pulp module to req/resp structs //

  // Define helper macros for wrapping and assigning to AXI structs

  `define AXI_EXPLODE_SLAVE_STRUCT(req_str, resp_str, pat) \
  assign awid_``pat``_i     = req_str.aw.id;             \
  assign awaddr_``pat``_i   = req_str.aw.addr;           \
  assign awlen_``pat``_i    = req_str.aw.len;            \
  assign awsize_``pat``_i   = req_str.aw.size;           \
  assign awburst_``pat``_i  = req_str.aw.burst;          \
  assign awlock_``pat``_i   = req_str.aw.lock;           \
  assign awcache_``pat``_i  = req_str.aw.cache;          \
  assign awprot_``pat``_i   = req_str.aw.prot;           \
  assign awqos_``pat``_i    = req_str.aw.qos;            \
  assign awregion_``pat``_i = req_str.aw.region;         \
  assign aw_atop_``pat``_i  = req_str.aw.atop;           \
  assign awuser_``pat``_i   = req_str.aw.user;           \
  assign awvalid_``pat``_i  = req_str.aw_valid;          \
  assign resp_str.aw_ready  = awready_``pat``_o;         \
                                                         \
  assign wdata_``pat``_i    = req_str.w.data;            \
  assign wstrb_``pat``_i    = req_str.w.strb;            \
  assign wlast_``pat``_i    = req_str.w.last;            \
  assign wuser_``pat``_i    = req_str.w.user;            \
  assign wvalid_``pat``_i   = req_str.w_valid;           \
  assign resp_str.w_ready   = wready_``pat``_o;          \
                                                         \
  assign resp_str.b.id      = bid_``pat``_o;             \
  assign resp_str.b.resp    = bresp_``pat``_o;           \
  assign resp_str.b.user    = buser_``pat``_o;           \
  assign resp_str.b_valid   = bvalid_``pat``_o;          \
  assign bready_``pat``_i   = req_str.b_ready;           \
                                                         \
  assign arid_``pat``_i     = req_str.ar.id;             \
  assign araddr_``pat``_i   = req_str.ar.addr;           \
  assign arlen_``pat``_i    = req_str.ar.len;            \
  assign arsize_``pat``_i   = req_str.ar.size;           \
  assign arburst_``pat``_i  = req_str.ar.burst;          \
  assign arlock_``pat``_i   = req_str.ar.lock;           \
  assign arcache_``pat``_i  = req_str.ar.cache;          \
  assign arprot_``pat``_i   = req_str.ar.prot;           \
  assign arqos_``pat``_i    = req_str.ar.qos;            \
  assign arregion_``pat``_i = req_str.ar.region;         \
  assign aruser_``pat``_i   = req_str.ar.user;           \
  assign arvalid_``pat``_i  = req_str.ar_valid;          \
  assign resp_str.ar_ready  = arready_``pat``_o;         \
                                                         \
  assign resp_str.r.id      = rid_``pat``_o;             \
  assign resp_str.r.data    = rdata_``pat``_o;           \
  assign resp_str.r.resp    = rresp_``pat``_o;           \
  assign resp_str.r.last    = rlast_``pat``_o;           \
  assign resp_str.r.user    = ruser_``pat``_o;           \
  assign resp_str.r_valid   = rvalid_``pat``_o;          \
  assign rready_``pat``_i   = req_str.r_ready


  `define AXI_WRAP_MASTER_STRUCT(req_str, resp_str, pat)   \
  assign req_str.aw.id      = awid_``pat``_o;            \
  assign req_str.aw.addr    = awaddr_``pat``_o;          \
  assign req_str.aw.len     = awlen_``pat``_o;           \
  assign req_str.aw.size    = awsize_``pat``_o;          \
  assign req_str.aw.burst   = awburst_``pat``_o;         \
  assign req_str.aw.lock    = awlock_``pat``_o;          \
  assign req_str.aw.cache   = awcache_``pat``_o;         \
  assign req_str.aw.prot    = awprot_``pat``_o;          \
  assign req_str.aw.qos     = awqos_``pat``_o;           \
  assign req_str.aw.region  = awregion_``pat``_o;        \
  assign req_str.aw.atop    = aw_atop_``pat``_o;         \
  assign req_str.aw.user    = awuser_``pat``_o;          \
  assign req_str.aw_valid   = awvalid_``pat``_o;         \
  assign awready_``pat``_i  = resp_str.aw_ready;         \
                                                         \
  assign req_str.w.data     = wdata_``pat``_o;           \
  assign req_str.w.strb     = wstrb_``pat``_o;           \
  assign req_str.w.last     = wlast_``pat``_o;           \
  assign req_str.w.user     = wuser_``pat``_o;           \
  assign req_str.w_valid    = wvalid_``pat``_o;          \
  assign wready_``pat``_i   = resp_str.w_ready;          \
                                                         \
  assign bid_``pat``_i      = resp_str.b.id;             \
  assign bresp_``pat``_i    = resp_str.b.resp;           \
  assign buser_``pat``_i    = resp_str.b.user;           \
  assign bvalid_``pat``_i   = resp_str.b_valid;          \
  assign req_str.b_ready    = bready_``pat``_o;          \
                                                         \
  assign req_str.ar.id      = arid_``pat``_o;            \
  assign req_str.ar.addr    = araddr_``pat``_o;          \
  assign req_str.ar.len     = arlen_``pat``_o;           \
  assign req_str.ar.size    = arsize_``pat``_o;          \
  assign req_str.ar.burst   = arburst_``pat``_o;         \
  assign req_str.ar.lock    = arlock_``pat``_o;          \
  assign req_str.ar.cache   = arcache_``pat``_o;         \
  assign req_str.ar.prot    = arprot_``pat``_o;          \
  assign req_str.ar.qos     = arqos_``pat``_o;           \
  assign req_str.ar.region  = arregion_``pat``_o;        \
  assign req_str.ar.user    = aruser_``pat``_o;          \
  assign req_str.ar_valid   = arvalid_``pat``_o;         \
  assign arready_``pat``_i  = resp_str.ar_ready;         \
                                                         \
  assign rid_``pat``_i      = resp_str.r.id;             \
  assign rdata_``pat``_i    = resp_str.r.data;           \
  assign rresp_``pat``_i    = resp_str.r.resp;           \
  assign rlast_``pat``_i    = resp_str.r.last;           \
  assign ruser_``pat``_i    = resp_str.r.user;           \
  assign rvalid_``pat``_i   = resp_str.r_valid;          \
  assign req_str.r_ready    = rready_``pat``_o;

  // Instantiate dut

  pms_top #(
    .CORE_TYPE (CORE_TYPE),
    .USE_FPU   (CORE_USE_FPU),
    .SIM_STDOUT(SIM_STDOUT),
    .BEHAV_MEM (BEHAV_MEM),
    .MACRO_ROM (MACRO_ROM),

    .N_SOC_PERF_COUNTERS(16),  // for RTL/FPGA 16 perf counters one for each event
    .N_CLUST_PERF_COUNTERS(16),

    .AXI_DATA_INP_WIDTH_EXT(AXI_DATA_INP_WIDTH_EXT),
    .AXI_DATA_OUP_WIDTH_EXT(AXI_DATA_OUP_WIDTH_EXT),
    .AXI_ID_OUP_WIDTH_EXT  (AXI_ID_OUP_WIDTH_EXT),
    .AXI_ID_INP_WIDTH_EXT  (AXI_ID_INP_WIDTH_EXT)
  ) i_dut (

    // AXI ports to external, flattened

    // AXI Master to nci_cp_top
    .awid_mst_o    (awid_mst_o),
    .awaddr_mst_o  (awaddr_mst_o),
    .awlen_mst_o   (awlen_mst_o),
    .awsize_mst_o  (awsize_mst_o),
    .awburst_mst_o (awburst_mst_o),
    .awlock_mst_o  (awlock_mst_o),
    .awcache_mst_o (awcache_mst_o),
    .awprot_mst_o  (awprot_mst_o),
    .awqos_mst_o   (awqos_mst_o),
    .awregion_mst_o(awregion_mst_o),
    .aw_atop_mst_o (aw_atop_mst_o),
    .awuser_mst_o  (awuser_mst_o),
    .awvalid_mst_o (awvalid_mst_o),
    .awready_mst_i (awready_mst_i),

    .wdata_mst_o (wdata_mst_o),
    .wstrb_mst_o (wstrb_mst_o),
    .wlast_mst_o (wlast_mst_o),
    .wuser_mst_o (wuser_mst_o),
    .wvalid_mst_o(wvalid_mst_o),
    .wready_mst_i(wready_mst_i),

    .bid_mst_i   (bid_mst_i),
    .bresp_mst_i (bresp_mst_i),
    .buser_mst_i (buser_mst_i),
    .bvalid_mst_i(bvalid_mst_i),
    .bready_mst_o(bready_mst_o),

    .arid_mst_o    (arid_mst_o),
    .araddr_mst_o  (araddr_mst_o),
    .arlen_mst_o   (arlen_mst_o),
    .arsize_mst_o  (arsize_mst_o),
    .arburst_mst_o (arburst_mst_o),
    .arlock_mst_o  (arlock_mst_o),
    .arcache_mst_o (arcache_mst_o),
    .arprot_mst_o  (arprot_mst_o),
    .arqos_mst_o   (arqos_mst_o),
    .arregion_mst_o(arregion_mst_o),
    .aruser_mst_o  (aruser_mst_o),
    .arvalid_mst_o (arvalid_mst_o),
    .arready_mst_i (arready_mst_i),

    .rid_mst_i   (rid_mst_i),
    .rdata_mst_i (rdata_mst_i),
    .rresp_mst_i (rresp_mst_i),
    .rlast_mst_i (rlast_mst_i),
    .ruser_mst_i (ruser_mst_i),
    .rvalid_mst_i(rvalid_mst_i),
    .rready_mst_o(rready_mst_o),


    // AXI Slave from nci_cp_top
    .awid_slv_i    (awid_slv_i),
    .awaddr_slv_i  (awaddr_slv_i),
    .awlen_slv_i   (awlen_slv_i),
    .awsize_slv_i  (awsize_slv_i),
    .awburst_slv_i (awburst_slv_i),
    .awlock_slv_i  (awlock_slv_i),
    .awcache_slv_i (awcache_slv_i),
    .awprot_slv_i  (awprot_slv_i),
    .awqos_slv_i   (awqos_slv_i),
    .awregion_slv_i(awregion_slv_i),
    .aw_atop_slv_i (aw_atop_slv_i),
    .awuser_slv_i  (awuser_slv_i),
    .awvalid_slv_i (awvalid_slv_i),
    .awready_slv_o (awready_slv_o),

    .wdata_slv_i (wdata_slv_i),
    .wstrb_slv_i (wstrb_slv_i),
    .wlast_slv_i (wlast_slv_i),
    .wuser_slv_i (wuser_slv_i),
    .wvalid_slv_i(wvalid_slv_i),
    .wready_slv_o(wready_slv_o),

    .bid_slv_o   (bid_slv_o),
    .bresp_slv_o (bresp_slv_o),
    .buser_slv_o (buser_slv_o),
    .bvalid_slv_o(bvalid_slv_o),
    .bready_slv_i(bready_slv_i),

    .arid_slv_i    (arid_slv_i),
    .araddr_slv_i  (araddr_slv_i),
    .arlen_slv_i   (arlen_slv_i),
    .arsize_slv_i  (arsize_slv_i),
    .arburst_slv_i (arburst_slv_i),
    .arlock_slv_i  (arlock_slv_i),
    .arcache_slv_i (arcache_slv_i),
    .arprot_slv_i  (arprot_slv_i),
    .arqos_slv_i   (arqos_slv_i),
    .arregion_slv_i(arregion_slv_i),
    .aruser_slv_i  (aruser_slv_i),
    .arvalid_slv_i (arvalid_slv_i),
    .arready_slv_o (arready_slv_o),

    .rid_slv_o   (rid_slv_o),
    .rdata_slv_o (rdata_slv_o),
    .rresp_slv_o (rresp_slv_o),
    .rlast_slv_o (rlast_slv_o),
    .ruser_slv_o (ruser_slv_o),
    .rvalid_slv_o(rvalid_slv_o),
    .rready_slv_i(rready_slv_i),

    // soc: on-pmu internal peripherals

    .pad_cfg_o(),
    .ref_clk_i(s_clk_ref),
    .sys_clk_i(s_clk_sys),
    .soc_clk_o(s_soc_clk),
    .rst_ni   (s_rst_n),

    .jtag_tdo_o (),
    .jtag_tck_i ('0),
    .jtag_tdi_i ('0),
    .jtag_tms_i ('0),
    .jtag_trst_i('0),

    .wdt_alert_o      (),
    .wdt_alert_clear_i('0),

    .scg_irq_i        ('0),
    .scp_irq_i        ('0),
    .scp_secure_irq_i ('0),
    .mbox_irq_i       ('0),
    .mbox_secure_irq_i('0),


    // Inout signals are split into input, output and enables

    //
    // Master interfaces
    //

    //I2C
    .out_i2c0_vrm_mst_scl_o  (),
    .out_i2c0_vrm_mst_sda_o  (),
    .out_i2c0_vrm_mst_alert_o(),

    .oe_i2c0_vrm_mst_scl_o  (),
    .oe_i2c0_vrm_mst_sda_o  (),
    .oe_i2c0_vrm_mst_alert_o(),

    .in_i2c0_vrm_mst_scl_i  ('0),
    .in_i2c0_vrm_mst_sda_i  ('0),
    .in_i2c0_vrm_mst_alert_i('0),

    .out_i2c1_vrm_mst_scl_o  (),
    .out_i2c1_vrm_mst_sda_o  (),
    .out_i2c1_vrm_mst_alert_o(),

    .oe_i2c1_vrm_mst_scl_o  (),
    .oe_i2c1_vrm_mst_sda_o  (),
    .oe_i2c1_vrm_mst_alert_o(),

    .in_i2c1_vrm_mst_scl_i  ('0),
    .in_i2c1_vrm_mst_sda_i  ('0),
    .in_i2c1_vrm_mst_alert_i('0),

    .out_i2c2_vrm_mst_scl_o  (),
    .out_i2c2_vrm_mst_sda_o  (),
    .out_i2c2_vrm_mst_alert_o(),

    .oe_i2c2_vrm_mst_scl_o  (),
    .oe_i2c2_vrm_mst_sda_o  (),
    .oe_i2c2_vrm_mst_alert_o(),

    .in_i2c2_vrm_mst_scl_i  ('0),
    .in_i2c2_vrm_mst_sda_i  ('0),
    .in_i2c2_vrm_mst_alert_i('0),

    .out_i2c3_vrm_mst_scl_o  (),
    .out_i2c3_vrm_mst_sda_o  (),
    .out_i2c3_vrm_mst_alert_o(),

    .oe_i2c3_vrm_mst_scl_o  (),
    .oe_i2c3_vrm_mst_sda_o  (),
    .oe_i2c3_vrm_mst_alert_o(),

    .in_i2c3_vrm_mst_scl_i  ('0),
    .in_i2c3_vrm_mst_sda_i  ('0),
    .in_i2c3_vrm_mst_alert_i('0),

    .out_i2c4_vrm_mst_scl_o  (),
    .out_i2c4_vrm_mst_sda_o  (),
    .out_i2c4_vrm_mst_alert_o(),

    .oe_i2c4_vrm_mst_scl_o  (),
    .oe_i2c4_vrm_mst_sda_o  (),
    .oe_i2c4_vrm_mst_alert_o(),

    .in_i2c4_vrm_mst_scl_i  ('0),
    .in_i2c4_vrm_mst_sda_i  ('0),
    .in_i2c4_vrm_mst_alert_i('0),

    .out_i2cc_vrm_mst_scl_o  (),
    .out_i2cc_vrm_mst_sda_o  (),
    .out_i2cc_vrm_mst_alert_o(),

    .oe_i2cc_vrm_mst_scl_o  (),
    .oe_i2cc_vrm_mst_sda_o  (),
    .oe_i2cc_vrm_mst_alert_o(),

    .in_i2cc_vrm_mst_scl_i  ('0),
    .in_i2cc_vrm_mst_sda_i  ('0),
    .in_i2cc_vrm_mst_alert_i('0),

    .out_i2c6_rtc_mst_scl_o  (),
    .out_i2c6_rtc_mst_sda_o  (),
    .out_i2c6_rtc_mst_alert_o(),

    .oe_i2c6_rtc_mst_scl_o  (),
    .oe_i2c6_rtc_mst_sda_o  (),
    .oe_i2c6_rtc_mst_alert_o(),

    .in_i2c6_rtc_mst_scl_i  ('0),
    .in_i2c6_rtc_mst_sda_i  ('0),
    .in_i2c6_rtc_mst_alert_i('0),

    .out_i2c7_bmc_slv_scl_o(),
    .out_i2c7_bmc_slv_sda_o(),

    .oe_i2c7_bmc_slv_scl_o(),
    .oe_i2c7_bmc_slv_sda_o(),

    .in_i2c7_bmc_slv_scl_i('0),
    .in_i2c7_bmc_slv_sda_i('0),

    .out_i2c8_os_mst_scl_o  (),
    .out_i2c8_os_mst_sda_o  (),
    .out_i2c8_os_mst_alert_o(),

    .oe_i2c8_os_mst_scl_o  (),
    .oe_i2c8_os_mst_sda_o  (),
    .oe_i2c8_os_mst_alert_o(),

    .in_i2c8_os_mst_scl_i  ('0),
    .in_i2c8_os_mst_sda_i  ('0),
    .in_i2c8_os_mst_alert_i('0),

    .out_i2c9_pcie_pnp_mst_scl_o  (),
    .out_i2c9_pcie_pnp_mst_sda_o  (),
    .out_i2c9_pcie_pnp_mst_alert_o(),

    .oe_i2c9_pcie_pnp_mst_scl_o  (),
    .oe_i2c9_pcie_pnp_mst_sda_o  (),
    .oe_i2c9_pcie_pnp_mst_alert_o(),

    .in_i2c9_pcie_pnp_mst_scl_i  ('0),
    .in_i2c9_pcie_pnp_mst_sda_i  ('0),
    .in_i2c9_pcie_pnp_mst_alert_i('0),

    .out_i2ca_bios_mst_scl_o  (),
    .out_i2ca_bios_mst_sda_o  (),
    .out_i2ca_bios_mst_alert_o(),

    .oe_i2ca_bios_mst_scl_o  (),
    .oe_i2ca_bios_mst_sda_o  (),
    .oe_i2ca_bios_mst_alert_o(),

    .in_i2ca_bios_mst_scl_i  ('0),
    .in_i2ca_bios_mst_sda_i  ('0),
    .in_i2ca_bios_mst_alert_i('0),

    .out_i2cb_bmc_mst_scl_o  (),
    .out_i2cb_bmc_mst_sda_o  (),
    .out_i2cb_bmc_mst_alert_o(),

    .oe_i2cb_bmc_mst_scl_o  (),
    .oe_i2cb_bmc_mst_sda_o  (),
    .oe_i2cb_bmc_mst_alert_o(),

    .in_i2cb_bmc_mst_scl_i  ('0),
    .in_i2cb_bmc_mst_sda_i  ('0),
    .in_i2cb_bmc_mst_alert_i('0),

    //SPI
    .in_qspi_flash_mst_csn0_i('0),
    .in_qspi_flash_mst_csn1_i('0),
    .in_qspi_flash_mst_sck_i ('0),
    .in_qspi_flash_mst_sdio_i('0),

    .out_qspi_flash_mst_csn0_o(),
    .out_qspi_flash_mst_csn1_o(),
    .out_qspi_flash_mst_sck_o (),
    .out_qspi_flash_mst_sdio_o(),

    .oe_qspi_flash_mst_csn0_o(),
    .oe_qspi_flash_mst_csn1_o(),
    .oe_qspi_flash_mst_sck_o (),
    .oe_qspi_flash_mst_sdio_o(),

    .in_spi0_vrm_mst_csn0_i('0),
    .in_spi0_vrm_mst_csn1_i('0),
    .in_spi0_vrm_mst_sck_i ('0),
    .in_spi0_vrm_mst_si_i  ('0),
    .in_spi0_vrm_mst_so_i  ('0),

    .out_spi0_vrm_mst_csn0_o(),
    .out_spi0_vrm_mst_csn1_o(),
    .out_spi0_vrm_mst_sck_o (),
    .out_spi0_vrm_mst_si_o  (),
    .out_spi0_vrm_mst_so_o  (),

    .oe_spi0_vrm_mst_csn0_o(),
    .oe_spi0_vrm_mst_csn1_o(),
    .oe_spi0_vrm_mst_sck_o (),
    .oe_spi0_vrm_mst_si_o  (),
    .oe_spi0_vrm_mst_so_o  (),

    .in_spi1_vrm_mst_csn0_i('0),
    .in_spi1_vrm_mst_csn1_i('0),
    .in_spi1_vrm_mst_sck_i ('0),
    .in_spi1_vrm_mst_si_i  ('0),
    .in_spi1_vrm_mst_so_i  ('0),

    .out_spi1_vrm_mst_csn0_o(),
    .out_spi1_vrm_mst_csn1_o(),
    .out_spi1_vrm_mst_sck_o (),
    .out_spi1_vrm_mst_si_o  (),
    .out_spi1_vrm_mst_so_o  (),

    .oe_spi1_vrm_mst_csn0_o(),
    .oe_spi1_vrm_mst_csn1_o(),
    .oe_spi1_vrm_mst_sck_o (),
    .oe_spi1_vrm_mst_si_o  (),
    .oe_spi1_vrm_mst_so_o  (),

    .in_spi2_vrm_mst_csn0_i('0),
    .in_spi2_vrm_mst_csn1_i('0),
    .in_spi2_vrm_mst_sck_i ('0),
    .in_spi2_vrm_mst_si_i  ('0),
    .in_spi2_vrm_mst_so_i  ('0),

    .out_spi2_vrm_mst_csn0_o(),
    .out_spi2_vrm_mst_csn1_o(),
    .out_spi2_vrm_mst_sck_o (),
    .out_spi2_vrm_mst_si_o  (),
    .out_spi2_vrm_mst_so_o  (),

    .oe_spi2_vrm_mst_csn0_o(),
    .oe_spi2_vrm_mst_csn1_o(),
    .oe_spi2_vrm_mst_sck_o (),
    .oe_spi2_vrm_mst_si_o  (),
    .oe_spi2_vrm_mst_so_o  (),

    .in_spi3_vrm_mst_csn_i('0),
    .in_spi3_vrm_mst_sck_i('0),
    .in_spi3_vrm_mst_si_i ('0),
    .in_spi3_vrm_mst_so_i ('0),

    .out_spi3_vrm_mst_csn_o(),
    .out_spi3_vrm_mst_sck_o(),
    .out_spi3_vrm_mst_si_o (),
    .out_spi3_vrm_mst_so_o (),

    .oe_spi3_vrm_mst_csn_o(),
    .oe_spi3_vrm_mst_sck_o(),
    .oe_spi3_vrm_mst_si_o (),
    .oe_spi3_vrm_mst_so_o (),

    .in_spi4_vrm_mst_csn_i('0),
    .in_spi4_vrm_mst_sck_i('0),
    .in_spi4_vrm_mst_si_i ('0),
    .in_spi4_vrm_mst_so_i ('0),

    .out_spi4_vrm_mst_csn_o(),
    .out_spi4_vrm_mst_sck_o(),
    .out_spi4_vrm_mst_si_o (),
    .out_spi4_vrm_mst_so_o (),

    .oe_spi4_vrm_mst_csn_o(),
    .oe_spi4_vrm_mst_sck_o(),
    .oe_spi4_vrm_mst_si_o (),
    .oe_spi4_vrm_mst_so_o (),

    .in_spi6_vrm_mst_csn_i('0),
    .in_spi6_vrm_mst_sck_i('0),
    .in_spi6_vrm_mst_si_i ('0),
    .in_spi6_vrm_mst_so_i ('0),

    .out_spi6_vrm_mst_csn_o(),
    .out_spi6_vrm_mst_sck_o(),
    .out_spi6_vrm_mst_si_o (),
    .out_spi6_vrm_mst_so_o (),

    .oe_spi6_vrm_mst_csn_o(),
    .oe_spi6_vrm_mst_sck_o(),
    .oe_spi6_vrm_mst_si_o (),
    .oe_spi6_vrm_mst_so_o (),

    //UART
    .in_uart1_rxd_i('0),
    .in_uart1_txd_i('0),

    .out_uart1_rxd_o(),
    .out_uart1_txd_o(),

    .oe_uart1_rxd_o(),
    .oe_uart1_txd_o(),

    //
    // Internally multiplexed interfaces
    //

    //I2C
    .out_i2c5_intr_sckt_scl_o  (),
    .out_i2c5_intr_sckt_sda_o  (),
    .out_i2c5_intr_sckt_alert_o(),

    .oe_i2c5_intr_sckt_scl_o  (),
    .oe_i2c5_intr_sckt_sda_o  (),
    .oe_i2c5_intr_sckt_alert_o(),

    .in_i2c5_intr_sckt_scl_i  ('0),
    .in_i2c5_intr_sckt_sda_i  ('0),
    .in_i2c5_intr_sckt_alert_i('0),

    //SPI
    .in_spi5_intr_sckt_csn_i  ('0),
    .in_spi5_intr_sckt_sck_i  ('0),
    .in_spi5_intr_sckt_si_i   ('0),
    .in_spi5_intr_sckt_so_i   ('0),
    .in_spi5_intr_sckt_alert_i('0),

    .out_spi5_intr_sckt_csn_o  (),
    .out_spi5_intr_sckt_sck_o  (),
    .out_spi5_intr_sckt_si_o   (),
    .out_spi5_intr_sckt_so_o   (),
    .out_spi5_intr_sckt_alert_o(),

    .oe_spi5_intr_sckt_csn_o  (),
    .oe_spi5_intr_sckt_sck_o  (),
    .oe_spi5_intr_sckt_si_o   (),
    .oe_spi5_intr_sckt_so_o   (),
    .oe_spi5_intr_sckt_alert_o(),

    //
    // SLP, SYS, CPU pins
    //
    .out_slp_s3_l_o       (),
    .out_slp_s4_l_o       (),
    .out_slp_s5_l_o       (),
    .out_sys_reset_l_o    (),
    .out_sys_rsmrst_l_o   (),
    .out_sys_pwr_btn_l_o  (),
    .out_sys_pwrgd_in_o   (),
    .out_sys_wake_l_o     (),
    .out_cpu_pwrgd_out_o  (),
    .out_cpu_throttle_o   (),
    .out_cpu_thermtrip_l_o(),
    .out_cpu_errcode_o    (),
    .out_cpu_reset_out_l_o(),
    .out_cpu_socket_id_o  (),
    .out_cpu_strap_o      (),

    .oe_slp_s3_l_o       (),
    .oe_slp_s4_l_o       (),
    .oe_slp_s5_l_o       (),
    .oe_sys_reset_l_o    (),
    .oe_sys_rsmrst_l_o   (),
    .oe_sys_pwr_btn_l_o  (),
    .oe_sys_pwrgd_in_o   (),
    .oe_sys_wake_l_o     (),
    .oe_cpu_pwrgd_out_o  (),
    .oe_cpu_throttle_o   (),
    .oe_cpu_thermtrip_l_o(),
    .oe_cpu_errcode_o    (),
    .oe_cpu_reset_out_l_o(),
    .oe_cpu_socket_id_o  (),
    .oe_cpu_strap_o      (),

    .in_slp_s3_l_i       ('0),
    .in_slp_s4_l_i       ('0),
    .in_slp_s5_l_i       ('0),
    .in_sys_reset_l_i    ('0),
    .in_sys_rsmrst_l_i   ('0),
    .in_sys_pwr_btn_l_i  ('0),
    .in_sys_pwrgd_in_i   ('0),
    .in_sys_wake_l_i     ('0),
    .in_cpu_pwrgd_out_i  ('0),
    .in_cpu_throttle_i   ('0),
    .in_cpu_thermtrip_l_i('0),
    .in_cpu_errcode_i    ('0),
    .in_cpu_reset_out_l_i('0),
    .in_cpu_socket_id_i  ('0),
    .in_cpu_strap_i      ('0),

    .bootsel_valid_i    (bootsel_valid),
    .bootsel_i          (bootsel),
    .fc_fetch_en_valid_i(fetch_en_valid),
    .fc_fetch_en_i      (fetch_en)
  );

  // Connect req/resp structs and exploded ports //

  // Wrap exploded master to struct master
  `AXI_WRAP_MASTER_STRUCT(to_ext_req, to_ext_resp, mst);

  // Explode struct slave to exploded slave
  `AXI_EXPLODE_SLAVE_STRUCT(from_ext_req, from_ext_resp, slv);

  // Test control_pulp master port (to_nci_cp_top) with a simulation memory
  axi_sim_mem #(
    .AddrWidth(AXI_ADDR_WIDTH_EXT),
    .DataWidth(AXI_DATA_OUP_WIDTH_EXT),
    .IdWidth  (AXI_ID_OUP_WIDTH_EXT),
    .UserWidth(AXI_USER_WIDTH_EXT),
    .axi_req_t(axi_req_oup_ext_t),
    .axi_rsp_t(axi_resp_oup_ext_t),
    .ApplDelay(5000ps),
    .AcqDelay (10000ps)
  ) i_axi_sim_ext (
    .clk_i    (s_soc_clk),
    .rst_ni   (s_rst_n),
    .axi_req_i(to_ext_req),
    .axi_rsp_o(to_ext_resp)
  );

  // Clock generation
  tb_clk_gen #(.CLK_PERIOD(REF_CLK_PERIOD)) i_ref_clk_gen (.clk_o(s_clk_ref));

  tb_clk_gen #(.CLK_PERIOD(SYS_CLK_PERIOD)) i_sys_clk_gen (.clk_o(s_clk_sys));

  initial begin : timing_format
    $timeformat(-9, 0, "ns", 9);
  end : timing_format

  // Directed verification: setup

  `define wait_for(signal) \
  do \
    @(posedge s_soc_clk); \
  while (!signal);

  task write_to_pulp(input axi_addr_ext_t addr, input axi_data_inp_ext_t data,
                     output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "write_to_pulp: unaligned 64-bit access");
    from_ext_req.aw.id     = '0;
    from_ext_req.aw.addr   = addr;
    from_ext_req.aw.len    = '0;
    from_ext_req.aw.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ext_req.aw.lock   = 1'b0;
    from_ext_req.aw.cache  = '0;
    from_ext_req.aw.prot   = '0;
    from_ext_req.aw.qos    = '0;
    from_ext_req.aw.region = '0;
    from_ext_req.aw.atop   = '0;
    from_ext_req.aw.user   = '0;
    from_ext_req.aw_valid  = 1'b1;
    `wait_for(from_ext_resp.aw_ready)
    from_ext_req.aw_valid = 1'b0;
    from_ext_req.w.data   = data;
    from_ext_req.w.strb   = '1;
    from_ext_req.w.last   = 1'b1;
    from_ext_req.w.user   = '0;
    from_ext_req.w_valid  = 1'b1;
    `wait_for(from_ext_resp.w_ready)
    from_ext_req.w_valid = 1'b0;
    from_ext_req.b_ready = 1'b1;
    `wait_for(from_ext_resp.b_valid)
    resp                 = from_ext_resp.b.resp;
    from_ext_req.b_ready = 1'b0;
  endtask  // write_to_pulp

  task write_to_pulp32(input axi_addr_ext_t addr, input logic [31:0] data,
                       output axi_pkg::resp_t resp);
    from_ext_req.aw.id     = '0;
    from_ext_req.aw.addr   = addr;
    from_ext_req.aw.len    = '0;
    from_ext_req.aw.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.aw.burst  = axi_pkg::BURST_INCR;
    from_ext_req.aw.lock   = 1'b0;
    from_ext_req.aw.cache  = '0;
    from_ext_req.aw.prot   = '0;
    from_ext_req.aw.qos    = '0;
    from_ext_req.aw.region = '0;
    from_ext_req.aw.atop   = '0;
    from_ext_req.aw.user   = '0;
    from_ext_req.aw_valid  = 1'b1;
    `wait_for(from_ext_resp.aw_ready)
    from_ext_req.aw_valid = 1'b0;
    from_ext_req.w.data   = (addr[2]) ? {data, 32'h0} : {32'h0, data};
    from_ext_req.w.strb   = (addr[2]) ? 8'hf0 : 8'h0f;
    from_ext_req.w.last   = 1'b1;
    from_ext_req.w.user   = '0;
    from_ext_req.w_valid  = 1'b1;
    `wait_for(from_ext_resp.w_ready)
    from_ext_req.w_valid = 1'b0;
    from_ext_req.b_ready = 1'b1;
    `wait_for(from_ext_resp.b_valid)
    resp                 = from_ext_resp.b.resp;
    from_ext_req.b_ready = 1'b0;
  endtask  // write_to_pulp32

  task read_from_pulp(input axi_addr_ext_t addr, output axi_data_inp_ext_t data,
                      output axi_pkg::resp_t resp);
    if (addr[2:0] != 3'b0)
      $fatal(1, "read_from_pulp: unaligned 64-bit access");
    from_ext_req.ar.id     = '0;
    from_ext_req.ar.addr   = addr;
    from_ext_req.ar.len    = '0;
    from_ext_req.ar.size   = $clog2(AXI_STRB_INP_WIDTH_EXT);
    from_ext_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ext_req.ar.lock   = 1'b0;
    from_ext_req.ar.cache  = '0;
    from_ext_req.ar.prot   = '0;
    from_ext_req.ar.qos    = '0;
    from_ext_req.ar.region = '0;
    from_ext_req.ar.user   = '0;
    from_ext_req.ar_valid  = 1'b1;
    `wait_for(from_ext_resp.ar_ready)
    from_ext_req.ar_valid = 1'b0;
    from_ext_req.r_ready  = 1'b1;
    `wait_for(from_ext_resp.r_valid)
    data                 = from_ext_resp.r.data;
    resp                 = from_ext_resp.r.resp;
    from_ext_req.r_ready = 1'b0;
  endtask  // read_from_pulp

  task read_from_pulp32(input axi_addr_ext_t addr, output logic [31:0] data,
                        output axi_pkg::resp_t resp);
    from_ext_req.ar.id     = '0;
    from_ext_req.ar.addr   = addr;
    from_ext_req.ar.len    = '0;
    from_ext_req.ar.size   = $clog2($bits(data)/8);
    from_ext_req.ar.burst  = axi_pkg::BURST_INCR;
    from_ext_req.ar.lock   = 1'b0;
    from_ext_req.ar.cache  = '0;
    from_ext_req.ar.prot   = '0;
    from_ext_req.ar.qos    = '0;
    from_ext_req.ar.region = '0;
    from_ext_req.ar.user   = '0;
    from_ext_req.ar_valid  = 1'b1;
    `wait_for(from_ext_resp.ar_ready)
    from_ext_req.ar_valid = 1'b0;
    from_ext_req.r_ready  = 1'b1;
    `wait_for(from_ext_resp.r_valid)
    data                 = from_ext_resp.r.data;
    resp                 = from_ext_resp.r.resp;
    from_ext_req.r_ready = 1'b0;
  endtask  // read_from_pulp32


  // Testbench driver process
  initial begin

    axi_pkg::resp_t resp;
    axi_data_inp_ext_t data, axi_data64;
    axi_addr_ext_t axi_addr32;

    int entry_point;
    logic [31:0] begin_l2_instr;
    logic [31:0] rdata;

    exit_status    = EXIT_SUCCESS;

    bootsel_valid  = 1'b0;
    bootsel        = 2'h0;
    fetch_en_valid = 1'b0;
    fetch_en       = 1'b0;

    from_ext_req   = '{default: '0};

    // read entry point from commandline
    if ($value$plusargs("ENTRY_POINT=%h", entry_point)) begin_l2_instr = entry_point;
    else begin_l2_instr = 32'h1C000880;
    $display("[TB] %t - Entry point is set to 0x%h", $realtime, begin_l2_instr);


    // Assert and release reset
    $display("[TB] %t - Asserting hard reset", $realtime);
    s_rst_n = 1'b0;

    repeat (10) begin
      @(posedge s_clk_sys);
    end

    // Release reset
    $display("[TB] %t - Releasing hard reset", $realtime);
    s_rst_n = 1'b1;

    repeat (10) begin
      @(posedge s_clk_sys);
    end

    // Optional: Test if we can write to L2 via AXI slave port
    @(posedge s_soc_clk);

    $display("[TB] %t - Test W/R onto L2 via AXI slave port", $realtime);

    write_to_pulp(begin_l2_instr, 64'h0000_0000_ABBA_ABBA, resp);
    assert (resp == axi_pkg::RESP_OKAY)
    else begin
      $error("write");
      exit_status = EXIT_FAIL;
    end

    $display("[TB] %t - Read from entry point address via AXI slave port", $realtime);
    read_from_pulp(begin_l2_instr, data, resp);
    assert (resp == axi_pkg::RESP_OKAY)
    else begin
      $error("read");
      exit_status = EXIT_FAIL;
    end


    // Select bootmode
    $display("[TB] %t - Assert bootmode", $realtime);
    bootsel_valid = 1'b1;
    bootsel       = 2'h3;

    #5us;

    // Load binary into L2 (main SRAM)
    $display("[TB] %t - Load binary into L2 via AXI slave port", $realtime);

    // read in the stimuli vectors  == address_value
    if ($value$plusargs("stimuli=%s", stimuli_file)) begin
      $display("[TB] %t - Loading custom stimuli from %s", $realtime, stimuli_file);
      stim_fd = $fopen(stimuli_file, "r");
    end else begin
      $display("[TB] %t - Loading default stimuli from ./stim.txt", $realtime);
      stim_fd = $fopen("./stim.txt", "r");
    end

    if (stim_fd == 0) $fatal(0, "Could not open stimuli file at %s", stimuli_file);

    while (!$feof(stim_fd)) begin
      @(posedge s_soc_clk);
      ret_code   = $fscanf(stim_fd, "%h\n", stimuli);

      axi_addr32 = stimuli[95:64];  // assign 32 bit address
      axi_data64 = stimuli[63:0];  // assign 64 bit data

      if (num_stim % 128 == 0) begin
        $display("[TB] %t - Write burst @%h for 1024 bytes", $realtime, axi_addr32);
      end

      write_to_pulp(axi_addr32, axi_data64, resp);
      assert (resp == axi_pkg::RESP_OKAY)
      else begin
        $error("write");
        exit_status = EXIT_FAIL;
      end

      num_stim++;

    end  // while (!$feof(stim_fd))


    // Write entry point into boot address register
    $display("[TB] %t - Write entry point into boot address register (reset vector): 0x%h @ %s",
             $realtime, begin_l2_instr, "1a104004");
    write_to_pulp32(SOC_CTRL_BOOT_ADDR, begin_l2_instr, resp);
    assert (resp == axi_pkg::RESP_OKAY)
    else begin
      $error("write");
      exit_status = EXIT_FAIL;
    end

    // Assert fetch enable
    $display("[TB] %t - Assert fetch enable", $realtime);
    fetch_en_valid = 1'b1;
    fetch_en       = 1'b1;

    #500us;

    // poll end of computation register
    $display("[TB] %t - Waiting for end of computation", $realtime);
    rdata = 0;
    while (rdata[31] == 0) begin
      read_from_pulp(SOC_CTRL_CORE_STATUS_ADDR, rdata, resp);
      assert (resp == axi_pkg::RESP_OKAY)
      else begin
        $error("read");
        exit_status = EXIT_FAIL;
      end

      #50us;
    end

    if (rdata[30:0] == 0) exit_status = EXIT_SUCCESS;
    else exit_status = EXIT_FAIL;
    $display("[TB] %t - Received status core: 0x%h", $realtime, rdata[30:0]);

    $stop;

  end  // initial begin

endmodule

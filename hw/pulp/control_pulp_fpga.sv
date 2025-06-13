// Copyright 2022 ETH Zurich and University of Bologna.
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
`include "control_pulp_assign.svh"

module control_pulp_fpga import pms_top_pkg::*; #(

  parameter int unsigned CORE_TYPE = 0,
  parameter int unsigned RISCY_FPU = 1,
  parameter int unsigned USE_HWPE = 0,
  parameter int unsigned PULP_XPULP = 1,
  parameter int unsigned SIM_STDOUT = 0,
  parameter int unsigned BEHAV_MEM = 0,
  parameter int unsigned FPGA_MEM = 0,
  parameter int unsigned MACRO_ROM = 0,
  parameter int unsigned USE_CLUSTER = 0,
  parameter int unsigned DMA_TYPE  = 1,
  parameter int unsigned SDMA_RT_MIDEND = 0,
  parameter int unsigned USE_D2D = 0,
  parameter int unsigned USE_D2D_DELAY_LINE = 0,
  parameter int unsigned D2D_NUM_CHANNELS = 0,
  parameter int unsigned D2D_NUM_LANES = 0,
  parameter int unsigned D2D_NUM_CREDITS = 0,

  // Define AXI types

  // PS master port
  localparam int unsigned AXI_ID_WIDTH_PS_MST = 16,
  localparam int unsigned AXI_USER_WIDTH_PS_MST = 16,
  localparam int unsigned AXI_DATA_WIDTH_PS_MST = 64,
  localparam int unsigned AXI_STRB_WIDTH_PS_MST = AXI_DATA_WIDTH_PS_MST/8,
  localparam int unsigned AXI_ADDR_WIDTH_PS_MST = 40,

  localparam type axi_id_ps_mst_t   = logic [AXI_ID_WIDTH_PS_MST-1:0],
  localparam type axi_user_ps_mst_t = logic [AXI_USER_WIDTH_PS_MST-1:0],
  localparam type axi_data_ps_mst_t = logic [AXI_DATA_WIDTH_PS_MST-1:0],
  localparam type axi_strb_ps_mst_t = logic [AXI_STRB_WIDTH_PS_MST-1:0],
  localparam type axi_addr_ps_mst_t = logic [AXI_ADDR_WIDTH_PS_MST-1:0],

  // PS slave port
  localparam int unsigned AXI_ID_WIDTH_PS_SLV = 6,
  localparam int unsigned AXI_USER_WIDTH_PS_SLV = 1,
  localparam int unsigned AXI_DATA_WIDTH_PS_SLV = 64,
  localparam int unsigned AXI_STRB_WIDTH_PS_SLV = AXI_DATA_WIDTH_PS_SLV/8,
  localparam int unsigned AXI_ADDR_WIDTH_PS_SLV = 49,

  localparam type axi_id_ps_slv_t   = logic [AXI_ID_WIDTH_PS_SLV-1:0],
  localparam type axi_user_ps_slv_t = logic [AXI_USER_WIDTH_PS_SLV-1:0],
  localparam type axi_data_ps_slv_t = logic [AXI_DATA_WIDTH_PS_SLV-1:0],
  localparam type axi_strb_ps_slv_t = logic [AXI_STRB_WIDTH_PS_SLV-1:0],
  localparam type axi_addr_ps_slv_t = logic [AXI_ADDR_WIDTH_PS_SLV-1:0]

) (

  // PS slave
  output                        axi_id_ps_slv_t ps_slv_aw_id_o,
  output                        axi_addr_ps_slv_t ps_slv_aw_addr_o,
  output                        axi_pkg::len_t ps_slv_aw_len_o,
  output                        axi_pkg::size_t ps_slv_aw_size_o,
  output                        axi_pkg::burst_t ps_slv_aw_burst_o,
  output logic                  ps_slv_aw_lock_o,
  output                        axi_pkg::cache_t ps_slv_aw_cache_o,
  output                        axi_pkg::prot_t ps_slv_aw_prot_o,
  output                        axi_pkg::qos_t ps_slv_aw_qos_o,
  output                        axi_pkg::region_t ps_slv_aw_region_o,
  output                        axi_pkg::atop_t ps_slv_aw_atop_o,
  output                        axi_user_ps_slv_t ps_slv_aw_user_o,
  output logic                  ps_slv_aw_valid_o,
  input logic                   ps_slv_aw_ready_i,
  output                        axi_data_ps_slv_t ps_slv_w_data_o,
  output                        axi_strb_ps_slv_t ps_slv_w_strb_o,
  output logic                  ps_slv_w_last_o,
  output                        axi_user_ps_slv_t ps_slv_w_user_o,
  output logic                  ps_slv_w_valid_o,
  input logic                   ps_slv_w_ready_i,
  input                         axi_id_ps_slv_t ps_slv_b_id_i,
  input                         axi_pkg::resp_t ps_slv_b_resp_i,
  input                         axi_user_ps_slv_t ps_slv_b_user_i,
  input logic                   ps_slv_b_valid_i,
  output logic                  ps_slv_b_ready_o,
  output                        axi_id_ps_slv_t ps_slv_ar_id_o,
  output                        axi_addr_ps_slv_t ps_slv_ar_addr_o,
  output                        axi_pkg::len_t ps_slv_ar_len_o,
  output                        axi_pkg::size_t ps_slv_ar_size_o,
  output                        axi_pkg::burst_t ps_slv_ar_burst_o,
  output logic                  ps_slv_ar_lock_o,
  output                        axi_pkg::cache_t ps_slv_ar_cache_o,
  output                        axi_pkg::prot_t ps_slv_ar_prot_o,
  output                        axi_pkg::qos_t ps_slv_ar_qos_o,
  output                        axi_pkg::region_t ps_slv_ar_region_o,
  output                        axi_user_ps_slv_t ps_slv_ar_user_o,
  output logic                  ps_slv_ar_valid_o,
  input logic                   ps_slv_ar_ready_i,
  input                         axi_id_ps_slv_t ps_slv_r_id_i,
  input                         axi_data_ps_slv_t ps_slv_r_data_i,
  input                         axi_pkg::resp_t ps_slv_r_resp_i,
  input logic                   ps_slv_r_last_i,
  input                         axi_user_ps_slv_t ps_slv_r_user_i,
  input logic                   ps_slv_r_valid_i,
  output logic                  ps_slv_r_ready_o,

  // PS master
  input                         axi_id_ps_mst_t ps_mst_aw_id_i,
  input                         axi_addr_ps_mst_t ps_mst_aw_addr_i,
  input                         axi_pkg::len_t ps_mst_aw_len_i,
  input                         axi_pkg::size_t ps_mst_aw_size_i,
  input                         axi_pkg::burst_t ps_mst_aw_burst_i,
  input logic                   ps_mst_aw_lock_i,
  input                         axi_pkg::cache_t ps_mst_aw_cache_i,
  input                         axi_pkg::prot_t ps_mst_aw_prot_i,
  input                         axi_pkg::qos_t ps_mst_aw_qos_i,
  input                         axi_pkg::region_t ps_mst_aw_region_i,
  input                         axi_pkg::atop_t ps_mst_aw_atop_i,
  input                         axi_user_ps_mst_t ps_mst_aw_user_i,
  input logic                   ps_mst_aw_valid_i,
  output logic                  ps_mst_aw_ready_o,
  input                         axi_data_ps_mst_t ps_mst_w_data_i,
  input                         axi_strb_ps_mst_t ps_mst_w_strb_i,
  input logic                   ps_mst_w_last_i,
  input                         axi_user_ps_mst_t ps_mst_w_user_i,
  input logic                   ps_mst_w_valid_i,
  output logic                  ps_mst_w_ready_o,
  output                        axi_id_ps_mst_t ps_mst_b_id_o,
  output                        axi_pkg::resp_t ps_mst_b_resp_o,
  output                        axi_user_ps_mst_t ps_mst_b_user_o,
  output logic                  ps_mst_b_valid_o,
  input logic                   ps_mst_b_ready_i,
  input                         axi_id_ps_mst_t ps_mst_ar_id_i,
  input                         axi_addr_ps_mst_t ps_mst_ar_addr_i,
  input                         axi_pkg::len_t ps_mst_ar_len_i,
  input                         axi_pkg::size_t ps_mst_ar_size_i,
  input                         axi_pkg::burst_t ps_mst_ar_burst_i,
  input logic                   ps_mst_ar_lock_i,
  input                         axi_pkg::cache_t ps_mst_ar_cache_i,
  input                         axi_pkg::prot_t ps_mst_ar_prot_i,
  input                         axi_pkg::qos_t ps_mst_ar_qos_i,
  input                         axi_pkg::region_t ps_mst_ar_region_i,
  input                         axi_user_ps_mst_t ps_mst_ar_user_i,
  input logic                   ps_mst_ar_valid_i,
  output logic                  ps_mst_ar_ready_o,
  output                        axi_id_ps_mst_t ps_mst_r_id_o,
  output                        axi_data_ps_mst_t ps_mst_r_data_o,
  output                        axi_pkg::resp_t ps_mst_r_resp_o,
  output logic                  ps_mst_r_last_o,
  output                        axi_user_ps_mst_t ps_mst_r_user_o,
  output logic                  ps_mst_r_valid_o,
  input logic                   ps_mst_r_ready_i,

  //output soc_clk
  output logic                  soc_clk_o,

  // Peripheral signals for soc, connected to control_pulp;

  // inout signals are split into input, output and enables
  output logic [31:0][5:0]      pad_cfg_o,
  // clock
  input logic                   ref_clk_i,
  input logic                   sys_clk_i,
  input logic                   rst_ni,

  // input logic                   bootsel_valid_i,
  // input logic [1:0]             bootsel_i,
  // input logic                   fc_fetch_en_valid_i,
  // input logic                   fc_fetch_en_i,

  // jtag
  output logic                  jtag_tdo_o,
  input logic                   jtag_tck_i,
  input logic                   jtag_tdi_i,
  input logic                   jtag_tms_i,
  input logic                   jtag_trst_ni,

  // wdt
  output logic [1:0]            wdt_alert_o,
  input  logic                  wdt_alert_clear_i,


  //SCMI mailbox PS to PL intr signal
  output logic                  out_completion_irq,


  // on-pmu internal peripherals as i/o pads (soc)

  // PMB PADS INOUT WIRES
  inout wire              pad_pmb_vr1_pms0_sda,
  inout wire              pad_pmb_vr1_pms0_scl,
  inout wire              pad_pmb_vr1_pms0_alert_n,
  inout wire              pad_pmb_vr2_pms0_sda,
  inout wire              pad_pmb_vr2_pms0_scl,
  inout wire              pad_pmb_vr2_pms0_alert_n,
  inout wire              pad_pmb_vr3_pms0_sda,
  inout wire              pad_pmb_vr3_pms0_scl,
  inout wire              pad_pmb_vr3_pms0_alert_n,
  inout wire              pad_pmb_pol1_pms0_sda,
  inout wire              pad_pmb_pol1_pms0_scl,
  inout wire              pad_pmb_pol1_pms0_alert_n,
  inout wire              pad_pmb_ibc_pms0_sda,
  inout wire              pad_pmb_ibc_pms0_scl,
  inout wire              pad_pmb_ibc_pms0_alert_n,

  // I2C PADS INOUT WIRES
  inout wire              pad_i2c2_pms0_sda,
  inout wire              pad_i2c2_pms0_scl,
  inout wire              pad_i2c2_pms0_smbalert_n,
  inout wire              pad_i2c3_pms0_sda,
  inout wire              pad_i2c3_pms0_scl,
  inout wire              pad_i2c3_pms0_smbalert_n,
  inout wire              pad_i2c4_pms0_sda,
  inout wire              pad_i2c4_pms0_scl,
  inout wire              pad_i2c4_pms0_smbalert_n,
  inout wire              pad_i2c5_pms0_sda,
  inout wire              pad_i2c5_pms0_scl,
  inout wire              pad_i2c5_pms0_smbalert_n,
  inout wire              pad_i2c6_pms0_slv_sda,
  inout wire              pad_i2c6_pms0_slv_scl,

  // AVS PADS INOUT WIRES
  inout wire              pad_pms_avs_clk_vr1,
  inout wire              pad_pms_avs_mdata_vr1,
  inout wire              pad_pms_avs_sdata_vr1,
  inout wire              pad_pms_avs_clk_vr2,
  inout wire              pad_pms_avs_mdata_vr2,
  inout wire              pad_pms_avs_sdata_vr2,
  inout wire              pad_pms_avs_clk_vr3,
  inout wire              pad_pms_avs_mdata_vr3,
  inout wire              pad_pms_avs_sdata_vr3,
  inout wire              pad_pms_avs_clk_ibc,
  inout wire              pad_pms_avs_mdata_ibc,
  inout wire              pad_pms_avs_sdata_ibc,

  // QSPI PADS INOUT WIRES
  inout wire              pad_pms_bios_spi_cs0_n,
  inout wire              pad_pms_bios_spi_clk,
  inout wire              pad_pms_bios_spi_io0,
  inout wire              pad_pms_bios_spi_io1,
  inout wire              pad_pms_bios_spi_io2,
  inout wire              pad_pms_bios_spi_io3,

  // INTER SOCKET PADS INOUT WIRES
  inout wire              pad_i2c7_pms0_sda,
  inout wire              pad_i2c7_pms0_scl,
  inout wire              pad_pms0_pms1_smbalert_n,
  inout wire              pad_pms0_pms1_spi_cs_n,
  inout wire              pad_pms0_pms1_spi_clk,
  inout wire              pad_pms0_pms1_spi_miso,
  inout wire              pad_pms0_pms1_spi_mosi,

  // GPIO PADS INOUT WIRES
  inout wire              pad_pms0_slp_s3_n,
  inout wire              pad_pms0_slp_s4_n,
  inout wire              pad_pms0_slp_s5_n,
  inout wire              pad_pms0_sys_reset_n,
  inout wire              pad_pms0_sys_rsmrst_n,
  inout wire              pad_pms0_sys_pwgd_in,
  inout wire              pad_pms0_pwr_btn_n,
  inout wire              pad_pms0_pwgd_out,
  inout wire              pad_pms0_throttle_0,
  inout wire              pad_pms0_throttle_1,
  inout wire              pad_pms0_thermtrip_n,
  inout wire              pad_pms0_errcode_0,
  inout wire              pad_pms0_errcode_1,
  inout wire              pad_pms0_errcode_2,
  inout wire              pad_pms0_errcode_3,
  inout wire              pad_pms0_reset_out_n,
  inout wire              pad_pms0_socket_id_0,
  inout wire              pad_pms0_socket_id_1,
  inout wire              pad_pms0_strap_0,
  inout wire              pad_pms0_strap_1,
  inout wire              pad_pms0_strap_2,
  inout wire              pad_pms0_strap_3,

  // UART PADS INOUT WIRES
  inout wire              pad_uart1_pms0_rxd,
  inout wire              pad_uart1_pms0_txd,
  
  //BOOT SELECTION INOUT WIRES
  inout wire              pad_bootsel0,
  inout wire              pad_bootsel1,
  inout wire              pad_bootsel_valid,
  inout wire              pad_fc_fetch_en,
  inout wire              pad_fc_fetch_en_valid,

  // TEST INTERRUPT SIGNALS
  inout wire              pad_completion_irq,
  inout wire              pad_doorbell_irq
);

  // Doorbell interrupts
  localparam int unsigned  NUM_SCMI_CHANNELS = 1;
  logic                    scg_irq, scp_irq, scp_secure_irq;
  logic [60:0]             mbox_irq;


  // Glue-logic for interfacing AXI ports between PS/PL (PL = control_pulp)
  // The needs of PS in terms of address range, address width, data width, id width and user width are here satisfied with converter modules
  // Hence, this wrapper module can be instantiated in a testbench, for cycle-accurate simulation

  // PL slv types
  typedef logic [AXI_ID_INP_WIDTH_PMS-1:0]   axi_id_pl_slv_t;
  typedef logic [AXI_USER_WIDTH_PMS-1:0]     axi_user_pl_slv_t;
  typedef logic [AXI_DATA_INP_WIDTH_PMS-1:0] axi_data_pl_slv_t;
  typedef logic [AXI_STRB_INP_WIDTH_PMS-1:0] axi_strb_pl_slv_t;
  typedef logic [AXI_ADDR_WIDTH_PMS-1:0]     axi_addr_pl_slv_t;

  // PL mst types
  typedef logic [AXI_ID_INP_WIDTH_PMS-1:0]   axi_id_ps_mst_idremap_t;
  typedef logic [AXI_ID_OUP_WIDTH_PMS-1:0]   axi_id_pl_mst_t;
  typedef logic [AXI_USER_WIDTH_PMS-1:0]     axi_user_pl_mst_t;
  typedef logic [AXI_DATA_OUP_WIDTH_PMS-1:0] axi_data_pl_mst_t;
  typedef logic [AXI_STRB_OUP_WIDTH_PMS-1:0] axi_strb_pl_mst_t;
  typedef logic [AXI_ADDR_WIDTH_PMS-1:0]     axi_addr_pl_mst_t;

  // address type compliant with PL address-width (32 bit)
  typedef logic [AXI_ADDR_WIDTH_PMS-1:0] axi_addr_ps_mst_addressremap_t;
  // address type compliant with PS address-width
  typedef logic [AXI_ADDR_WIDTH_PS_SLV-1:0] axi_addr_ps_slv_addressremap_t;
  typedef logic [AXI_ADDR_WIDTH_PMS-1:0]    axi_addr_pl_mst_addressremap_t;

  // id type compliant with PS id-width
  typedef logic [AXI_ID_WIDTH_PS_MST-1:0]   axi_id_pl_mst_idremap_t;

  // xbar0 configuration
  localparam axi_pkg::xbar_cfg_t XbarCfgPSMst = '{
    NoSlvPorts:         2,
    NoMstPorts:         2,
    MaxMstTrans:        8,
    MaxSlvTrans:        8,
    FallThrough:        1'b1,
    LatencyMode:        axi_pkg::NO_LATENCY,
    PipelineStages:     0, 
    AxiIdWidthSlvPorts: AXI_ID_WIDTH_PS_MST,
    AxiIdUsedSlvPorts:  AXI_ID_WIDTH_PS_MST,
    AxiAddrWidth:       AXI_ADDR_WIDTH_PMS,  // 32 but remapping is needed before connecting to PL slv
    AxiDataWidth:       AXI_DATA_WIDTH_PS_MST,  // same for both PS mst and PL slv
    NoAddrRules:        3,
    UniqueIds:          1'b1
  };
  // xbar1 configuration
  localparam axi_pkg::xbar_cfg_t XbarCfgPLMst = '{
    NoSlvPorts:         1,
    NoMstPorts:         2,
    MaxMstTrans:        8,
    MaxSlvTrans:        8,
    FallThrough:        1'b1,
    LatencyMode:        axi_pkg::NO_LATENCY,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: AXI_ID_OUP_WIDTH_PMS,
    AxiIdUsedSlvPorts:  AXI_ID_OUP_WIDTH_PMS,
    AxiAddrWidth:       AXI_ADDR_WIDTH_PMS,
    AxiDataWidth:       AXI_DATA_WIDTH_PS_SLV,
    NoAddrRules:        2,
    UniqueIds:          1'b1
  };

  // xbar0 output ports
  typedef logic [AXI_ID_WIDTH_PS_MST+$clog2(XbarCfgPSMst.NoSlvPorts)-1:0]  axi_id_ps_mst_xbar_t;
  // xbar1 output port
  typedef logic [AXI_ID_OUP_WIDTH_PMS+$clog2(XbarCfgPLMst.NoSlvPorts)-1:0] axi_id_pl_mst_xbar_t;


  // PS mst address view
  // Mailboxes
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_MBOX_START_ADDR = 32'hA600_0000;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_MBOX_END_ADDR = 32'hABFF_FFFF;
  // L2
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_L2_START_ADDR = 32'hA000_0000;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_L2_END_ADDR = 32'hA5FF_FFFF;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PL_SLV_L2_START_ADDR = 32'h1A00_0000;
  // L1
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_L1_START_ADDR = 32'h0000_0000;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PS_MST_L1_END_ADDR = 32'h0040_0000;

  // PL mst address view
  // Mailboxes
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PL_MST_MBOX_START_ADDR = 32'hFFFF_0000;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PL_MST_MBOX_END_ADDR = 32'hFFFF_FFFF;
  // ext
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PL_MST_EXT_START_ADDR = 32'h2000_0000;
  localparam logic [AXI_ADDR_WIDTH_PMS-1:0] AXI_PL_MST_EXT_END_ADDR = 32'hFFFE_FFFF;
  localparam logic [AXI_ADDR_WIDTH_PS_SLV-1:0] AXI_PS_SLV_EXT_START_ADDR = 49'h0_0000_7800_0000;


  // Delay between PS and PL in (AXI) clock cycles
  localparam int unsigned FixedDelayInput = 0;
  localparam int unsigned FixedDelayOutput = 0;
  localparam int unsigned StallRandomInput = 0;
  localparam int unsigned StallRandomOutput = 0;

  // I. PS TO PL DIRECTION

  // Define PS axi req/resp structs master

  // Define PL (control_pulp) axi req/resp type structs for nci_cp_top slave

  // 2. PL slave port

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_pl_slv_t,     axi_addr_pl_slv_t, axi_id_pl_slv_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_pl_slv_t,      axi_data_pl_slv_t, axi_strb_pl_slv_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_pl_slv_t,      axi_id_pl_slv_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_pl_slv_t,     axi_addr_pl_slv_t, axi_id_pl_slv_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_pl_slv_t,      axi_data_pl_slv_t, axi_id_pl_slv_t, axi_user_pl_slv_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_slv_t,    axi_aw_pl_slv_t, axi_w_pl_slv_t, axi_ar_pl_slv_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_pl_slv_t,   axi_b_pl_slv_t, axi_r_pl_slv_t);

  // Build PL final slave ports (after conversions)
  axi_req_pl_slv_t   to_pl_req  ;
  axi_resp_pl_slv_t  to_pl_resp ;

  // 1. PS master port

  // NB: when building PS initial master port structs, already get user_width of PL slave;
  // The latter is immediately assigned when wrapping the flattened ports into structs

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_mst_t,     axi_addr_ps_mst_t, axi_id_ps_mst_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_ps_mst_t,      axi_data_ps_mst_t, axi_strb_ps_mst_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_ps_mst_t,      axi_id_ps_mst_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_mst_t,     axi_addr_ps_mst_t, axi_id_ps_mst_t, axi_user_pl_slv_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_ps_mst_t,      axi_data_ps_mst_t, axi_id_ps_mst_t, axi_user_pl_slv_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_mst_t,    axi_aw_ps_mst_t, axi_w_ps_mst_t, axi_ar_ps_mst_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_ps_mst_t,   axi_b_ps_mst_t, axi_r_ps_mst_t);

  // Build PS master
  axi_req_ps_mst_t          from_ps_req;
  axi_resp_ps_mst_t         from_ps_resp;

  // AXI delayer: model CNoC latency
  axi_req_ps_mst_t  from_ps_req_delayed;
  axi_resp_ps_mst_t from_ps_resp_delayed;

  axi_delayer #(
    .aw_chan_t         (axi_aw_ps_mst_t),
    .w_chan_t          (axi_w_ps_mst_t),
    .b_chan_t          (axi_b_ps_mst_t),
    .ar_chan_t         (axi_ar_ps_mst_t),
    .r_chan_t          (axi_r_ps_mst_t),
    .axi_req_t         (axi_req_ps_mst_t),
    .axi_resp_t        (axi_resp_ps_mst_t),
    .FixedDelayInput   (FixedDelayInput),
    .FixedDelayOutput  (FixedDelayOutput),
    .StallRandomInput  (StallRandomInput),
    .StallRandomOutput (StallRandomOutput)
  ) i_axi_delayer_ps2pl (
    .clk_i            (s_soc_clk),
    .rst_ni           (rst_ni),
    .slv_req_i        (from_ps_req),
    .slv_resp_o       (from_ps_resp),
    .mst_req_o        (from_ps_req_delayed),
    .mst_resp_i       (from_ps_resp_delayed)
  );

  // Address width converter, only takes the 32 LSB from PS mst address without remapping

  // Define req/resp struct following address width remapping
  // NB: B, R channels (resp struct) and W channel: address-agnostic
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_mst_addressremap_t,     axi_addr_ps_mst_addressremap_t, axi_id_ps_mst_t,   axi_user_pl_slv_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_mst_addressremap_t,     axi_addr_ps_mst_addressremap_t, axi_id_ps_mst_t,   axi_user_pl_slv_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_mst_addressremap_t,    axi_aw_ps_mst_addressremap_t,   axi_w_ps_mst_t,    axi_ar_ps_mst_addressremap_t);

  // Address converter master ports
  axi_req_ps_mst_addressremap_t  from_ps_addressremap_req;
  axi_resp_ps_mst_t              from_ps_addressremap_resp;

  // cut incoming addresses to 32 bit
  axi_modify_address #(
    .slv_req_t  ( axi_req_ps_mst_t       ),
    .mst_addr_t ( axi_addr_ps_mst_addressremap_t ),
    .mst_req_t  ( axi_req_ps_mst_addressremap_t  ),
    .axi_resp_t ( axi_resp_ps_mst_t      )
  ) i_axi_cut_addr_from_ps (
    .slv_req_i     ( from_ps_req_delayed  ),
    .slv_resp_o    ( from_ps_resp_delayed ),
    .mst_req_o     ( from_ps_addressremap_req  ),
    .mst_resp_i    ( from_ps_addressremap_resp ),
    .mst_aw_addr_i ( from_ps_req_delayed.aw.addr[31:0]),
    .mst_ar_addr_i ( from_ps_req_delayed.ar.addr[31:0])
  );


  // AXI  xbar0 2_to_2
  // slv0: GL PS2PL output
  // slv1: PL master port from xbar1
  // mst0: L2
  // mst1: mailbox scmi

  // xbar0 address rule
  typedef axi_pkg::xbar_rule_32_t rule_ps_mst_t;
  localparam rule_ps_mst_t [XbarCfgPSMst.NoAddrRules-1:0] AddrMapPSMst = '{
    '{idx: 32'd1, start_addr: AXI_PS_MST_MBOX_START_ADDR, end_addr: AXI_PS_MST_MBOX_END_ADDR}, // mailbox
    '{idx: 32'd0, start_addr: AXI_PS_MST_L2_START_ADDR, end_addr: AXI_PS_MST_L2_END_ADDR}, // L2
    '{idx: 32'd0, start_addr: AXI_PS_MST_L1_START_ADDR, end_addr: AXI_PS_MST_L1_END_ADDR}  // L1
  };

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_mst_xbar_t,     axi_addr_ps_mst_addressremap_t,      axi_id_ps_mst_xbar_t,   axi_user_pl_slv_t   );
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_ps_mst_xbar_t,      axi_id_ps_mst_xbar_t,                axi_user_pl_slv_t                           );
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_mst_xbar_t,     axi_addr_ps_mst_addressremap_t,      axi_id_ps_mst_xbar_t,   axi_user_pl_slv_t   );
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_ps_mst_xbar_t,      axi_data_ps_mst_t,                   axi_id_ps_mst_xbar_t,   axi_user_pl_slv_t   );

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_mst_xbar_t,    axi_aw_ps_mst_xbar_t,   axi_w_ps_mst_t,         axi_ar_ps_mst_xbar_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_ps_mst_xbar_t,   axi_b_ps_mst_xbar_t,    axi_r_ps_mst_xbar_t                         );

  // xbar0 master ports signals
  axi_req_ps_mst_xbar_t    [XbarCfgPSMst.NoMstPorts-1:0]  axi_xbar0_master_ports_req;
  axi_resp_ps_mst_xbar_t   [XbarCfgPSMst.NoMstPorts-1:0]  axi_xbar0_master_ports_resp;

  // xbar0 slave ports signals
  axi_req_ps_mst_addressremap_t    [XbarCfgPSMst.NoSlvPorts-1:0]  axi_xbar0_slave_ports_req;
  axi_resp_ps_mst_t                [XbarCfgPSMst.NoSlvPorts-1:0]  axi_xbar0_slave_ports_resp;

  // xbar0 slave ports connections
  assign axi_xbar0_slave_ports_req[0] = from_ps_addressremap_req;
  assign from_ps_addressremap_resp    = axi_xbar0_slave_ports_resp[0];


  // xbar0 instantiation
  axi_xbar #(
    .Cfg          ( XbarCfgPSMst ),
    .slv_aw_chan_t( axi_aw_ps_mst_addressremap_t ),
    .mst_aw_chan_t( axi_aw_ps_mst_xbar_t ),
    .w_chan_t     ( axi_w_ps_mst_t ),
    .slv_b_chan_t ( axi_b_ps_mst_t ),
    .mst_b_chan_t ( axi_b_ps_mst_xbar_t ),
    .slv_ar_chan_t( axi_ar_ps_mst_addressremap_t ),
    .mst_ar_chan_t( axi_ar_ps_mst_xbar_t ),
    .slv_r_chan_t ( axi_r_ps_mst_t ),
    .mst_r_chan_t ( axi_r_ps_mst_xbar_t ),
    .slv_req_t    ( axi_req_ps_mst_addressremap_t ),
    .slv_resp_t   ( axi_resp_ps_mst_t ),
    .mst_req_t    ( axi_req_ps_mst_xbar_t  ),
    .mst_resp_t   ( axi_resp_ps_mst_xbar_t ),
    .rule_t       ( rule_ps_mst_t )
  ) i_xbar_ps2pl_2x2 (
    .clk_i      ( s_soc_clk ),
    .rst_ni     ( rst_ni    ),
    .test_i     ( 1'b0      ),
    .slv_ports_req_i  ( axi_xbar0_slave_ports_req  ),
    .slv_ports_resp_o ( axi_xbar0_slave_ports_resp ),
    .mst_ports_req_o  ( axi_xbar0_master_ports_req   ),
    .mst_ports_resp_i ( axi_xbar0_master_ports_resp  ),
    .addr_map_i       ( AddrMapPSMst      ),
    .en_default_mst_port_i ( '0      ),
    .default_mst_port_i    ( '0      )
  );


  // Define req/resp struct after id width remapping
  // NB: W channel unchanged from PS master
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_mst_idremap_t,     axi_addr_ps_mst_addressremap_t,    axi_id_ps_mst_idremap_t,   axi_user_pl_slv_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_ps_mst_idremap_t,      axi_id_ps_mst_idremap_t,           axi_user_pl_slv_t                           );
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_mst_idremap_t,     axi_addr_ps_mst_addressremap_t,    axi_id_ps_mst_idremap_t,   axi_user_pl_slv_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_ps_mst_idremap_t,      axi_data_ps_mst_t,                 axi_id_ps_mst_idremap_t,   axi_user_pl_slv_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_mst_idremap_t,    axi_aw_ps_mst_idremap_t,           axi_w_ps_mst_t,            axi_ar_ps_mst_idremap_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_ps_mst_idremap_t,   axi_b_ps_mst_idremap_t,            axi_r_ps_mst_idremap_t);

  axi_req_ps_mst_idremap_t      from_ps_idremap_req;
  axi_resp_ps_mst_idremap_t     from_ps_idremap_resp;

  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AXI_ID_WIDTH_PS_MST+$clog2(XbarCfgPSMst.NoSlvPorts)              ),
    .AxiMstPortIdWidth      ( AXI_ID_INP_WIDTH_PMS                                             ),
    .AxiSlvPortMaxUniqIds   ( 16                                                               ),
    .AxiSlvPortMaxTxnsPerId ( 13                                                               ),
    .AxiSlvPortMaxTxns      (                                                                  ),
    .AxiMstPortMaxUniqIds   (                                                                  ),
    .AxiMstPortMaxTxnsPerId (                                                                  ),
    .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS                                               ),
    .AxiDataWidth           ( AXI_DATA_WIDTH_PS_MST                                            ),
    .AxiUserWidth           ( AXI_USER_WIDTH_PMS                                               ),
    .slv_req_t              ( axi_req_ps_mst_xbar_t                                            ),
    .slv_resp_t             ( axi_resp_ps_mst_xbar_t                                           ),
    .mst_req_t              ( axi_req_ps_mst_idremap_t                                         ),
    .mst_resp_t             ( axi_resp_ps_mst_idremap_t                                        )
    ) i_axi_iw_converter_xbar02pl (
    .clk_i      ( s_soc_clk ),
    .rst_ni     ( rst_ni                           ),
    .slv_req_i  ( axi_xbar0_master_ports_req[0]    ),
    .slv_resp_o ( axi_xbar0_master_ports_resp[0]   ),
    .mst_req_o  ( from_ps_idremap_req              ),
    .mst_resp_i ( from_ps_idremap_resp             )
  );


  // Address converter, only remap

  axi_modify_address #(
    .slv_req_t  ( axi_req_ps_mst_idremap_t       ),
    .mst_addr_t ( axi_addr_pl_slv_t              ),
    .mst_req_t  ( axi_req_pl_slv_t               ),
    .axi_resp_t ( axi_resp_ps_mst_idremap_t      )
  ) i_axi_remap_addr_xbar02pl (
    .slv_req_i     ( from_ps_idremap_req  ),
    .slv_resp_o    ( from_ps_idremap_resp ),
    .mst_req_o     ( to_pl_req  ),
    .mst_resp_i    ( to_pl_resp ),
    .mst_aw_addr_i ( from_ps_idremap_req.aw.addr - (AXI_PS_MST_L2_START_ADDR - AXI_PL_SLV_L2_START_ADDR) ),
    .mst_ar_addr_i ( from_ps_idremap_req.ar.addr - (AXI_PS_MST_L2_START_ADDR - AXI_PL_SLV_L2_START_ADDR) )
  );

  // iw conv output port towards mailbox-scmi
  axi_req_pl_slv_t   to_mailbox_req  ;
  axi_resp_pl_slv_t  to_mailbox_resp ;
  logic   s_completion_irq;
  logic   s_doorbell_irq;


  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AXI_ID_WIDTH_PS_MST+$clog2(XbarCfgPSMst.NoSlvPorts)              ),
    .AxiMstPortIdWidth      ( AXI_ID_INP_WIDTH_PMS                                             ),
    .AxiSlvPortMaxUniqIds   ( 16                                                               ),
    .AxiSlvPortMaxTxnsPerId ( 13                                                               ),
    .AxiSlvPortMaxTxns      (                                                                  ),
    .AxiMstPortMaxUniqIds   (                                                                  ),
    .AxiMstPortMaxTxnsPerId (                                                                  ),
    .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS                                               ),
    .AxiDataWidth           ( AXI_DATA_WIDTH_PS_MST                                            ),
    .AxiUserWidth           ( AXI_USER_WIDTH_PMS                                               ),
    .slv_req_t              ( axi_req_ps_mst_xbar_t                                            ),
    .slv_resp_t             ( axi_resp_ps_mst_xbar_t                                           ),
    .mst_req_t              ( axi_req_pl_slv_t                                                 ),
    .mst_resp_t             ( axi_resp_pl_slv_t                                                )
    ) i_axi_iw_converter_xbar2mailbox (
    .clk_i      ( s_soc_clk ),
    .rst_ni     ( rst_ni                           ),
    .slv_req_i  ( axi_xbar0_master_ports_req[1]    ),
    .slv_resp_o ( axi_xbar0_master_ports_resp[1]   ),
    .mst_req_o  ( to_mailbox_req                   ),
    .mst_resp_i ( to_mailbox_resp                  )
  );

  // AXI mailboxes
  axi_scmi_mailbox #(
    .NumChannels             ( NUM_SCMI_CHANNELS         ),
    .AxiIdWidth              ( AXI_ID_INP_WIDTH_PMS      ),
    .AxiAddrWidth            ( AXI_ADDR_WIDTH_PMS        ),
    .AxiSlvPortDataWidth     ( AXI_DATA_INP_WIDTH_PMS    ),
    .AxiUserWidth            ( AXI_USER_WIDTH_PMS        ),
    .AxiMaxReads             ( 1                         ),
    .axi_req_t               ( axi_req_pl_slv_t          ),
    .axi_resp_t              ( axi_resp_pl_slv_t         )
  ) i_axi_scmi_mailbox (
    .clk_i           (s_soc_clk      ),
    .rst_ni          (rst_ni         ),
    .axi_mbox_req    (to_mailbox_req ),
    .axi_mbox_rsp    (to_mailbox_resp),

    // .irq_completion_o    (/*TODO*/),  // completion irq platform->agent
    // .irq_doorbell_o      ({mbox_irq, scp_secure_irq, scp_irq, scg_irq})  // doorbell irq agent->platform

    .irq_completion_o    (s_completion_irq),  // completion irq platform->agent
    .irq_doorbell_o      (s_doorbell_irq)  // doorbell irq agent->platform
  );
  
  assign out_completion_irq = s_completion_irq;

  // II. PL TO PS DIRECTION

  // Define PL (control_pulp) axi req/resp type structs for nci_cp_top master

  // 1. PL master port

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_pl_mst_t,     axi_addr_pl_mst_t, axi_id_pl_mst_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_pl_mst_t,      axi_data_pl_mst_t, axi_strb_pl_mst_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_pl_mst_t,      axi_id_pl_mst_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_pl_mst_t,     axi_addr_pl_mst_t, axi_id_pl_mst_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_pl_mst_t,      axi_data_pl_mst_t, axi_id_pl_mst_t, axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_mst_t,    axi_aw_pl_mst_t, axi_w_pl_mst_t, axi_ar_pl_mst_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_pl_mst_t,   axi_b_pl_mst_t, axi_r_pl_mst_t);

  // Build PL master ports
  axi_req_pl_mst_t  from_pl_req, from_pl_req_tied; // !remind: need packed structs
  axi_resp_pl_mst_t from_pl_resp, from_pl_resp_tied;

  // Tie atop to 0 in mst direction
  assign from_pl_req_tied = '{
    aw: '{
      id:     from_pl_req.aw.id,
      addr:   from_pl_req.aw.addr,
      len:    from_pl_req.aw.len,
      size:   from_pl_req.aw.size,
      burst:  from_pl_req.aw.burst,
      lock:   from_pl_req.aw.lock,
      cache:  from_pl_req.aw.cache,
      prot:   from_pl_req.aw.prot,
      qos:    from_pl_req.aw.qos,
      region: from_pl_req.aw.region,
      atop:   '0,
      user:   from_pl_req.aw.user,
      default: '0
    },
    aw_valid: from_pl_req.aw_valid,
    w:        from_pl_req.w,
    w_valid:  from_pl_req.w_valid,
    b_ready:  from_pl_req.b_ready,
    ar: '{
      id:     from_pl_req.ar.id,
      addr:   from_pl_req.ar.addr,
      len:    from_pl_req.ar.len,
      size:   from_pl_req.ar.size,
      burst:  from_pl_req.ar.burst,
      lock:   from_pl_req.ar.lock,
      cache:  from_pl_req.ar.cache,
      prot:   from_pl_req.ar.prot,
      qos:    from_pl_req.ar.qos,
      region: from_pl_req.ar.region,
      user:   from_pl_req.ar.user,
      default: '0
    },
    ar_valid: from_pl_req.ar_valid,
    r_ready:  from_pl_req.r_ready,
    default: '0
  };

  `AXI_ASSIGN_RESP_STRUCT(from_pl_resp, from_pl_resp_tied);


  // Define PS axi req/resp structs slave

  // 2. PS slave port

  // NB: when building PS final slave port structs, still keep user_width of PL master;
  // The correct user_width will be assigned during the req/resp structs flattening at the end;

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_slv_t,     axi_addr_ps_slv_t, axi_id_ps_slv_t,   axi_user_pl_mst_t);
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_ps_slv_t,      axi_data_ps_slv_t, axi_strb_ps_slv_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_ps_slv_t,      axi_id_ps_slv_t,   axi_user_pl_mst_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_slv_t,     axi_addr_ps_slv_t, axi_id_ps_slv_t,   axi_user_pl_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_ps_slv_t,      axi_data_ps_slv_t, axi_id_ps_slv_t,   axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_slv_t,    axi_aw_ps_slv_t,   axi_w_ps_slv_t,    axi_ar_ps_slv_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_ps_slv_t,   axi_b_ps_slv_t,    axi_r_ps_slv_t);

  // Build PS final slave ports (after conversions)
  axi_req_ps_slv_t          to_ps_req;
  axi_resp_ps_slv_t         to_ps_resp;

  // Data width converter
  `AXI_TYPEDEF_W_CHAN_T(        axi_w_pl_mst_dwc_t,      axi_data_ps_slv_t, axi_strb_ps_slv_t,  axi_user_pl_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_pl_mst_dwc_t,      axi_data_ps_slv_t, axi_id_pl_mst_t,    axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_mst_dwc_t,    axi_aw_pl_mst_t,   axi_w_pl_mst_dwc_t, axi_ar_pl_mst_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_pl_mst_dwc_t,   axi_b_pl_mst_t,    axi_r_pl_mst_dwc_t);

  axi_req_pl_mst_dwc_t          from_pl_dwc_req;
  axi_resp_pl_mst_dwc_t         from_pl_dwc_resp;

  axi_dw_converter #(
    .AxiSlvPortDataWidth   ( AXI_DATA_OUP_WIDTH_PMS                                       ),
    .AxiMstPortDataWidth   ( AXI_DATA_WIDTH_PS_SLV                                        ),
    .AxiAddrWidth          ( AXI_ADDR_WIDTH_PMS                                           ),
    .AxiIdWidth            ( AXI_ID_OUP_WIDTH_PMS                                         ),
    .aw_chan_t             ( axi_aw_pl_mst_t                                              ),
    .mst_w_chan_t          ( axi_w_pl_mst_dwc_t                                           ),
    .slv_w_chan_t          ( axi_w_pl_mst_t                                               ),
    .b_chan_t              ( axi_b_pl_mst_t                                               ),
    .ar_chan_t             ( axi_ar_pl_mst_t                                              ),
    .mst_r_chan_t          ( axi_r_pl_mst_dwc_t                                           ),
    .slv_r_chan_t          ( axi_r_pl_mst_t                                               ),
    .axi_mst_req_t         ( axi_req_pl_mst_dwc_t                                         ),
    .axi_mst_resp_t        ( axi_resp_pl_mst_dwc_t                                        ),
    .axi_slv_req_t         ( axi_req_pl_mst_t                                             ),
    .axi_slv_resp_t        ( axi_resp_pl_mst_t                                            )
  ) i_axi_dwc_xbar1xbar0 (
    .clk_i                 ( soc_clk_o ),
    .rst_ni                ( rst_ni ),
    // Slave interface
    .slv_req_i             ( from_pl_req_tied  ),
    .slv_resp_o            ( from_pl_resp_tied ),
    // Master interface
    .mst_req_o             ( from_pl_dwc_req  ),
    .mst_resp_i            ( from_pl_dwc_resp )
  );

  // AXI  xbar1 1_to_2
  // slv0: PL mst port
  // mst0: connection to ID and datawidth converter towards xbar0 slv1 port, so
  // that PL can access the mailbox via xbar0
  // mst1: GL PL2PS input

  // xbar1 address rule (typedef made again but it is the same type as ps address rule)
  typedef axi_pkg::xbar_rule_32_t rule_pl_mst_t;
  localparam rule_pl_mst_t [XbarCfgPLMst.NoAddrRules-1:0] AddrMapPLMst = '{
    '{idx: 32'd1, start_addr: AXI_PL_MST_EXT_START_ADDR, end_addr: AXI_PL_MST_EXT_END_ADDR}, // to PS
    '{idx: 32'd0, start_addr: AXI_PL_MST_MBOX_START_ADDR, end_addr: AXI_PL_MST_MBOX_END_ADDR}  // to xbar0 (mailbox)
  };

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_pl_mst_xbar_t,     axi_addr_pl_mst_t,    axi_id_pl_mst_xbar_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_pl_mst_xbar_t,      axi_id_pl_mst_xbar_t, axi_user_pl_mst_t                      );
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_pl_mst_xbar_t,     axi_addr_pl_mst_t,    axi_id_pl_mst_xbar_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_pl_mst_xbar_t,      axi_data_ps_slv_t,    axi_id_pl_mst_xbar_t, axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_mst_xbar_t,    axi_aw_pl_mst_xbar_t, axi_w_pl_mst_dwc_t,   axi_ar_pl_mst_xbar_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_pl_mst_xbar_t,   axi_b_pl_mst_xbar_t,  axi_r_pl_mst_xbar_t);

  // xbar1 master ports signals
  axi_req_pl_mst_xbar_t    [XbarCfgPLMst.NoMstPorts-1:0]  axi_xbar1_master_ports_req;
  axi_resp_pl_mst_xbar_t   [XbarCfgPLMst.NoMstPorts-1:0]  axi_xbar1_master_ports_resp;

  // xbar1 slave ports signals
  axi_req_pl_mst_dwc_t     [XbarCfgPLMst.NoSlvPorts-1:0]  axi_xbar1_slave_ports_req;
  axi_resp_pl_mst_dwc_t    [XbarCfgPLMst.NoSlvPorts-1:0]  axi_xbar1_slave_ports_resp;

  // xbar1 slave ports connections
  assign axi_xbar1_slave_ports_req[0] = from_pl_dwc_req;
  assign from_pl_dwc_resp             = axi_xbar1_slave_ports_resp[0];

  // xbar1 instantiation
  axi_xbar #(
    .Cfg          ( XbarCfgPLMst ),
    .slv_aw_chan_t( axi_aw_pl_mst_t ),
    .mst_aw_chan_t( axi_aw_pl_mst_xbar_t ),
    .w_chan_t     ( axi_w_pl_mst_dwc_t ),
    .slv_b_chan_t ( axi_b_pl_mst_t ),
    .mst_b_chan_t ( axi_b_pl_mst_xbar_t ),
    .slv_ar_chan_t( axi_ar_pl_mst_t ),
    .mst_ar_chan_t( axi_ar_pl_mst_xbar_t ),
    .slv_r_chan_t ( axi_r_pl_mst_dwc_t ),
    .mst_r_chan_t ( axi_r_pl_mst_xbar_t ),
    .slv_req_t    ( axi_req_pl_mst_dwc_t ),
    .slv_resp_t   ( axi_resp_pl_mst_dwc_t ),
    .mst_req_t    ( axi_req_pl_mst_xbar_t  ),
    .mst_resp_t   ( axi_resp_pl_mst_xbar_t ),
    .rule_t       ( rule_pl_mst_t )
  ) i_xbar_pl2ps_1x2 (
    .clk_i      ( soc_clk_o ),
    .rst_ni     ( rst_ni    ),
    .test_i     ( 1'b0      ),
    .slv_ports_req_i  ( axi_xbar1_slave_ports_req  ),
    .slv_ports_resp_o ( axi_xbar1_slave_ports_resp ),
    .mst_ports_req_o  ( axi_xbar1_master_ports_req   ),
    .mst_ports_resp_i ( axi_xbar1_master_ports_resp  ),
    .addr_map_i       ( AddrMapPLMst      ),
    .en_default_mst_port_i ( '0      ),
    .default_mst_port_i    ( '0      )
  );


  // Address conversion between the two crossbars:
  // only remaps to let PL mst see the mailbox with the same address range of PS mst
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_pl_mst_addressremap_t,     axi_addr_pl_mst_addressremap_t, axi_id_pl_mst_xbar_t,   axi_user_pl_mst_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_pl_mst_addressremap_t,     axi_addr_pl_mst_addressremap_t, axi_id_pl_mst_xbar_t,   axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_mst_addressremap_t,    axi_aw_pl_mst_addressremap_t,  axi_w_pl_mst_dwc_t, axi_ar_pl_mst_addressremap_t);

  // Build PS slave following address remapping
  axi_req_pl_mst_addressremap_t       from_pl_addressremap_req;
  axi_resp_pl_mst_xbar_t              from_pl_addressremap_resp;

  // AXI Address offset + zext
  axi_modify_address #(
    .slv_req_t     ( axi_req_pl_mst_xbar_t          ),
    .mst_addr_t    ( axi_addr_pl_mst_addressremap_t ),
    .mst_req_t     ( axi_req_pl_mst_addressremap_t  ),
    .axi_resp_t    ( axi_resp_pl_mst_xbar_t         )
  ) i_axi_remap_addr_pl_mst (
    .slv_req_i     ( axi_xbar1_master_ports_req[0]  ),
    .slv_resp_o    ( axi_xbar1_master_ports_resp[0] ),
    .mst_req_o     ( from_pl_addressremap_req       ),
    .mst_resp_i    ( from_pl_addressremap_resp      ),
    .mst_aw_addr_i ( (axi_xbar1_master_ports_req[0].aw.addr) - (AXI_PL_MST_MBOX_START_ADDR - AXI_PS_MST_MBOX_START_ADDR) ),
    .mst_ar_addr_i ( (axi_xbar1_master_ports_req[0].ar.addr) - (AXI_PL_MST_MBOX_START_ADDR - AXI_PS_MST_MBOX_START_ADDR) )
  );

  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_pl_mst_idremap_t,     axi_addr_pl_mst_addressremap_t,    axi_id_pl_mst_idremap_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_B_CHAN_T(        axi_b_pl_mst_idremap_t,      axi_id_pl_mst_idremap_t,           axi_user_pl_mst_t                         );
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_pl_mst_idremap_t,     axi_addr_pl_mst_addressremap_t,    axi_id_pl_mst_idremap_t, axi_user_pl_mst_t);
  `AXI_TYPEDEF_R_CHAN_T(        axi_r_pl_mst_idremap_t,      axi_data_ps_slv_t,                 axi_id_pl_mst_idremap_t, axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_pl_mst_idremap_t,    axi_aw_pl_mst_idremap_t, axi_w_pl_mst_dwc_t,   axi_ar_pl_mst_idremap_t);
  `AXI_TYPEDEF_RESP_T(          axi_resp_pl_mst_idremap_t,   axi_b_pl_mst_idremap_t,  axi_r_pl_mst_idremap_t);

  axi_req_pl_mst_idremap_t      from_pl_idremap_req;
  axi_resp_pl_mst_idremap_t     from_pl_idremap_resp;

  // iw converter between the 2 crossbars
  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AXI_ID_OUP_WIDTH_PMS+$clog2(XbarCfgPLMst.NoSlvPorts)         ),
    .AxiMstPortIdWidth      ( AXI_ID_WIDTH_PS_MST                                          ),
    .AxiSlvPortMaxUniqIds   ( 13                                                           ), // todo: see better
    .AxiSlvPortMaxTxnsPerId ( 16                                                           ),
    .AxiSlvPortMaxTxns      (                                                              ),
    .AxiMstPortMaxUniqIds   (                                                              ),
    .AxiMstPortMaxTxnsPerId (                                                              ),
    .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS                                           ),
    .AxiDataWidth           ( AXI_DATA_WIDTH_PS_SLV                                        ),
    .AxiUserWidth           ( AXI_USER_WIDTH_PMS                                           ),
    .slv_req_t              ( axi_req_pl_mst_addressremap_t                                ),
    .slv_resp_t             ( axi_resp_pl_mst_xbar_t                                       ),
    .mst_req_t              ( axi_req_pl_mst_idremap_t                                     ),
    .mst_resp_t             ( axi_resp_pl_mst_idremap_t                                    )
  ) i_axi_iw_converter_xbar1xbar0 (
    .clk_i      ( soc_clk_o                       ),
    .rst_ni     ( rst_ni                          ),
    .slv_req_i  ( from_pl_addressremap_req        ),
    .slv_resp_o ( from_pl_addressremap_resp       ),
    .mst_req_o  ( from_pl_idremap_req    ),
    .mst_resp_i ( from_pl_idremap_resp   )
  );

  assign axi_xbar0_slave_ports_req[1] =  from_pl_idremap_req;
  assign from_pl_idremap_resp         =  axi_xbar0_slave_ports_resp[1];


  // Address conversion between crossbar1 and PS slave:
  // 1. bitwidth: zero extension (32 bit to 49 bit)
  // 2. range: adapt to PS range

  // Define req/resp struct following address width remapping
  // NB: B, R channels (resp struct) and W channel: address-agnostic;
  `AXI_TYPEDEF_AW_CHAN_T(       axi_aw_ps_slv_addressremap_t,     axi_addr_ps_slv_addressremap_t, axi_id_pl_mst_xbar_t,   axi_user_pl_mst_t);
  `AXI_TYPEDEF_AR_CHAN_T(       axi_ar_ps_slv_addressremap_t,     axi_addr_ps_slv_addressremap_t, axi_id_pl_mst_xbar_t,   axi_user_pl_mst_t);

  `AXI_TYPEDEF_REQ_T(           axi_req_ps_slv_addressremap_t,    axi_aw_ps_slv_addressremap_t,  axi_w_pl_mst_dwc_t, axi_ar_ps_slv_addressremap_t);

  // Build PS slave following address remapping
  axi_req_ps_slv_addressremap_t       to_ps_addressremap_req;
  axi_resp_pl_mst_xbar_t              to_ps_addressremap_resp;

  // AXI Address offset + zext
  axi_modify_address #(
    .slv_req_t     ( axi_req_pl_mst_xbar_t          ),
    .mst_addr_t    ( axi_addr_ps_slv_addressremap_t ),
    .mst_req_t     ( axi_req_ps_slv_addressremap_t  ),
    .axi_resp_t    ( axi_resp_pl_mst_xbar_t         )
  ) i_axi_remap_addr_ps_slv (
    .slv_req_i     ( axi_xbar1_master_ports_req[1]  ),
    .slv_resp_o    ( axi_xbar1_master_ports_resp[1] ),
    .mst_req_o     ( to_ps_addressremap_req         ),
    .mst_resp_i    ( to_ps_addressremap_resp        ),
    .mst_aw_addr_i ( {{17{1'b0}}, axi_xbar1_master_ports_req[1].aw.addr} + (AXI_PS_SLV_EXT_START_ADDR - AXI_PL_MST_EXT_START_ADDR) ), // prepend 32-bit ADDR_WIDTH (PL) with 0s to reach 49-bit ADDR_WIDTH (PS)
    .mst_ar_addr_i ( {{17{1'b0}}, axi_xbar1_master_ports_req[1].ar.addr} + (AXI_PS_SLV_EXT_START_ADDR - AXI_PL_MST_EXT_START_ADDR) )
  );

  // ID width converter from xbar1 to ps slv
  axi_req_ps_slv_t  to_ps_idremap_req;
  axi_resp_ps_slv_t to_ps_idremap_resp;

  axi_iw_converter #(
    .AxiSlvPortIdWidth      ( AXI_ID_OUP_WIDTH_PMS+$clog2(XbarCfgPLMst.NoSlvPorts)          ),
    .AxiMstPortIdWidth      ( AXI_ID_WIDTH_PS_SLV                                           ),
    .AxiSlvPortMaxUniqIds   ( 13                                                            ), // todo: see better
    .AxiSlvPortMaxTxnsPerId ( 16                                                            ),
    .AxiSlvPortMaxTxns      (                                                               ),
    .AxiMstPortMaxUniqIds   (                                                               ),
    .AxiMstPortMaxTxnsPerId (                                                               ),
    .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS                                            ),
    .AxiDataWidth           ( AXI_DATA_WIDTH_PS_SLV                                         ),
    .AxiUserWidth           ( AXI_USER_WIDTH_PMS                                            ),
    .slv_req_t              ( axi_req_ps_slv_addressremap_t                                 ),
    .slv_resp_t             ( axi_resp_pl_mst_xbar_t                                        ),
    .mst_req_t              ( axi_req_ps_slv_t                                              ),
    .mst_resp_t             ( axi_resp_ps_slv_t                                             )
  ) i_axi_iw_converter_pl2ps (
    .clk_i      ( soc_clk_o                   ),
    .rst_ni     ( rst_ni                      ),
    .slv_req_i  ( to_ps_addressremap_req      ),
    .slv_resp_o ( to_ps_addressremap_resp     ),
    .mst_req_o  ( to_ps_idremap_req         ),
    .mst_resp_i ( to_ps_idremap_resp        )
  );

  // AXI delayer: model CNoC latency

  axi_delayer #(
    .aw_chan_t         (axi_aw_ps_slv_t),
    .w_chan_t          (axi_w_ps_slv_t),
    .b_chan_t          (axi_b_ps_slv_t),
    .ar_chan_t         (axi_ar_ps_slv_t),
    .r_chan_t          (axi_r_ps_slv_t),
    .axi_req_t         (axi_req_ps_slv_t),
    .axi_resp_t        (axi_resp_ps_slv_t),
    .FixedDelayInput   (FixedDelayInput),
    .FixedDelayOutput  (FixedDelayOutput),
    .StallRandomInput  (StallRandomInput),
    .StallRandomOutput (StallRandomOutput)
  ) i_axi_delayer_pl2ps (
    .clk_i            (soc_clk_o),
    .rst_ni           (rst_ni),
    .slv_req_i        (to_ps_idremap_req),
    .slv_resp_o       (to_ps_idremap_resp),
    .mst_req_o        (to_ps_req),
    .mst_resp_i       (to_ps_resp)
  );

  // Flatten exposed structs into ports

  // PS master: from_ps_req, from_ps_resp
  // PS slave: to_ps_req, to_ps_resp
  // NB adjust user bitwidth during the assignment (truncate or zext)

  // PS slave
  assign ps_slv_aw_id_o          = to_ps_req.aw.id;
  assign ps_slv_aw_addr_o        = to_ps_req.aw.addr;
  assign ps_slv_aw_len_o         = to_ps_req.aw.len;
  assign ps_slv_aw_size_o        = to_ps_req.aw.size;
  assign ps_slv_aw_burst_o       = to_ps_req.aw.burst;
  assign ps_slv_aw_lock_o        = to_ps_req.aw.lock;
  assign ps_slv_aw_cache_o       = to_ps_req.aw.cache;
  assign ps_slv_aw_prot_o        = to_ps_req.aw.prot;
  assign ps_slv_aw_qos_o         = to_ps_req.aw.qos;
  assign ps_slv_aw_region_o      = to_ps_req.aw.region;
  assign ps_slv_aw_atop_o        = to_ps_req.aw.atop;
  assign ps_slv_aw_user_o        = to_ps_req.aw.user[0]; //USR CONV
  assign ps_slv_aw_valid_o       = to_ps_req.aw_valid;
  assign to_ps_resp.aw_ready     = ps_slv_aw_ready_i;
  assign ps_slv_w_data_o         = to_ps_req.w.data;
  assign ps_slv_w_strb_o         = to_ps_req.w.strb;
  assign ps_slv_w_last_o         = to_ps_req.w.last;
  assign ps_slv_w_user_o         = to_ps_req.w.user[0]; //USR CONV
  assign ps_slv_w_valid_o        = to_ps_req.w_valid;
  assign to_ps_resp.w_ready      = ps_slv_w_ready_i;
  assign to_ps_resp.b.id         = ps_slv_b_id_i;
  assign to_ps_resp.b.resp       = ps_slv_b_resp_i;
  assign to_ps_resp.b.user       = ps_slv_b_user_i[0]; //USR CONV
  assign to_ps_resp.b_valid      = ps_slv_b_valid_i;
  assign ps_slv_b_ready_o        = to_ps_req.b_ready;
  assign ps_slv_ar_id_o          = to_ps_req.ar.id;
  assign ps_slv_ar_addr_o        = to_ps_req.ar.addr;
  assign ps_slv_ar_len_o         = to_ps_req.ar.len;
  assign ps_slv_ar_size_o        = to_ps_req.ar.size;
  assign ps_slv_ar_burst_o       = to_ps_req.ar.burst;
  assign ps_slv_ar_lock_o        = to_ps_req.ar.lock;
  assign ps_slv_ar_cache_o       = to_ps_req.ar.cache;
  assign ps_slv_ar_prot_o        = to_ps_req.ar.prot;
  assign ps_slv_ar_qos_o         = to_ps_req.ar.qos;
  assign ps_slv_ar_region_o      = to_ps_req.ar.region;
  assign ps_slv_ar_user_o        = to_ps_req.ar.user[0]; //USR CONV
  assign ps_slv_ar_valid_o       = to_ps_req.ar_valid;
  assign to_ps_resp.ar_ready     = ps_slv_ar_ready_i;
  assign to_ps_resp.r.id         = ps_slv_r_id_i;
  assign to_ps_resp.r.data       = ps_slv_r_data_i;
  assign to_ps_resp.r.resp       = ps_slv_r_resp_i;
  assign to_ps_resp.r.last       = ps_slv_r_last_i;
  assign to_ps_resp.r.user       = ps_slv_r_user_i[0]; //USR CONV
  assign to_ps_resp.r_valid      = ps_slv_r_valid_i;
  assign ps_slv_r_ready_o        = to_ps_req.r_ready;

  // PS master
  assign from_ps_req.aw.id       = ps_mst_aw_id_i;
  assign from_ps_req.aw.addr     = ps_mst_aw_addr_i;
  assign from_ps_req.aw.len      = ps_mst_aw_len_i;
  assign from_ps_req.aw.size     = ps_mst_aw_size_i;
  assign from_ps_req.aw.burst    = ps_mst_aw_burst_i;
  assign from_ps_req.aw.lock     = ps_mst_aw_lock_i;
  assign from_ps_req.aw.cache    = ps_mst_aw_cache_i;
  assign from_ps_req.aw.prot     = ps_mst_aw_prot_i;
  assign from_ps_req.aw.qos      = ps_mst_aw_qos_i;
  assign from_ps_req.aw.region   = ps_mst_aw_region_i;
  assign from_ps_req.aw.atop     = ps_mst_aw_atop_i;
  assign from_ps_req.aw.user     = ps_mst_aw_user_i[5:0]; //USR CONV
  assign from_ps_req.aw_valid    = ps_mst_aw_valid_i;
  assign ps_mst_aw_ready_o       = from_ps_resp.aw_ready;
  assign from_ps_req.w.data      = ps_mst_w_data_i;
  assign from_ps_req.w.strb      = ps_mst_w_strb_i;
  assign from_ps_req.w.last      = ps_mst_w_last_i;
  assign from_ps_req.w.user      = ps_mst_w_user_i[5:0]; //USR CONV
  assign from_ps_req.w_valid     = ps_mst_w_valid_i;
  assign ps_mst_w_ready_o        = from_ps_resp.w_ready;
  assign ps_mst_b_id_o           = from_ps_resp.b.id;
  assign ps_mst_b_resp_o         = from_ps_resp.b.resp;
  assign ps_mst_b_user_o         = from_ps_resp.b.user[5:0]; //USR CONV
  assign ps_mst_b_valid_o        = from_ps_resp.b_valid;
  assign from_ps_req.b_ready     = ps_mst_b_ready_i;
  assign from_ps_req.ar.id       = ps_mst_ar_id_i;
  assign from_ps_req.ar.addr     = ps_mst_ar_addr_i;
  assign from_ps_req.ar.len      = ps_mst_ar_len_i;
  assign from_ps_req.ar.size     = ps_mst_ar_size_i;
  assign from_ps_req.ar.burst    = ps_mst_ar_burst_i;
  assign from_ps_req.ar.lock     = ps_mst_ar_lock_i;
  assign from_ps_req.ar.cache    = ps_mst_ar_cache_i;
  assign from_ps_req.ar.prot     = ps_mst_ar_prot_i;
  assign from_ps_req.ar.qos      = ps_mst_ar_qos_i;
  assign from_ps_req.ar.region   = ps_mst_ar_region_i;
  assign from_ps_req.ar.user     = ps_mst_ar_user_i[5:0]; //USR CONV
  assign from_ps_req.ar_valid    = ps_mst_ar_valid_i;
  assign ps_mst_ar_ready_o       = from_ps_resp.ar_ready;
  assign ps_mst_r_id_o           = from_ps_resp.r.id;
  assign ps_mst_r_data_o         = from_ps_resp.r.data;
  assign ps_mst_r_last_o         = from_ps_resp.r.last;
  assign ps_mst_r_resp_o         = from_ps_resp.r.resp;
  assign ps_mst_r_user_o         = from_ps_resp.r.user[5:0]; //USR CONV
  assign ps_mst_r_valid_o        = from_ps_resp.r_valid;
  assign from_ps_req.r_ready     = ps_mst_r_ready_i;


  //////////////////////////////////////////////
  // FPGA-specific: IO peripherals glue logic //
  //////////////////////////////////////////////

  // Wrap IOs peripherals as tri-states wires for FPGA

  // ENABLE SIGNALS TO THE PADS
  logic            s_oe_i2c0_vrm_mst_sda;
  logic            s_oe_i2c0_vrm_mst_scl;
  logic            s_oe_i2c0_vrm_mst_alert;
  logic            s_oe_i2c1_vrm_mst_sda;
  logic            s_oe_i2c1_vrm_mst_scl;
  logic            s_oe_i2c1_vrm_mst_alert;
  logic            s_oe_i2c2_vrm_mst_sda;
  logic            s_oe_i2c2_vrm_mst_scl;
  logic            s_oe_i2c2_vrm_mst_alert;
  logic            s_oe_i2c3_vrm_mst_sda;
  logic            s_oe_i2c3_vrm_mst_scl;
  logic            s_oe_i2c3_vrm_mst_alert;
  logic            s_oe_i2cc_vrm_mst_sda;
  logic            s_oe_i2cc_vrm_mst_scl;
  logic            s_oe_i2cc_vrm_mst_alert;
  logic            s_oe_i2c6_rtc_mst_sda;
  logic            s_oe_i2c6_rtc_mst_scl;
  logic            s_oe_i2c6_rtc_mst_alert;
  logic            s_oe_i2c8_os_mst_sda;
  logic            s_oe_i2c8_os_mst_scl;
  logic            s_oe_i2c8_os_mst_alert;
  logic            s_oe_i2c9_pcie_pnp_mst_sda;
  logic            s_oe_i2c9_pcie_pnp_mst_scl;
  logic            s_oe_i2c9_pcie_pnp_mst_alert;
  logic            s_oe_i2ca_bios_mst_sda;
  logic            s_oe_i2ca_bios_mst_scl;
  logic            s_oe_i2ca_bios_mst_alert;
  logic            s_oe_i2c7_bmc_slv_sda;
  logic            s_oe_i2c7_bmc_slv_scl;
  logic            s_oe_i2c5_intr_sckt_sda;
  logic            s_oe_i2c5_intr_sckt_scl;
  logic            s_oe_i2c5_intr_sckt_alert;
  logic            s_oe_spi0_vrm_mst_sck;
  logic            s_oe_spi0_vrm_mst_si;
  logic            s_oe_spi0_vrm_mst_so;
  logic            s_oe_spi1_vrm_mst_sck;
  logic            s_oe_spi1_vrm_mst_si;
  logic            s_oe_spi1_vrm_mst_so;
  logic            s_oe_spi2_vrm_mst_sck;
  logic            s_oe_spi2_vrm_mst_si;
  logic            s_oe_spi2_vrm_mst_so;
  logic            s_oe_spi3_vrm_mst_sck;
  logic            s_oe_spi3_vrm_mst_si;
  logic            s_oe_spi3_vrm_mst_so;
  logic            s_oe_qspi_flash_mst_csn0;
  logic            s_oe_qspi_flash_mst_sck;
  logic [3:0]      s_oe_qspi_flash_mst_sdio;
  logic            s_oe_spi5_intr_sckt_csn;
  logic            s_oe_spi5_intr_sckt_sck;
  logic            s_oe_spi5_intr_sckt_so;
  logic            s_oe_spi5_intr_sckt_si;
  logic            s_oe_uart1_rxd;
  logic            s_oe_uart1_txd;
  logic            s_oe_slp_s3_l;
  logic            s_oe_slp_s4_l;
  logic            s_oe_slp_s5_l;
  logic            s_oe_sys_reset_l;
  logic            s_oe_sys_rsmrst_l;
  logic            s_oe_sys_pwrgd_in;
  logic            s_oe_sys_pwr_btn_l;
  logic            s_oe_cpu_pwrgd_out;
  logic [1:0]      s_oe_cpu_throttle;
  logic            s_oe_cpu_thermtrip_l;
  logic [3:0]      s_oe_cpu_errcode;
  logic            s_oe_cpu_reset_out_l;
  logic [1:0]      s_oe_cpu_socket_id;
  logic [3:0]      s_oe_cpu_strap;

  // INPUTS SIGNALS TO THE PADS
  logic            s_in_i2c0_vrm_mst_sda;
  logic            s_in_i2c0_vrm_mst_scl;
  logic            s_in_i2c0_vrm_mst_alert;
  logic            s_in_i2c1_vrm_mst_sda;
  logic            s_in_i2c1_vrm_mst_scl;
  logic            s_in_i2c1_vrm_mst_alert;
  logic            s_in_i2c2_vrm_mst_sda;
  logic            s_in_i2c2_vrm_mst_scl;
  logic            s_in_i2c2_vrm_mst_alert;
  logic            s_in_i2c3_vrm_mst_sda;
  logic            s_in_i2c3_vrm_mst_scl;
  logic            s_in_i2c3_vrm_mst_alert;
  logic            s_in_i2cc_vrm_mst_sda;
  logic            s_in_i2cc_vrm_mst_scl;
  logic            s_in_i2cc_vrm_mst_alert;
  logic            s_in_i2c6_rtc_mst_sda;
  logic            s_in_i2c6_rtc_mst_scl;
  logic            s_in_i2c6_rtc_mst_alert;
  logic            s_in_i2c8_os_mst_sda;
  logic            s_in_i2c8_os_mst_scl;
  logic            s_in_i2c8_os_mst_alert;
  logic            s_in_i2c9_pcie_pnp_mst_sda;
  logic            s_in_i2c9_pcie_pnp_mst_scl;
  logic            s_in_i2c9_pcie_pnp_mst_alert;
  logic            s_in_i2ca_bios_mst_sda;
  logic            s_in_i2ca_bios_mst_scl;
  logic            s_in_i2ca_bios_mst_alert;
  logic            s_in_i2c7_bmc_slv_sda;
  logic            s_in_i2c7_bmc_slv_scl;
  logic            s_in_i2c5_intr_sckt_sda;
  logic            s_in_i2c5_intr_sckt_scl;
  logic            s_in_i2c5_intr_sckt_alert;
  logic            s_in_spi0_vrm_mst_sck;
  logic            s_in_spi0_vrm_mst_si;
  logic            s_in_spi0_vrm_mst_so;
  logic            s_in_spi1_vrm_mst_sck;
  logic            s_in_spi1_vrm_mst_si;
  logic            s_in_spi1_vrm_mst_so;
  logic            s_in_spi2_vrm_mst_sck;
  logic            s_in_spi2_vrm_mst_si;
  logic            s_in_spi2_vrm_mst_so;
  logic            s_in_spi3_vrm_mst_sck;
  logic            s_in_spi3_vrm_mst_si;
  logic            s_in_spi3_vrm_mst_so;
  logic            s_in_qspi_flash_mst_csn0;
  logic            s_in_qspi_flash_mst_sck;
  logic [3:0]      s_in_qspi_flash_mst_sdio;
  logic            s_in_spi5_intr_sckt_csn;
  logic            s_in_spi5_intr_sckt_sck;
  logic            s_in_spi5_intr_sckt_so;
  logic            s_in_spi5_intr_sckt_si;
  logic            s_in_uart1_rxd;
  logic            s_in_uart1_txd;
  logic            s_in_slp_s3_l;
  logic            s_in_slp_s4_l;
  logic            s_in_slp_s5_l;
  logic            s_in_sys_reset_l;
  logic            s_in_sys_rsmrst_l;
  logic            s_in_sys_pwrgd_in;
  logic            s_in_sys_wake_l;
  logic            s_in_sys_pwr_btn_l;
  logic            s_in_cpu_pwrgd_out;
  logic [1:0]      s_in_cpu_throttle;
  logic            s_in_cpu_thermtrip_l;
  logic [3:0]      s_in_cpu_errcode;
  logic            s_in_cpu_reset_out_l;
  logic [1:0]      s_in_cpu_socket_id;
  logic [3:0]      s_in_cpu_strap;

  // SIGNALS FROM THE PADS
  logic            s_out_i2c0_vrm_mst_sda;
  logic            s_out_i2c0_vrm_mst_scl;
  logic            s_out_i2c0_vrm_mst_alert;
  logic            s_out_i2c1_vrm_mst_sda;
  logic            s_out_i2c1_vrm_mst_scl;
  logic            s_out_i2c1_vrm_mst_alert;
  logic            s_out_i2c2_vrm_mst_sda;
  logic            s_out_i2c2_vrm_mst_scl;
  logic            s_out_i2c2_vrm_mst_alert;
  logic            s_out_i2c3_vrm_mst_sda;
  logic            s_out_i2c3_vrm_mst_scl;
  logic            s_out_i2c3_vrm_mst_alert;
  logic            s_out_i2cc_vrm_mst_sda;
  logic            s_out_i2cc_vrm_mst_scl;
  logic            s_out_i2cc_vrm_mst_alert;
  logic            s_out_i2c6_rtc_mst_sda;
  logic            s_out_i2c6_rtc_mst_scl;
  logic            s_out_i2c6_rtc_mst_alert;
  logic            s_out_i2c8_os_mst_sda;
  logic            s_out_i2c8_os_mst_scl;
  logic            s_out_i2c8_os_mst_alert;
  logic            s_out_i2c9_pcie_pnp_mst_sda;
  logic            s_out_i2c9_pcie_pnp_mst_scl;
  logic            s_out_i2c9_pcie_pnp_mst_alert;
  logic            s_out_i2ca_bios_mst_sda;
  logic            s_out_i2ca_bios_mst_scl;
  logic            s_out_i2ca_bios_mst_alert;
  logic            s_out_i2c7_bmc_slv_sda;
  logic            s_out_i2c7_bmc_slv_scl;
  logic            s_out_i2c5_intr_sckt_sda;
  logic            s_out_i2c5_intr_sckt_scl;
  logic            s_out_i2c5_intr_sckt_alert;
  logic            s_out_spi0_vrm_mst_sck;
  logic            s_out_spi0_vrm_mst_si;
  logic            s_out_spi0_vrm_mst_so;
  logic            s_out_spi1_vrm_mst_sck;
  logic            s_out_spi1_vrm_mst_si;
  logic            s_out_spi1_vrm_mst_so;
  logic            s_out_spi2_vrm_mst_sck;
  logic            s_out_spi2_vrm_mst_si;
  logic            s_out_spi2_vrm_mst_so;
  logic            s_out_spi3_vrm_mst_sck;
  logic            s_out_spi3_vrm_mst_si;
  logic            s_out_spi3_vrm_mst_so;
  logic            s_out_qspi_flash_mst_csn0;
  logic            s_out_qspi_flash_mst_sck;
  logic [3:0]      s_out_qspi_flash_mst_sdio;
  logic            s_out_spi5_intr_sckt_csn;
  logic            s_out_spi5_intr_sckt_sck;
  logic            s_out_spi5_intr_sckt_so;
  logic            s_out_spi5_intr_sckt_si;
  logic            s_out_uart1_rxd;
  logic            s_out_uart1_txd;
  logic            s_out_slp_s3_l;
  logic            s_out_slp_s4_l;
  logic            s_out_slp_s5_l;
  logic            s_out_sys_reset_l;
  logic            s_out_sys_rsmrst_l;
  logic            s_out_sys_pwrgd_in;
  logic            s_out_sys_pwr_btn_l;
  logic            s_out_cpu_pwrgd_out;
  logic [1:0]      s_out_cpu_throttle;
  logic            s_out_cpu_thermtrip_l;
  logic [3:0]      s_out_cpu_errcode;
  logic            s_out_cpu_reset_out_l;
  logic [1:0]      s_out_cpu_socket_id;
  logic [3:0]      s_out_cpu_strap;

  // Padframe signals to glue control_pulp into 'chip-like pulp'
  logic [31:0][5:0]      s_pad_cfg ;

  logic [N_SPI-1:0][3:0] s_out_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_out_qspi_csn;
  logic [N_SPI-1:0]      s_out_qspi_sck;
  logic                  s_out_spi_mst_alert;
  logic [3:0]            s_out_spi_slv_sdio;
  logic                  s_out_spi_slv_csn;
  logic                  s_out_spi_slv_sck;
  logic                  s_out_spi_slv_alert;
  logic [N_UART-1:0]     s_out_uart_rx;
  logic [N_UART-1:0]     s_out_uart_tx;
  logic [N_I2C-1:0]      s_out_i2c_sda;
  logic [N_I2C-1:0]      s_out_i2c_scl;
  logic [N_I2C-1:0]      s_out_i2c_alert;

  logic [N_SPI-1:0][3:0] s_in_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_in_qspi_csn;
  logic [N_SPI-1:0]      s_in_qspi_sck;
  logic                  s_in_spi_mst_alert;
  logic [3:0]            s_in_spi_slv_sdio;
  logic                  s_in_spi_slv_csn;
  logic                  s_in_spi_slv_sck;
  logic [N_UART-1:0]     s_in_uart_rx;
  logic [N_UART-1:0]     s_in_uart_tx;
  logic [N_I2C-1:0]      s_in_i2c_sda;
  logic [N_I2C-1:0]      s_in_i2c_scl;
  logic [N_I2C-1:0]      s_in_i2c_alert;

  logic [N_SPI-1:0][3:0] s_oe_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_oe_qspi_csn;
  logic [N_SPI-1:0]      s_oe_qspi_sck;
  logic                  s_oe_spi_mst_alert;
  logic [3:0]            s_oe_spi_slv_sdio;
  logic                  s_oe_spi_slv_csn;
  logic                  s_oe_spi_slv_sck;
  logic                  s_oe_spi_slv_alert;
  logic [N_UART-1:0]     s_oe_uart_rx;
  logic [N_UART-1:0]     s_oe_uart_tx;
  logic [N_I2C-1:0]      s_oe_i2c_sda;
  logic [N_I2C-1:0]      s_oe_i2c_scl;
  logic [N_I2C-1:0]      s_oe_i2c_alert;

  // Internally multiplexed interfaces

  //SPI

  logic [N_SPI-1:0][3:0] s_in_qspi_sdio_t;
  logic [N_SPI-1:0][3:0] s_in_qspi_csn_t;
  logic [N_SPI-1:0]      s_in_qspi_sck_t;
  logic                  s_in_spi_mst_alert_t;

  logic [3:0]            s_in_spi_slv_sdio_t;
  logic                  s_in_spi_slv_csn_t;
  logic                  s_in_spi_slv_sck_t;
  logic                  s_in_spi_slv_alert_t;

  //I2C
  logic                  s_out_i2c_intr_sckt_scl;
  logic                  s_out_i2c_intr_sckt_sda;
  logic                  s_out_i2c_intr_sckt_alert;

  logic                  s_oe_i2c_intr_sckt_scl;
  logic                  s_oe_i2c_intr_sckt_sda;
  logic                  s_oe_i2c_intr_sckt_alert;

  logic                  s_in_i2c_intr_sckt_scl;
  logic                  s_in_i2c_intr_sckt_sda;
  logic                  s_in_i2c_intr_sckt_alert;

  //BMC I2C SLV
  logic [N_I2C_SLV-1:0]  s_out_i2c_slv_scl;
  logic [N_I2C_SLV-1:0]  s_out_i2c_slv_sda;

  logic [N_I2C_SLV-1:0]  s_oe_i2c_slv_scl;
  logic [N_I2C_SLV-1:0]  s_oe_i2c_slv_sda;

  logic [N_I2C_SLV-1:0]  s_in_i2c_slv_scl;
  logic [N_I2C_SLV-1:0]  s_in_i2c_slv_sda;

  //GPIO
  logic [31:0]           gpio_in;
  logic [31:0]           gpio_out;
  logic [31:0]           gpio_dir;
  logic [31:0][3:0]      gpio_cfg;

  // Inter-socket mux select signals
  logic                  s_spi_dir_sel;
  logic                  s_i2c_dir_sel;

  // Clock and reset generation, external clock configuration
  logic                    s_test_clk, s_dft_test_mode, s_dft_cg_enable;
  logic                    s_cluster_clk, s_periph_clk, s_timer_clk;
  logic                    s_soc_rstn, s_cluster_rstn, s_cluster_rstn_gen, s_cluster_rstn_reg;
  logic                    s_clk_mux_sel;
  logic                    reset_mux_n;

  APB_BUS                  s_apb_clk_ctrl_bus();
  APB_BUS                  s_apb_pad_cfg_bus();

  // No test mode for FPGA top-level wrapper
  assign s_test_clk = 1'b0;
  assign s_dft_test_mode = 1'b0;
  assign s_dft_cg_enable = 1'b0;

  assign s_cluster_rstn = s_cluster_rstn_gen && s_cluster_rstn_reg;

`ifdef PULP_FPGA_EMUL
  fpga_system_clk_rst_gen i_system_clk_rst_gen (
`else
  system_clk_rst_gen i_system_clk_rst_gen (
`endif
    .sys_clk_i                  ( sys_clk_i                     ),
    .ref_clk_i                  ( ref_clk_i                     ),
    .clk_sel_i                  ( s_clk_mux_sel                 ),

    .rstn_glob_i                ( reset_mux_n                   ),
    .rstn_soc_sync_o            ( s_soc_rstn                    ),
    .rstn_cluster_sync_o        ( s_cluster_rstn_gen            ),

    .test_mode_i                ( s_dft_test_mode               ),

    .apb_slave                  ( s_apb_clk_ctrl_bus            ),

    .clk_soc_o                  ( s_soc_clk                     ),
    .clk_per_o                  ( s_periph_clk                  ),
    .clk_slow_o                 ( s_timer_clk                   ),
    .clk_cluster_o              ( s_cluster_clk                 )
  );

  // Tie Padframe configuration APB port
  assign s_apb_pad_cfg_bus.prdata = 1'b0;
  assign s_apb_pad_cfg_bus.pready = 1'b0;
  assign s_apb_pad_cfg_bus.pslverr = 1'b0;

  assign soc_clk_o = s_soc_clk;

  // I/O flattening

  // Multiplexing operation SPI
  // TODO: Add spi master[5] and spi slave alert assignments

  assign s_out_spi5_intr_sckt_csn  = (s_spi_dir_sel == 1'b0) ? s_out_qspi_csn[5] : {1'b1,s_out_spi_slv_csn};
  assign s_out_spi5_intr_sckt_sck  = (s_spi_dir_sel == 1'b0) ? s_out_qspi_sck[5] : s_out_spi_slv_sck;
  assign s_out_spi5_intr_sckt_si   = (s_spi_dir_sel == 1'b0) ? s_out_qspi_sdio[5] : s_out_spi_slv_sdio[0];
  assign s_out_spi5_intr_sckt_so   = (s_spi_dir_sel == 1'b0) ? s_out_qspi_sdio[5] : s_out_spi_slv_sdio[1];

  assign s_oe_spi5_intr_sckt_csn   = (s_spi_dir_sel == 1'b0) ? s_oe_qspi_csn[5] : {1'b1,s_oe_spi_slv_csn};
  assign s_oe_spi5_intr_sckt_sck   = (s_spi_dir_sel == 1'b0) ? s_oe_qspi_sck[5] : s_oe_spi_slv_sck;
  assign s_oe_spi5_intr_sckt_si    = (s_spi_dir_sel == 1'b0) ? s_oe_qspi_sdio[5] : s_oe_spi_slv_sdio[0];
  assign s_oe_spi5_intr_sckt_so    = (s_spi_dir_sel == 1'b0) ? s_oe_qspi_sdio[5] : s_oe_spi_slv_sdio[1];

  assign s_in_qspi_csn_t[5]        = (s_spi_dir_sel == 1'b1) ? 1'b1 : s_in_spi5_intr_sckt_csn;
  assign s_in_qspi_sck_t[5]        = (s_spi_dir_sel == 1'b1) ? 1'b0 : s_in_spi5_intr_sckt_sck;
  assign s_in_qspi_sdio_t[5][0]    = (s_spi_dir_sel == 1'b1) ? 1'b0 : s_in_spi5_intr_sckt_si;
  assign s_in_qspi_sdio_t[5][1]    = (s_spi_dir_sel == 1'b1) ? 1'b0 : s_in_spi5_intr_sckt_so;
  assign s_in_qspi_sdio_t[5][3:2]  = 2'b0;
  assign s_in_spi_mst_alert_t      = 1'b0;

  assign s_in_spi_slv_csn_t        = (s_spi_dir_sel == 1'b0) ? s_in_spi_slv_csn : s_in_spi5_intr_sckt_csn;
  assign s_in_spi_slv_sck_t        = (s_spi_dir_sel == 1'b0) ? s_in_spi_slv_sck : s_in_spi5_intr_sckt_sck;
  assign s_in_spi_slv_sdio_t[0]    = (s_spi_dir_sel == 1'b0) ? s_in_spi_slv_sdio : s_in_spi5_intr_sckt_si;
  assign s_in_spi_slv_sdio_t[1]    = (s_spi_dir_sel == 1'b0) ? s_in_spi_slv_sdio : s_in_spi5_intr_sckt_so;
  assign s_in_spi_slv_sdio_t[3:2]  = 2'b0;
  assign s_in_spi_slv_alert_t      = 1'b0;

  // Multiplexing operation I2C
  // I2C master Number 5 and I2C slave Number 1
  assign s_out_i2c5_intr_sckt_scl   =  (s_i2c_dir_sel == 1'b1)      ?   s_out_i2c_scl[5]          :   s_out_i2c_slv_scl[1];
  assign s_out_i2c5_intr_sckt_sda   =  (s_i2c_dir_sel == 1'b1)      ?   s_out_i2c_sda[5]          :   s_out_i2c_slv_sda[1];
  assign s_out_i2c5_intr_sckt_alert =  (s_i2c_dir_sel == 1'b1)      ?   s_out_i2c_alert[5]        :   1'b0;

  assign s_oe_i2c5_intr_sckt_scl    =  (s_i2c_dir_sel == 1'b1)      ?   s_oe_i2c_scl[5]           :   s_oe_i2c_slv_scl[1];
  assign s_oe_i2c5_intr_sckt_sda    =  (s_i2c_dir_sel == 1'b1)      ?   s_oe_i2c_sda[5]           :   s_oe_i2c_slv_sda[1];
  assign s_oe_i2c5_intr_sckt_alert  =  (s_i2c_dir_sel == 1'b1)      ?   s_oe_i2c_alert[5]         :   1'b0;

  assign s_in_i2c_scl[5]          =  (s_i2c_dir_sel == 1'b1)      ?   s_in_i2c5_intr_sckt_scl   :   1'b1;
  assign s_in_i2c_sda[5]          =  (s_i2c_dir_sel == 1'b1)      ?   s_in_i2c5_intr_sckt_sda   :   1'b1;
  assign s_in_i2c_alert[5]        =  (s_i2c_dir_sel == 1'b1)      ?   s_in_i2c5_intr_sckt_alert :   1'b0;

  assign s_in_i2c_slv_scl[1]      =  (s_i2c_dir_sel == 1'b1)      ?   1'b1                      :   s_in_i2c5_intr_sckt_scl;
  assign s_in_i2c_slv_sda[1]      =  (s_i2c_dir_sel == 1'b1)      ?   1'b1                      :   s_in_i2c5_intr_sckt_sda;

  // Other master channels are normally assigned
  for (genvar i=6; i < N_SPI; i++) begin: assign_qspi_csn1
    assign s_in_qspi_csn_t[i] = s_in_qspi_csn[i];
  end

  for (genvar i=0; i < 5; i++) begin: assign_qspi_csn2
    assign s_in_qspi_csn_t[i] = s_in_qspi_csn[i];
  end

  for (genvar i=6; i < N_SPI; i++) begin: assign_qspi_sdio1
    assign s_in_qspi_sdio_t[i] = s_in_qspi_sdio[i];
  end

  for (genvar i=0; i < 5; i++) begin: assign_qspi_sdio2
    assign s_in_qspi_sdio_t[i] = s_in_qspi_sdio[i];
  end

  for (genvar i=6; i < N_SPI; i++) begin: assign_qspi_sck1
    assign s_in_qspi_sck_t[i] = s_in_qspi_sck[i];
  end

  for (genvar i=0; i < 5; i++) begin: assign_qspi_sck2
    assign s_in_qspi_sck_t[i] = s_in_qspi_sck[i];
  end

  logic [1:0]              bootmode_reg;

  // Mux the reset according to bootmode, needed for arbitration between JTAG and PS bootmodes
  assign bootmode_reg = i_control_pulp.i_soc_domain.pulp_soc_i.soc_peripherals_i.i_apb_soc_ctrl.r_bootsel;

  always_comb begin
     unique case (bootmode_reg) // Signal propagated from memory mapped bootmode APB register
       2'h0: begin
         reset_mux_n = rst_ni;
       end
       2'h1: begin
         reset_mux_n = ~rst_ni & jtag_trst_ni;
       end
       2'h2: begin
         reset_mux_n = rst_ni;
       end
       2'h3: begin
         reset_mux_n = rst_ni;
       end
       default: begin
         reset_mux_n = rst_ni;
       end
     endcase
  end // always_comb


  // Exploding IO peripherals signals

  //I2C
  `I2C_EXPLODE_STRUCT_FPGA(i2c0_vrm_mst,      i2c, 0);
  `I2C_EXPLODE_STRUCT_FPGA(i2c1_vrm_mst,      i2c, 1);
  `I2C_EXPLODE_STRUCT_FPGA(i2c2_vrm_mst,      i2c, 2);
  `I2C_EXPLODE_STRUCT_FPGA(i2c3_vrm_mst,      i2c, 3);
  `I2C_EXPLODE_STRUCT_FPGA(i2cc_vrm_mst,      i2c, 11);
  `I2C_EXPLODE_STRUCT_FPGA(i2c6_rtc_mst,      i2c, 6);
  `I2C_EXPLODE_STRUCT_FPGA(i2c8_os_mst,       i2c, 7);
  `I2C_EXPLODE_STRUCT_FPGA(i2c9_pcie_pnp_mst, i2c, 8);
  `I2C_EXPLODE_STRUCT_FPGA(i2ca_bios_mst,     i2c, 9);

  //SPI
  `AVS_EXPLODE_STRUCT_FPGA(spi0_vrm_mst,         qspi, 0);
  `AVS_EXPLODE_STRUCT_FPGA(spi1_vrm_mst,         qspi, 1);
  `AVS_EXPLODE_STRUCT_FPGA(spi2_vrm_mst,         qspi, 2);
  `AVS_EXPLODE_STRUCT_FPGA(spi3_vrm_mst,         qspi, 3);
  `QSPI_EXPLODE_STRUCT_FPGA(qspi_flash_mst, qspi, 7);

  //UART
  assign s_in_uart_rx[0] = s_in_uart1_rxd;
  assign s_in_uart_tx[0] = s_in_uart1_txd;

  assign s_out_uart1_rxd = s_out_uart_rx[0];
  assign s_out_uart1_txd = s_out_uart_tx[0];

  assign s_oe_uart1_rxd = s_oe_uart_rx[0];
  assign s_oe_uart1_txd = s_oe_uart_tx[0];

  //I2C slave from BMC
  assign s_in_i2c_slv_scl[0] = s_in_i2c7_bmc_slv_scl;
  assign s_in_i2c_slv_sda[0] = s_in_i2c7_bmc_slv_sda;

  assign s_out_i2c7_bmc_slv_scl = s_out_i2c_slv_scl[0];
  assign s_out_i2c7_bmc_slv_sda = s_out_i2c_slv_sda[0];

  assign s_oe_i2c7_bmc_slv_scl = s_oe_i2c_slv_scl[0];
  assign s_oe_i2c7_bmc_slv_sda = s_oe_i2c_slv_sda[0];

  // BOOT MODE SEL SIGNALS
  logic [1:0]s_bootsel;
  logic s_bootsel_valid;
  logic s_fc_fetch_en;
  logic s_fc_fetch_en_valid;

  // Instantiate pad_frame for chip-like inout signals
  pad_frame_fpga i_pad_frame (
    // OUTPUT ENABLE SIGNALS TO THE PADS
    .oe_i2c0_vrm_mst_sda_i         ( s_oe_i2c0_vrm_mst_sda         ),
    .oe_i2c0_vrm_mst_scl_i         ( s_oe_i2c0_vrm_mst_scl         ),
    .oe_i2c0_vrm_mst_alert_i       ( s_oe_i2c0_vrm_mst_alert       ),
    .oe_i2c1_vrm_mst_sda_i         ( s_oe_i2c1_vrm_mst_sda         ),
    .oe_i2c1_vrm_mst_scl_i         ( s_oe_i2c1_vrm_mst_scl         ),
    .oe_i2c1_vrm_mst_alert_i       ( s_oe_i2c1_vrm_mst_alert       ),
    .oe_i2c2_vrm_mst_sda_i         ( s_oe_i2c2_vrm_mst_sda         ),
    .oe_i2c2_vrm_mst_scl_i         ( s_oe_i2c2_vrm_mst_scl         ),
    .oe_i2c2_vrm_mst_alert_i       ( s_oe_i2c2_vrm_mst_alert       ),
    .oe_i2c3_vrm_mst_sda_i         ( s_oe_i2c3_vrm_mst_sda         ),
    .oe_i2c3_vrm_mst_scl_i         ( s_oe_i2c3_vrm_mst_scl         ),
    .oe_i2c3_vrm_mst_alert_i       ( s_oe_i2c3_vrm_mst_alert       ),
    .oe_i2cc_vrm_mst_sda_i         ( s_oe_i2cc_vrm_mst_sda         ),
    .oe_i2cc_vrm_mst_scl_i         ( s_oe_i2cc_vrm_mst_scl         ),
    .oe_i2cc_vrm_mst_alert_i       ( s_oe_i2cc_vrm_mst_alert       ),
    .oe_i2c6_rtc_mst_sda_i         ( s_oe_i2c6_rtc_mst_sda         ),
    .oe_i2c6_rtc_mst_scl_i         ( s_oe_i2c6_rtc_mst_scl         ),
    .oe_i2c6_rtc_mst_alert_i       ( s_oe_i2c6_rtc_mst_alert       ),
    .oe_i2c8_os_mst_sda_i          ( s_oe_i2c8_os_mst_sda          ),
    .oe_i2c8_os_mst_scl_i          ( s_oe_i2c8_os_mst_scl          ),
    .oe_i2c8_os_mst_alert_i        ( s_oe_i2c8_os_mst_alert        ),
    .oe_i2c9_pcie_pnp_mst_sda_i    ( s_oe_i2c9_pcie_pnp_mst_sda    ),
    .oe_i2c9_pcie_pnp_mst_scl_i    ( s_oe_i2c9_pcie_pnp_mst_scl    ),
    .oe_i2c9_pcie_pnp_mst_alert_i  ( s_oe_i2c9_pcie_pnp_mst_alert  ),
    .oe_i2ca_bios_mst_sda_i        ( s_oe_i2ca_bios_mst_sda        ),
    .oe_i2ca_bios_mst_scl_i        ( s_oe_i2ca_bios_mst_scl        ),
    .oe_i2ca_bios_mst_alert_i      ( s_oe_i2ca_bios_mst_alert      ),
    .oe_i2c7_bmc_slv_sda_i         ( s_oe_i2c7_bmc_slv_sda         ),
    .oe_i2c7_bmc_slv_scl_i         ( s_oe_i2c7_bmc_slv_scl         ),
    .oe_i2c5_intr_sckt_sda_i       ( s_oe_i2c5_intr_sckt_sda       ),
    .oe_i2c5_intr_sckt_scl_i       ( s_oe_i2c5_intr_sckt_scl       ),
    .oe_i2c5_intr_sckt_alert_i     ( s_oe_i2c5_intr_sckt_alert     ),
    .oe_spi0_vrm_mst_sck_i         ( s_oe_spi0_vrm_mst_sck         ),
    .oe_spi0_vrm_mst_si_i          ( s_oe_spi0_vrm_mst_si          ),
    .oe_spi0_vrm_mst_so_i          ( s_oe_spi0_vrm_mst_so          ),
    .oe_spi1_vrm_mst_sck_i         ( s_oe_spi1_vrm_mst_sck         ),
    .oe_spi1_vrm_mst_si_i          ( s_oe_spi1_vrm_mst_si          ),
    .oe_spi1_vrm_mst_so_i          ( s_oe_spi1_vrm_mst_so          ),
    .oe_spi2_vrm_mst_sck_i         ( s_oe_spi2_vrm_mst_sck         ),
    .oe_spi2_vrm_mst_si_i          ( s_oe_spi2_vrm_mst_si          ),
    .oe_spi2_vrm_mst_so_i          ( s_oe_spi2_vrm_mst_so          ),
    .oe_spi3_vrm_mst_sck_i         ( s_oe_spi3_vrm_mst_sck         ),
    .oe_spi3_vrm_mst_si_i          ( s_oe_spi3_vrm_mst_si          ),
    .oe_spi3_vrm_mst_so_i          ( s_oe_spi3_vrm_mst_so          ),
    .oe_qspi_flash_mst_csn0_i      ( s_oe_qspi_flash_mst_csn0      ),
    .oe_qspi_flash_mst_sck_i       ( s_oe_qspi_flash_mst_sck       ),
    .oe_qspi_flash_mst_sdio_i      ( s_oe_qspi_flash_mst_sdio      ),
    .oe_spi5_intr_sckt_csn_i       ( s_oe_spi5_intr_sckt_csn       ),
    .oe_spi5_intr_sckt_sck_i       ( s_oe_spi5_intr_sckt_sck       ),
    .oe_spi5_intr_sckt_so_i        ( s_oe_spi5_intr_sckt_so        ),
    .oe_spi5_intr_sckt_si_i        ( s_oe_spi5_intr_sckt_si        ),
    .oe_uart1_rxd_i                ( s_oe_uart1_rxd                ),
    .oe_uart1_txd_i                ( s_oe_uart1_txd                ),
    .oe_slp_s3_l_i                 ( s_oe_slp_s3_l                 ),
    .oe_slp_s4_l_i                 ( s_oe_slp_s4_l                 ),
    .oe_slp_s5_l_i                 ( s_oe_slp_s5_l                 ),
    .oe_sys_reset_l_i              ( s_oe_sys_reset_l              ),
    .oe_sys_rsmrst_l_i             ( s_oe_sys_rsmrst_l             ),
    .oe_sys_pwrgd_in_i             ( s_oe_sys_pwrgd_in             ),
    .oe_sys_pwr_btn_l_i            ( s_oe_sys_pwr_btn_l            ),
    .oe_cpu_pwrgd_out_i            ( s_oe_cpu_pwrgd_out            ),
    .oe_cpu_throttle_i             ( s_oe_cpu_throttle             ),
    .oe_cpu_thermtrip_l_i          ( s_oe_cpu_thermtrip_l          ),
    .oe_cpu_errcode_i              ( s_oe_cpu_errcode              ),
    .oe_cpu_reset_out_l_i          ( s_oe_cpu_reset_out_l          ),
    .oe_cpu_socket_id_i            ( s_oe_cpu_socket_id            ),
    .oe_cpu_strap_i                ( s_oe_cpu_strap                ),

    // INPUTS SIGNALS TO THE PADS
    .in_i2c0_vrm_mst_sda_o         ( s_in_i2c0_vrm_mst_sda         ),
    .in_i2c0_vrm_mst_scl_o         ( s_in_i2c0_vrm_mst_scl         ),
    .in_i2c0_vrm_mst_alert_o       ( s_in_i2c0_vrm_mst_alert       ),
    .in_i2c1_vrm_mst_sda_o         ( s_in_i2c1_vrm_mst_sda         ),
    .in_i2c1_vrm_mst_scl_o         ( s_in_i2c1_vrm_mst_scl         ),
    .in_i2c1_vrm_mst_alert_o       ( s_in_i2c1_vrm_mst_alert       ),
    .in_i2c2_vrm_mst_sda_o         ( s_in_i2c2_vrm_mst_sda         ),
    .in_i2c2_vrm_mst_scl_o         ( s_in_i2c2_vrm_mst_scl         ),
    .in_i2c2_vrm_mst_alert_o       ( s_in_i2c2_vrm_mst_alert       ),
    .in_i2c3_vrm_mst_sda_o         ( s_in_i2c3_vrm_mst_sda         ),
    .in_i2c3_vrm_mst_scl_o         ( s_in_i2c3_vrm_mst_scl         ),
    .in_i2c3_vrm_mst_alert_o       ( s_in_i2c3_vrm_mst_alert       ),
    .in_i2cc_vrm_mst_sda_o         ( s_in_i2cc_vrm_mst_sda         ),
    .in_i2cc_vrm_mst_scl_o         ( s_in_i2cc_vrm_mst_scl         ),
    .in_i2cc_vrm_mst_alert_o       ( s_in_i2cc_vrm_mst_alert       ),
    .in_i2c6_rtc_mst_sda_o         ( s_in_i2c6_rtc_mst_sda         ),
    .in_i2c6_rtc_mst_scl_o         ( s_in_i2c6_rtc_mst_scl         ),
    .in_i2c6_rtc_mst_alert_o       ( s_in_i2c6_rtc_mst_alert       ),
    .in_i2c8_os_mst_sda_o          ( s_in_i2c8_os_mst_sda          ),
    .in_i2c8_os_mst_scl_o          ( s_in_i2c8_os_mst_scl          ),
    .in_i2c8_os_mst_alert_o        ( s_in_i2c8_os_mst_alert        ),
    .in_i2c9_pcie_pnp_mst_sda_o    ( s_in_i2c9_pcie_pnp_mst_sda    ),
    .in_i2c9_pcie_pnp_mst_scl_o    ( s_in_i2c9_pcie_pnp_mst_scl    ),
    .in_i2c9_pcie_pnp_mst_alert_o  ( s_in_i2c9_pcie_pnp_mst_alert  ),
    .in_i2ca_bios_mst_sda_o        ( s_in_i2ca_bios_mst_sda        ),
    .in_i2ca_bios_mst_scl_o        ( s_in_i2ca_bios_mst_scl        ),
    .in_i2ca_bios_mst_alert_o      ( s_in_i2ca_bios_mst_alert      ),
    .in_i2c7_bmc_slv_sda_o         ( s_in_i2c7_bmc_slv_sda         ),
    .in_i2c7_bmc_slv_scl_o         ( s_in_i2c7_bmc_slv_scl         ),
    .in_i2c5_intr_sckt_sda_o       ( s_in_i2c5_intr_sckt_sda       ),
    .in_i2c5_intr_sckt_scl_o       ( s_in_i2c5_intr_sckt_scl       ),
    .in_i2c5_intr_sckt_alert_o     ( s_in_i2c5_intr_sckt_alert     ),
    .in_spi0_vrm_mst_sck_o         ( s_in_spi0_vrm_mst_sck         ),
    .in_spi0_vrm_mst_si_o          ( s_in_spi0_vrm_mst_si          ),
    .in_spi0_vrm_mst_so_o          ( s_in_spi0_vrm_mst_so          ),
    .in_spi1_vrm_mst_sck_o         ( s_in_spi1_vrm_mst_sck         ),
    .in_spi1_vrm_mst_si_o          ( s_in_spi1_vrm_mst_si          ),
    .in_spi1_vrm_mst_so_o          ( s_in_spi1_vrm_mst_so          ),
    .in_spi2_vrm_mst_sck_o         ( s_in_spi2_vrm_mst_sck         ),
    .in_spi2_vrm_mst_si_o          ( s_in_spi2_vrm_mst_si          ),
    .in_spi2_vrm_mst_so_o          ( s_in_spi2_vrm_mst_so          ),
    .in_spi3_vrm_mst_sck_o         ( s_in_spi3_vrm_mst_sck         ),
    .in_spi3_vrm_mst_si_o          ( s_in_spi3_vrm_mst_si          ),
    .in_spi3_vrm_mst_so_o          ( s_in_spi3_vrm_mst_so          ),
    .in_qspi_flash_mst_csn0_o      ( s_in_qspi_flash_mst_csn0      ),
    .in_qspi_flash_mst_sck_o       ( s_in_qspi_flash_mst_sck       ),
    .in_qspi_flash_mst_sdio_o      ( s_in_qspi_flash_mst_sdio      ),
    .in_spi5_intr_sckt_csn_o       ( s_in_spi5_intr_sckt_csn       ),
    .in_spi5_intr_sckt_sck_o       ( s_in_spi5_intr_sckt_sck       ),
    .in_spi5_intr_sckt_so_o        ( s_in_spi5_intr_sckt_so        ),
    .in_spi5_intr_sckt_si_o        ( s_in_spi5_intr_sckt_si        ),
    .in_uart1_rxd_o                ( s_in_uart1_rxd                ),
    .in_uart1_txd_o                ( s_in_uart1_txd                ),
    .in_slp_s3_l_o                 ( s_in_slp_s3_l                 ),
    .in_slp_s4_l_o                 ( s_in_slp_s4_l                 ),
    .in_slp_s5_l_o                 ( s_in_slp_s5_l                 ),
    .in_sys_reset_l_o              ( s_in_sys_reset_l              ),
    .in_sys_rsmrst_l_o             ( s_in_sys_rsmrst_l             ),
    .in_sys_pwrgd_in_o             ( s_in_sys_pwrgd_in             ),
    .in_sys_pwr_btn_l_o            ( s_in_sys_pwr_btn_l            ),
    .in_cpu_pwrgd_out_o            ( s_in_cpu_pwrgd_out            ),
    .in_cpu_throttle_o             ( s_in_cpu_throttle             ),
    .in_cpu_thermtrip_l_o          ( s_in_cpu_thermtrip_l          ),
    .in_cpu_errcode_o              ( s_in_cpu_errcode              ),
    .in_cpu_reset_out_l_o          ( s_in_cpu_reset_out_l          ),
    .in_cpu_socket_id_o            ( s_in_cpu_socket_id            ),
    .in_cpu_strap_o                ( s_in_cpu_strap                ),

    // OUTPUT SIGNALS FROM THE PADS
    .out_i2c0_vrm_mst_sda_i        ( s_out_i2c0_vrm_mst_sda        ),
    .out_i2c0_vrm_mst_scl_i        ( s_out_i2c0_vrm_mst_scl        ),
    .out_i2c0_vrm_mst_alert_i      ( s_out_i2c0_vrm_mst_alert      ),
    .out_i2c1_vrm_mst_sda_i        ( s_out_i2c1_vrm_mst_sda        ),
    .out_i2c1_vrm_mst_scl_i        ( s_out_i2c1_vrm_mst_scl        ),
    .out_i2c1_vrm_mst_alert_i      ( s_out_i2c1_vrm_mst_alert      ),
    .out_i2c2_vrm_mst_sda_i        ( s_out_i2c2_vrm_mst_sda        ),
    .out_i2c2_vrm_mst_scl_i        ( s_out_i2c2_vrm_mst_scl        ),
    .out_i2c2_vrm_mst_alert_i      ( s_out_i2c2_vrm_mst_alert      ),
    .out_i2c3_vrm_mst_sda_i        ( s_out_i2c3_vrm_mst_sda        ),
    .out_i2c3_vrm_mst_scl_i        ( s_out_i2c3_vrm_mst_scl        ),
    .out_i2c3_vrm_mst_alert_i      ( s_out_i2c3_vrm_mst_alert      ),
    .out_i2cc_vrm_mst_sda_i        ( s_out_i2cc_vrm_mst_sda        ),
    .out_i2cc_vrm_mst_scl_i        ( s_out_i2cc_vrm_mst_scl        ),
    .out_i2cc_vrm_mst_alert_i      ( s_out_i2cc_vrm_mst_alert      ),
    .out_i2c6_rtc_mst_sda_i        ( s_out_i2c6_rtc_mst_sda        ),
    .out_i2c6_rtc_mst_scl_i        ( s_out_i2c6_rtc_mst_scl        ),
    .out_i2c6_rtc_mst_alert_i      ( s_out_i2c6_rtc_mst_alert      ),
    .out_i2c8_os_mst_sda_i         ( s_out_i2c8_os_mst_sda         ),
    .out_i2c8_os_mst_scl_i         ( s_out_i2c8_os_mst_scl         ),
    .out_i2c8_os_mst_alert_i       ( s_out_i2c8_os_mst_alert       ),
    .out_i2c9_pcie_pnp_mst_sda_i   ( s_out_i2c9_pcie_pnp_mst_sda   ),
    .out_i2c9_pcie_pnp_mst_scl_i   ( s_out_i2c9_pcie_pnp_mst_scl   ),
    .out_i2c9_pcie_pnp_mst_alert_i ( s_out_i2c9_pcie_pnp_mst_alert ),
    .out_i2ca_bios_mst_sda_i       ( s_out_i2ca_bios_mst_sda       ),
    .out_i2ca_bios_mst_scl_i       ( s_out_i2ca_bios_mst_scl       ),
    .out_i2ca_bios_mst_alert_i     ( s_out_i2ca_bios_mst_alert     ),
    .out_i2c7_bmc_slv_sda_i        ( s_out_i2c7_bmc_slv_sda        ),
    .out_i2c7_bmc_slv_scl_i        ( s_out_i2c7_bmc_slv_scl        ),
    .out_i2c5_intr_sckt_sda_i      ( s_out_i2c5_intr_sckt_sda      ),
    .out_i2c5_intr_sckt_scl_i      ( s_out_i2c5_intr_sckt_scl      ),
    .out_i2c5_intr_sckt_alert_i    ( s_out_i2c5_intr_sckt_alert    ),
    .out_spi0_vrm_mst_sck_i        ( s_out_spi0_vrm_mst_sck        ),
    .out_spi0_vrm_mst_si_i         ( s_out_spi0_vrm_mst_si         ),
    .out_spi0_vrm_mst_so_i         ( s_out_spi0_vrm_mst_so         ),
    .out_spi1_vrm_mst_sck_i        ( s_out_spi1_vrm_mst_sck        ),
    .out_spi1_vrm_mst_si_i         ( s_out_spi1_vrm_mst_si         ),
    .out_spi1_vrm_mst_so_i         ( s_out_spi1_vrm_mst_so         ),
    .out_spi2_vrm_mst_sck_i        ( s_out_spi2_vrm_mst_sck        ),
    .out_spi2_vrm_mst_si_i         ( s_out_spi2_vrm_mst_si         ),
    .out_spi2_vrm_mst_so_i         ( s_out_spi2_vrm_mst_so         ),
    .out_spi3_vrm_mst_sck_i        ( s_out_spi3_vrm_mst_sck        ),
    .out_spi3_vrm_mst_si_i         ( s_out_spi3_vrm_mst_si         ),
    .out_spi3_vrm_mst_so_i         ( s_out_spi3_vrm_mst_so         ),
    .out_qspi_flash_mst_csn0_i     ( s_out_qspi_flash_mst_csn0     ),
    .out_qspi_flash_mst_sck_i      ( s_out_qspi_flash_mst_sck      ),
    .out_qspi_flash_mst_sdio_i     ( s_out_qspi_flash_mst_sdio     ),
    .out_spi5_intr_sckt_csn_i      ( s_out_spi5_intr_sckt_csn      ),
    .out_spi5_intr_sckt_sck_i      ( s_out_spi5_intr_sckt_sck      ),
    .out_spi5_intr_sckt_so_i       ( s_out_spi5_intr_sckt_so       ),
    .out_spi5_intr_sckt_si_i       ( s_out_spi5_intr_sckt_si       ),
    .out_uart1_rxd_i               ( s_out_uart1_rxd               ),
    .out_uart1_txd_i               ( s_out_uart1_txd               ),
    .out_slp_s3_l_i                ( s_out_slp_s3_l                ),
    .out_slp_s4_l_i                ( s_out_slp_s4_l                ),
    .out_slp_s5_l_i                ( s_out_slp_s5_l                ),
    .out_sys_reset_l_i             ( s_out_sys_reset_l             ),
    .out_sys_rsmrst_l_i            ( s_out_sys_rsmrst_l            ),
    .out_sys_pwrgd_in_i            ( s_out_sys_pwrgd_in            ),
    .out_sys_pwr_btn_l_i           ( s_out_sys_pwr_btn_l           ),
    .out_cpu_pwrgd_out_i           ( s_out_cpu_pwrgd_out           ),
    .out_cpu_throttle_i            ( s_out_cpu_throttle            ),
    .out_cpu_thermtrip_l_i         ( s_out_cpu_thermtrip_l         ),
    .out_cpu_errcode_i             ( s_out_cpu_errcode             ),
    .out_cpu_reset_out_l_i         ( s_out_cpu_reset_out_l         ),
    .out_cpu_socket_id_i           ( s_out_cpu_socket_id           ),
    .out_cpu_strap_i               ( s_out_cpu_strap               ),
    .out_doorbell                  ( s_doorbell_irq                ),
    .out_completion                ( s_completion_irq              ),

    // EXT CHIP TP                 PADS
    .pad_pmb_vr1_pms0_sda          ( pad_pmb_vr1_pms0_sda          ),
    .pad_pmb_vr1_pms0_scl          ( pad_pmb_vr1_pms0_scl          ),
    .pad_pmb_vr1_pms0_alert_n      ( pad_pmb_vr1_pms0_alert_n      ),
    .pad_pmb_vr2_pms0_sda          ( pad_pmb_vr2_pms0_sda          ),
    .pad_pmb_vr2_pms0_scl          ( pad_pmb_vr2_pms0_scl          ),
    .pad_pmb_vr2_pms0_alert_n      ( pad_pmb_vr2_pms0_alert_n      ),
    .pad_pmb_vr3_pms0_sda          ( pad_pmb_vr3_pms0_sda          ),
    .pad_pmb_vr3_pms0_scl          ( pad_pmb_vr3_pms0_scl          ),
    .pad_pmb_vr3_pms0_alert_n      ( pad_pmb_vr3_pms0_alert_n      ),
    .pad_pmb_pol1_pms0_sda         ( pad_pmb_pol1_pms0_sda         ),
    .pad_pmb_pol1_pms0_scl         ( pad_pmb_pol1_pms0_scl         ),
    .pad_pmb_pol1_pms0_alert_n     ( pad_pmb_pol1_pms0_alert_n     ),
    .pad_pmb_ibc_pms0_sda          ( pad_pmb_ibc_pms0_sda          ),
    .pad_pmb_ibc_pms0_scl          ( pad_pmb_ibc_pms0_scl          ),
    .pad_pmb_ibc_pms0_alert_n      ( pad_pmb_ibc_pms0_alert_n      ),
    .pad_i2c2_pms0_sda             ( pad_i2c2_pms0_sda             ),
    .pad_i2c2_pms0_scl             ( pad_i2c2_pms0_scl             ),
    .pad_i2c2_pms0_smbalert_n      ( pad_i2c2_pms0_smbalert_n      ),
    .pad_i2c3_pms0_sda             ( pad_i2c3_pms0_sda             ),
    .pad_i2c3_pms0_scl             ( pad_i2c3_pms0_scl             ),
    .pad_i2c3_pms0_smbalert_n      ( pad_i2c3_pms0_smbalert_n      ),
    .pad_i2c4_pms0_sda             ( pad_i2c4_pms0_sda             ),
    .pad_i2c4_pms0_scl             ( pad_i2c4_pms0_scl             ),
    .pad_i2c4_pms0_smbalert_n      ( pad_i2c4_pms0_smbalert_n      ),
    .pad_i2c5_pms0_sda             ( pad_i2c5_pms0_sda             ),
    .pad_i2c5_pms0_scl             ( pad_i2c5_pms0_scl             ),
    .pad_i2c5_pms0_smbalert_n      ( pad_i2c5_pms0_smbalert_n      ),
    .pad_i2c6_pms0_slv_sda         ( pad_i2c6_pms0_slv_sda         ),
    .pad_i2c6_pms0_slv_scl         ( pad_i2c6_pms0_slv_scl         ),
    .pad_i2c7_pms0_sda             ( pad_i2c7_pms0_sda             ),
    .pad_i2c7_pms0_scl             ( pad_i2c7_pms0_scl             ),
    .pad_pms0_pms1_smbalert_n      ( pad_pms0_pms1_smbalert_n      ),
    .pad_pms_avs_clk_vr1           ( pad_pms_avs_clk_vr1           ),
    .pad_pms_avs_mdata_vr1         ( pad_pms_avs_mdata_vr1         ),
    .pad_pms_avs_sdata_vr1         ( pad_pms_avs_sdata_vr1         ),
    .pad_pms_avs_clk_vr2           ( pad_pms_avs_clk_vr2           ),
    .pad_pms_avs_mdata_vr2         ( pad_pms_avs_mdata_vr2         ),
    .pad_pms_avs_sdata_vr2         ( pad_pms_avs_sdata_vr2         ),
    .pad_pms_avs_clk_vr3           ( pad_pms_avs_clk_vr3           ),
    .pad_pms_avs_mdata_vr3         ( pad_pms_avs_mdata_vr3         ),
    .pad_pms_avs_sdata_vr3         ( pad_pms_avs_sdata_vr3         ),
    .pad_pms_avs_clk_ibc           ( pad_pms_avs_clk_ibc           ),
    .pad_pms_avs_mdata_ibc         ( pad_pms_avs_mdata_ibc         ),
    .pad_pms_avs_sdata_ibc         ( pad_pms_avs_sdata_ibc         ),
    .pad_pms_bios_spi_cs0_n        ( pad_pms_bios_spi_cs0_n        ),
    .pad_pms_bios_spi_clk          ( pad_pms_bios_spi_clk          ),
    .pad_pms_bios_spi_io0          ( pad_pms_bios_spi_io0          ),
    .pad_pms_bios_spi_io1          ( pad_pms_bios_spi_io1          ),
    .pad_pms_bios_spi_io2          ( pad_pms_bios_spi_io2          ),
    .pad_pms_bios_spi_io3          ( pad_pms_bios_spi_io3          ),
    .pad_pms0_pms1_spi_cs_n        ( pad_pms0_pms1_spi_cs_n        ),
    .pad_pms0_pms1_spi_clk         ( pad_pms0_pms1_spi_clk         ),
    .pad_pms0_pms1_spi_miso        ( pad_pms0_pms1_spi_miso        ),
    .pad_pms0_pms1_spi_mosi        ( pad_pms0_pms1_spi_mosi        ),
    .pad_uart1_pms0_rxd            ( pad_uart1_pms0_rxd            ),
    .pad_uart1_pms0_txd            ( pad_uart1_pms0_txd            ),
    .pad_pms0_slp_s3_n             ( pad_pms0_slp_s3_n             ),
    .pad_pms0_slp_s4_n             ( pad_pms0_slp_s4_n             ),
    .pad_pms0_slp_s5_n             ( pad_pms0_slp_s5_n             ),
    .pad_pms0_sys_reset_n          ( pad_pms0_sys_reset_n          ),
    .pad_pms0_sys_rsmrst_n         ( pad_pms0_sys_rsmrst_n         ),
    .pad_pms0_sys_pwgd_in          ( pad_pms0_sys_pwgd_in          ),
    .pad_pms0_pwr_btn_n            ( pad_pms0_pwr_btn_n            ),
    .pad_pms0_pwgd_out             ( pad_pms0_pwgd_out             ),
    .pad_pms0_throttle_0           ( pad_pms0_throttle_0           ),
    .pad_pms0_throttle_1           ( pad_pms0_throttle_1           ),
    .pad_pms0_thermtrip_n          ( pad_pms0_thermtrip_n          ),
    .pad_pms0_errcode_0            ( pad_pms0_errcode_0            ),
    .pad_pms0_errcode_1            ( pad_pms0_errcode_1            ),
    .pad_pms0_errcode_2            ( pad_pms0_errcode_2            ),
    .pad_pms0_errcode_3            ( pad_pms0_errcode_3            ),
    .pad_pms0_reset_out_n          ( pad_pms0_reset_out_n          ),
    .pad_pms0_socket_id_0          ( pad_pms0_socket_id_0          ),
    .pad_pms0_socket_id_1          ( pad_pms0_socket_id_1          ),
    .pad_pms0_strap_0              ( pad_pms0_strap_0              ),
    .pad_pms0_strap_1              ( pad_pms0_strap_1              ),
    .pad_pms0_strap_2              ( pad_pms0_strap_2              ),
    .pad_pms0_strap_3              ( pad_pms0_strap_3              ),

    .pad_bootsel0                  ( pad_bootsel0                  ),
    .pad_bootsel1                  ( pad_bootsel1                  ),
    .pad_bootsel_valid             ( pad_bootsel_valid             ),
    .pad_fc_fetch_en               ( pad_fc_fetch_en               ),
    .pad_fc_fetch_en_valid         ( pad_fc_fetch_en_valid         ),
    .pad_completion_irq            ( pad_completion_irq            ),
    .pad_doorbell_irq              ( pad_doorbell_irq              ),

    .bootsel_o                     ( s_bootsel                     ),
    .bootsel_valid_o               ( s_bootsel_valid               ),
    .fc_fetch_en_o                 ( s_fc_fetch_en                 ),
    .fc_fetch_en_valid_o           ( s_fc_fetch_en_valid           ),

    .pad_cfg_i                     ( s_pad_cfg                     )
  );

  // SLP, SYS, CPU pins
  assign s_out_slp_s3_l         = gpio_out[0];
  assign s_out_slp_s4_l         = gpio_out[1];
  assign s_out_slp_s5_l         = gpio_out[2];
  assign s_out_cpu_pwrgd_out    = gpio_out[3];
  assign s_out_cpu_thermtrip_l  = gpio_out[4];
  assign s_out_cpu_errcode[0]   = gpio_out[5];
  assign s_out_cpu_errcode[1]   = gpio_out[6];
  assign s_out_cpu_errcode[2]   = gpio_out[7];
  assign s_out_cpu_errcode[3]   = gpio_out[8];
  assign s_out_cpu_reset_out_l  = gpio_out[9];
  assign s_out_sys_reset_l      = gpio_out[10];
  assign s_out_sys_rsmrst_l     = gpio_out[11];
  assign s_out_sys_pwr_btn_l    = gpio_out[12];
  assign s_out_sys_pwrgd_in     = gpio_out[13];
  assign s_out_sys_wake_l       = gpio_out[14];
  assign s_out_cpu_throttle[0]  = gpio_out[15];
  assign s_out_cpu_throttle[1]  = gpio_out[16];
  assign s_out_cpu_socket_id[0] = gpio_out[17];
  assign s_out_cpu_socket_id[1] = gpio_out[18];
  assign s_out_cpu_strap[0]     = gpio_out[19];
  assign s_out_cpu_strap[1]     = gpio_out[20];
  assign s_out_cpu_strap[2]     = gpio_out[21];
  assign s_out_cpu_strap[3]     = gpio_out[22];

  // SLP, SYS, CPU pins
  assign gpio_in[0]  = s_in_slp_s3_l;
  assign gpio_in[1]  = s_in_slp_s4_l;
  assign gpio_in[2]  = s_in_slp_s5_l;
  assign gpio_in[3]  = s_in_cpu_pwrgd_out;
  assign gpio_in[4]  = s_in_cpu_thermtrip_l;
  assign gpio_in[5]  = s_in_cpu_errcode[0];
  assign gpio_in[6]  = s_in_cpu_errcode[1];
  assign gpio_in[7]  = s_in_cpu_errcode[2];
  assign gpio_in[8]  = s_in_cpu_errcode[3];
  assign gpio_in[9]  = s_in_cpu_reset_out_l;
  assign gpio_in[10] = s_in_sys_reset_l;
  assign gpio_in[11] = s_in_sys_rsmrst_l;
  assign gpio_in[12] = s_in_sys_pwr_btn_l;
  assign gpio_in[13] = s_in_sys_pwrgd_in;
  assign gpio_in[14] = s_in_sys_wake_l;
  assign gpio_in[15] = s_in_cpu_throttle[0];
  assign gpio_in[16] = s_in_cpu_throttle[1];
  assign gpio_in[17] = s_in_cpu_socket_id[0];
  assign gpio_in[18] = s_in_cpu_socket_id[1];
  assign gpio_in[19] = s_in_cpu_strap[0];
  assign gpio_in[20] = s_in_cpu_strap[1];
  assign gpio_in[21] = s_in_cpu_strap[2];
  assign gpio_in[22] = s_in_cpu_strap[3];

  // SLP, SYS, CPU pins: output enables set set to '1' if pin is an output and
  // to '0' if it's an input pin (assuming a pull up behaviour of the final pad)
  assign s_oe_slp_s3_l         = gpio_dir[0];
  assign s_oe_slp_s4_l         = gpio_dir[1];
  assign s_oe_slp_s5_l         = gpio_dir[2];
  assign s_oe_cpu_pwrgd_out    = gpio_dir[3];
  assign s_oe_cpu_thermtrip_l  = gpio_dir[4];
  assign s_oe_cpu_errcode[0]   = gpio_dir[5];
  assign s_oe_cpu_errcode[1]   = gpio_dir[6];
  assign s_oe_cpu_errcode[2]   = gpio_dir[7];
  assign s_oe_cpu_errcode[3]   = gpio_dir[8];
  assign s_oe_cpu_reset_out_l  = gpio_dir[9];
  assign s_oe_sys_reset_l      = gpio_dir[10];
  assign s_oe_sys_rsmrst_l     = gpio_dir[11];
  assign s_oe_sys_pwr_btn_l    = gpio_dir[12];
  assign s_oe_sys_pwrgd_in     = gpio_dir[13];
  assign s_oe_sys_wake_l       = gpio_dir[14];
  assign s_oe_cpu_throttle[0]  = gpio_dir[15];
  assign s_oe_cpu_throttle[1]  = gpio_dir[16];
  assign s_oe_cpu_socket_id[0] = gpio_dir[17];
  assign s_oe_cpu_socket_id[1] = gpio_dir[18];
  assign s_oe_cpu_strap[0]     = gpio_dir[19];
  assign s_oe_cpu_strap[1]     = gpio_dir[20];
  assign s_oe_cpu_strap[2]     = gpio_dir[21];
  assign s_oe_cpu_strap[3]     = gpio_dir[22];

  // Unused GPIOs
  for (genvar i = 24; i < 32; i++) begin: assign_gpio_unused
    assign gpio_in[i]  = 1'b0;
  end

  for (genvar i = 0; i < 32; i++) begin: assign_padcfg
    assign pad_cfg_o[i] = {2'b0, gpio_cfg[i]};
  end

  // Instantiate control_pulp

  control_pulp #(
    .CORE_TYPE(CORE_TYPE),
    .USE_FPU(RISCY_FPU),
    .USE_HWPE(USE_HWPE),
    .PULP_XPULP(PULP_XPULP),
    .SIM_STDOUT(SIM_STDOUT),
    .BEHAV_MEM(BEHAV_MEM),
    .FPGA_MEM(FPGA_MEM),
    .MACRO_ROM(MACRO_ROM),
    .USE_CLUSTER(USE_CLUSTER),
    .DMA_TYPE(DMA_TYPE),

    .N_SOC_PERF_COUNTERS(16),  // for RTL/FPGA 16 perf counters one for each event
    .N_CLUST_PERF_COUNTERS(16),

     // nci_cp_top Master
    .axi_req_inp_ext_t       (axi_req_pl_slv_t),
    .axi_resp_inp_ext_t      (axi_resp_pl_slv_t),
     // nci_cp_top Slave
    .axi_req_oup_ext_t       (axi_req_pl_mst_t),
    .axi_resp_oup_ext_t      (axi_resp_pl_mst_t)

  ) i_control_pulp (

    // control-pulp interaction ports with off-pmu objects

    // nci_cp_top Master
    .from_ext_req_i       (to_pl_req),
    .from_ext_resp_o      (to_pl_resp),
     // nci_cp_top Slave
    .to_ext_req_o         (from_pl_req),
    .to_ext_resp_i        (from_pl_resp),

    .apb_clk_ctrl_bus   ( s_apb_clk_ctrl_bus    ),
    .clk_mux_sel_o      ( s_clk_mux_sel         ),
    .apb_pad_cfg_bus    ( s_apb_pad_cfg_bus     ),

    // on-pmu internal peripherals (soc)
    .soc_clk_i          ( s_soc_clk             ),
    .periph_clk_i       ( s_periph_clk          ),
    .cluster_clk_i      ( s_cluster_clk         ),
    .ref_clk_i          ( s_timer_clk           ),
    .test_clk_i         ( '0                    ), // for dft
    .soc_rst_ni         ( s_soc_rstn            ),
    .cluster_rst_ni     ( s_cluster_rstn        ),
    .cluster_rst_reg_no ( s_cluster_rstn_reg    ),

    .dft_test_mode_i               ( '0                      ),
    .dft_cg_enable_i               ( '0                      ),

    .jtag_tdo_o,
    .jtag_tck_i,
    .jtag_tdi_i,
    .jtag_tms_i,
    .jtag_trst_ni,

    .wdt_alert_o,
    .wdt_alert_clear_i,

    .scg_irq_i                     (scg_irq                  ),
    .scp_irq_i                     (scp_irq                  ),
    .scp_secure_irq_i              (scp_secure_irq           ),
    .mbox_irq_i                    ({11'h0, s_doorbell_irq}  ),
    .mbox_secure_irq_i             ('0                       ),

    .oe_qspi_sdio_o                ( s_oe_qspi_sdio          ),
    .oe_qspi_csn_o                 ( s_oe_qspi_csn           ),
    .oe_qspi_sck_o                 ( s_oe_qspi_sck           ),
    .oe_spi_mst_alert_o            ( s_oe_spi_mst_alert      ),
    .oe_spi_slv_sdio_o             ( s_oe_spi_slv_sdio       ),
    .oe_spi_slv_csn_o              ( s_oe_spi_slv_csn        ),
    .oe_spi_slv_sck_o              ( s_oe_spi_slv_sck        ),
    .oe_spi_slv_alert_o            ( s_oe_spi_slv_alert      ),
    .oe_i2c_sda_o                  ( s_oe_i2c_sda            ),
    .oe_i2c_scl_o                  ( s_oe_i2c_scl            ),
    .oe_i2c_alert_o                ( s_oe_i2c_alert          ),

    .oe_i2c_slv_sda_o              ( s_oe_i2c_slv_sda        ),
    .oe_i2c_slv_scl_o              ( s_oe_i2c_slv_scl        ),

    .oe_uart_rx_o                  ( s_oe_uart_rx            ),
    .oe_uart_tx_o                  ( s_oe_uart_tx            ),

    .out_qspi_sdio_o               ( s_out_qspi_sdio         ),
    .out_qspi_csn_o                ( s_out_qspi_csn          ),
    .out_qspi_sck_o                ( s_out_qspi_sck          ),
    .out_spi_mst_alert_o           ( s_out_spi_mst_alert     ),
    .out_spi_slv_sdio_o            ( s_out_spi_slv_sdio      ),
    .out_spi_slv_csn_o             ( s_out_spi_slv_csn       ),
    .out_spi_slv_sck_o             ( s_out_spi_slv_sck       ),
    .out_spi_slv_alert_o           ( s_out_spi_slv_alert     ),
    .out_i2c_sda_o                 ( s_out_i2c_sda           ),
    .out_i2c_scl_o                 ( s_out_i2c_scl           ),
    .out_i2c_alert_o               ( s_out_i2c_alert         ),

    .out_i2c_slv_sda_o             ( s_out_i2c_slv_sda       ),
    .out_i2c_slv_scl_o             ( s_out_i2c_slv_scl       ),

    .out_uart_rx_o                 ( s_out_uart_rx           ),
    .out_uart_tx_o                 ( s_out_uart_tx           ),

    .in_qspi_sdio_i                ( s_in_qspi_sdio_t        ),
    .in_qspi_csn_i                 ( s_in_qspi_csn_t         ),
    .in_qspi_sck_i                 ( s_in_qspi_sck_t         ),
    .in_spi_mst_alert_i            ( s_in_spi_mst_alert_t    ),
    .in_spi_slv_sdio_i             ( s_in_spi_slv_sdio_t     ),
    .in_spi_slv_csn_i              ( s_in_spi_slv_csn_t      ),
    .in_spi_slv_sck_i              ( s_in_spi_slv_sck_t      ),
    .in_spi_slv_alert_i            ( s_in_spi_slv_alert_t    ),
    .in_i2c_sda_i                  ( s_in_i2c_sda            ),
    .in_i2c_scl_i                  ( s_in_i2c_scl            ),
    .in_i2c_alert_i                ( s_in_i2c_alert          ),

    .in_i2c_slv_sda_i              ( s_in_i2c_slv_sda        ),
    .in_i2c_slv_scl_i              ( s_in_i2c_slv_scl        ),

    .in_uart_rx_i                  ( s_in_uart_rx            ),
    .in_uart_tx_i                  ( s_in_uart_tx            ),

    .sel_spi_dir_o                 ( s_spi_dir_sel           ),
    .sel_i2c_mux_o                 ( s_i2c_dir_sel           ), //TODO replace `_mux_` for `_dir_` in the port name!

    .gpio_in_i                     ( gpio_in                 ),
    .gpio_out_o                    ( gpio_out                ),
    .gpio_dir_o                    ( gpio_dir                ),
    .gpio_cfg_o                    ( gpio_cfg                ),

    .bootsel_valid_i               (s_bootsel_valid          ),  
    .bootsel_i                     ({1'b0, s_bootsel}        ),
    .fc_fetch_en_valid_i           (s_fc_fetch_en_valid),
    .fc_fetch_en_i                 (s_fc_fetch_en)
  );

endmodule // control_pulp_fpga

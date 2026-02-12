// Copyright (c) 2022 ETH Zurich and University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
//


`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module axi_scmi_mailbox
  import scmi_reg_pkg::*;
#(
  parameter int unsigned NumChannels             = 1,
  parameter int unsigned AxiIdWidth              = 8,
  parameter int unsigned AxiAddrWidth            = 64,
  parameter int unsigned AxiSlvPortDataWidth     = 64,
  parameter int unsigned AxiUserWidth            = 1,
  parameter int unsigned AxiMaxReads             = 1,
  parameter type axi_req_t                       = logic,
  parameter type axi_resp_t                      = logic,
  localparam int unsigned AxiMstPortDataWidth = 32
) (
  input  logic       clk_i, // Clock
  input  logic       rst_ni, // Asynchronous reset active low

  input  logic       testmode_i, // Test mode (for scan)

  input  axi_req_t   axi_mbox_req,
  output axi_resp_t  axi_mbox_rsp,

  output [NumChannels-1:0]        irq_completion_o, // completion interrupt platform to agent
  output [NumChannels-1:0]        irq_doorbell_o    // doorbell interrupt agent to platform
);

  typedef logic [AxiAddrWidth-1:0]            addr_t;
  typedef logic [AxiMstPortDataWidth-1:0]   data_t;
  typedef logic [AxiMstPortDataWidth/8-1:0] strb_t;

  typedef logic [AxiIdWidth-1:0] id_t                   ;
  typedef logic [AxiMstPortDataWidth-1:0] mst_data_t  ;
  typedef logic [AxiMstPortDataWidth/8-1:0] mst_strb_t;
  typedef logic [AxiSlvPortDataWidth-1:0] slv_data_t  ;
  typedef logic [AxiSlvPortDataWidth/8-1:0] slv_strb_t;
  typedef logic [AxiUserWidth-1:0] user_t               ;


  `REG_BUS_TYPEDEF_REQ(reg_req_t, addr_t, data_t, strb_t)
  `REG_BUS_TYPEDEF_RSP(reg_rsp_t, data_t)

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(mst_w_chan_t, mst_data_t, mst_strb_t, user_t)
  `AXI_TYPEDEF_W_CHAN_T(slv_w_chan_t, slv_data_t, slv_strb_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_chan_t, mst_data_t, id_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_chan_t, slv_data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, aw_chan_t, mst_w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, b_chan_t, mst_r_chan_t)
  `AXI_TYPEDEF_REQ_T(slv_req_t, aw_chan_t, slv_w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, b_chan_t, slv_r_chan_t)

  reg_req_t reg_req;
  reg_rsp_t reg_rsp;

  mst_req_t  axi32_mbox_req;
  mst_resp_t axi32_mbox_rsp;

  scmi_reg_pkg::scmi_reg2hw_t reg2hw;

  assign irq_doorbell_o[0]   = reg2hw.doorbell_c0.intr.q;
  assign irq_completion_o[0] = reg2hw.completion_interrupt_c0.intr.q;
  assign irq_doorbell_o[1]   = reg2hw.doorbell_c1.intr.q;
  assign irq_completion_o[1] = reg2hw.completion_interrupt_c1.intr.q;
  assign irq_doorbell_o[2]   = reg2hw.doorbell_c2.intr.q;
  assign irq_completion_o[2] = reg2hw.completion_interrupt_c2.intr.q;
  assign irq_doorbell_o[3]   = reg2hw.doorbell_c3.intr.q;
  assign irq_completion_o[3] = reg2hw.completion_interrupt_c3.intr.q;
  assign irq_doorbell_o[4]   = reg2hw.doorbell_c4.intr.q;
  assign irq_completion_o[4] = reg2hw.completion_interrupt_c4.intr.q;
  assign irq_doorbell_o[5]   = reg2hw.doorbell_c5.intr.q;
  assign irq_completion_o[5] = reg2hw.completion_interrupt_c5.intr.q;
  assign irq_doorbell_o[6]   = reg2hw.doorbell_c6.intr.q;
  assign irq_completion_o[6] = reg2hw.completion_interrupt_c6.intr.q;
  assign irq_doorbell_o[7]   = reg2hw.doorbell_c7.intr.q;
  assign irq_completion_o[7] = reg2hw.completion_interrupt_c7.intr.q;
  assign irq_doorbell_o[8]   = reg2hw.doorbell_c8.intr.q;
  assign irq_completion_o[8] = reg2hw.completion_interrupt_c8.intr.q;
  assign irq_doorbell_o[9]   = reg2hw.doorbell_c9.intr.q;
  assign irq_completion_o[9] = reg2hw.completion_interrupt_c9.intr.q;
  assign irq_doorbell_o[10]   = reg2hw.doorbell_c10.intr.q;
  assign irq_completion_o[10] = reg2hw.completion_interrupt_c10.intr.q;
  assign irq_doorbell_o[11]   = reg2hw.doorbell_c11.intr.q;
  assign irq_completion_o[11] = reg2hw.completion_interrupt_c11.intr.q;
  assign irq_doorbell_o[12]   = reg2hw.doorbell_c12.intr.q;
  assign irq_completion_o[12] = reg2hw.completion_interrupt_c12.intr.q;
  assign irq_doorbell_o[13]   = reg2hw.doorbell_c13.intr.q;
  assign irq_completion_o[13] = reg2hw.completion_interrupt_c13.intr.q;
  assign irq_doorbell_o[14]   = reg2hw.doorbell_c14.intr.q;
  assign irq_completion_o[14] = reg2hw.completion_interrupt_c14.intr.q;
  assign irq_doorbell_o[15]   = reg2hw.doorbell_c15.intr.q;
  assign irq_completion_o[15] = reg2hw.completion_interrupt_c15.intr.q;
  assign irq_doorbell_o[16]   = reg2hw.doorbell_c16.intr.q;
  assign irq_completion_o[16] = reg2hw.completion_interrupt_c16.intr.q;
  assign irq_doorbell_o[17]   = reg2hw.doorbell_c17.intr.q;
  assign irq_completion_o[17] = reg2hw.completion_interrupt_c17.intr.q;
  assign irq_doorbell_o[18]   = reg2hw.doorbell_c18.intr.q;
  assign irq_completion_o[18] = reg2hw.completion_interrupt_c18.intr.q;
  assign irq_doorbell_o[19]   = reg2hw.doorbell_c19.intr.q;
  assign irq_completion_o[19] = reg2hw.completion_interrupt_c19.intr.q;
  assign irq_doorbell_o[20]   = reg2hw.doorbell_c20.intr.q;
  assign irq_completion_o[20] = reg2hw.completion_interrupt_c20.intr.q;
  assign irq_doorbell_o[21]   = reg2hw.doorbell_c21.intr.q;
  assign irq_completion_o[21] = reg2hw.completion_interrupt_c21.intr.q;
  assign irq_doorbell_o[22]   = reg2hw.doorbell_c22.intr.q;
  assign irq_completion_o[22] = reg2hw.completion_interrupt_c22.intr.q;
  assign irq_doorbell_o[23]   = reg2hw.doorbell_c23.intr.q;
  assign irq_completion_o[23] = reg2hw.completion_interrupt_c23.intr.q;
  assign irq_doorbell_o[24]   = reg2hw.doorbell_c24.intr.q;
  assign irq_completion_o[24] = reg2hw.completion_interrupt_c24.intr.q;
  assign irq_doorbell_o[25]   = reg2hw.doorbell_c25.intr.q;
  assign irq_completion_o[25] = reg2hw.completion_interrupt_c25.intr.q;
  assign irq_doorbell_o[26]   = reg2hw.doorbell_c26.intr.q;
  assign irq_completion_o[26] = reg2hw.completion_interrupt_c26.intr.q;
  assign irq_doorbell_o[27]   = reg2hw.doorbell_c27.intr.q;
  assign irq_completion_o[27] = reg2hw.completion_interrupt_c27.intr.q;
  assign irq_doorbell_o[28]   = reg2hw.doorbell_c28.intr.q;
  assign irq_completion_o[28] = reg2hw.completion_interrupt_c28.intr.q;
  assign irq_doorbell_o[29]   = reg2hw.doorbell_c29.intr.q;
  assign irq_completion_o[29] = reg2hw.completion_interrupt_c29.intr.q;
  assign irq_doorbell_o[30]   = reg2hw.doorbell_c30.intr.q;
  assign irq_completion_o[30] = reg2hw.completion_interrupt_c30.intr.q;
  assign irq_doorbell_o[31]   = reg2hw.doorbell_c31.intr.q;
  assign irq_completion_o[31] = reg2hw.completion_interrupt_c31.intr.q;
  assign irq_doorbell_o[32]   = reg2hw.doorbell_c32.intr.q;
  assign irq_completion_o[32] = reg2hw.completion_interrupt_c32.intr.q;
  assign irq_doorbell_o[33]   = reg2hw.doorbell_c33.intr.q;
  assign irq_completion_o[33] = reg2hw.completion_interrupt_c33.intr.q;
  assign irq_doorbell_o[34]   = reg2hw.doorbell_c34.intr.q;
  assign irq_completion_o[34] = reg2hw.completion_interrupt_c34.intr.q;
  assign irq_doorbell_o[35]   = reg2hw.doorbell_c35.intr.q;
  assign irq_completion_o[35] = reg2hw.completion_interrupt_c35.intr.q;
  assign irq_doorbell_o[36]   = reg2hw.doorbell_c36.intr.q;
  assign irq_completion_o[36] = reg2hw.completion_interrupt_c36.intr.q;
  assign irq_doorbell_o[37]   = reg2hw.doorbell_c37.intr.q;
  assign irq_completion_o[37] = reg2hw.completion_interrupt_c37.intr.q;
  assign irq_doorbell_o[38]   = reg2hw.doorbell_c38.intr.q;
  assign irq_completion_o[38] = reg2hw.completion_interrupt_c38.intr.q;
  assign irq_doorbell_o[39]   = reg2hw.doorbell_c39.intr.q;
  assign irq_completion_o[39] = reg2hw.completion_interrupt_c39.intr.q;
  assign irq_doorbell_o[40]   = reg2hw.doorbell_c40.intr.q;
  assign irq_completion_o[40] = reg2hw.completion_interrupt_c40.intr.q;
  assign irq_doorbell_o[41]   = reg2hw.doorbell_c41.intr.q;
  assign irq_completion_o[41] = reg2hw.completion_interrupt_c41.intr.q;
  assign irq_doorbell_o[42]   = reg2hw.doorbell_c42.intr.q;
  assign irq_completion_o[42] = reg2hw.completion_interrupt_c42.intr.q;
  assign irq_doorbell_o[43]   = reg2hw.doorbell_c43.intr.q;
  assign irq_completion_o[43] = reg2hw.completion_interrupt_c43.intr.q;
  assign irq_doorbell_o[44]   = reg2hw.doorbell_c44.intr.q;
  assign irq_completion_o[44] = reg2hw.completion_interrupt_c44.intr.q;
  assign irq_doorbell_o[45]   = reg2hw.doorbell_c45.intr.q;
  assign irq_completion_o[45] = reg2hw.completion_interrupt_c45.intr.q;
  assign irq_doorbell_o[46]   = reg2hw.doorbell_c46.intr.q;
  assign irq_completion_o[46] = reg2hw.completion_interrupt_c46.intr.q;
  assign irq_doorbell_o[47]   = reg2hw.doorbell_c47.intr.q;
  assign irq_completion_o[47] = reg2hw.completion_interrupt_c47.intr.q;
  assign irq_doorbell_o[48]   = reg2hw.doorbell_c48.intr.q;
  assign irq_completion_o[48] = reg2hw.completion_interrupt_c48.intr.q;
  assign irq_doorbell_o[49]   = reg2hw.doorbell_c49.intr.q;
  assign irq_completion_o[49] = reg2hw.completion_interrupt_c49.intr.q;
  assign irq_doorbell_o[50]   = reg2hw.doorbell_c50.intr.q;
  assign irq_completion_o[50] = reg2hw.completion_interrupt_c50.intr.q;
  assign irq_doorbell_o[51]   = reg2hw.doorbell_c51.intr.q;
  assign irq_completion_o[51] = reg2hw.completion_interrupt_c51.intr.q;
  assign irq_doorbell_o[52]   = reg2hw.doorbell_c52.intr.q;
  assign irq_completion_o[52] = reg2hw.completion_interrupt_c52.intr.q;
  assign irq_doorbell_o[53]   = reg2hw.doorbell_c53.intr.q;
  assign irq_completion_o[53] = reg2hw.completion_interrupt_c53.intr.q;
  assign irq_doorbell_o[54]   = reg2hw.doorbell_c54.intr.q;
  assign irq_completion_o[54] = reg2hw.completion_interrupt_c54.intr.q;
  assign irq_doorbell_o[55]   = reg2hw.doorbell_c55.intr.q;
  assign irq_completion_o[55] = reg2hw.completion_interrupt_c55.intr.q;
  assign irq_doorbell_o[56]   = reg2hw.doorbell_c56.intr.q;
  assign irq_completion_o[56] = reg2hw.completion_interrupt_c56.intr.q;
  assign irq_doorbell_o[57]   = reg2hw.doorbell_c57.intr.q;
  assign irq_completion_o[57] = reg2hw.completion_interrupt_c57.intr.q;
  assign irq_doorbell_o[58]   = reg2hw.doorbell_c58.intr.q;
  assign irq_completion_o[58] = reg2hw.completion_interrupt_c58.intr.q;
  assign irq_doorbell_o[59]   = reg2hw.doorbell_c59.intr.q;
  assign irq_completion_o[59] = reg2hw.completion_interrupt_c59.intr.q;
  assign irq_doorbell_o[60]   = reg2hw.doorbell_c60.intr.q;
  assign irq_completion_o[60] = reg2hw.completion_interrupt_c60.intr.q;
  assign irq_doorbell_o[61]   = reg2hw.doorbell_c61.intr.q;
  assign irq_completion_o[61] = reg2hw.completion_interrupt_c61.intr.q;
  assign irq_doorbell_o[62]   = reg2hw.doorbell_c62.intr.q;
  assign irq_completion_o[62] = reg2hw.completion_interrupt_c62.intr.q;
  assign irq_doorbell_o[63]   = reg2hw.doorbell_c63.intr.q;
  assign irq_completion_o[63] = reg2hw.completion_interrupt_c63.intr.q;

  scmi_reg_top #(
     .reg_req_t(reg_req_t),
     .reg_rsp_t(reg_rsp_t)
   ) u_shared_memory (
     .clk_i,
     .rst_ni,
     .reg2hw,
     .reg_req_i(reg_req),
     .reg_rsp_o(reg_rsp),
     .devmode_i(1'b1)
   );

   axi_dw_converter #(
    .AxiMaxReads        ( AxiMaxReads             ),
    .AxiSlvPortDataWidth( AxiSlvPortDataWidth     ),
    .AxiMstPortDataWidth( AxiMstPortDataWidth     ),
    .AxiAddrWidth       ( AxiAddrWidth            ),
    .AxiIdWidth         ( AxiIdWidth              ),
    .aw_chan_t          ( aw_chan_t               ),
    .mst_w_chan_t       ( mst_w_chan_t            ),
    .slv_w_chan_t       ( slv_w_chan_t            ),
    .b_chan_t           ( b_chan_t                ),
    .ar_chan_t          ( ar_chan_t               ),
    .mst_r_chan_t       ( mst_r_chan_t            ),
    .slv_r_chan_t       ( slv_r_chan_t            ),
    .axi_mst_req_t      ( mst_req_t               ),
    .axi_mst_resp_t     ( mst_resp_t              ),
    .axi_slv_req_t      ( slv_req_t               ),
    .axi_slv_resp_t     ( slv_resp_t              )
   ) i_axi_dw_converter_scmi (
    .clk_i      ( clk_i    ),
    .rst_ni     ( rst_ni   ),
    // slave port
    .slv_req_i  ( axi_mbox_req  ),
    .slv_resp_o ( axi_mbox_rsp  ),
    // master port
    .mst_req_o  ( axi32_mbox_req  ),
    .mst_resp_i ( axi32_mbox_rsp  )
  );

   axi_to_reg #(
     .ADDR_WIDTH(AxiAddrWidth),
     .DATA_WIDTH(AxiMstPortDataWidth),
     .ID_WIDTH(AxiIdWidth),
     .USER_WIDTH(AxiUserWidth),
     .AXI_MAX_WRITE_TXNS(1),
     .AXI_MAX_READ_TXNS(1),
     .DECOUPLE_W(0),
     .axi_req_t(mst_req_t),
     .axi_rsp_t(mst_resp_t),
     .reg_req_t(reg_req_t),
     .reg_rsp_t(reg_rsp_t)
   ) u_axi2reg_intf (
     .clk_i,
     .rst_ni,
     .testmode_i(testmode_i),
     .axi_req_i(axi32_mbox_req),
     .axi_rsp_o(axi32_mbox_rsp),
     .reg_req_o(reg_req),
     .reg_rsp_i(reg_rsp)
   );

endmodule // axi_scmi_mailbox


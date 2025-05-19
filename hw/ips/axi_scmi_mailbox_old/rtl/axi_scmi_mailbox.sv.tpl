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

% for i in range(src):
  assign irq_doorbell_o[${i}]   = reg2hw.doorbell_c${i}.intr.q;
  assign irq_completion_o[${i}] = reg2hw.completion_interrupt_c${i}.intr.q;
% endfor

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
     .testmode_i(1'b0),
     .axi_req_i(axi32_mbox_req),
     .axi_rsp_o(axi32_mbox_rsp),
     .reg_req_o(reg_req),
     .reg_rsp_i(reg_rsp)
   );

endmodule // axi_scmi_mailbox

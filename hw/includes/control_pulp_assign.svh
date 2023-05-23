// Copyright (c) 2014-2022 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`ifndef CONTROL_PULP_ASSIGN_SVH_
`define CONTROL_PULP_ASSIGN_SVH_


// Define helper macros for exploding/wrapping and assigning to/from AXI structs

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


`define AXI_WRAP_SLAVE_STRUCT(req_str, resp_str, pat)  \
   assign req_str.aw.id          = awid_``pat``_i;     \
   assign req_str.aw.addr        = awaddr_``pat``_i;   \
   assign req_str.aw.len         = awlen_``pat``_i;    \
   assign req_str.aw.size        = awsize_``pat``_i;   \
   assign req_str.aw.burst       = awburst_``pat``_i;  \
   assign req_str.aw.lock        = awlock_``pat``_i;   \
   assign req_str.aw.cache       = awcache_``pat``_i;  \
   assign req_str.aw.prot        = awprot_``pat``_i;   \
   assign req_str.aw.qos         = awqos_``pat``_i;    \
   assign req_str.aw.region      = awregion_``pat``_i; \
   assign req_str.aw.atop        = aw_atop_``pat``_i;  \
   assign req_str.aw.user        = awuser_``pat``_i;   \
   assign req_str.aw_valid       = awvalid_``pat``_i;  \
   assign awready_``pat``_o      = resp_str.aw_ready;  \
                                                       \
   assign req_str.w.data         = wdata_``pat``_i;    \
   assign req_str.w.strb         = wstrb_``pat``_i;    \
   assign req_str.w.last         = wlast_``pat``_i;    \
   assign req_str.w.user         = wuser_``pat``_i;    \
   assign req_str.w_valid        = wvalid_``pat``_i;   \
   assign wready_``pat``_o       = resp_str.w_ready;   \
                                                       \
   assign bid_``pat``_o          = resp_str.b.id;      \
   assign bresp_``pat``_o        = resp_str.b.resp;    \
   assign buser_``pat``_o        = resp_str.b.user;    \
   assign bvalid_``pat``_o       = resp_str.b_valid;   \
   assign req_str.b_ready        = bready_``pat``_i;   \
                                                       \
   assign req_str.ar.id          = arid_``pat``_i;     \
   assign req_str.ar.addr        = araddr_``pat``_i;   \
   assign req_str.ar.len         = arlen_``pat``_i;    \
   assign req_str.ar.size        = arsize_``pat``_i;   \
   assign req_str.ar.burst       = arburst_``pat``_i;  \
   assign req_str.ar.lock        = arlock_``pat``_i;   \
   assign req_str.ar.cache       = arcache_``pat``_i;  \
   assign req_str.ar.prot        = arprot_``pat``_i;   \
   assign req_str.ar.qos         = arqos_``pat``_i;    \
   assign req_str.ar.region      = arregion_``pat``_i; \
   assign req_str.ar.user        = aruser_``pat``_i;   \
   assign req_str.ar_valid       = arvalid_``pat``_i;  \
   assign arready_``pat``_o      = resp_str.ar_ready; \
                                                       \
   assign rid_``pat``_o          = resp_str.r.id;      \
   assign rdata_``pat``_o        = resp_str.r.data;    \
   assign rresp_``pat``_o        = resp_str.r.resp;    \
   assign rlast_``pat``_o        = resp_str.r.last;    \
   assign ruser_``pat``_o        = resp_str.r.user;    \
   assign rvalid_``pat``_o       = resp_str.r_valid;   \
   assign req_str.r_ready        = rready_``pat``_i;


 `define AXI_EXPLODE_MASTER_STRUCT(req_str, resp_str, pat) \
   assign awid_``pat``_o      = req_str.aw.id;         \
   assign awaddr_``pat``_o    = req_str.aw.addr;       \
   assign awlen_``pat``_o     = req_str.aw.len;        \
   assign awsize_``pat``_o    = req_str.aw.size;       \
   assign awburst_``pat``_o   = req_str.aw.burst;      \
   assign awlock_``pat``_o    = req_str.aw.lock;       \
   assign awcache_``pat``_o   = req_str.aw.cache;      \
   assign awprot_``pat``_o    = req_str.aw.prot;       \
   assign awqos_``pat``_o     = req_str.aw.qos;        \
   assign awregion_``pat``_o  = req_str.aw.region;     \
   assign aw_atop_``pat``_o   = req_str.aw.atop;       \
   assign awuser_``pat``_o    = req_str.aw.user;       \
   assign awvalid_``pat``_o   = req_str.aw_valid;      \
   assign resp_str.aw_ready   = awready_``pat``_i;     \
                                                       \
   assign wdata_``pat``_o     = req_str.w.data;        \
   assign wstrb_``pat``_o     = req_str.w.strb;        \
   assign wlast_``pat``_o     = req_str.w.last;        \
   assign wuser_``pat``_o     = req_str.w.user;        \
   assign wvalid_``pat``_o    = req_str.w_valid;       \
   assign resp_str.w_ready    = wready_``pat``_i;      \
                                                       \
   assign resp_str.b.id       = bid_``pat``_i;         \
   assign resp_str.b.resp     = bresp_``pat``_i;       \
   assign resp_str.b.user     = buser_``pat``_i;       \
   assign resp_str.b_valid    = bvalid_``pat``_i;      \
   assign bready_``pat``_o    = req_str.b_ready;       \
                                                       \
   assign arid_``pat``_o      = req_str.ar.id;         \
   assign araddr_``pat``_o    = req_str.ar.addr;       \
   assign arlen_``pat``_o     = req_str.ar.len;        \
   assign arsize_``pat``_o    = req_str.ar.size;       \
   assign arburst_``pat``_o   = req_str.ar.burst;      \
   assign arlock_``pat``_o    = req_str.ar.lock;       \
   assign arcache_``pat``_o   = req_str.ar.cache;      \
   assign arprot_``pat``_o    = req_str.ar.prot;       \
   assign arqos_``pat``_o     = req_str.ar.qos;        \
   assign arregion_``pat``_o  = req_str.ar.region;     \
   assign aruser_``pat``_o    = req_str.ar.user;       \
   assign arvalid_``pat``_o   = req_str.ar_valid;      \
   assign resp_str.ar_ready   = arready_``pat``_i;     \
                                                       \
   assign resp_str.r.id       = rid_``pat``_i;         \
   assign resp_str.r.data     = rdata_``pat``_i;       \
   assign resp_str.r.resp     = rresp_``pat``_i;       \
   assign resp_str.r.last     = rlast_``pat``_i;       \
   assign resp_str.r.user     = ruser_``pat``_i;       \
   assign resp_str.r_valid    = rvalid_``pat``_i;      \
   assign rready_``pat``_o    = req_str.r_ready;


// Define helper macros to wrap peripherals exploded ports into arrays

//I2C
`define I2C_WRAP_STRUCT(expl_name, vect_name, index)                             \
  assign in_``expl_name``_scl_i             = s_in_``vect_name``_scl[index];     \
  assign s_out_``vect_name``_scl[index]     = out_``expl_name``_scl_o;           \
  assign s_oe_``vect_name``_scl[index]      = oe_``expl_name``_scl_o;            \
  assign in_``expl_name``_sda_i             = s_in_``vect_name``_sda[index];     \
  assign s_out_``vect_name``_sda[index]     = out_``expl_name``_sda_o;           \
  assign s_oe_``vect_name``_sda[index]      = oe_``expl_name``_sda_o;

//SPI
`define SPI_WRAP_STRUCT1(expl_name, vect_name, index)                            \
  assign in_``expl_name``_sck_i             = s_in_``vect_name``_sck[index];     \
  assign s_out_``vect_name``_sck[index]     = out_``expl_name``_sck_o;           \
  assign s_oe_``vect_name``_sck[index]      = oe_``expl_name``_sck_o;            \
  assign in_``expl_name``_csn_i             = s_in_``vect_name``_csn[index][0];  \
  assign s_out_``vect_name``_csn[index][0]  = out_``expl_name``_csn_o;           \
  assign s_oe_``vect_name``_csn[index][0]   = oe_``expl_name``_csn_o;            \
  assign s_out_``vect_name``_csn[index][1]  = 1'b1;                              \
  assign s_oe_``vect_name``_csn[index][1]   = 1'b0;                              \
  assign s_out_``vect_name``_csn[index][2]  = 1'b1;                              \
  assign s_oe_``vect_name``_csn[index][2]   = 1'b0;                              \
  assign s_out_``vect_name``_csn[index][3]  = 1'b1;                              \
  assign s_oe_``vect_name``_csn[index][3]   = 1'b0;                              \
  assign in_``expl_name``_si_i              = s_in_``vect_name``_sdio[index][0]; \
  assign s_out_``vect_name``_sdio[index][0] = out_``expl_name``_si_o;            \
  assign s_oe_``vect_name``_sdio[index][0]  = oe_``expl_name``_si_o;             \
  assign in_``expl_name``_so_i              = s_in_``vect_name``_sdio[index][1]; \
  assign s_out_``vect_name``_sdio[index][1] = out_``expl_name``_so_o;            \
  assign s_oe_``vect_name``_sdio[index][1]  = oe_``expl_name``_so_o;             \
  assign s_out_``vect_name``_sdio[index][2] = 1'b0;                              \
  assign s_oe_``vect_name``_sdio[index][2]  = 1'b0;                              \
  assign s_out_``vect_name``_sdio[index][3] = 1'b0;                              \
  assign s_oe_``vect_name``_sdio[index][3]  = 1'b0;

`define SPI_WRAP_STRUCT2(expl_name, vect_name, index)                            \
  assign in_``expl_name``_sck_i             = s_in_``vect_name``_sck[index];     \
  assign s_out_``vect_name``_sck[index]     = out_``expl_name``_sck_o;           \
  assign s_oe_``vect_name``_sck[index]      = oe_``expl_name``_sck_o;            \
  assign in_``expl_name``_csn0_i            = s_in_``vect_name``_csn[index][0];  \
  assign s_out_``vect_name``_csn[index][0]  = out_``expl_name``_csn0_o;          \
  assign s_oe_``vect_name``_csn[index][0]   = oe_``expl_name``_csn0_o;           \
  assign in_``expl_name``_csn1_i            = s_in_``vect_name``_csn[index][1];  \
  assign s_out_``vect_name``_csn[index][1]  = out_``expl_name``_csn1_o;          \
  assign s_oe_``vect_name``_csn[index][1]   = oe_``expl_name``_csn1_o;           \
  assign s_out_``vect_name``_csn[index][2]  = 1'b1;                              \
  assign s_oe_``vect_name``_csn[index][2]   = 1'b0;                              \
  assign s_out_``vect_name``_csn[index][3]  = 1'b1;                              \
  assign s_oe_``vect_name``_csn[index][3]   = 1'b0;                              \
  assign in_``expl_name``_si_i              = s_in_``vect_name``_sdio[index][0]; \
  assign s_out_``vect_name``_sdio[index][0] = out_``expl_name``_si_o;            \
  assign s_oe_``vect_name``_sdio[index][0]  = oe_``expl_name``_si_o;             \
  assign in_``expl_name``_so_i              = s_in_``vect_name``_sdio[index][1]; \
  assign s_out_``vect_name``_sdio[index][1] = out_``expl_name``_so_o;            \
  assign s_oe_``vect_name``_sdio[index][1]  = oe_``expl_name``_so_o;             \
  assign s_out_``vect_name``_sdio[index][2] = 1'b0;                              \
  assign s_oe_``vect_name``_sdio[index][2]  = 1'b0;                              \
  assign s_out_``vect_name``_sdio[index][3] = 1'b0;                              \
  assign s_oe_``vect_name``_sdio[index][3]  = 1'b0;

`define QSPI_WRAP_STRUCT(expl_name, vect_name, index)                            \
  assign in_``expl_name``_sck_i             = s_in_``vect_name``_sck[index];     \
  assign s_out_``vect_name``_sck[index]     = out_``expl_name``_sck_o;           \
  assign s_oe_``vect_name``_sck[index]      = oe_``expl_name``_sck_o;            \
  assign in_``expl_name``_csn0_i            = s_in_``vect_name``_csn[index][0];  \
  assign s_out_``vect_name``_csn[index][0]  = out_``expl_name``_csn0_o;          \
  assign s_oe_``vect_name``_csn[index][0]   = oe_``expl_name``_csn0_o;           \
  assign in_``expl_name``_csn1_i            = s_in_``vect_name``_csn[index][1];  \
  assign s_out_``vect_name``_csn[index][1]  = out_``expl_name``_csn1_o;          \
  assign s_oe_``vect_name``_csn[index][1]   = oe_``expl_name``_csn1_o;           \
  assign in_``expl_name``_sdio_i            = s_in_``vect_name``_sdio[index];    \
  assign s_out_``vect_name``_sdio[index]    = out_``expl_name``_sdio_o;          \
  assign s_oe_``vect_name``_sdio[index]     = oe_``expl_name``_sdio_o;


// Define helper macros for exploding and assigning to peripherals ports

  //I2C
`define I2C_EXPLODE_STRUCT(expl_name, vect_name, index)                      \
  assign in_``vect_name``_scl_i[index]   = in_``expl_name``_scl_i      ;     \
  assign out_``expl_name``_scl_o         = out_``vect_name``_scl_o[index];   \
  assign oe_``expl_name``_scl_o          = oe_``vect_name``_scl_o[index];    \
  assign in_``vect_name``_sda_i[index]   = in_``expl_name``_sda_i      ;     \
  assign out_``expl_name``_sda_o         = out_``vect_name``_sda_o[index];   \
  assign oe_``expl_name``_sda_o          = oe_``vect_name``_sda_o[index];    \
  assign in_``vect_name``_alert_i[index] = in_``expl_name``_alert_i      ;   \
  assign out_``expl_name``_alert_o       = out_``vect_name``_alert_o[index]; \
  assign oe_``expl_name``_alert_o        = oe_``vect_name``_alert_o[index];

  //SPI
`define SPI_EXPLODE_STRUCT1(expl_name, vect_name, index)                         \
  assign in_``vect_name``_sck_i[index]     = in_``expl_name``_sck_i;             \
  assign out_``expl_name``_sck_o           = out_``vect_name``_sck_o[index];     \
  assign oe_``expl_name``_sck_o            = oe_``vect_name``_sck_o[index];      \
  assign in_``vect_name``_csn_i[index][0]  = in_``expl_name``_csn_i;             \
  assign out_``expl_name``_csn_o           = out_``vect_name``_csn_o[index][0];  \
  assign oe_``expl_name``_csn_o            = oe_``vect_name``_csn_o[index][0];   \
  assign in_``vect_name``_sdio_i[index][0] = in_``expl_name``_si_i;              \
  assign out_``expl_name``_si_o            = out_``vect_name``_sdio_o[index][0]; \
  assign oe_``expl_name``_si_o             = oe_``vect_name``_sdio_o[index][0];  \
  assign in_``vect_name``_sdio_i[index][1] = in_``expl_name``_so_i;              \
  assign out_``expl_name``_so_o            = out_``vect_name``_sdio_o[index][1]; \
  assign oe_``expl_name``_so_o             = oe_``vect_name``_sdio_o[index][1];  \
  assign in_``vect_name``_csn_i[index][1]  = 1'b1;                               \
  assign in_``vect_name``_csn_i[index][2]  = 1'b1;                               \
  assign in_``vect_name``_csn_i[index][3]  = 1'b1;                               \
  assign in_``vect_name``_sdio_i[index][2] = 1'b0;                               \
  assign in_``vect_name``_sdio_i[index][3] = 1'b0;

`define SPI_EXPLODE_STRUCT2(expl_name, vect_name, index)                         \
  assign in_``vect_name``_sck_i[index]     = in_``expl_name``_sck_i;             \
  assign out_``expl_name``_sck_o           = out_``vect_name``_sck_o[index];     \
  assign oe_``expl_name``_sck_o            = oe_``vect_name``_sck_o[index];      \
  assign in_``vect_name``_csn_i[index][0]  = in_``expl_name``_csn0_i;            \
  assign out_``expl_name``_csn0_o          = out_``vect_name``_csn_o[index][0];  \
  assign oe_``expl_name``_csn0_o           = oe_``vect_name``_csn_o[index][0];   \
  assign in_``vect_name``_csn_i[index][1]  = in_``expl_name``_csn1_i;            \
  assign out_``expl_name``_csn1_o          = out_``vect_name``_csn_o[index][1];  \
  assign oe_``expl_name``_csn1_o           = oe_``vect_name``_csn_o[index][1];   \
  assign in_``vect_name``_sdio_i[index][0] = in_``expl_name``_si_i;              \
  assign out_``expl_name``_si_o            = out_``vect_name``_sdio_o[index][0]; \
  assign oe_``expl_name``_si_o             = oe_``vect_name``_sdio_o[index][0];  \
  assign in_``vect_name``_sdio_i[index][1] = in_``expl_name``_so_i;              \
  assign out_``expl_name``_so_o            = out_``vect_name``_sdio_o[index][1]; \
  assign oe_``expl_name``_so_o             = oe_``vect_name``_sdio_o[index][1];  \
  assign in_``vect_name``_csn_i[index][2]  = 1'b1;                               \
  assign in_``vect_name``_csn_i[index][3]  = 1'b1;                               \
  assign in_``vect_name``_sdio_i[index][2] = 1'b0;                               \
  assign in_``vect_name``_sdio_i[index][3] = 1'b0;

`define SPI_EXPLODE_ALERT(expl_name, vect_name)                 \
  assign in_``vect_name``_alert_i  = in_``expl_name``_alert_i;  \
  assign out_``expl_name``_alert_o = out_``vect_name``_alert_o; \
  assign oe_``expl_name``_alert_o  = oe_``vect_name``_alert_o;

`define QSPI_EXPLODE_STRUCT(expl_name, vect_name, index)                       \
  assign in_``vect_name``_sck_i[index]    = in_``expl_name``_sck_i;            \
  assign out_``expl_name``_sck_o          = out_``vect_name``_sck_o[index];    \
  assign oe_``expl_name``_sck_o           = oe_``vect_name``_sck_o[index];     \
  assign in_``vect_name``_csn_i[index][0] = in_``expl_name``_csn0_i;           \
  assign out_``expl_name``_csn0_o         = out_``vect_name``_csn_o[index][0]; \
  assign oe_``expl_name``_csn0_o          = oe_``vect_name``_csn_o[index][0];  \
  assign in_``vect_name``_csn_i[index][1] = in_``expl_name``_csn1_i;           \
  assign out_``expl_name``_csn1_o         = out_``vect_name``_csn_o[index][1]; \
  assign oe_``expl_name``_csn1_o          = oe_``vect_name``_csn_o[index][1];  \
  assign in_``vect_name``_sdio_i[index]   = in_``expl_name``_sdio_i;           \
  assign out_``expl_name``_sdio_o         = out_``vect_name``_sdio_o[index];   \
  assign oe_``expl_name``_sdio_o          = oe_``vect_name``_sdio_o[index];    \
  assign in_``vect_name``_csn_i[index][2] = 1'b1;                              \
  assign in_``vect_name``_csn_i[index][3] = 1'b1;


  // FPGA

  //I2C
`define I2C_EXPLODE_STRUCT_FPGA(expl_name, vect_name, index)                     \
  assign s_in_``vect_name``_scl[index]     = s_in_``expl_name``_scl      ;       \
  assign s_out_``expl_name``_scl           = s_out_``vect_name``_scl[index];     \
  assign s_oe_``expl_name``_scl            = s_oe_``vect_name``_scl[index];      \
  assign s_in_``vect_name``_sda[index]     = s_in_``expl_name``_sda      ;       \
  assign s_out_``expl_name``_sda           = s_out_``vect_name``_sda[index];     \
  assign s_oe_``expl_name``_sda            = s_oe_``vect_name``_sda[index];      \
  assign s_in_``vect_name``_alert[index]   = s_in_``expl_name``_alert      ;     \
  assign s_out_``expl_name``_alert         = s_out_``vect_name``_alert[index];   \
  assign s_oe_``expl_name``_alert          = s_oe_``vect_name``_alert[index];

  //SPI
`define SPI_EXPLODE_STRUCT_FPGA(expl_name, vect_name, index)                          \
  assign s_in_``vect_name``_sck[index]     = s_in_``expl_name``_sck ;            \
  assign s_out_``expl_name``_sck           = s_out_``vect_name``_sck[index];     \
  assign s_oe_``expl_name``_sck            = s_oe_``vect_name``_sck[index];      \
  assign s_in_``vect_name``_csn[index][0]  = s_in_``expl_name``_csn ;            \
  assign s_out_``expl_name``_csn           = s_out_``vect_name``_csn[index][0];  \
  assign s_oe_``expl_name``_csn            = s_oe_``vect_name``_csn[index][0];   \
  assign s_in_``vect_name``_sdio[index][0] = s_in_``expl_name``_si ;             \
  assign s_out_``expl_name``_si            = s_out_``vect_name``_sdio[index][0]; \
  assign s_oe_``expl_name``_si             = s_oe_``vect_name``_sdio[index][0];  \
  assign s_in_``vect_name``_sdio[index][1] = s_in_``expl_name``_so ;             \
  assign s_out_``expl_name``_so            = s_out_``vect_name``_sdio[index][1]; \
  assign s_oe_``expl_name``_so             = s_oe_``vect_name``_sdio[index][1];  \
  assign s_in_``vect_name``_csn[index][1]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][2]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][3]  = 1'b1;                               \
  assign s_in_``vect_name``_sdio[index][2] = 1'b0;                               \
  assign s_in_``vect_name``_sdio[index][3] = 1'b0;

`define AVS_EXPLODE_STRUCT_FPGA(expl_name, vect_name, index)                          \
  assign s_in_``vect_name``_sck[index]     = s_in_``expl_name``_sck ;            \
  assign s_out_``expl_name``_sck           = s_out_``vect_name``_sck[index];     \
  assign s_oe_``expl_name``_sck            = s_oe_``vect_name``_sck[index];      \
  assign s_in_``vect_name``_sdio[index][0] = s_in_``expl_name``_si ;             \
  assign s_out_``expl_name``_si            = s_out_``vect_name``_sdio[index][0]; \
  assign s_oe_``expl_name``_si             = s_oe_``vect_name``_sdio[index][0];  \
  assign s_in_``vect_name``_sdio[index][1] = s_in_``expl_name``_so ;             \
  assign s_out_``expl_name``_so            = s_out_``vect_name``_sdio[index][1]; \
  assign s_oe_``expl_name``_so             = s_oe_``vect_name``_sdio[index][1];  \
  assign s_in_``vect_name``_csn[index][0]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][1]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][2]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][3]  = 1'b1;                               \
  assign s_in_``vect_name``_sdio[index][2] = 1'b0;                               \
  assign s_in_``vect_name``_sdio[index][3] = 1'b0;

`define SPI_EXPLODE_ALERT_FPGA(expl_name, vect_name)                             \
  assign in_``vect_name``_alert_i          = s_in_``expl_name``_alert ;          \
  assign s_out_``expl_name``_alert         = out_``vect_name``_alert_o;          \
  assign s_oe_``expl_name``_alert          = oe_``vect_name``_alert_o;           \

`define QSPI_EXPLODE_STRUCT_FPGA(expl_name, vect_name, index)                    \
  assign s_in_``vect_name``_sck[index]     = s_in_``expl_name``_sck ;            \
  assign s_out_``expl_name``_sck           = s_out_``vect_name``_sck[index];     \
  assign s_oe_``expl_name``_sck            = s_oe_``vect_name``_sck[index];      \
  assign s_in_``vect_name``_csn[index][0]  = s_in_``expl_name``_csn0 ;           \
  assign s_out_``expl_name``_csn0          = s_out_``vect_name``_csn[index][0];  \
  assign s_oe_``expl_name``_csn0           = s_oe_``vect_name``_csn[index][0];   \
  assign s_in_``vect_name``_sdio[index]    = s_in_``expl_name``_sdio ;           \
  assign s_out_``expl_name``_sdio          = s_out_``vect_name``_sdio[index];    \
  assign s_oe_``expl_name``_sdio           = s_oe_``vect_name``_sdio[index];     \
  assign s_in_``vect_name``_csn[index][1]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][2]  = 1'b1;                               \
  assign s_in_``vect_name``_csn[index][3]  = 1'b1;

`endif

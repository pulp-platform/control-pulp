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


package control_pulp_pkg;
  // AXI parameters
  // from/to nci_cp_top, internal to PMS
  parameter int unsigned AXI_ID_INP_WIDTH_PMS = 7;
  parameter int unsigned AXI_ID_OUP_WIDTH_PMS = 6;
  parameter int unsigned AXI_USER_WIDTH_PMS = 6;
  parameter int unsigned AXI_DATA_INP_WIDTH_PMS = 64;
  parameter int unsigned AXI_STRB_INP_WIDTH_PMS = AXI_DATA_INP_WIDTH_PMS/8;
  parameter int unsigned AXI_DATA_OUP_WIDTH_PMS = 64;
  parameter int unsigned AXI_STRB_OUP_WIDTH_PMS = AXI_DATA_OUP_WIDTH_PMS/8;
  parameter int unsigned AXI_ADDR_WIDTH_PMS = 32;

  // Define AXI types shortcuts
  // from/to nci_cp_top, internal to PMS
  typedef logic [AXI_ID_INP_WIDTH_PMS-1:0]     axi_id_inp_ext_t;
  typedef logic [AXI_ID_OUP_WIDTH_PMS-1:0]     axi_id_oup_ext_t;
  typedef logic [AXI_USER_WIDTH_PMS-1:0]       axi_user_ext_t;
  typedef logic [AXI_DATA_INP_WIDTH_PMS-1:0]   axi_data_inp_ext_t;
  typedef logic [AXI_STRB_INP_WIDTH_PMS-1:0]   axi_strb_inp_ext_t;
  typedef logic [AXI_DATA_OUP_WIDTH_PMS-1:0]   axi_data_oup_ext_t;
  typedef logic [AXI_STRB_OUP_WIDTH_PMS-1:0]   axi_strb_oup_ext_t;
  typedef logic [AXI_ADDR_WIDTH_PMS-1:0]       axi_addr_ext_t;

endpackage // control_pulp_pkg

// Copyright 2022 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Robert Balas (balasr@iis.ee.ethz.ch)


package pms_top_pkg;
  parameter int unsigned N_I2C = 12;
  parameter int unsigned N_I2C_SLV = 2; //num i2c slave
  parameter int unsigned N_SPI = 8;
  parameter int unsigned N_UART = 1;

  parameter int unsigned N_L2_BANKS = 4;     // num interleaved banks
  parameter int unsigned N_L2_BANKS_PRI = 2; // num private banks

  parameter int unsigned L2_BANK_SIZE = 28672; // size of single L2 interleaved bank in 32-bit words

  // L2_BANK_SIZE_PRI indicates the size of a single private bank in 32-bit words.
  // It is set as a localparam in `ips/pulp_soc/rtl/pulp_soc/l2_ram_multi_bank.sv`
  // and should not be changed. It is listed in this package for reference.
  parameter int unsigned L2_BANK_SIZE_PRI = 8192; // size of single L2 private bank in 32-bit words

  parameter int unsigned ROM_SIZE = 2048; // size of bootrom

  parameter int unsigned N_L1_BANKS = 16; // num of banks in cluster
  parameter int unsigned L1_BANK_SIZE = 1024; // size of single L1 bank in 32-bit words

  parameter int unsigned PULP_XPULP = 1; // Enable PULP custom extensions in the CV32E40P core

  parameter int unsigned CLUST_NB_FPU = 8; // Number of FPUs in the cluster. Default to 8 private per-core FPUs
  parameter int unsigned CLUST_NB_EXT_DIVSQRT = 1; // Number of external DIVSQRT units in the cluster. Default to 1.

  parameter int unsigned NUM_EXT_INTERRUPTS = 222; // Number of external interrupts to the pms. An interrupt is considered
                                                   // external if the interrupt source is outside the pms, which routes the
                                                   // generated line(s) only. It equals NUM_INTERRUPTS-32-2, where NUM_INTERRUPTS
                                                   // defaults to 256. 32 are the default internal CLINT interrupts, while 2
                                                   // are the manager domain's DMA interrupts.

  import control_pulp_pkg::*;

  // Export AXI parameters from control_pulp
  export control_pulp_pkg::AXI_ID_INP_WIDTH_PMS;
  export control_pulp_pkg::AXI_ID_OUP_WIDTH_PMS;
  export control_pulp_pkg::AXI_USER_WIDTH_PMS;
  export control_pulp_pkg::AXI_DATA_INP_WIDTH_PMS;
  export control_pulp_pkg::AXI_STRB_INP_WIDTH_PMS;
  export control_pulp_pkg::AXI_DATA_OUP_WIDTH_PMS;
  export control_pulp_pkg::AXI_STRB_OUP_WIDTH_PMS;
  export control_pulp_pkg::AXI_ADDR_WIDTH_PMS;

  // export typdefs from control_pulp
  export control_pulp_pkg::axi_id_inp_ext_t;
  export control_pulp_pkg::axi_id_oup_ext_t;
  export control_pulp_pkg::axi_user_ext_t;
  export control_pulp_pkg::axi_data_inp_ext_t;
  export control_pulp_pkg::axi_strb_inp_ext_t;
  export control_pulp_pkg::axi_data_oup_ext_t;
  export control_pulp_pkg::axi_strb_oup_ext_t;
  export control_pulp_pkg::axi_addr_ext_t;

endpackage // pms_top_pkg

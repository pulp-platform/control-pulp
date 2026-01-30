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


`include "pulp_soc_defines.sv"
`include "soc_bus_defines.sv"
`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "register_interface/typedef.svh"
`include "register_interface/assign.svh"

module control_pulp import control_pulp_pkg::*; #(

  parameter int unsigned CORE_TYPE = 0, // 0 for RISCY, 1 for IBEX RV32IMC (formerly ZERORISCY), 2 for IBEX RV32EC (formerly MICRORISCY)
  parameter int unsigned USE_FPU = 1,
  parameter int unsigned USE_HWPE = 0,
  parameter int unsigned USE_CLUSTER_HWPE = 0,
  parameter int unsigned PULP_XPULP = 1,
  parameter int unsigned SIM_STDOUT = 1,
  parameter int unsigned BEHAV_MEM = 1,
  parameter int unsigned FPGA_MEM = 0,
  parameter int unsigned MACRO_ROM = 0,
  parameter int unsigned USE_CLUSTER = 1,
  parameter int unsigned DMA_TYPE = 1, // 1 for idma (new), 0 for mchan
                                       // (legacy). Default 1 for idma

  parameter int unsigned SDMA_RT_MIDEND = 0, // only valid when using idma (DMA_TYPE=1)

  parameter int unsigned N_L2_BANKS = 4,          // num interleaved banks
  parameter int unsigned N_L2_BANKS_PRI = 2,      // num private banks
  parameter int unsigned L2_BANK_SIZE = 28672,    // size of single L2 interleaved bank in 32-bit words
  parameter int unsigned L2_BANK_SIZE_PRI = 8192, // size of single L2 private bank in 32-bit words
  parameter int unsigned N_L1_BANKS = 16,         // num of banks in cluster
  parameter int unsigned L1_BANK_SIZE = 1024,     // size of single L1 bank in 32-bit words

  parameter int unsigned CLUST_NB_FPU = 8,
  parameter int unsigned CLUST_NB_EXT_DIVSQRT = 1,

  parameter int unsigned N_SOC_PERF_COUNTERS = 1,
  parameter int unsigned N_CLUST_PERF_COUNTERS = 1,
  parameter int unsigned N_I2C = 12,
  parameter int unsigned N_I2C_SLV = 2,
  parameter int unsigned N_SPI = 8,
  parameter int unsigned N_UART = 1,

  parameter int unsigned USE_D2D = 0,
  parameter int unsigned USE_D2D_DELAY_LINE = 0,
  parameter int unsigned D2D_NUM_CHANNELS = 0,
  parameter int unsigned D2D_NUM_LANES = 0,
  parameter int unsigned D2D_NUM_CREDITS = 0,

  // axi req and resp types

  // nci_cp_top Master
  parameter              type axi_req_inp_ext_t = logic,
  parameter              type axi_resp_inp_ext_t = logic,
  // nci_cp_top Slave
  parameter              type axi_req_oup_ext_t = logic,
  parameter              type axi_resp_oup_ext_t = logic,

  localparam int unsigned NGPIO = 32,
  localparam int unsigned NBIT_PADCFG = 4
) (

  // External ports. If USE_D2D is asserted, the D2D interface is used

  // AXI ports
  input                                    axi_req_inp_ext_t from_ext_req_i,
  output                                   axi_resp_inp_ext_t from_ext_resp_o,
  output                                   axi_req_oup_ext_t to_ext_req_o,
  input                                    axi_resp_oup_ext_t to_ext_resp_i,

  // D2D interface
  input logic  [D2D_NUM_CHANNELS-1:0]                    d2d_clk_i,
  input logic  [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_i,
  output logic [D2D_NUM_CHANNELS-1:0]                    d2d_clk_o,
  output logic [D2D_NUM_CHANNELS-1:0][D2D_NUM_LANES-1:0] d2d_data_o,

  // APB interfaces to configure external IPs
  APB_BUS.Master                           apb_clk_ctrl_bus,
  output logic                             clk_mux_sel_o,
  APB_BUS.Master                           apb_pad_cfg_bus,

  // Generated domain clocks
  input logic                              soc_clk_i,
  input logic                              periph_clk_i,
  input logic                              cluster_clk_i,
  input logic                              ref_clk_i,

  input logic                              test_clk_i,
  // Domain resets
  input logic                              soc_rst_ni,
  input logic                              cluster_rst_ni,
  output logic                             cluster_rst_reg_no,

  // test
  input logic                              dft_test_mode_i,
  input logic                              dft_cg_enable_i,
  // jtag
  output logic                             jtag_tdo_o,
  input logic                              jtag_tck_i,
  input logic                              jtag_tdi_i,
  input logic                              jtag_tms_i,
  input logic                              jtag_trst_ni,
  // wdt
  output logic [1:0]                       wdt_alert_o,
  input  logic                             wdt_alert_clear_i,
  // interrupts
  input logic                              scg_irq_i,
  input logic                              scp_irq_i,
  input logic                              scp_secure_irq_i,
  input logic [71:0]                       mbox_irq_i,
  input logic [71:0]                       mbox_secure_irq_i,

  // inout signals are split into input, output and enables
  // spi/i2c/uart

  output logic [N_SPI-1:0][3:0]            oe_qspi_sdio_o,
  output logic [N_SPI-1:0][3:0]            oe_qspi_csn_o,
  output logic [N_SPI-1:0]                 oe_qspi_sck_o,
  output logic                             oe_spi_mst_alert_o,
  output logic [3:0]                       oe_spi_slv_sdio_o,
  output logic                             oe_spi_slv_csn_o,
  output logic                             oe_spi_slv_sck_o,
  output logic                             oe_spi_slv_alert_o,
  output logic [N_I2C-1:0]                 oe_i2c_sda_o,
  output logic [N_I2C-1:0]                 oe_i2c_scl_o,
  output logic [N_I2C-1:0]                 oe_i2c_alert_o,

  output logic [N_I2C_SLV-1:0]             oe_i2c_slv_sda_o,
  output logic [N_I2C_SLV-1:0]             oe_i2c_slv_scl_o,

  output logic [N_UART-1:0]                oe_uart_rx_o,
  output logic [N_UART-1:0]                oe_uart_tx_o,

  output logic [N_SPI-1:0][3:0]            out_qspi_sdio_o,
  output logic [N_SPI-1:0][3:0]            out_qspi_csn_o,
  output logic [N_SPI-1:0]                 out_qspi_sck_o,
  output logic                             out_spi_mst_alert_o,
  output logic [3:0]                       out_spi_slv_sdio_o,
  output logic                             out_spi_slv_csn_o,
  output logic                             out_spi_slv_sck_o,
  output logic                             out_spi_slv_alert_o,
  output logic [N_I2C-1:0]                 out_i2c_sda_o,
  output logic [N_I2C-1:0]                 out_i2c_scl_o,
  output logic [N_I2C-1:0]                 out_i2c_alert_o,

  output logic [N_I2C_SLV-1:0]             out_i2c_slv_sda_o,
  output logic [N_I2C_SLV-1:0]             out_i2c_slv_scl_o,

  output logic [N_UART-1:0]                out_uart_rx_o,
  output logic [N_UART-1:0]                out_uart_tx_o,

  input logic [N_SPI-1:0][3:0]             in_qspi_sdio_i,
  input logic [N_SPI-1:0][3:0]             in_qspi_csn_i,
  input logic [N_SPI-1:0]                  in_qspi_sck_i,
  input logic                              in_spi_mst_alert_i,
  input logic [3:0]                        in_spi_slv_sdio_i,
  input logic                              in_spi_slv_csn_i,
  input logic                              in_spi_slv_sck_i,
  input logic                              in_spi_slv_alert_i,
  input logic [N_I2C-1:0]                  in_i2c_sda_i,
  input logic [N_I2C-1:0]                  in_i2c_scl_i,
  input logic [N_I2C-1:0]                  in_i2c_alert_i,

  input logic [N_I2C_SLV-1:0]              in_i2c_slv_sda_i,
  input logic [N_I2C_SLV-1:0]              in_i2c_slv_scl_i,

  input logic [N_UART-1:0]                 in_uart_rx_i,
  input logic [N_UART-1:0]                 in_uart_tx_i,

  input logic [NGPIO-1:0]                   gpio_in_i,
  output logic [NGPIO-1:0]                  gpio_out_o,
  output logic [NGPIO-1:0]                  gpio_dir_o,
  output logic [NGPIO-1:0][NBIT_PADCFG-1:0] gpio_cfg_o,

  //inter-socket mux signal
  output logic                             sel_spi_dir_o,
  output logic                             sel_i2c_mux_o,

  input logic                              bootsel_valid_i,
  input logic [2:0]                        bootsel_i,
  input logic                              fc_fetch_en_valid_i,
  input logic                              fc_fetch_en_i
);

  // soc/ext axi
  localparam int unsigned AXI_SOC_EXT_DATA_WIDTH     = 64;
  localparam int unsigned AXI_SOC_EXT_STRB_WIDTH     = AXI_SOC_EXT_DATA_WIDTH/8;
  localparam int unsigned AXI_SOC_EXT_ID_WIDTH       = pkg_soc_interconnect::AXI_ID_OUT_WIDTH + 1; // = (1 + clog2(13)) + 1 = 6 (because of axi mux)

  // soc/cluster axi
  localparam int unsigned AXI_ADDR_WIDTH             = 32;
  localparam int unsigned AXI_CLUSTER_SOC_DATA_WIDTH = 64;
  localparam int unsigned AXI_SOC_CLUSTER_DATA_WIDTH = 32;
  localparam int unsigned AXI_SOC_CLUSTER_ID_WIDTH   = pkg_soc_interconnect::AXI_ID_OUT_WIDTH; // = 1 + clog2(13) = 5
  localparam int unsigned AXI_CLUSTER_SOC_ID_WIDTH   = AXI_SOC_CLUSTER_ID_WIDTH + $clog2(`NB_SLAVE); // = 5 + clog2(4) = 7;

  localparam int unsigned AXI_USER_WIDTH             = 6;
  localparam int unsigned AXI_CLUSTER_SOC_STRB_WIDTH = AXI_CLUSTER_SOC_DATA_WIDTH/8;
  localparam int unsigned AXI_SOC_CLUSTER_STRB_WIDTH = AXI_SOC_CLUSTER_DATA_WIDTH/8;

  localparam int unsigned AXI_CLUSTER_SOC_AW_WIDTH   = AXI_CLUSTER_SOC_ID_WIDTH+AXI_ADDR_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::len_t)+$bits(axi_pkg::size_t)+$bits(axi_pkg::burst_t)+$bits(axi_pkg::cache_t)+$bits(axi_pkg::prot_t)+$bits(axi_pkg::qos_t)+$bits(axi_pkg::region_t)+$bits(axi_pkg::atop_t)+1;
  localparam int unsigned AXI_CLUSTER_SOC_W_WIDTH    = AXI_USER_WIDTH+AXI_CLUSTER_SOC_STRB_WIDTH+AXI_CLUSTER_SOC_DATA_WIDTH+1;
  localparam int unsigned AXI_CLUSTER_SOC_R_WIDTH    = AXI_CLUSTER_SOC_ID_WIDTH+AXI_CLUSTER_SOC_DATA_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::resp_t)+1;
  localparam int unsigned AXI_CLUSTER_SOC_B_WIDTH    = AXI_USER_WIDTH+AXI_CLUSTER_SOC_ID_WIDTH+$bits(axi_pkg::resp_t);
  localparam int unsigned AXI_CLUSTER_SOC_AR_WIDTH   = AXI_CLUSTER_SOC_ID_WIDTH+AXI_ADDR_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::len_t)+$bits(axi_pkg::size_t)+$bits(axi_pkg::burst_t)+$bits(axi_pkg::cache_t)+$bits(axi_pkg::prot_t)+$bits(axi_pkg::qos_t)+$bits(axi_pkg::region_t)+1;

  localparam int unsigned AXI_SOC_CLUSTER_AW_WIDTH   = AXI_SOC_CLUSTER_ID_WIDTH+AXI_ADDR_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::len_t)+$bits(axi_pkg::size_t)+$bits(axi_pkg::burst_t)+$bits(axi_pkg::cache_t)+$bits(axi_pkg::prot_t)+$bits(axi_pkg::qos_t)+$bits(axi_pkg::region_t)+$bits(axi_pkg::atop_t)+1;
  localparam int unsigned AXI_SOC_CLUSTER_W_WIDTH    = AXI_USER_WIDTH+AXI_SOC_CLUSTER_STRB_WIDTH+AXI_SOC_CLUSTER_DATA_WIDTH+1;
  localparam int unsigned AXI_SOC_CLUSTER_R_WIDTH    = AXI_SOC_CLUSTER_ID_WIDTH+AXI_SOC_CLUSTER_DATA_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::resp_t)+1;
  localparam int unsigned AXI_SOC_CLUSTER_B_WIDTH    = AXI_USER_WIDTH+AXI_SOC_CLUSTER_ID_WIDTH+$bits(axi_pkg::resp_t);
  localparam int unsigned AXI_SOC_CLUSTER_AR_WIDTH   = AXI_SOC_CLUSTER_ID_WIDTH+AXI_ADDR_WIDTH+AXI_USER_WIDTH+$bits(axi_pkg::len_t)+$bits(axi_pkg::size_t)+$bits(axi_pkg::burst_t)+$bits(axi_pkg::cache_t)+$bits(axi_pkg::prot_t)+$bits(axi_pkg::qos_t)+$bits(axi_pkg::region_t)+1;

  localparam int unsigned BUFFER_WIDTH               = 8;
  localparam int unsigned EVENT_WIDTH                = 8;
  localparam int unsigned LOG_DEPTH                  = 3;

  localparam int unsigned CVP_ADDR_WIDTH             = 32;
  localparam int unsigned CVP_DATA_WIDTH             = 32;

  // soc_domain
  localparam int unsigned ZFINX = 1;        // fc zfinx

  // cluster_domain
  localparam int unsigned L2_SIZE = (L2_BANK_SIZE * N_L2_BANKS + L2_BANK_SIZE_PRI*N_L2_BANKS_PRI) * 4; // in bytes: (NumWords * 32 * NumBanks)/8
  localparam int unsigned L1_SIZE = L1_BANK_SIZE * N_L1_BANKS * 4; // in bytes: (NumWords * 32 * NumBanks)/8
  localparam int unsigned CLUST_ZFINX = 1;

  // Interrupts
  localparam int unsigned NUM_INTERRUPTS = 256;
  localparam int unsigned NUM_CL_INTERRUPTS = 32;

  //
  // To SoC
  //

  logic                        s_mode_select;

  logic [N_UART-1:0]           s_uart_tx;
  logic [N_UART-1:0]           s_uart_rx;

  logic [N_I2C-1:0]            s_i2c_scl_in;
  logic [N_I2C-1:0]            s_i2c_scl_out;
  logic [N_I2C-1:0]            s_i2c_scl_oe;
  logic [N_I2C-1:0]            s_i2c_sda_in;
  logic [N_I2C-1:0]            s_i2c_sda_out;
  logic [N_I2C-1:0]            s_i2c_sda_oe;

  logic [N_I2C_SLV-1:0]        s_i2c_slv_scl_in;
  logic [N_I2C_SLV-1:0]        s_i2c_slv_scl_out;
  logic [N_I2C_SLV-1:0]        s_i2c_slv_scl_oe;
  logic [N_I2C_SLV-1:0]        s_i2c_slv_sda_in;
  logic [N_I2C_SLV-1:0]        s_i2c_slv_sda_out;
  logic [N_I2C_SLV-1:0]        s_i2c_slv_sda_oe;

  logic [N_SPI-1:0]            s_spi_clk;
  logic [N_SPI-1:0][3:0]       s_spi_csn;
  logic [N_SPI-1:0][3:0]       s_spi_oen;
  logic [N_SPI-1:0][3:0]       s_spi_sdo;
  logic [N_SPI-1:0][3:0]       s_spi_sdi;

  logic                        s_spi_clk_slv;
  logic                        s_spi_csn_slv;
  logic [3:0]                  s_spi_oen_slv;
  logic [3:0]                  s_spi_sdo_slv;
  logic [3:0]                  s_spi_sdi_slv;

  logic [3:0]                  s_timer0;
  logic [3:0]                  s_timer1;
  logic [3:0]                  s_timer2;
  logic [3:0]                  s_timer3;

  logic [`NB_CORES-1:0]        s_dbg_irq_valid;

  logic                        s_dma_pe_irq_ack;
  logic                        s_dma_pe_irq_valid;

  //
  // SOC TO CLUSTER DOMAINS SIGNALS
  //

  logic                        s_cluster_busy;
  logic                        s_cluster_irq;
  logic                        s_cluster_fetch_enable;
  logic [63:0]                 s_cluster_boot_addr;
  logic                        s_cluster_test_en;
  logic                        s_cluster_pow;
  logic                        s_cluster_byp;

  logic                        s_dma_pe_evt_ack;
  logic                        s_dma_pe_evt_valid;
  logic                        s_pf_evt_ack;
  logic                        s_pf_evt_valid;

  logic [BUFFER_WIDTH-1:0]     s_event_writetoken;
  logic [BUFFER_WIDTH-1:0]     s_event_readpointer;
  logic [EVENT_WIDTH-1:0]      s_event_dataasync;

  // SOC TO CLUSTER AXI BUS
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_aw_wptr;
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_aw_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_CLUSTER_SOC_AW_WIDTH-1:0] s_cluster_soc_bus_aw_data;

  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_ar_wptr;
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_ar_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_CLUSTER_SOC_AR_WIDTH-1:0] s_cluster_soc_bus_ar_data;

  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_w_wptr;
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_w_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_CLUSTER_SOC_W_WIDTH-1:0]  s_cluster_soc_bus_w_data;

  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_r_wptr;
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_r_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_CLUSTER_SOC_R_WIDTH-1:0]  s_cluster_soc_bus_r_data;

  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_b_wptr;
  logic [LOG_DEPTH:0]                                    s_cluster_soc_bus_b_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_CLUSTER_SOC_B_WIDTH-1:0]  s_cluster_soc_bus_b_data;


  // CLUSTER TO SOC AXI BUS
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_aw_wptr;
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_aw_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_SOC_CLUSTER_AW_WIDTH-1:0] s_soc_cluster_bus_aw_data;

  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_ar_wptr;
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_ar_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_SOC_CLUSTER_AR_WIDTH-1:0] s_soc_cluster_bus_ar_data;

  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_w_wptr;
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_w_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_SOC_CLUSTER_W_WIDTH-1:0]  s_soc_cluster_bus_w_data;

  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_r_wptr;
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_r_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_SOC_CLUSTER_R_WIDTH-1:0]  s_soc_cluster_bus_r_data;

  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_b_wptr;
  logic [LOG_DEPTH:0]                                    s_soc_cluster_bus_b_rptr;
  logic [2**LOG_DEPTH-1:0][AXI_SOC_CLUSTER_B_WIDTH-1:0]  s_soc_cluster_bus_b_data;

  // only supports 32 GPIOs
  if (NGPIO != 32)
    $fatal(1, "control_pulp only supports NGPIO=32");

  //
  // OUTPUT ENABLES
  //
  // SPI Master
  assign oe_qspi_sdio_o  = ~s_spi_oen;

  for (genvar i = 0; i < N_SPI; i++) begin: assign_oe_qspi_mst_csn
    for (genvar j = 0; j < 4; j++) begin: assign_oe_qspi_mst_csn_i
      assign oe_qspi_csn_o[i][j]   = 1'b1;
    end
  end

  assign oe_spi_mst_alert_o = 1'b1; // SPI slv alert is an input pin

  for (genvar i = 0; i < N_SPI; i++) begin: assign_oe_qspi_mst_sck
    assign oe_qspi_sck_o[i]   = 1'b1;
  end

  // SPI SLAVE
  assign oe_spi_slv_sdio_o  = ~s_spi_oen_slv;
  assign oe_spi_slv_csn_o   = 1'b0;
  assign oe_spi_slv_sck_o   = 1'b0;

  assign oe_spi_slv_alert_o = 1'b0; // SPI slv alert is an output pin

  // UART
  for (genvar i = 0; i < N_UART; i++) begin: assign_oe_uart
    assign oe_uart_rx_o[i]  = 1'b0;
    assign oe_uart_tx_o[i]  = 1'b1;
  end

  // I2C MASTER
  assign oe_i2c_sda_o     = s_i2c_sda_oe;
  assign oe_i2c_scl_o     = s_i2c_scl_oe;

  for (genvar i = 0; i < N_I2C; i++) begin: assign_oe_i2c_mst_alert
    assign oe_i2c_alert_o[i]   = 1'b0;
  end

  // I2C SLAVE
  assign oe_i2c_slv_sda_o     = s_i2c_slv_sda_oe;
  assign oe_i2c_slv_scl_o     = s_i2c_slv_scl_oe;

  //
  // DATA OUTPUT
  //

  // SPI MASTER
  assign out_qspi_sdio_o  = s_spi_sdo;
  assign out_qspi_csn_o   = s_spi_csn;
  assign out_qspi_sck_o   = s_spi_clk;

  assign out_spi_mst_alert_o = 1'b0;

  // SPI SLAVE
  assign out_spi_slv_sdio_o  = s_spi_sdo_slv;
  assign out_spi_slv_csn_o   = 1'b1;
  assign out_spi_slv_sck_o   = 1'b0;

  assign out_spi_slv_alert_o = 1'b0;

  // UART
  for (genvar i = 0; i < N_UART; i++) begin: assign_out_uart
    assign out_uart_rx_o[i]  = 1'b0;
  end

  assign out_uart_tx_o  = s_uart_tx;

  // I2C MASTER
  assign out_i2c_sda_o    = s_i2c_sda_out;
  assign out_i2c_scl_o    = s_i2c_scl_out;

  for (genvar i = 0; i < N_I2C; i++) begin: assign_out_i2c_mst_alert
    assign out_i2c_alert_o[i]   = 1'b0;
  end

  // I2C SLAVE
  assign out_i2c_slv_sda_o    = s_i2c_slv_sda_out;
  assign out_i2c_slv_scl_o    = s_i2c_slv_scl_out;

  //
  // DATA INPUT
  //

  // SPI MASTER
  assign s_spi_sdi = in_qspi_sdio_i;

  // SPI SLAVE
  assign s_spi_sdi_slv = in_spi_slv_sdio_i;
  assign s_spi_clk_slv = in_spi_slv_sck_i;
  assign s_spi_csn_slv = in_spi_slv_csn_i;

  // I2C MASTER
  assign s_i2c_sda_in      = in_i2c_sda_i;
  assign s_i2c_scl_in      = in_i2c_scl_i;

  // I2C SLAVE
  assign s_i2c_slv_sda_in  = in_i2c_slv_sda_i;
  assign s_i2c_slv_scl_in  = in_i2c_slv_scl_i;

  // UART
  assign s_uart_rx  = in_uart_rx_i;

  // TODO: assign I2C alert master input and SPI master and slave inputs

  assign s_mode_select = 1'b0;


  // Break soc_domain AXI external interfaces into req/resp structs ports for control_pulp
  // Define AXI interfaces for actual external block (nci_cp_top) -> soc_domain AXI interfaces

  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH_PMS),
    .AXI_DATA_WIDTH (AXI_DATA_INP_WIDTH_PMS),
    .AXI_ID_WIDTH   (AXI_ID_INP_WIDTH_PMS),
    .AXI_USER_WIDTH (AXI_USER_WIDTH_PMS)
  ) axi_ext_in ();

  AXI_BUS #(
    .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH_PMS),
    .AXI_DATA_WIDTH (AXI_DATA_OUP_WIDTH_PMS),
    .AXI_ID_WIDTH   (AXI_ID_OUP_WIDTH_PMS),
    .AXI_USER_WIDTH (AXI_USER_WIDTH_PMS)
  ) axi_ext_out ();

  // AXI widths assertion checks for (1) ext AXI master (2) ext AXI slave

  // AXI data IN width
  if (AXI_DATA_INP_WIDTH_PMS != AXI_CLUSTER_SOC_DATA_WIDTH)
    $fatal(1, "AXI data width mismatch on nci_cp_top AXI slave port"); // ext AXI slave (default 64 bit)

  // AXi data OUT width
  if (AXI_DATA_OUP_WIDTH_PMS != AXI_SOC_EXT_DATA_WIDTH)
    $fatal(1, "AXI data width mismatch on nci_cp_top AXI master port"); // ext AXI master (default 64 bit)

  // AXI addr width
  if (AXI_ADDR_WIDTH_PMS != AXI_ADDR_WIDTH)
    $fatal(1, "AXI addr width mismatch on nci_cp_top AXI master and slave ports"); // ext AXI master and slave (default 32 bit)

  // AXI ID_IN width
  if (AXI_ID_INP_WIDTH_PMS != AXI_CLUSTER_SOC_ID_WIDTH)
    $fatal(1, "AXI ID width mismatch on nci_cp_top AXI slave port"); // ext AXI slave (default 7 bit)

  // AXI ID_OUT width
  if (AXI_ID_OUP_WIDTH_PMS != AXI_SOC_EXT_ID_WIDTH)
    $fatal(1, "AXI ID width mismatch on nci_cp_top AXI master port"); // ext AXI master (default 5 bit)

  // AXI User width
  if (AXI_USER_WIDTH_PMS != AXI_USER_WIDTH)
    $fatal(1, "AXI user width mismatch on nci_cp_top AXI master and slave ports"); // ext AXI master and slave (default 6 bit)

  // l2 bus (to explode)
  XBAR_TCDM_BUS tcdm_interleaved_l2_bus [N_L2_BANKS]();
  XBAR_TCDM_BUS tcdm_private_l2_bus [N_L2_BANKS_PRI]();

  // 3. Connect soc_domain AXI interfaces and req/resp structs
  // cfg regs
  APB_BUS apb_serial_link_bus();

  if (USE_D2D) begin : gen_d2d
    // Convert APB to regbus
    typedef logic [31:0] addr_t;
    typedef logic [31:0] data_t;
    typedef logic [3:0]  strb_t;
    REG_BUS #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) regbus_serial_link_cfg(soc_clk_i);
    // regbus req/resp
    `REG_BUS_TYPEDEF_ALL(regbus_serial_link, addr_t, data_t, strb_t);
    regbus_serial_link_req_t regbus_serial_link_cfg_req;
    regbus_serial_link_rsp_t regbus_serial_link_cfg_rsp;

    // apb to regbus bridge
    apb_to_reg i_apb_to_regbus_serial_link (
      .clk_i    (soc_clk_i),
      .rst_ni   (soc_rst_ni),
      .penable_i(apb_serial_link_bus.penable),
      .pwrite_i (apb_serial_link_bus.pwrite),
      .paddr_i  (apb_serial_link_bus.paddr),
      .psel_i   (apb_serial_link_bus.psel),
      .pwdata_i (apb_serial_link_bus.pwdata),
      .prdata_o (apb_serial_link_bus.prdata),
      .pready_o (apb_serial_link_bus.pready),
      .pslverr_o(apb_serial_link_bus.pslverr),
      .reg_o    (regbus_serial_link_cfg)
    );

    // regbus interface to req/resp structs
    `REG_BUS_ASSIGN_TO_REQ(regbus_serial_link_cfg_req, regbus_serial_link_cfg)
    `REG_BUS_ASSIGN_FROM_RSP(regbus_serial_link_cfg, regbus_serial_link_cfg_rsp)

     // PMS AXI Master
    `AXI_TYPEDEF_AW_CHAN_T(axi_aw_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
    `AXI_TYPEDEF_W_CHAN_T(axi_w_inp_ext_t, axi_data_inp_ext_t, axi_strb_inp_ext_t, axi_user_ext_t);
    `AXI_TYPEDEF_B_CHAN_T(axi_b_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
    `AXI_TYPEDEF_AR_CHAN_T(axi_ar_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
    `AXI_TYPEDEF_R_CHAN_T( axi_r_inp_ext_t, axi_data_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);

    // AXI to D2D
    axi_req_inp_ext_t from_ext_req, to_ext_req_iwc;
    axi_resp_inp_ext_t from_ext_resp, to_ext_resp_iwc;
    axi_req_oup_ext_t to_ext_req;
    axi_resp_oup_ext_t to_ext_resp;

    // PULP as master
    `AXI_ASSIGN_TO_REQ(to_ext_req, axi_ext_out);
    `AXI_ASSIGN_FROM_RESP(axi_ext_out, to_ext_resp);

    // PULP as slave
    `AXI_ASSIGN_FROM_REQ(axi_ext_in, from_ext_req);
    `AXI_ASSIGN_TO_RESP(from_ext_resp, axi_ext_in);

    // Align outgoing and incoming ID widths

    axi_iw_converter #(
      .AxiSlvPortIdWidth      ( AXI_ID_OUP_WIDTH_PMS    ),
      .AxiMstPortIdWidth      ( AXI_ID_INP_WIDTH_PMS    ),
      .AxiSlvPortMaxUniqIds   ( 16                      ),
      .AxiSlvPortMaxTxnsPerId ( 13                      ),
      .AxiAddrWidth           ( AXI_ADDR_WIDTH_PMS      ),
      .AxiDataWidth           ( AXI_DATA_INP_WIDTH_PMS  ),
      .AxiUserWidth           ( AXI_USER_WIDTH_PMS      ),
      .slv_req_t              ( axi_req_oup_ext_t       ),
      .slv_resp_t             ( axi_resp_oup_ext_t      ),
      .mst_req_t              ( axi_req_inp_ext_t       ),
      .mst_resp_t             ( axi_resp_inp_ext_t      )
    ) i_axi_iwc_ext_to_d2d (
      .clk_i      ( soc_clk_i       ),
      .rst_ni     ( soc_rst_ni      ),
      .slv_req_i  ( to_ext_req      ),
      .slv_resp_o ( to_ext_resp     ),
      .mst_req_o  ( to_ext_req_iwc  ),
      .mst_resp_i ( to_ext_resp_iwc )
    );

    // D2D link
    serial_link_wrapper #(
      .axi_req_t  (axi_req_inp_ext_t),
      .axi_rsp_t  (axi_resp_inp_ext_t),
      .aw_chan_t  (axi_aw_inp_ext_t),
      .ar_chan_t  (axi_ar_inp_ext_t),
      .r_chan_t   (axi_r_inp_ext_t),
      .w_chan_t   (axi_w_inp_ext_t),
      .b_chan_t   (axi_b_inp_ext_t),
      .cfg_req_t  (regbus_serial_link_req_t),
      .cfg_rsp_t  (regbus_serial_link_rsp_t),
      .NumChannels(D2D_NUM_CHANNELS),
      .NumLanes   (D2D_NUM_LANES),
      .NumCredits (D2D_NUM_CREDITS),
      .MaxClkDiv  (1024),
      .UseDelayLine (USE_D2D_DELAY_LINE)
    ) i_d2d_link (
      .clk_i         (soc_clk_i),
      .rst_ni        (soc_rst_ni),
      .clk_sl_i      (soc_clk_i),
      .rst_sl_ni     (soc_rst_ni),
      .clk_reg_i     (soc_clk_i),
      .rst_reg_ni    (soc_rst_ni),
      .testmode_i    (dft_test_mode_i),
      .axi_in_req_i  (to_ext_req_iwc),
      .axi_in_rsp_o  (to_ext_resp_iwc),
      .axi_out_req_o (from_ext_req),
      .axi_out_rsp_i (from_ext_resp),
      .cfg_req_i     (regbus_serial_link_cfg_req),
      .cfg_rsp_o     (regbus_serial_link_cfg_rsp),
      .ddr_rcv_clk_i (d2d_clk_i),
      .ddr_rcv_clk_o (d2d_clk_o),
      .ddr_i         (d2d_data_i),
      .ddr_o         (d2d_data_o),
      .isolated_i    ('0 ),
      .isolate_o     (   ),
      .clk_ena_o     (   ),
      .reset_no      (   )
    );

    // tie AXI4 ports
    assign to_ext_req_o    = '0;
    assign from_ext_resp_o = '0;

  end else begin : gen_no_d2d
    // PULP as master
    `AXI_ASSIGN_TO_REQ(to_ext_req_o, axi_ext_out);
    `AXI_ASSIGN_FROM_RESP(axi_ext_out, to_ext_resp_i);

    // PULP as slave
    `AXI_ASSIGN_FROM_REQ(axi_ext_in, from_ext_req_i);
    `AXI_ASSIGN_TO_RESP(from_ext_resp_o, axi_ext_in);

    // Tie d2d link ports
    assign d2d_clk_o = '0;
    assign d2d_data_o = '0;
    assign apb_serial_link_bus.prdata = '0;
    assign apb_serial_link_bus.pready = 1'b0;
    assign apb_serial_link_bus.pslverr = 1'b0;
  end

  //
  // SOC DOMAIN module instantiation
  //

  if(USE_HWPE)
    $fatal(1, "hwpe support is disabled. Make sure parameter USE_HWPE=1");

  if(CORE_TYPE != 0)
    $fatal(1, "ibex support is disabled. Make sure parameter CORE_TYPE=0");

  soc_domain #(
    /*AUTOINSTPARAM*/
    .CORE_TYPE             ( CORE_TYPE                  ),
    .PULP_XPULP            ( PULP_XPULP                 ),
    .USE_FPU               ( USE_FPU                    ),
    .USE_HWPE              ( USE_HWPE                   ),
    .ZFINX                 ( ZFINX                      ),
    .N_PERF_COUNTERS       ( N_SOC_PERF_COUNTERS        ),
    .AXI_ADDR_WIDTH        ( AXI_ADDR_WIDTH             ),
    .AXI_DATA_IN_WIDTH     ( AXI_CLUSTER_SOC_DATA_WIDTH ), // 64
    .AXI_DATA_OUT_S2C_WIDTH ( AXI_SOC_CLUSTER_DATA_WIDTH ), // 32
    .AXI_DATA_OUT_S2E_WIDTH ( AXI_SOC_EXT_DATA_WIDTH     ), // 64
    .AXI_ID_IN_WIDTH       ( AXI_CLUSTER_SOC_ID_WIDTH   ), // 7
    .AXI_ID_OUT_S2C_WIDTH  ( AXI_SOC_CLUSTER_ID_WIDTH   ), // 5 [1 + clog2(13)]
    .AXI_ID_OUT_S2E_WIDTH  ( AXI_SOC_EXT_ID_WIDTH       ), // 6 [1 + clog2(13)] + 1 (because of axi mux)
    .AXI_USER_WIDTH        ( AXI_USER_WIDTH             ),
    .AXI_STRB_IN_WIDTH     ( AXI_CLUSTER_SOC_STRB_WIDTH ),
    .AXI_STRB_OUT_S2C_WIDTH( AXI_SOC_CLUSTER_STRB_WIDTH ),
    .AXI_STRB_OUT_S2E_WIDTH( AXI_SOC_EXT_STRB_WIDTH     ),
    .C2S_AW_WIDTH          ( AXI_CLUSTER_SOC_AW_WIDTH   ),
    .C2S_W_WIDTH           ( AXI_CLUSTER_SOC_W_WIDTH    ),
    .C2S_B_WIDTH           ( AXI_CLUSTER_SOC_B_WIDTH    ),
    .C2S_AR_WIDTH          ( AXI_CLUSTER_SOC_AR_WIDTH   ),
    .C2S_R_WIDTH           ( AXI_CLUSTER_SOC_R_WIDTH    ),
    .S2C_AW_WIDTH          ( AXI_SOC_CLUSTER_AW_WIDTH   ),
    .S2C_W_WIDTH           ( AXI_SOC_CLUSTER_W_WIDTH    ),
    .S2C_B_WIDTH           ( AXI_SOC_CLUSTER_B_WIDTH    ),
    .S2C_AR_WIDTH          ( AXI_SOC_CLUSTER_AR_WIDTH   ),
    .S2C_R_WIDTH           ( AXI_SOC_CLUSTER_R_WIDTH    ),
    .BUFFER_WIDTH          ( BUFFER_WIDTH               ),
    .EVNT_WIDTH            ( EVENT_WIDTH                ),
    .NGPIO                 ( NGPIO                      ),
    .NBIT_PADCFG           ( NBIT_PADCFG                ),
    .N_UART                ( N_UART                     ),
    .N_SPI                 ( N_SPI                      ),
    .N_I2C                 ( N_I2C                      ),
    .N_I2C_SLV             ( N_I2C_SLV                  ),
    .N_L2_BANKS            ( N_L2_BANKS                 ),
    .N_L2_BANKS_PRI        ( N_L2_BANKS_PRI             ),
    .L2_BANK_SIZE          ( L2_BANK_SIZE               ),
    .L2_BANK_SIZE_PRI      ( L2_BANK_SIZE_PRI           ),
    .L2_SIZE               ( L2_SIZE                    ),
    .NUM_INTERRUPTS        ( NUM_INTERRUPTS             ),
    .SIM_STDOUT            ( SIM_STDOUT                 ),
    .MACRO_ROM             ( MACRO_ROM                  ),
    .USE_CLUSTER           ( USE_CLUSTER                ),
    .SDMA_RT_MIDEND        ( SDMA_RT_MIDEND             )
  ) i_soc_domain (

    .soc_clk_i,
    .periph_clk_i,
    .ref_clk_i,
    .test_clk_i,

    .soc_rst_ni,
    .cluster_rst_ni,

    .mode_select_i                ( s_mode_select                    ),
    .dft_cg_enable_i,
    .dft_test_mode_i,

    .bootsel_valid_i              ( bootsel_valid_i                  ),
    .bootsel_i                    ( bootsel_i                        ),

    .fc_fetch_en_valid_i          ( fc_fetch_en_valid_i              ),
    .fc_fetch_en_i                ( fc_fetch_en_i                    ),

    .jtag_tck_i                   ( jtag_tck_i                       ),
    .jtag_trst_ni                 ( jtag_trst_ni                     ),
    .jtag_tms_i                   ( jtag_tms_i                       ),
    .jtag_tdi_i                   ( jtag_tdi_i                       ),
    .jtag_tdo_o                   ( jtag_tdo_o                       ),

    .wdt_alert_o,
    .wdt_alert_clear_i,

    .scg_irq_i,
    .scp_irq_i,
    .scp_secure_irq_i,
    .mbox_irq_i,
    .mbox_secure_irq_i,

    .gpio_in_i,
    .gpio_out_o,
    .gpio_dir_o,
    .gpio_cfg_o,

    .uart_tx_o                    ( s_uart_tx                        ),
    .uart_rx_i                    ( s_uart_rx                        ),

    .timer_ch0_o                  ( s_timer0                         ),
    .timer_ch1_o                  ( s_timer1                         ),
    .timer_ch2_o                  ( s_timer2                         ),
    .timer_ch3_o                  ( s_timer3                         ),

    .i2c_scl_i                    ( s_i2c_scl_in                     ),
    .i2c_scl_o                    ( s_i2c_scl_out                    ),
    .i2c_scl_oe_o                 ( s_i2c_scl_oe                     ),
    .i2c_sda_i                    ( s_i2c_sda_in                     ),
    .i2c_sda_o                    ( s_i2c_sda_out                    ),
    .i2c_sda_oe_o                 ( s_i2c_sda_oe                     ),

    .i2c_slv_scl_i                ( s_i2c_slv_scl_in                 ),
    .i2c_slv_scl_o                ( s_i2c_slv_scl_out                ),
    .i2c_slv_scl_oe_o             ( s_i2c_slv_scl_oe                 ),
    .i2c_slv_sda_i                ( s_i2c_slv_sda_in                 ),
    .i2c_slv_sda_o                ( s_i2c_slv_sda_out                ),
    .i2c_slv_sda_oe_o             ( s_i2c_slv_sda_oe                 ),

    .spi_clk_o                    ( s_spi_clk                        ),
    .spi_csn_o                    ( s_spi_csn                        ),
    .spi_oen_o                    ( s_spi_oen                        ),
    .spi_sdo_o                    ( s_spi_sdo                        ),
    .spi_sdi_i                    ( s_spi_sdi                        ),

    .spi_clk_i                    ( s_spi_clk_slv                    ),
    .spi_csn_i                    ( s_spi_csn_slv                    ),
    .spi_oen_slv_o                ( s_spi_oen_slv                    ),
    .spi_sdo_slv_o                ( s_spi_sdo_slv                    ),
    .spi_sdi_slv_i                ( s_spi_sdi_slv                    ),

    .sel_spi_dir_o                ( sel_spi_dir_o                    ),
    .sel_i2c_mux_o                ( sel_i2c_mux_o                    ),

    .cluster_busy_i               ( s_cluster_busy                   ),

    .cluster_events_wt_o          ( s_event_writetoken               ),
    .cluster_events_rp_i          ( s_event_readpointer              ),
    .cluster_events_da_o          ( s_event_dataasync                ),

    .cluster_irq_o                ( s_cluster_irq                    ),

    .dbg_irq_valid_o              ( s_dbg_irq_valid                  ),

    .dma_pe_evt_ack_o             ( s_dma_pe_evt_ack                 ),
    .dma_pe_evt_valid_i           ( s_dma_pe_evt_valid               ),
    .dma_pe_irq_ack_o             ( s_dma_pe_irq_ack                 ),
    .dma_pe_irq_valid_i           ( s_dma_pe_irq_valid               ),
    .pf_evt_ack_o                 ( s_pf_evt_ack                     ),
    .pf_evt_valid_i               ( s_pf_evt_valid                   ),

    .cluster_pow_o                ( s_cluster_pow                    ),
    .cluster_byp_o                ( s_cluster_byp                    ),

    .async_data_slave_aw_wptr_i   ( s_cluster_soc_bus_aw_wptr        ),
    .async_data_slave_aw_rptr_o   ( s_cluster_soc_bus_aw_rptr        ),
    .async_data_slave_aw_data_i   ( s_cluster_soc_bus_aw_data        ),

    .async_data_slave_ar_wptr_i   ( s_cluster_soc_bus_ar_wptr        ),
    .async_data_slave_ar_rptr_o   ( s_cluster_soc_bus_ar_rptr        ),
    .async_data_slave_ar_data_i   ( s_cluster_soc_bus_ar_data        ),

    .async_data_slave_w_wptr_i    ( s_cluster_soc_bus_w_wptr         ),
    .async_data_slave_w_data_i    ( s_cluster_soc_bus_w_data         ),
    .async_data_slave_w_rptr_o    ( s_cluster_soc_bus_w_rptr         ),

    .async_data_slave_r_wptr_o    ( s_cluster_soc_bus_r_wptr         ),
    .async_data_slave_r_rptr_i    ( s_cluster_soc_bus_r_rptr         ),
    .async_data_slave_r_data_o    ( s_cluster_soc_bus_r_data         ),

    .async_data_slave_b_wptr_o    ( s_cluster_soc_bus_b_wptr         ),
    .async_data_slave_b_rptr_i    ( s_cluster_soc_bus_b_rptr         ),
    .async_data_slave_b_data_o    ( s_cluster_soc_bus_b_data         ),

    .async_data_master_aw_wptr_o  ( s_soc_cluster_bus_aw_wptr        ),
    .async_data_master_aw_rptr_i  ( s_soc_cluster_bus_aw_rptr        ),
    .async_data_master_aw_data_o  ( s_soc_cluster_bus_aw_data        ),

    .async_data_master_ar_wptr_o  ( s_soc_cluster_bus_ar_wptr        ),
    .async_data_master_ar_rptr_i  ( s_soc_cluster_bus_ar_rptr        ),
    .async_data_master_ar_data_o  ( s_soc_cluster_bus_ar_data        ),

    .async_data_master_w_wptr_o   ( s_soc_cluster_bus_w_wptr         ),
    .async_data_master_w_data_o   ( s_soc_cluster_bus_w_data         ),
    .async_data_master_w_rptr_i   ( s_soc_cluster_bus_w_rptr         ),

    .async_data_master_r_wptr_i   ( s_soc_cluster_bus_r_wptr         ),
    .async_data_master_r_rptr_o   ( s_soc_cluster_bus_r_rptr         ),
    .async_data_master_r_data_i   ( s_soc_cluster_bus_r_data         ),

    .async_data_master_b_wptr_i   ( s_soc_cluster_bus_b_wptr         ),
    .async_data_master_b_rptr_o   ( s_soc_cluster_bus_b_rptr         ),
    .async_data_master_b_data_i   ( s_soc_cluster_bus_b_data         ),

    .cluster_rst_reg_no,

    .cluster_fetch_enable_o       ( s_cluster_fetch_enable           ),
    .cluster_boot_addr_o          ( s_cluster_boot_addr              ),
    .cluster_test_en_o            ( s_cluster_test_en                ),

    // soc_domain AXI interfaces towards outside
    .axi_ext_slv                  ( axi_ext_in                       ),
    .axi_ext_mst                  ( axi_ext_out                      ),

    .tcdm_interleaved_l2_bus      ( tcdm_interleaved_l2_bus          ),
    .tcdm_private_l2_bus          ( tcdm_private_l2_bus              ),

    .apb_serial_link_bus          ( apb_serial_link_bus              ),
    .apb_clk_ctrl_bus             ( apb_clk_ctrl_bus                 ),
    .apb_pad_cfg_bus              ( apb_pad_cfg_bus                  ),
    .clk_mux_sel_o                ( clk_mux_sel_o                    ),

    .*);

  if(USE_CLUSTER) begin: gen_cluster

     if(USE_CLUSTER_HWPE)
      $fatal(1, "cluster hwpe support is disabled. Make sure parameter USE_CLUSTER_HWPE=0");

    // FPU configuration check
    `ifndef FPU_CLUSTER
      if (USE_FPU == 1)
        $fatal(1, "`FPU_CLUSTER in rtl/includes/pulp_soc_defines.sv must be defined when USE_FPU=1");
    `endif

    if(USE_FPU) begin
      if(CLUST_NB_FPU != 8 && CLUST_NB_EXT_DIVSQRT != 1)
        $info("The default FPU configuration of the PMS in the cluster expects 8 private FPUs and 1 shared DIVSQRT");
    end


    // TODO: unfuck the cluster_domain parameters
    cluster_domain #(
    //CLUSTER PARAMETERS
      .NB_CORES            (`NB_CORES),
      .DMA_QUEUE_DEPTH     (`DMA_QUEUE_DEPTH),
      .NB_OUTSND_BURSTS    (`NB_OUTSND_BURSTS),
      .TWD_QUEUE_DEPTH     (`TWD_QUEUE_DEPTH),
      .NB_HWPE_PORTS       (0),
      .NB_DMAS             (4),
      .TCDM_SIZE           (L1_SIZE), // in bytes
      .NB_TCDM_BANKS       (N_L1_BANKS),
      .TCDM_BANK_SIZE      (L1_SIZE/N_L1_BANKS), // in bytes
      .TCDM_NUM_ROWS       (L1_BANK_SIZE),
      .L2_SIZE             (L2_SIZE),
      .HWPE_PRESENT        (USE_CLUSTER_HWPE),
    // ICACHE PARAMETERS
      .SET_ASSOCIATIVE     (4),
      .CACHE_LINE          (1),
      .CACHE_SIZE          (4096),
      .ICACHE_DATA_WIDTH   (128),
      .L0_BUFFER_FEATURE   ("DISABLED"),
      .MULTICAST_FEATURE   ("DISABLED"),
      .SHARED_ICACHE       ("ENABLED"),
      .DIRECT_MAPPED_FEATURE("DISABLED"),
    // CORE PARAMETERS
      .PULP_XPULP          (PULP_XPULP),
      .ROM_BOOT_ADDR       (32'h1A000000),
      .BOOT_ADDR           (32'h1C000000),
      .INSTR_RDATA_WIDTH   (32),
      .N_PERF_COUNTERS     (N_CLUST_PERF_COUNTERS),
      .CLUST_FPU           (USE_FPU),
      .CLUST_NB_FPU        (CLUST_NB_FPU),
      .CLUST_NB_EXT_DIVSQRT(CLUST_NB_EXT_DIVSQRT),
      .CLUST_ZFINX         (CLUST_ZFINX),
      .NUM_INTERRUPTS      (NUM_CL_INTERRUPTS),
    // AXI ADDR WIDTH
      .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
      .AXI_DATA_S2C_WIDTH  (AXI_SOC_CLUSTER_DATA_WIDTH), //5
      .AXI_DATA_C2S_WIDTH  (AXI_CLUSTER_SOC_DATA_WIDTH), //7
      .AXI_USER_WIDTH      (AXI_USER_WIDTH),
      .AXI_ID_IN_WIDTH     (AXI_SOC_CLUSTER_ID_WIDTH),
      .AXI_ID_OUT_WIDTH    (AXI_CLUSTER_SOC_ID_WIDTH),
      .DC_SLICE_BUFFER_WIDTH(8),
      .LOG_DEPTH           (3),
    // AXI CLUSTER TO SOC CDC
      .C2S_AW_WIDTH        (AXI_CLUSTER_SOC_AW_WIDTH),
      .C2S_W_WIDTH         (AXI_CLUSTER_SOC_W_WIDTH),
      .C2S_B_WIDTH         (AXI_CLUSTER_SOC_B_WIDTH),
      .C2S_AR_WIDTH        (AXI_CLUSTER_SOC_AR_WIDTH),
      .C2S_R_WIDTH         (AXI_CLUSTER_SOC_R_WIDTH),
    // AXI SOC TO CLUSTER
      .S2C_AW_WIDTH        (AXI_SOC_CLUSTER_AW_WIDTH),
      .S2C_W_WIDTH         (AXI_SOC_CLUSTER_W_WIDTH),
      .S2C_B_WIDTH         (AXI_SOC_CLUSTER_B_WIDTH),
      .S2C_AR_WIDTH        (AXI_SOC_CLUSTER_AR_WIDTH),
      .S2C_R_WIDTH         (AXI_SOC_CLUSTER_R_WIDTH),
    // CLUSTER MAIN PARAMETERS
      .DATA_WIDTH          (32),
      .ADDR_WIDTH          (32),
      .TEST_SET_BIT        (20),
      .LOG_CLUSTER         (5),
      .PE_ROUTING_LSB      (10),
      .EVNT_WIDTH          (8),
      .BEHAV_MEM           (BEHAV_MEM),
      .FPGA_MEM           (FPGA_MEM),
      .DMA_TYPE            (DMA_TYPE)
    ) i_cluster_domain (
      .clk_i                        ( cluster_clk_i                    ),
      .rst_ni                       ( cluster_rst_ni                   ),
      .ref_clk_i,

      .test_mode_i                  ( dft_test_mode_i                  ),

      .ext_events_writetoken_i      ( s_event_writetoken               ),
      .ext_events_readpointer_o     ( s_event_readpointer              ),
      .ext_events_dataasync_i       ( s_event_dataasync                ),

      .dma_pe_evt_ack_i             ( s_dma_pe_evt_ack                 ),
      .dma_pe_evt_valid_o           ( s_dma_pe_evt_valid               ),
      .dma_pe_irq_ack_i             ( s_dma_pe_irq_ack                 ),
      .dma_pe_irq_valid_o           ( s_dma_pe_irq_valid               ),

      .dbg_irq_valid_i              ( s_dbg_irq_valid                  ), //s_dbg_irq_valid

      .pf_evt_ack_i                 ( s_pf_evt_ack                     ),
      .pf_evt_valid_o               ( s_pf_evt_valid                   ),

      .busy_o                       ( s_cluster_busy                   ),

      .async_data_master_aw_wptr_o  ( s_cluster_soc_bus_aw_wptr        ),
      .async_data_master_aw_rptr_i  ( s_cluster_soc_bus_aw_rptr        ),
      .async_data_master_aw_data_o  ( s_cluster_soc_bus_aw_data        ),

      .async_data_master_ar_wptr_o  ( s_cluster_soc_bus_ar_wptr        ),
      .async_data_master_ar_rptr_i  ( s_cluster_soc_bus_ar_rptr        ),
      .async_data_master_ar_data_o  ( s_cluster_soc_bus_ar_data        ),

      .async_data_master_w_wptr_o   ( s_cluster_soc_bus_w_wptr         ),
      .async_data_master_w_rptr_i   ( s_cluster_soc_bus_w_rptr         ),
      .async_data_master_w_data_o   ( s_cluster_soc_bus_w_data         ),

      .async_data_master_r_wptr_i   ( s_cluster_soc_bus_r_wptr         ),
      .async_data_master_r_rptr_o   ( s_cluster_soc_bus_r_rptr         ),
      .async_data_master_r_data_i   ( s_cluster_soc_bus_r_data         ),

      .async_data_master_b_wptr_i   ( s_cluster_soc_bus_b_wptr         ),
      .async_data_master_b_rptr_o   ( s_cluster_soc_bus_b_rptr         ),
      .async_data_master_b_data_i   ( s_cluster_soc_bus_b_data         ),


      .async_data_slave_aw_wptr_i   ( s_soc_cluster_bus_aw_wptr        ),
      .async_data_slave_aw_rptr_o   ( s_soc_cluster_bus_aw_rptr        ),
      .async_data_slave_aw_data_i   ( s_soc_cluster_bus_aw_data        ),

      .async_data_slave_ar_wptr_i   ( s_soc_cluster_bus_ar_wptr        ),
      .async_data_slave_ar_rptr_o   ( s_soc_cluster_bus_ar_rptr        ),
      .async_data_slave_ar_data_i   ( s_soc_cluster_bus_ar_data        ),

      .async_data_slave_w_wptr_i    ( s_soc_cluster_bus_w_wptr         ),
      .async_data_slave_w_rptr_o    ( s_soc_cluster_bus_w_rptr         ),
      .async_data_slave_w_data_i    ( s_soc_cluster_bus_w_data         ),

      .async_data_slave_r_wptr_o    ( s_soc_cluster_bus_r_wptr         ),
      .async_data_slave_r_rptr_i    ( s_soc_cluster_bus_r_rptr         ),
      .async_data_slave_r_data_o    ( s_soc_cluster_bus_r_data         ),

      .async_data_slave_b_wptr_o    ( s_soc_cluster_bus_b_wptr         ),
      .async_data_slave_b_rptr_i    ( s_soc_cluster_bus_b_rptr         ),
      .async_data_slave_b_data_o    ( s_soc_cluster_bus_b_data         )
    );

  end else begin // if (USE_CLUSTER)

    // Tie signals form soc to cluster
    assign s_cluster_busy = 1'b0;
    assign s_event_readpointer = 1'b0;
    assign s_dma_pe_evt_valid = 1'b0;
    assign s_dma_pe_irq_valid = 1'b0;
    assign s_pf_evt_valid = 1'b0;
    assign s_cluster_soc_bus_aw_wptr = '0;
    assign s_cluster_soc_bus_aw_data = '0;
    assign s_cluster_soc_bus_ar_wptr = '0;
    assign s_cluster_soc_bus_ar_data = '0;
    assign s_cluster_soc_bus_w_wptr = '0;
    assign s_cluster_soc_bus_w_data = '0;
    assign s_cluster_soc_bus_r_rptr = '0;
    assign s_cluster_soc_bus_b_rptr = '0;
    assign s_soc_cluster_bus_aw_rptr = '0;
    assign s_soc_cluster_bus_ar_rptr = '0;
    assign s_soc_cluster_bus_w_rptr = '0;
    assign s_soc_cluster_bus_r_wptr = '0;
    assign s_soc_cluster_bus_r_data = '0;
    assign s_soc_cluster_bus_b_wptr = '0;
    assign s_soc_cluster_bus_b_data = '0;

  end // else: !if(USE_CLUSTER)

  // 2**L2_MEM_ADDR_WIDTH rows (64 bits each) in L2 -->
  // TOTAL L2 SIZE = 8byte * 2^L2_MEM_ADDR_WIDTH
  localparam L2_MEM_ADDR_WIDTH = $clog2(L2_BANK_SIZE * N_L2_BANKS) - $clog2(N_L2_BANKS);

  // external L2
  l2_ram_multi_bank #(
    .NB_BANKS              ( N_L2_BANKS       ),
    .BANK_SIZE_INTL_SRAM   ( L2_BANK_SIZE     ),
    .L2_BANK_SIZE_PRI      ( L2_BANK_SIZE_PRI ),
    .BEHAV_MEM             ( BEHAV_MEM        ),
    .FPGA_MEM              ( FPGA_MEM         )
  ) l2_ram_i (
    .clk_i           ( soc_clk_i ),
    .rst_ni          ( soc_rst_ni ),
    .init_ni         ( 1'b1                     ),
    .test_mode_i     ( dft_test_mode_i          ),
    .mem_slave       ( tcdm_interleaved_l2_bus  ),
    .mem_pri_slave   ( tcdm_private_l2_bus      )
  );

endmodule // control_pulp

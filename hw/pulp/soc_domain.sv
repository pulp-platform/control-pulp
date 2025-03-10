// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`include "pulp_soc_defines.sv"

module soc_domain #(
    parameter CORE_TYPE            = 0,
    parameter PULP_XPULP           = 1,
    parameter USE_FPU              = 1,
    parameter USE_HWPE             = 1,
    parameter ZFINX                = 0,
    parameter N_PERF_COUNTERS      = 1,
    parameter NB_CL_CORES          = 8,
    parameter AXI_ADDR_WIDTH       = 32,
    parameter AXI_DATA_IN_WIDTH    = 64,
    parameter AXI_DATA_OUT_S2C_WIDTH = 32,
    parameter AXI_DATA_OUT_S2E_WIDTH = 64,
    parameter AXI_ID_IN_WIDTH      = 7,
    parameter AXI_ID_INT_WIDTH     = 8,
    parameter AXI_ID_OUT_S2C_WIDTH = 5,
    parameter AXI_ID_OUT_S2E_WIDTH = 6,
    parameter AXI_USER_WIDTH       = 6,
    parameter AXI_STRB_IN_WIDTH    = AXI_DATA_IN_WIDTH/8,
    parameter AXI_STRB_OUT_S2C_WIDTH = AXI_DATA_OUT_S2C_WIDTH/8,
    parameter AXI_STRB_OUT_S2E_WIDTH = AXI_DATA_OUT_S2E_WIDTH/8,

    parameter C2S_AW_WIDTH         = 1,
    parameter C2S_W_WIDTH          = 1,
    parameter C2S_B_WIDTH          = 1,
    parameter C2S_AR_WIDTH         = 1,
    parameter C2S_R_WIDTH          = 1,
    parameter S2C_AW_WIDTH         = 1,
    parameter S2C_W_WIDTH          = 1,
    parameter S2C_B_WIDTH          = 1,
    parameter S2C_AR_WIDTH         = 1,
    parameter S2C_R_WIDTH          = 1,
    parameter LOG_DEPTH            = 3,

    parameter BUFFER_WIDTH         = 8,
    parameter EVNT_WIDTH           = 8,

    parameter int unsigned NGPIO       = 32,
    parameter int unsigned NBIT_PADCFG = 4,

    parameter int unsigned N_UART = 1,
    parameter int unsigned N_SPI  = 1,
    parameter int unsigned N_I2C  = 2,
    parameter int unsigned N_I2C_SLV  = 2,

    parameter int unsigned N_L2_BANKS     = 0,
    parameter int unsigned N_L2_BANKS_PRI = 0,
    parameter int unsigned L2_BANK_SIZE     = 0,
    parameter int unsigned L2_BANK_SIZE_PRI = 0,
    parameter int unsigned L2_SIZE = 0,
    parameter int unsigned NUM_INTERRUPTS = 0,
    parameter int unsigned NUM_EXT_INTERRUPTS = 222,
    parameter int unsigned SIM_STDOUT = 0,
    parameter int unsigned MACRO_ROM = 0,
    parameter int unsigned USE_CLUSTER = 0
)(

    input logic                               soc_clk_i,
    input logic                               periph_clk_i,
    input logic                               ref_clk_i,
    input logic                               test_clk_i,
    input logic                               soc_rst_ni,
    input logic                               cluster_rst_ni,

    input logic                               dft_test_mode_i,
    input logic                               dft_cg_enable_i,

    input logic                               mode_select_i,

    input logic                               bootsel_valid_i,
    input logic [2:0]                         bootsel_i,

    input logic                               fc_fetch_en_valid_i,
    input logic                               fc_fetch_en_i,

    input logic                               jtag_tck_i,
    input logic                               jtag_trst_ni,
    input logic                               jtag_tms_i,
    input logic                               jtag_tdi_i,
    output logic                              jtag_tdo_o,

    output logic [1:0]                        wdt_alert_o,
    input  logic                              wdt_alert_clear_i,

    input logic  [NUM_EXT_INTERRUPTS-1:0]     irq_ext_i,

    output logic [NB_CL_CORES-1:0]            dbg_irq_valid_o,

    input logic [NGPIO-1:0]                   gpio_in_i,
    output logic [NGPIO-1:0]                  gpio_out_o,
    output logic [NGPIO-1:0]                  gpio_dir_o,
    output logic [NGPIO-1:0][NBIT_PADCFG-1:0] gpio_cfg_o,

    output logic [N_UART-1:0]                 uart_tx_o,
    input logic  [N_UART-1:0]                 uart_rx_i,

    output logic [3:0]                        timer_ch0_o,
    output logic [3:0]                        timer_ch1_o,
    output logic [3:0]                        timer_ch2_o,
    output logic [3:0]                        timer_ch3_o,

    input logic  [N_I2C-1:0]                  i2c_scl_i,
    output logic [N_I2C-1:0]                  i2c_scl_o,
    output logic [N_I2C-1:0]                  i2c_scl_oe_o,
    input logic  [N_I2C-1:0]                  i2c_sda_i,
    output logic [N_I2C-1:0]                  i2c_sda_o,
    output logic [N_I2C-1:0]                  i2c_sda_oe_o,

    input logic  [N_I2C_SLV-1:0]              i2c_slv_scl_i,
    output logic [N_I2C_SLV-1:0]              i2c_slv_scl_o,
    output logic [N_I2C_SLV-1:0]              i2c_slv_scl_oe_o,
    input logic  [N_I2C_SLV-1:0]              i2c_slv_sda_i,
    output logic [N_I2C_SLV-1:0]              i2c_slv_sda_o,
    output logic [N_I2C_SLV-1:0]              i2c_slv_sda_oe_o,

    output logic [N_SPI-1:0]                  spi_clk_o,
    output logic [N_SPI-1:0][3:0]             spi_csn_o,
    output logic [N_SPI-1:0][3:0]             spi_oen_o,
    output logic [N_SPI-1:0][3:0]             spi_sdo_o,
    input logic [N_SPI-1:0][3:0]              spi_sdi_i,

    input logic                               spi_clk_i,
    input logic                               spi_csn_i,
    output logic [3:0]                        spi_oen_slv_o,
    output logic [3:0]                        spi_sdo_slv_o,
    input logic [3:0]                         spi_sdi_slv_i,

    //inter-socket mux signals
    output logic                              sel_spi_dir_o,
	output logic                              sel_i2c_mux_o,

    // CLUSTER
    output logic                              cluster_rst_reg_no,
    input logic                               cluster_busy_i,
    output logic                              cluster_irq_o,

    output logic                              cluster_fetch_enable_o,
    output logic [63:0]                       cluster_boot_addr_o,
    output logic                              cluster_test_en_o,
    output logic                              cluster_pow_o,
    output logic                              cluster_byp_o,

    // EVENT BUS
    output logic [BUFFER_WIDTH-1:0]           cluster_events_wt_o,
    input logic [BUFFER_WIDTH-1:0]            cluster_events_rp_i,
    output logic [EVNT_WIDTH-1:0]             cluster_events_da_o,

    output logic                              dma_pe_evt_ack_o,
    input logic                               dma_pe_evt_valid_i,

    output logic                              dma_pe_irq_ack_o,
    input logic                               dma_pe_irq_valid_i,

    output logic                              pf_evt_ack_o,
    input logic                               pf_evt_valid_i,

    // AXI4 SLAVE
    input logic [LOG_DEPTH:0]                        async_data_slave_aw_wptr_i,
    input logic [2**LOG_DEPTH-1:0][C2S_AW_WIDTH-1:0] async_data_slave_aw_data_i,
    output logic [LOG_DEPTH:0]                       async_data_slave_aw_rptr_o,

    // READ ADDRESS CHANNEL
    input logic [LOG_DEPTH:0]                        async_data_slave_ar_wptr_i,
    input logic [2**LOG_DEPTH-1:0][C2S_AR_WIDTH-1:0] async_data_slave_ar_data_i,
    output logic [LOG_DEPTH:0]                       async_data_slave_ar_rptr_o,

    // WRITE DATA CHANNEL
    input logic [LOG_DEPTH:0]                        async_data_slave_w_wptr_i,
    input logic [2**LOG_DEPTH-1:0][C2S_W_WIDTH-1:0]  async_data_slave_w_data_i,
    output logic [LOG_DEPTH:0]                       async_data_slave_w_rptr_o,

    // READ DATA CHANNEL
    output logic [LOG_DEPTH:0]                       async_data_slave_r_wptr_o,
    output logic [2**LOG_DEPTH-1:0][C2S_R_WIDTH-1:0] async_data_slave_r_data_o,
    input logic [LOG_DEPTH:0]                        async_data_slave_r_rptr_i,

    // WRITE RESPONSE CHANNEL
    output logic [LOG_DEPTH:0]                       async_data_slave_b_wptr_o,
    output logic [2**LOG_DEPTH-1:0][C2S_B_WIDTH-1:0] async_data_slave_b_data_o,
    input logic [LOG_DEPTH:0]                        async_data_slave_b_rptr_i,

    // AXI4 MASTER
    output logic [LOG_DEPTH:0]                        async_data_master_aw_wptr_o,
    output logic [2**LOG_DEPTH-1:0][S2C_AW_WIDTH-1:0] async_data_master_aw_data_o,
    input logic [LOG_DEPTH:0]                         async_data_master_aw_rptr_i,

    // READ ADDRESS CHANNEL
    output logic [LOG_DEPTH:0]                        async_data_master_ar_wptr_o,
    output logic [2**LOG_DEPTH-1:0][S2C_AR_WIDTH-1:0] async_data_master_ar_data_o,
    input logic [LOG_DEPTH:0]                         async_data_master_ar_rptr_i,

    // WRITE DATA CHANNEL
    output logic [LOG_DEPTH:0]                        async_data_master_w_wptr_o,
    output logic [2**LOG_DEPTH-1:0][S2C_W_WIDTH-1:0]  async_data_master_w_data_o,
    input logic [LOG_DEPTH:0]                         async_data_master_w_rptr_i,

    // READ DATA CHANNEL
    input logic [LOG_DEPTH:0]                       async_data_master_r_wptr_i,
    input logic [2**LOG_DEPTH-1:0][S2C_R_WIDTH-1:0] async_data_master_r_data_i,
    output logic [LOG_DEPTH:0]                      async_data_master_r_rptr_o,

    // WRITE RESPONSE CHANNEL
    input logic [LOG_DEPTH:0]                       async_data_master_b_wptr_i,
    input logic [2**LOG_DEPTH-1:0][S2C_B_WIDTH-1:0] async_data_master_b_data_i,
    output logic [LOG_DEPTH:0]                      async_data_master_b_rptr_o,

    // AXI interfaces to outside of control pulp
    AXI_BUS.Slave                            axi_ext_slv,  // from nci_cp_top
    AXI_BUS.Master                           axi_ext_mst,

    XBAR_TCDM_BUS.Master                     tcdm_interleaved_l2_bus[N_L2_BANKS],
    XBAR_TCDM_BUS.Master                     tcdm_private_l2_bus[N_L2_BANKS_PRI],

    APB_BUS.Master                           apb_serial_link_bus,
    APB_BUS.Master                           apb_clk_ctrl_bus,
    APB_BUS.Master                           apb_pad_cfg_bus,
    output logic                             clk_mux_sel_o
);



    pulp_soc #(/*AUTOINSTPARAM*/
        .CORE_TYPE               ( CORE_TYPE             ),
        .PULP_XPULP              ( PULP_XPULP            ),
        .USE_FPU                 ( USE_FPU               ),
        .USE_HWPE                ( USE_HWPE              ),
        .NB_HWPE_PORTS           ( 4                     ),
        .USE_CLUSTER_EVENT       ( 1                     ),
        .ZFINX                   ( ZFINX                 ),
        .N_PERF_COUNTERS         ( N_PERF_COUNTERS       ),
        .NB_CORES                ( NB_CL_CORES           ),
        .AXI_ADDR_WIDTH          ( AXI_ADDR_WIDTH        ),
        .AXI_DATA_IN_WIDTH       ( AXI_DATA_IN_WIDTH     ),
        .AXI_DATA_OUT_S2C_WIDTH  ( AXI_DATA_OUT_S2C_WIDTH),
        .AXI_DATA_OUT_S2E_WIDTH  ( AXI_DATA_OUT_S2E_WIDTH),
        .AXI_ID_IN_WIDTH         ( AXI_ID_IN_WIDTH       ),
        .AXI_ID_OUT_S2C_WIDTH    ( AXI_ID_OUT_S2C_WIDTH  ),
        .AXI_ID_OUT_S2E_WIDTH    ( AXI_ID_OUT_S2E_WIDTH  ),
        .AXI_STRB_WIDTH_IN       ( AXI_STRB_IN_WIDTH     ),
        .AXI_STRB_WIDTH_S2C_OUT  ( AXI_STRB_OUT_S2C_WIDTH),
        .AXI_STRB_WIDTH_S2E_OUT  ( AXI_STRB_OUT_S2E_WIDTH),
        .AXI_USER_WIDTH          ( AXI_USER_WIDTH        ),
        .C2S_AW_WIDTH            ( C2S_AW_WIDTH          ),
        .C2S_W_WIDTH             ( C2S_W_WIDTH           ),
        .C2S_B_WIDTH             ( C2S_B_WIDTH           ),
        .C2S_AR_WIDTH            ( C2S_AR_WIDTH          ),
        .C2S_R_WIDTH             ( C2S_R_WIDTH           ),
        .S2C_AW_WIDTH            ( S2C_AW_WIDTH          ),
        .S2C_W_WIDTH             ( S2C_W_WIDTH           ),
        .S2C_B_WIDTH             ( S2C_B_WIDTH           ),
        .S2C_AR_WIDTH            ( S2C_AR_WIDTH          ),
        .S2C_R_WIDTH             ( S2C_R_WIDTH           ),
        .EVNT_WIDTH              ( EVNT_WIDTH            ),
        .BUFFER_WIDTH            ( BUFFER_WIDTH          ),
        .NGPIO                   ( NGPIO                 ),
        .NBIT_PADCFG             ( NBIT_PADCFG           ),
        .N_UART                  ( N_UART                ),
        .N_SPI                   ( N_SPI                 ),
        .N_I2C                   ( N_I2C                 ),
        .N_I2C_SLV               ( N_I2C_SLV             ),
        .N_L2_BANKS              ( N_L2_BANKS            ),
        .N_L2_BANKS_PRI          ( N_L2_BANKS_PRI        ),
        .L2_BANK_SIZE            ( L2_BANK_SIZE          ),
        .L2_BANK_SIZE_PRI        ( L2_BANK_SIZE_PRI      ),
        .L2_SIZE                 ( L2_SIZE               ),
        .NUM_INTERRUPTS          ( NUM_INTERRUPTS        ),
        .SIM_STDOUT              ( SIM_STDOUT            ),
        .MACRO_ROM               ( MACRO_ROM             ),
        .USE_CLUSTER             ( USE_CLUSTER           )
    ) pulp_soc_i (
        .cluster_dbg_irq_valid_o ( dbg_irq_valid_o ),
        .axi_ext_slv             ( axi_ext_slv     ),
        .axi_ext_mst             ( axi_ext_mst     ),
        .s_mem_l2_bus            ( tcdm_interleaved_l2_bus ),
        .s_mem_l2_pri_bus        ( tcdm_private_l2_bus ),

        // from_cluster and to_cluster AXI ports
        .async_data_slave_aw_wptr_i   ( async_data_slave_aw_wptr_i ),
        .async_data_slave_aw_rptr_o   ( async_data_slave_aw_rptr_o ),
        .async_data_slave_aw_data_i   ( async_data_slave_aw_data_i ),

        .async_data_slave_ar_wptr_i   ( async_data_slave_ar_wptr_i ),
        .async_data_slave_ar_rptr_o   ( async_data_slave_ar_rptr_o ),
        .async_data_slave_ar_data_i   ( async_data_slave_ar_data_i ),

        .async_data_slave_w_wptr_i    ( async_data_slave_w_wptr_i ),
        .async_data_slave_w_data_i    ( async_data_slave_w_data_i ),
        .async_data_slave_w_rptr_o    ( async_data_slave_w_rptr_o ),

        .async_data_slave_r_wptr_o    ( async_data_slave_r_wptr_o ),
        .async_data_slave_r_rptr_i    ( async_data_slave_r_rptr_i ),
        .async_data_slave_r_data_o    ( async_data_slave_r_data_o ),

        .async_data_slave_b_wptr_o    ( async_data_slave_b_wptr_o ),
        .async_data_slave_b_rptr_i    ( async_data_slave_b_rptr_i ),
        .async_data_slave_b_data_o    ( async_data_slave_b_data_o ),

        .async_data_master_aw_wptr_o  ( async_data_master_aw_wptr_o ),
        .async_data_master_aw_rptr_i  ( async_data_master_aw_rptr_i ),
        .async_data_master_aw_data_o  ( async_data_master_aw_data_o ),

        .async_data_master_ar_wptr_o  ( async_data_master_ar_wptr_o ),
        .async_data_master_ar_rptr_i  ( async_data_master_ar_rptr_i ),
        .async_data_master_ar_data_o  ( async_data_master_ar_data_o ),

        .async_data_master_w_wptr_o   ( async_data_master_w_wptr_o ),
        .async_data_master_w_data_o   ( async_data_master_w_data_o ),
        .async_data_master_w_rptr_i   ( async_data_master_w_rptr_i ),

        .async_data_master_r_wptr_i   ( async_data_master_r_wptr_i ),
        .async_data_master_r_rptr_o   ( async_data_master_r_rptr_o ),
        .async_data_master_r_data_i   ( async_data_master_r_data_i ),

        .async_data_master_b_wptr_i   ( async_data_master_b_wptr_i ),
        .async_data_master_b_rptr_o   ( async_data_master_b_rptr_o ),
        .async_data_master_b_data_i   ( async_data_master_b_data_i ),

        // Outputs
        .cluster_fetch_enable_o(cluster_fetch_enable_o),
        .cluster_boot_addr_o(cluster_boot_addr_o[63:0]),
        .cluster_test_en_o (cluster_test_en_o),
        .cluster_pow_o     (cluster_pow_o),
        .cluster_byp_o     (cluster_byp_o),
        .cluster_rst_reg_no(cluster_rst_reg_no),
        .cluster_irq_o     (cluster_irq_o),
        .cluster_events_wt_o(cluster_events_wt_o[BUFFER_WIDTH-1:0]),
        .cluster_events_da_o(cluster_events_da_o[EVNT_WIDTH-1:0]),
        .dma_pe_evt_ack_o  (dma_pe_evt_ack_o),
        .dma_pe_irq_ack_o  (dma_pe_irq_ack_o),
        .pf_evt_ack_o      (pf_evt_ack_o),
        .gpio_out_o        (gpio_out_o[NGPIO-1:0]),
        .gpio_dir_o        (gpio_dir_o[NGPIO-1:0]),
        .gpio_cfg_o        (gpio_cfg_o),
        .uart_tx_o         (uart_tx_o),
        .timer_ch0_o       (timer_ch0_o[3:0]),
        .timer_ch1_o       (timer_ch1_o[3:0]),
        .timer_ch2_o       (timer_ch2_o[3:0]),
        .timer_ch3_o       (timer_ch3_o[3:0]),
        .i2c_scl_o         (i2c_scl_o[N_I2C-1:0]),
        .i2c_scl_oe_o      (i2c_scl_oe_o[N_I2C-1:0]),
        .i2c_sda_o         (i2c_sda_o[N_I2C-1:0]),
        .i2c_sda_oe_o      (i2c_sda_oe_o[N_I2C-1:0]),
        .i2c_slv_scl_o     (i2c_slv_scl_o[N_I2C_SLV-1:0]),
        .i2c_slv_scl_oe_o  (i2c_slv_scl_oe_o[N_I2C_SLV-1:0]),
        .i2c_slv_sda_o     (i2c_slv_sda_o[N_I2C_SLV-1:0]),
        .i2c_slv_sda_oe_o  (i2c_slv_sda_oe_o[N_I2C_SLV-1:0]),
        .spi_clk_o         (spi_clk_o[N_SPI-1:0]),
        .spi_sdo_o         (spi_sdo_o/*[N_SPI-1:0][3:0]*/),
        .spi_csn_o         (spi_csn_o/*[N_SPI-1:0][3:0]*/),
        .spi_oen_o         (spi_oen_o/*[N_SPI-1:0][3:0]*/),
        .spi_oen_slv_o     (spi_oen_slv_o/*[3:0]*/),
        .spi_sdo_slv_o     (spi_sdo_slv_o/*[3:0]*/),
        .sel_spi_dir_o     (sel_spi_dir_o),
        .sel_i2c_mux_o     (sel_i2c_mux_o),
        .jtag_tdo_o        (jtag_tdo_o),
        .soc_clk_i         (soc_clk_i),
        .wdt_alert_o       (wdt_alert_o),

        // Inputs
        .ref_clk_i         (ref_clk_i),
        .periph_clk_i      (periph_clk_i),
        .test_clk_i        (test_clk_i),
        .soc_rst_ni        (soc_rst_ni),
        .cluster_rst_ni    (cluster_rst_ni),
        .dft_test_mode_i   (dft_test_mode_i),
        .dft_cg_enable_i   (dft_cg_enable_i),
        .mode_select_i     (mode_select_i),
        .bootsel_valid_i   (bootsel_valid_i),
        .bootsel_i         (bootsel_i[2:0]),
        .fc_fetch_en_valid_i(fc_fetch_en_valid_i),
        .fc_fetch_en_i     (fc_fetch_en_i),
        .cluster_events_rp_i(cluster_events_rp_i[BUFFER_WIDTH-1:0]),
        .cluster_busy_i    (cluster_busy_i),
        .dma_pe_evt_valid_i(dma_pe_evt_valid_i),
        .dma_pe_irq_valid_i(dma_pe_irq_valid_i),
        .pf_evt_valid_i    (pf_evt_valid_i),
        .gpio_in_i         (gpio_in_i[NGPIO-1:0]),
        .uart_rx_i         (uart_rx_i),
        .i2c_scl_i         (i2c_scl_i[N_I2C-1:0]),
        .i2c_sda_i         (i2c_sda_i[N_I2C-1:0]),
        .i2c_slv_scl_i     (i2c_slv_scl_i[N_I2C_SLV-1:0]),
        .i2c_slv_sda_i     (i2c_slv_sda_i[N_I2C_SLV-1:0]),
        .spi_sdi_i         (spi_sdi_i/*[N_SPI-1:0][3:0]*/),
        .spi_sdi_slv_i     (spi_sdi_slv_i/*[3:0]*/),
        .spi_csn_i         (spi_csn_i),
        .spi_clk_i         (spi_clk_i),
        .jtag_tck_i        (jtag_tck_i),
        .jtag_trst_ni      (jtag_trst_ni),
        .jtag_tms_i        (jtag_tms_i),
        .jtag_tdi_i        (jtag_tdi_i),
        .irq_ext_i,
        .wdt_alert_clear_i (wdt_alert_clear_i),
        .apb_serial_link_bus (apb_serial_link_bus),
        .apb_clk_ctrl_bus  (apb_clk_ctrl_bus),
        .apb_pad_cfg_bus   (apb_pad_cfg_bus),
        .clk_mux_sel_o     (clk_mux_sel_o)
    );

endmodule

// Local Variables:
// verilog-library-flags:("-y . -y ../../ips/pulp_soc/rtl/pulp_soc/")
// End:

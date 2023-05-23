// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


module pad_frame_top import control_pulp_pkg::*;
    (

        input logic [31:0][5:0]       pad_cfg_i ,

        // SYS CLOCK
        output logic                  sys_clk_o ,

        // REF CLOCK
        output logic                  ref_clk_o ,

        // RESET SIGNALS
        output logic                  rstn_o ,

        // JTAG SIGNALS
        output logic                  jtag_tck_o ,
        output logic                  jtag_tdi_o ,
        input logic                   jtag_tdo_i ,
        output logic                  jtag_tms_o ,
        output logic                  jtag_trst_o ,

        input logic [N_SPI-1:0][3:0]  oe_qspi_sdio_i ,
        input logic [N_SPI-1:0][1:0]  oe_qspi_csn_i ,
        input logic [N_SPI-1:0]       oe_qspi_sck_i ,
        input logic                   oe_i2c0_sda_i , // i2c_smbus_os_mst
        input logic                   oe_i2c0_scl_i ,
        input logic                   oe_i2c1_sda_i , // i2c_smbus_bios_mst
        input logic                   oe_i2c1_scl_i ,
        input logic                   oe_i2c2_sda_i , // i2c_bmc_mst
        input logic                   oe_i2c2_scl_i ,
        input logic                   oe_i2c3_sda_i , // i2c_rtc_mst
        input logic                   oe_i2c3_scl_i ,
        input logic                   oe_i2c4_sda_i , // i2c_pcie_pnp_mst
        input logic                   oe_i2c4_scl_i ,
        input logic                   oe_i2c5_sda_i , // i2c_pmb_vrm_mst[0]
        input logic                   oe_i2c5_scl_i ,
        input logic                   oe_i2c6_sda_i , // i2c_pmb_vrm_mst[1]
        input logic                   oe_i2c6_scl_i ,
        input logic                   oe_i2c7_sda_i , // i2c_pmb_vrm_mst[2]
        input logic                   oe_i2c7_scl_i ,
        input logic                   oe_i2c8_sda_i , // i2c_pmb_vrm_mst[3]
        input logic                   oe_i2c8_scl_i ,
        input logic                   oe_i2c9_sda_i , // i2c_pmb_vrm_mst[4]
        input logic                   oe_i2c9_scl_i ,
        input logic                   oe_i2c10_sda_i , // i2c_pmb_vrm_mst[5]
        input logic                   oe_i2c10_scl_i ,
        input logic                   oe_i2c11_sda_i , // i2c_pmb_vrm_mst[6]
        input logic                   oe_i2c11_scl_i ,
        input logic [N_UART-1:0]      oe_uart_rx_i ,
        input logic [N_UART-1:0]      oe_uart_tx_i ,

        // INPUTS SIGNALS TO THE PADS
        input logic [N_SPI-1:0][3:0]  out_qspi_sdio_i ,
        input logic [N_SPI-1:0][1:0]  out_qspi_csn_i ,
        input logic [N_SPI-1:0]       out_qspi_sck_i ,
        input logic                   out_i2c0_sda_i , // i2c_smbus_os_mst
        input logic                   out_i2c0_scl_i ,
        input logic                   out_i2c1_sda_i , // i2c_smbus_bios_mst
        input logic                   out_i2c1_scl_i ,
        input logic                   out_i2c2_sda_i , // i2c_bmc_mst
        input logic                   out_i2c2_scl_i ,
        input logic                   out_i2c3_sda_i , // i2c_rtc_mst
        input logic                   out_i2c3_scl_i ,
        input logic                   out_i2c4_sda_i , // i2c_pcie_pnp_mst
        input logic                   out_i2c4_scl_i ,
        input logic                   out_i2c5_sda_i , // i2c_pmb_vrm_mst[0]
        input logic                   out_i2c5_scl_i ,
        input logic                   out_i2c6_sda_i , // i2c_pmb_vrm_mst[1]
        input logic                   out_i2c6_scl_i ,
        input logic                   out_i2c7_sda_i , // i2c_pmb_vrm_mst[2]
        input logic                   out_i2c7_scl_i ,
        input logic                   out_i2c8_sda_i , // i2c_pmb_vrm_mst[3]
        input logic                   out_i2c8_scl_i ,
        input logic                   out_i2c9_sda_i , // i2c_pmb_vrm_mst[4]
        input logic                   out_i2c9_scl_i ,
        input logic                   out_i2c10_sda_i , // i2c_pmb_vrm_mst[5]
        input logic                   out_i2c10_scl_i ,
        input logic                   out_i2c11_sda_i , // i2c_pmb_vrm_mst[6]
        input logic                   out_i2c11_scl_i ,
        input logic [N_UART-1:0]      out_uart_rx_i ,
        input logic [N_UART-1:0]      out_uart_tx_i ,

        // OUTPUT SIGNALS FROM THE PADS
        output logic [N_SPI-1:0][3:0] in_qspi_sdio_o ,
        output logic [N_SPI-1:0][1:0] in_qspi_csn_o ,
        output logic [N_SPI-1:0]      in_qspi_sck_o ,
        output logic                  in_i2c0_sda_o , // i2c_smbus_os_mst
        output logic                  in_i2c0_scl_o ,
        output logic                  in_i2c1_sda_o , // i2c_smbus_bios_mst
        output logic                  in_i2c1_scl_o ,
        output logic                  in_i2c2_sda_o , // i2c_bmc_mst
        output logic                  in_i2c2_scl_o ,
        output logic                  in_i2c3_sda_o , // i2c_rtc_mst
        output logic                  in_i2c3_scl_o ,
        output logic                  in_i2c4_sda_o , // i2c_pcie_pnp_mst
        output logic                  in_i2c4_scl_o ,
        output logic                  in_i2c5_sda_o , // i2c_pmb_vrm_mst[0]
        output logic                  in_i2c5_scl_o ,
        output logic                  in_i2c6_sda_o , // i2c_pmb_vrm_mst[1]
        output logic                  in_i2c6_scl_o ,
        output logic                  in_i2c7_sda_o , // i2c_pmb_vrm_mst[2]
        output logic                  in_i2c7_scl_o ,
        output logic                  in_i2c8_sda_o , // i2c_pmb_vrm_mst[3]
        output logic                  in_i2c8_scl_o ,
        output logic                  in_i2c9_sda_o , // i2c_pmb_vrm_mst[4]
        output logic                  in_i2c9_scl_o ,
        output logic                  in_i2c10_sda_o , // i2c_pmb_vrm_mst[5]
        output logic                  in_i2c10_scl_o ,
        output logic                  in_i2c11_sda_o , // i2c_pmb_vrm_mst[6]
        output logic                  in_i2c11_scl_o ,
        output logic [N_UART-1:0]     in_uart_rx_o ,
        output logic [N_UART-1:0]     in_uart_tx_o ,

        output logic                  bootsel_valid_o,
        output logic [1:0]            bootsel_o ,
        output logic                  fc_fetch_en_valid_o,
        output logic                  fc_fetch_en_o,

        // EXT CHIP TP              PADS
        inout wire [N_SPI-2:0][3:0]   pad_qspi_sdio ,
        inout wire [N_SPI-2:0][1:0]   pad_qspi_csn ,
        inout wire [N_SPI-2:0]        pad_qspi_sck ,
        inout wire [3:0]              pad_spi_dpi_sdio,
        inout wire [1:0]              pad_spi_dpi_csn,
        inout wire                    pad_spi_dpi_sck,
        inout wire [3:0]              pad_spi_intr_sckt_sdio,
        inout wire [1:0]              pad_spi_intr_sckt_csn,
        inout wire                    pad_spi_intr_sckt_sck,
        inout wire                    pad_i2c0_sda , // i2c_smbus_os_mst
        inout wire                    pad_i2c0_scl ,
        inout wire                    pad_i2c1_sda , // i2c_smbus_bios_mst
        inout wire                    pad_i2c1_scl ,
        inout wire                    pad_i2c2_sda , // i2c_bmc_mst
        inout wire                    pad_i2c2_scl ,
        inout wire                    pad_i2c3_sda , // i2c_rtc_mst
        inout wire                    pad_i2c3_scl ,
        inout wire                    pad_i2c4_sda , // i2c_pcie_pnp_mst
        inout wire                    pad_i2c4_scl ,
        inout wire                    pad_i2c5_sda , // i2c_pmb_vrm_mst[0]
        inout wire                    pad_i2c5_scl ,
        inout wire                    pad_i2c6_sda , // i2c_pmb_vrm_mst[1]
        inout wire                    pad_i2c6_scl ,
        inout wire                    pad_i2c7_sda , // i2c_pmb_vrm_mst[2]
        inout wire                    pad_i2c7_scl ,
        inout wire                    pad_i2c8_sda , // i2c_pmb_vrm_mst[3]
        inout wire                    pad_i2c8_scl ,
        inout wire                    pad_i2c9_sda , // i2c_pmb_vrm_mst[4]
        inout wire                    pad_i2c9_scl ,
        inout wire                    pad_i2c10_sda , // i2c_pmb_vrm_mst[5]
        inout wire                    pad_i2c10_scl ,
        inout wire                    pad_i2c11_sda , // i2c_pmb_vrm_mst[6]
        inout wire                    pad_i2c11_scl ,
        inout wire [N_UART-1:0]       pad_uart_rx ,
        inout wire [N_UART-1:0]       pad_uart_tx ,

        inout wire                    pad_reset_n ,
        inout wire                    pad_bootsel_valid,
        inout wire                    pad_bootsel0 ,
        inout wire                    pad_bootsel1 ,
        inout wire                    pad_jtag_tck ,
        inout wire                    pad_jtag_tdi ,
        inout wire                    pad_jtag_tdo ,
        inout wire                    pad_jtag_tms ,
        inout wire                    pad_jtag_trst ,
        inout wire                    pad_xtal_in ,
        inout wire                    pad_sysclk_in ,

        inout wire                    pad_fc_fetch_en_valid,
        inout wire                    pad_fc_fetch_en
    );

    // Temporary output enable signals for sck
    logic [N_SPI-1:0]                   qspi_oe_t;
    logic                               spi_intr_sckt_oe_t;

    // Temporary input signals for spi masters
    logic [N_SPI-1:0][3:0]              in_qspi_sdio_o_t1;
    logic [N_SPI-1:0][1:0]              in_qspi_csn_o_t1;
    logic [N_SPI-1:0]                   in_qspi_sck_o_t1;

    logic [3:0]                         in_qspi_sdio_o_t2;
    logic [1:0]                         in_qspi_csn_o_t2;
    logic                               in_qspi_sck_o_t2;

    for (genvar i = 0; i < N_SPI; i++) begin: in_qspi_sdio_assign
      if (i==0) begin
        assign in_qspi_sdio_o[i] = in_qspi_sdio_o_t1[i] | in_qspi_sdio_o_t2;
      end else begin
        assign in_qspi_sdio_o[i] = in_qspi_sdio_o_t1[i];
      end
    end

    for (genvar i = 0; i < N_SPI; i++) begin: in_qspi_csn_assign
      if (i==0) begin
        assign in_qspi_csn_o[i] = in_qspi_csn_o_t1[i] & in_qspi_csn_o_t2;
      end else begin
        assign in_qspi_csn_o[i] = in_qspi_csn_o_t1[i];
      end
    end

    for (genvar i = 0; i < N_SPI; i++) begin: in_qspi_sck_assign
      if (i==0) begin
        assign in_qspi_sck_o[i] = in_qspi_sck_o_t1[i] | in_qspi_sck_o_t2;
      end else begin
        assign in_qspi_sck_o[i] = in_qspi_sck_o_t1[i];
      end
    end

    for (genvar i = 0; i < N_SPI; i++) begin: qspi_csn_oe
      assign qspi_oe_t[i] = out_qspi_csn_i[i][0] & out_qspi_csn_i[i][1];
    end

    assign spi_intr_sckt_oe_t = out_qspi_csn_i[5][0] & out_qspi_csn_i[5][1];

    /////////////////////////////////////////////////////////////////////
    // SPI MASTER PAD assign (SPI n°5 is assigned to inter-socket pad) //
    /////////////////////////////////////////////////////////////////////

    for (genvar i = 0; i < 5; i++) begin: pad_func_pd_spi_sdio0
      for (genvar j = 0; j < 4; j++) begin: pad_func_pd_spi_sdio_i
        pad_functional_pd padinst_qspi_sdio ( .OEN(~oe_qspi_sdio_i[i][j]), .I(out_qspi_sdio_i[i][j]), .O(in_qspi_sdio_o_t1[i][j]), .PAD(pad_qspi_sdio[i][j]), .PEN(1'b0) );
      end
    end // block: pad_func_pd_spi_sdio0

    for (genvar i = 6; i < N_SPI; i++) begin: pad_func_pd_spi_sdio1
      for (genvar j = 0; j < 4; j++) begin: pad_func_pd_spi_sdio_i
        pad_functional_pd padinst_qspi_sdio ( .OEN(~oe_qspi_sdio_i[i][j]), .I(out_qspi_sdio_i[i][j]), .O(in_qspi_sdio_o_t1[i][j]), .PAD(pad_qspi_sdio[i-1][j]), .PEN(1'b0) );
      end
    end // block: pad_func_pd_spi_sdio1

    for (genvar i = 0; i < 5; i++) begin: pad_func_pd_spi_csn0
      for (genvar j = 0; j < 2; j++ ) begin: pad_func_pd_spi_csn_i
        pad_functional_pu padinst_qspi_csn ( .OEN(out_qspi_csn_i[i][j]),.I(1'b0), .O(in_qspi_csn_o_t1[i][j]), .PAD(pad_qspi_csn[i][j]), .PEN(1'b0) );
     end
    end // block: pad_func_pd_spi_csn0

    for (genvar i = 6; i < N_SPI; i++) begin: pad_func_pd_spi_csn1
      for (genvar j = 0; j < 2; j++ ) begin: pad_func_pd_spi_csn_i
        pad_functional_pu padinst_qspi_csn ( .OEN(out_qspi_csn_i[i][j]),.I(1'b0), .O(in_qspi_csn_o_t1[i][j]), .PAD(pad_qspi_csn[i-1][j]), .PEN(1'b0) );
     end
    end // block: pad_func_pd_spi_csn1

    for (genvar i = 0; i < 5; i++) begin: pad_func_pd_spi_sck0
        pad_functional_pd padinst_qspi_sck ( .OEN(qspi_oe_t[i]), .I(out_qspi_sck_i[i]), .O(in_qspi_sck_o_t1[i]), .PAD(pad_qspi_sck[i]), .PEN(1'b0) );
    end

    for (genvar i = 6; i < N_SPI; i++) begin: pad_func_pd_spi_sck1
        pad_functional_pd padinst_qspi_sck ( .OEN(qspi_oe_t[i]), .I(out_qspi_sck_i[i]), .O(in_qspi_sck_o_t1[i]), .PAD(pad_qspi_sck[i-1]), .PEN(1'b0) );
    end

    /////////////////////////////////
    // Inter-socket SPI PAD assign //
    /////////////////////////////////

    for (genvar i = 0; i < 4; i++ ) begin: pad_func_spi_intr_sckt_sdio
      pad_functional_pd padinst_spi_intr_sckt_sdio ( .OEN(~oe_qspi_sdio_i[5][i] ), .I(out_qspi_sdio_i[5][i] ), .O(in_qspi_sdio_o_t1[5][i] ), .PAD(pad_spi_intr_sckt_sdio[i]), .PEN(1'b0) );
    end

    for (genvar i = 0; i < 2; i++ ) begin: pad_func_spi_intr_sckt_csn
      pad_functional_pu padinst_spi_intr_sckt_csn  ( .OEN(out_qspi_csn_i[5][i] ), .I(1'b0), .O(in_qspi_csn_o_t1[5][i] ), .PAD(pad_spi_intr_sckt_csn[i] ), .PEN(1'b0) );
    end

    pad_functional_pd padinst_spi_intr_sckt_sck  ( .OEN(spi_intr_sckt_oe_t ), .I(out_qspi_sck_i[5] ), .O(in_qspi_sck_o_t1[5] ), .PAD(pad_spi_intr_sckt_sck ), .PEN(1'b0) );

    ///////////////////////////////////////
    // DPI SPI assign, for FREERTOS test //
    ///////////////////////////////////////

    for (genvar i = 0; i < 4; i++ ) begin: pad_func_spi_dpi_sdio
      pad_functional_pd padinst_spi_dpi_sdio ( .OEN(~oe_qspi_sdio_i[0][i] ), .I(out_qspi_sdio_i[0][i] ), .O(in_qspi_sdio_o_t2[i] ), .PAD(pad_spi_dpi_sdio[i]), .PEN(1'b0) );
    end

    for (genvar i = 0; i < 2; i++ ) begin: pad_func_spi_dpi_csn
      pad_functional_pd padinst_spi_dpi_csn  ( .OEN(~oe_qspi_csn_i[0][i] ), .I(out_qspi_csn_i[0][i] ), .O(in_qspi_csn_o_t2[i] ), .PAD(pad_spi_dpi_csn[i] ), .PEN(1'b0) );
    end

    pad_functional_pd padinst_spi_dpi_sck  ( .OEN(~oe_qspi_sck_i[0] ), .I(out_qspi_sck_i[0] ), .O(in_qspi_sck_o_t2 ), .PAD(pad_spi_dpi_sck ), .PEN(1'b0) );

    for (genvar i = 0; i < N_UART; i++) begin: pad_func_pu_uart
      pad_functional_pu padinst_uart_rx  (.OEN(~oe_uart_rx_i[i]   ), .I(out_uart_rx_i[i]   ), .O(in_uart_rx_o[i]   ), .PAD(pad_uart_rx[i]   ), .PEN(1'b1 ) );
      pad_functional_pu padinst_uart_tx  (.OEN(~oe_uart_tx_i[i]   ), .I(out_uart_tx_i[i]   ), .O(in_uart_tx_o[i]   ), .PAD(pad_uart_tx[i]   ), .PEN(1'b1 ) );
    end

    pad_functional_pu padinst_i2c0_sda   (.OEN(~oe_i2c0_sda_i  ), .I(out_i2c0_sda_i  ), .O(in_i2c0_sda_o  ), .PAD(pad_i2c0_sda  ), .PEN(~pad_cfg_i[7][0] ) );
    pad_functional_pu padinst_i2c0_scl   (.OEN(~oe_i2c0_scl_i  ), .I(out_i2c0_scl_i  ), .O(in_i2c0_scl_o  ), .PAD(pad_i2c0_scl  ), .PEN(~pad_cfg_i[8][0] ) );
    pad_functional_pu padinst_i2c1_sda   (.OEN(~oe_i2c1_sda_i  ), .I(out_i2c1_sda_i  ), .O(in_i2c1_sda_o  ), .PAD(pad_i2c1_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c1_scl   (.OEN(~oe_i2c1_scl_i  ), .I(out_i2c1_scl_i  ), .O(in_i2c1_scl_o  ), .PAD(pad_i2c1_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c2_sda   (.OEN(~oe_i2c2_sda_i  ), .I(out_i2c2_sda_i  ), .O(in_i2c2_sda_o  ), .PAD(pad_i2c2_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c2_scl   (.OEN(~oe_i2c2_scl_i  ), .I(out_i2c2_scl_i  ), .O(in_i2c2_scl_o  ), .PAD(pad_i2c2_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c3_sda   (.OEN(~oe_i2c3_sda_i  ), .I(out_i2c3_sda_i  ), .O(in_i2c3_sda_o  ), .PAD(pad_i2c3_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c3_scl   (.OEN(~oe_i2c3_scl_i  ), .I(out_i2c3_scl_i  ), .O(in_i2c3_scl_o  ), .PAD(pad_i2c3_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c4_sda   (.OEN(~oe_i2c4_sda_i  ), .I(out_i2c4_sda_i  ), .O(in_i2c4_sda_o  ), .PAD(pad_i2c4_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c4_scl   (.OEN(~oe_i2c4_scl_i  ), .I(out_i2c4_scl_i  ), .O(in_i2c4_scl_o  ), .PAD(pad_i2c4_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c5_sda   (.OEN(~oe_i2c5_sda_i  ), .I(out_i2c5_sda_i  ), .O(in_i2c5_sda_o  ), .PAD(pad_i2c5_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c5_scl   (.OEN(~oe_i2c5_scl_i  ), .I(out_i2c5_scl_i  ), .O(in_i2c5_scl_o  ), .PAD(pad_i2c5_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c6_sda   (.OEN(~oe_i2c6_sda_i  ), .I(out_i2c6_sda_i  ), .O(in_i2c6_sda_o  ), .PAD(pad_i2c6_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c6_scl   (.OEN(~oe_i2c6_scl_i  ), .I(out_i2c6_scl_i  ), .O(in_i2c6_scl_o  ), .PAD(pad_i2c6_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c7_sda   (.OEN(~oe_i2c7_sda_i  ), .I(out_i2c7_sda_i  ), .O(in_i2c7_sda_o  ), .PAD(pad_i2c7_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c7_scl   (.OEN(~oe_i2c7_scl_i  ), .I(out_i2c7_scl_i  ), .O(in_i2c7_scl_o  ), .PAD(pad_i2c7_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c8_sda   (.OEN(~oe_i2c8_sda_i  ), .I(out_i2c8_sda_i  ), .O(in_i2c8_sda_o  ), .PAD(pad_i2c8_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c8_scl   (.OEN(~oe_i2c8_scl_i  ), .I(out_i2c8_scl_i  ), .O(in_i2c8_scl_o  ), .PAD(pad_i2c8_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c9_sda   (.OEN(~oe_i2c9_sda_i  ), .I(out_i2c9_sda_i  ), .O(in_i2c9_sda_o  ), .PAD(pad_i2c9_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c9_scl   (.OEN(~oe_i2c9_scl_i  ), .I(out_i2c9_scl_i  ), .O(in_i2c9_scl_o  ), .PAD(pad_i2c9_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c10_sda  (.OEN(~oe_i2c10_sda_i  ), .I(out_i2c10_sda_i  ), .O(in_i2c10_sda_o  ), .PAD(pad_i2c10_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c10_scl  (.OEN(~oe_i2c10_scl_i  ), .I(out_i2c10_scl_i  ), .O(in_i2c10_scl_o  ), .PAD(pad_i2c10_scl  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c11_sda  (.OEN(~oe_i2c11_sda_i  ), .I(out_i2c11_sda_i  ), .O(in_i2c11_sda_o  ), .PAD(pad_i2c11_sda  ), .PEN(1'b1             ) );
    pad_functional_pu padinst_i2c11_scl  (.OEN(~oe_i2c11_scl_i  ), .I(out_i2c11_scl_i  ), .O(in_i2c11_scl_o  ), .PAD(pad_i2c11_scl  ), .PEN(1'b1             ) );

`ifndef PULP_FPGA_EMUL
  pad_functional_pu padinst_sys_clk    (.OEN(1'b1            ), .I(                ), .O(sys_clk_o      ), .PAD(pad_sysclk_in ), .PEN(1'b1             ) );
  pad_functional_pu padinst_ref_clk    (.OEN(1'b1            ), .I(                ), .O(ref_clk_o      ), .PAD(pad_xtal_in   ), .PEN(1'b1             ) );
  pad_functional_pu padinst_reset_n    (.OEN(1'b1            ), .I(                ), .O(rstn_o         ), .PAD(pad_reset_n   ), .PEN(1'b1             ) );
  pad_functional_pu padinst_jtag_tck   (.OEN(1'b1            ), .I(                ), .O(jtag_tck_o     ), .PAD(pad_jtag_tck  ), .PEN(1'b1             ) );
  pad_functional_pu padinst_jtag_tms   (.OEN(1'b1            ), .I(                ), .O(jtag_tms_o     ), .PAD(pad_jtag_tms  ), .PEN(1'b1             ) );
  pad_functional_pu padinst_jtag_tdi   (.OEN(1'b1            ), .I(                ), .O(jtag_tdi_o     ), .PAD(pad_jtag_tdi  ), .PEN(1'b1             ) );
  pad_functional_pu padinst_jtag_trstn (.OEN(1'b1            ), .I(                ), .O(jtag_trst_o    ), .PAD(pad_jtag_trst ), .PEN(1'b1             ) );
  pad_functional_pd padinst_jtag_tdo   (.OEN(1'b0            ), .I(jtag_tdo_i      ), .O(               ), .PAD(pad_jtag_tdo  ), .PEN(1'b1             ) );

  pad_functional_pu padinst_fc_fetch_en_valid  (.OEN(1'b1    ), .I(                ), .O(fc_fetch_en_valid_o), .PAD(pad_fc_fetch_en_valid), .PEN(1'b1  ) );
  pad_functional_pd padinst_fc_fetch_en        (.OEN(1'b1    ), .I(                ), .O(fc_fetch_en_o      ), .PAD(pad_fc_fetch_en      ), .PEN(1'b1  ) );

  pad_functional_pu padinst_bootsel_valid   (.OEN(1'b1            ), .I(                ), .O(bootsel_valid_o ), .PAD(pad_bootsel_valid  ), .PEN(1'b1     ) );
  pad_functional_pu padinst_bootsel0        (.OEN(1'b1            ), .I(                ), .O(bootsel_o[0]    ), .PAD(pad_bootsel0       ), .PEN(1'b1             ) );
  pad_functional_pu padinst_bootsel1        (.OEN(1'b1            ), .I(                ), .O(bootsel_o[1]    ), .PAD(pad_bootsel1       ), .PEN(1'b1             ) );
`else
  assign sys_clk_o = pad_sysclk_in;
  assign ref_clk_o = pad_xtal_in;
  assign rstn_o = pad_reset_n;

  //JTAG signals
  assign pad_jtag_tdo = jtag_tdo_i;
  assign jtag_trst_o = pad_jtag_trst;
  assign jtag_tms_o = pad_jtag_tms;
  assign jtag_tck_o = pad_jtag_tck;
  assign jtag_tdi_o = pad_jtag_tdi;

  // start booting immediately
  assign fc_fetch_en_valid_o = pad_fc_fetch_en_valid;
  assign fc_fetch_en_o = pad_fc_fetch_en;

  // fpga boot
  assign bootsel_valid_o = pad_bootsel_valid;
  assign bootsel_o[0] = pad_bootsel0;
  assign bootsel_o[1] = pad_bootsel1;
`endif

endmodule // pad_frame_top

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
// Corrado Bonfanti <corrado.bonfanti@unibo.it>


module tb_pad_frame_top import pms_top_pkg::*;
    (

        input logic [31:0][5:0]       pad_cfg_i ,

        // JTAG SIGNALS
        output logic                  jtag_tck_o ,
        output logic                  jtag_tdi_o ,
        input logic                   jtag_tdo_i ,
        output logic                  jtag_tms_o ,
        output logic                  jtag_trst_o ,

        // INPUTS SIGNALS TO THE PADS
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
        input logic [N_I2C_SLV-1:0]   oe_i2c_slv_sda_i,
        input logic [N_I2C_SLV-1:0]   oe_i2c_slv_scl_i,
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
        input logic [N_I2C_SLV-1:0]   out_i2c_slv_sda_i,
        input logic [N_I2C_SLV-1:0]   out_i2c_slv_scl_i,
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
        output logic [N_I2C_SLV-1:0]  in_i2c_slv_sda_o,
        output logic [N_I2C_SLV-1:0]  in_i2c_slv_scl_o,
        output logic [N_UART-1:0]     in_uart_rx_o ,
        output logic [N_UART-1:0]     in_uart_tx_o ,

        // GPIOs
        input logic                   out_slp_s3_l_i,
        input logic                   out_slp_s4_l_i,
        input logic                   out_slp_s5_l_i,
        input logic                   out_sys_reset_l_i,
        input logic                   out_sys_rsmrst_l_i,
        input logic                   out_sys_pwr_btn_l_i,
        input logic                   out_sys_pwrgd_in_i,
        input logic                   out_sys_wake_l_i,
        input logic                   out_cpu_pwrgd_out_i,
        input logic [1:0]             out_cpu_throttle_i,
        input logic                   out_cpu_thermtrip_l_i,
        input logic [3:0]             out_cpu_errcode_i,
        input logic                   out_cpu_reset_out_l_i,
        input logic [1:0]             out_cpu_socket_id_i,
        input logic [3:0]             out_cpu_strap_i,

        input logic                   oe_slp_s3_l_i,
        input logic                   oe_slp_s4_l_i,
        input logic                   oe_slp_s5_l_i,
        input logic                   oe_sys_reset_l_i,
        input logic                   oe_sys_rsmrst_l_i,
        input logic                   oe_sys_pwr_btn_l_i,
        input logic                   oe_sys_pwrgd_in_i,
        input logic                   oe_sys_wake_l_i,
        input logic                   oe_cpu_pwrgd_out_i,
        input logic [1:0]             oe_cpu_throttle_i,
        input logic                   oe_cpu_thermtrip_l_i,
        input logic [3:0]             oe_cpu_errcode_i,
        input logic                   oe_cpu_reset_out_l_i,
        input logic [1:0]             oe_cpu_socket_id_i,
        input logic [3:0]             oe_cpu_strap_i,

        output logic                  in_slp_s3_l_o,
        output logic                  in_slp_s4_l_o,
        output logic                  in_slp_s5_l_o,
        output logic                  in_sys_reset_l_o,
        output logic                  in_sys_rsmrst_l_o,
        output logic                  in_sys_pwr_btn_l_o,
        output logic                  in_sys_pwrgd_in_o,
        output logic                  in_sys_wake_l_o,
        output logic                  in_cpu_pwrgd_out_o,
        output logic [1:0]            in_cpu_throttle_o,
        output logic                  in_cpu_thermtrip_l_o,
        output logic [3:0]            in_cpu_errcode_o,
        output logic                  in_cpu_reset_out_l_o,
        output logic [1:0]            in_cpu_socket_id_o,
        output logic [3:0]            in_cpu_strap_o,

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
        inout wire [N_I2C_SLV-1:0]    pad_i2c_slv_sda ,
        inout wire [N_I2C_SLV-1:0]    pad_i2c_slv_scl ,
        inout wire [N_UART-1:0]       pad_uart_rx ,
        inout wire [N_UART-1:0]       pad_uart_tx ,

        // GPIOs pads
        inout wire                    pad_slp_s3 ,
        inout wire                    pad_slp_s4 ,
        inout wire                    pad_slp_s5 ,
        inout wire                    pad_sys_reset ,
        inout wire                    pad_sys_rsmrst ,
        inout wire                    pad_sys_pwr_btn ,
        inout wire                    pad_sys_pwrgd_in ,
        inout wire                    pad_sys_wake ,
        inout wire                    pad_cpu_pwrgd_out ,
        inout wire                    pad_cpu_throttle_0 ,
        inout wire                    pad_cpu_throttle_1 ,
        inout wire                    pad_cpu_thermtrip ,
        inout wire                    pad_cpu_errcode_0 ,
        inout wire                    pad_cpu_errcode_1 ,
        inout wire                    pad_cpu_errcode_2 ,
        inout wire                    pad_cpu_errcode_3 ,
        inout wire                    pad_cpu_reset_out_n ,
        inout wire                    pad_cpu_socket_id_0 ,
        inout wire                    pad_cpu_socket_id_1 ,
        inout wire                    pad_cpu_strap_0 ,
        inout wire                    pad_cpu_strap_1 ,
        inout wire                    pad_cpu_strap_2 ,
        inout wire                    pad_cpu_strap_3 ,

        inout wire                    pad_jtag_tck ,
        inout wire                    pad_jtag_tdi ,
        inout wire                    pad_jtag_tdo ,
        inout wire                    pad_jtag_tms ,
        inout wire                    pad_jtag_trst

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

    for (genvar i = 0; i < N_I2C_SLV; i++) begin: pad_func_pu_i2c_slv
      pad_functional_pu padinst_slv_sda ( .OEN(~oe_i2c_slv_sda_i[i] ), .I(out_i2c_slv_sda_i[i] ), .O(in_i2c_slv_sda_o[i] ), .PAD(pad_i2c_slv_sda[i] ), .PEN(1'b0 ));
      pad_functional_pu padinst_slv_scl ( .OEN(~oe_i2c_slv_scl_i[i] ), .I(out_i2c_slv_scl_i[i] ), .O(in_i2c_slv_scl_o[i] ), .PAD(pad_i2c_slv_scl[i] ), .PEN(1'b0 ));
    end


    // GPIOs
    pad_functional_pd padinst_pms0_slp_s3_n( .OEN(~oe_slp_s3_l_i ), .I(out_slp_s3_l_i ), .O(in_slp_s3_l_o ), .PAD(pad_slp_s3 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_slp_s4_n( .OEN(~oe_slp_s4_l_i ), .I(out_slp_s4_l_i ), .O(in_slp_s4_l_o ), .PAD(pad_slp_s4 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_slp_s5_n( .OEN(~oe_slp_s5_l_i ), .I(out_slp_s5_l_i ), .O(in_slp_s5_l_o ), .PAD(pad_slp_s5 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_sys_reset_n( .OEN(~oe_sys_reset_l_i ), .I(out_sys_reset_l_i ), .O(in_sys_reset_l_o ), .PAD(pad_sys_reset ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_sys_rsmrst_n( .OEN(~oe_sys_rsmrst_l_i ), .I(out_sys_rsmrst_l_i ), .O(in_sys_rsmrst_l_o ), .PAD(pad_sys_rsmrst ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_sys_pwgd_in( .OEN(~oe_sys_pwrgd_in_i ), .I(out_sys_pwrgd_in_i ), .O(in_sys_pwrgd_in_o ), .PAD(pad_sys_pwrgd_in ), .PEN(1'b0 ));
    pad_functional_pu padinst_pms0_pwr_btn_n( .OEN(~oe_sys_pwr_btn_l_i ), .I(out_sys_pwr_btn_l_i ), .O(in_sys_pwr_btn_l_o ), .PAD(pad_sys_pwr_btn ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_pwgd_out( .OEN(~oe_cpu_pwrgd_out_i ), .I(out_cpu_pwrgd_out_i ), .O(in_cpu_pwrgd_out_o ), .PAD(pad_cpu_pwrgd_out ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_throttle_0( .OEN(~oe_cpu_throttle_i[0] ), .I(out_cpu_throttle_i[0] ), .O(in_cpu_throttle_o[0] ), .PAD(pad_cpu_throttle_0 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_throttle_1( .OEN(~oe_cpu_throttle_i[1] ), .I(out_cpu_throttle_i[1] ), .O(in_cpu_throttle_o[1] ), .PAD(pad_cpu_throttle_1 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_thermtrip_n( .OEN(~oe_cpu_thermtrip_l_i ), .I(out_cpu_thermtrip_l_i ), .O(in_cpu_thermtrip_l_o ), .PAD(pad_cpu_thermtrip_n ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_errcode_0( .OEN(~oe_cpu_errcode_i[0] ), .I(out_cpu_errcode_i[0] ), .O(in_cpu_errcode_o[0] ), .PAD(pad_cpu_errcode_0 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_errcode_1( .OEN(~oe_cpu_errcode_i[1] ), .I(out_cpu_errcode_i[1] ), .O(in_cpu_errcode_o[1] ), .PAD(pad_cpu_errcode_1 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_errcode_2( .OEN(~oe_cpu_errcode_i[2] ), .I(out_cpu_errcode_i[2] ), .O(in_cpu_errcode_o[2] ), .PAD(pad_cpu_errcode_2 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_errcode_3( .OEN(~oe_cpu_errcode_i[3] ), .I(out_cpu_errcode_i[3] ), .O(in_cpu_errcode_o[3] ), .PAD(pad_cpu_errcode_3 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_reset_out_n( .OEN(~oe_cpu_reset_out_l_i ), .I(out_cpu_reset_out_l_i ), .O(in_cpu_reset_out_l_o ), .PAD(pad_reset_out_n ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_socket_id_0( .OEN(~oe_cpu_socket_id_i[0] ), .I(out_cpu_socket_id_i[0] ), .O(in_cpu_socket_id_o[0] ), .PAD(pad_cpu_socket_id_0 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_socket_id_1( .OEN(~oe_cpu_socket_id_i[1] ), .I(out_cpu_socket_id_i[1] ), .O(in_cpu_socket_id_o[1] ), .PAD(pad_cpu_socket_id_1 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_strap_0( .OEN(~oe_cpu_strap_i[0] ), .I(out_cpu_strap_i[0] ), .O(in_cpu_strap_o[0] ), .PAD(pad_cpu_strap_0 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_strap_1( .OEN(~oe_cpu_strap_i[1] ), .I(out_cpu_strap_i[1] ), .O(in_cpu_strap_o[1] ), .PAD(pad_cpu_strap_1 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_strap_2( .OEN(~oe_cpu_strap_i[2] ), .I(out_cpu_strap_i[2] ), .O(in_cpu_strap_o[2] ), .PAD(pad_cpu_strap_2 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_strap_3( .OEN(~oe_cpu_strap_i[3] ), .I(out_cpu_strap_i[3] ), .O(in_cpu_strap_o[3] ), .PAD(pad_cpu_strap_3 ), .PEN(1'b0 ));
    pad_functional_pd padinst_pms0_sys_wake( .OEN(~oe_sys_wake_l_i ), .I(out_sys_wake_l_i ), .O(in_sys_wake_l_o ), .PAD(pad_sys_wake ), .PEN(1'b0 ));

    //JTAG signals
    assign pad_jtag_tdo = jtag_tdo_i;
    assign jtag_trst_o = pad_jtag_trst;
    assign jtag_tms_o = pad_jtag_tms;
    assign jtag_tck_o = pad_jtag_tck;
    assign jtag_tdi_o = pad_jtag_tdi;

endmodule // pad_frame_top

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

// Corrado Bonfanti <corrado.bonfanti@unibo.it>

`include "axi/assign.svh"
`include "axi/typedef.svh"

module tb_spi_slv;
  import control_pulp_pkg::*;
  import axi_test::*;

  parameter CONFIG_FILE = "NONE";

  // Simulation platform parameters

  // Choose your core: 0 for RISCY, 1 for ZERORISCY
  parameter CORE_TYPE = 0;
  // if RISCY is instantiated (CORE_TYPE == 0), RISCY_FPU enables the FPU
  parameter RISCY_FPU = 1;
  // Choose whether to use behavioral memory models or compiled memory macros
  parameter BEHAV_MEM = 1;

  // the following parameters can activate instantiation of the verification IPs for SPI, I2C and I2s
  // see the instructions in rtl/vip/{i2c_eeprom,i2s,spi_flash} to download the verification IPs
  parameter USE_S25FS256S_MODEL = 0;
  parameter USE_24FC1025_MODEL = 0;

  // TODO: period of the system clock (600MhZ)
  // period of the external reference clock (100MhZ)
  parameter REF_CLK_PERIOD = 10ns;

  // how L2 is loaded. valid values are "JTAG" or "STANDALONE", the latter works only when USE_S25FS256S_MODEL is 1
  parameter LOAD_L2 = "JTAG";

  // enable DPI-based JTAG
  parameter ENABLE_DPI = 0;

  // enable DPI-based peripherals
  parameter ENABLE_DEV_DPI = 0;

  // enable DPI-based custom debug bridge
  parameter ENABLE_EXTERNAL_DRIVER = 0;

  // enable DPI-based openocd debug bridge
  parameter ENABLE_OPENOCD = 0;

  // enable Debug Module Tests
  parameter ENABLE_DM_TESTS = 0;

  // use the pulp tap to access the bus
  parameter USE_PULP_BUS_ACCESS = 1;

  // UART baud rate in bps
  parameter BAUDRATE = 115200;

  // use frequency-locked loop to generate internal clock
  parameter USE_FLL = 1;

  // for PULP, 8 cores
  parameter NB_CORES = 8;

  // SPI standards, do not change
  parameter logic [1:0] SPI_STD = 2'b00;
  parameter logic [1:0] SPI_QUAD_TX = 2'b01;
  parameter logic [1:0] SPI_QUAD_RX = 2'b10;

  // JTAG mux configuration, do not change
  parameter logic [1:0] JTAG_DPI = 2'b01;
  parameter logic [1:0] JTAG_BRIDGE = 2'b10;

  // exit
  localparam int EXIT_SUCCESS = 0;
  localparam int EXIT_FAIL = 1;
  localparam int EXIT_ERROR = -1;

  // contains the program code
  string stimuli_file;

  // simulation vars
  logic uart_tb_rx_en = 1'b0;

  int num_stim;
  logic [95:0] stimuli[100000:0];  // array for the stimulus vectors

  logic [1:0] jtag_mux = 2'b00;

  logic dev_dpi_en = 0;

  logic [255:0][31:0] jtag_data;

  jtag_pkg::test_mode_if_t test_mode_if = new;
  jtag_pkg::debug_mode_if_t debug_mode_if = new;
  pulp_tap_pkg::pulp_tap_if_soc_t pulp_tap = new;


  // System wires for the in/out/enable signals of control-pulp (taken from pulp.sv)

  logic [47:0][5:0] s_pad_cfg;

  logic [N_SPI-1:0][3:0] s_out_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_out_qspi_csn;
  logic [N_SPI-1:0][1:0] s_out_qspi_csn_pad;
  logic [N_SPI-1:0] s_out_qspi_sck;
  logic [3:0] s_out_spi_slv_sdio;
  logic s_out_spi_slv_csn;
  logic s_out_spi_slv_sck;
  logic s_out_uart_rx;
  logic s_out_uart_tx;
  logic [N_I2C-1:0] s_out_i2c_sda;
  logic [N_I2C-1:0] s_out_i2c_scl;

  logic [N_SPI-1:0][3:0] s_in_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_in_qspi_csn;
  logic [N_SPI-1:0][1:0] s_in_qspi_csn_pad;
  logic [N_SPI-1:0] s_in_qspi_sck;
  logic [3:0] s_in_spi_slv_sdio;
  logic s_in_spi_slv_csn;
  logic s_in_spi_slv_sck;
  logic s_in_uart_rx;
  logic s_in_uart_tx;
  logic [N_I2C-1:0] s_in_i2c_sda;
  logic [N_I2C-1:0] s_in_i2c_scl;

  logic [N_SPI-1:0][3:0] s_oe_qspi_sdio;
  logic [N_SPI-1:0][3:0] s_oe_qspi_csn;
  logic [N_SPI-1:0][1:0] s_oe_qspi_csn_pad;
  logic [N_SPI-1:0] s_oe_qspi_sck;
  logic [3:0] s_oe_spi_slv_sdio;
  logic s_oe_spi_slv_csn;
  logic s_oe_spi_slv_sck;
  logic s_oe_uart_rx;
  logic s_oe_uart_tx;
  logic [N_I2C-1:0] s_oe_i2c_sda;
  logic [N_I2C-1:0] s_oe_i2c_scl;

  //
  //OTHER PAD FRAME SIGNALS
  //

  logic s_ref_clk_glue;
  logic s_sys_clk_glue;
  logic s_rstn_glue;

  logic s_jtag_tck_glue;
  logic s_jtag_tdi_glue;
  logic s_jtag_tdo_glue;
  logic s_jtag_tms_glue;
  logic s_jtag_trst_glue;

  logic s_fc_fetch_en_valid_glue;
  logic s_fc_fetch_en_glue;

  logic [1:0] bootsel_glue;

  // System wires for the padframe-like inout signal used in the testbench

  // the w_/s_ prefixes are used to mean wire/tri-type and logic-type (respectively)

  logic s_rst_n = 1'b0;
  logic s_rst_dpi_n;
  wire w_rst_n;

  logic s_clk_ref;
  wire w_clk_ref;

  tri [N_SPI-1:0][3:0] w_spi_master_sdio;
  tri [N_SPI-1:0][1:0] w_spi_master_csn;
  tri [N_SPI-1:0] w_spi_master_sck;

  tri [3:0] w_spi_slave_sdio;
  tri w_spi_slave_csn;
  tri w_spi_slave_sck;

  wire [N_I2C-1:0] w_i2c_scl;
  wire [N_I2C-1:0] w_i2c_sda;

  logic [1:0] s_padmode_spi_master = SPI_STD;

  tri w_uart_rx;
  tri w_uart_tx;

  wire w_trstn;
  wire w_tck;
  wire w_tdi;
  wire w_tms;
  wire w_tdo;

  wire w_fc_fetch_en_valid;
  wire w_fc_fetch_en;

  logic s_vpi_trstn;
  logic s_vpi_tck;
  logic s_vpi_tdi;
  logic s_vpi_tms;

  wire w_bridge_trstn;
  wire w_bridge_tdo;
  wire w_bridge_tck;
  wire w_bridge_tdi;
  wire w_bridge_tms;

  logic s_trstn = 1'b0;
  logic s_tck = 1'b0;
  logic s_tdi = 1'b0;
  logic s_tms = 1'b0;
  logic s_tdo;

  // jtag openocd bridge signals
  logic sim_jtag_tck;
  logic sim_jtag_tms;
  logic sim_jtag_tdi;
  logic sim_jtag_trstn;
  logic sim_jtag_tdo;
  logic [31:0] sim_jtag_exit;
  logic sim_jtag_enable;

  // tmp signals for assignment to wires
  logic tmp_rst_n;
  logic tmp_clk_ref;
  logic tmp_trstn;
  logic tmp_tck;
  logic tmp_tdi;
  logic tmp_tms;
  logic tmp_tdo;
  logic tmp_bridge_tdo;
  logic [3:0] w_spi_slave_sdio_int;
  logic w_spi_slave_sck_int;
  logic w_spi_slave_csn_int;

  wire [1:0] w_bootsel;
  logic [1:0] s_bootsel;


  logic [8:0] jtag_conf_reg, jtag_conf_rego;  // 22bits but actually only the last 9bits are used


  int exit_status = EXIT_SUCCESS;  // per default we pass

  // Glue code for defining fake inout pads on top of the control_pulp module
  // in a chip-like fashion;
  //
  // 'padframe.sv' takes each input/output/enable ports of control_pulp and
  // glues them in a single inout pad;
  //
  // Said pads are used in the testbench.

  // Assign a subset of chip select signals from spi to pad frame
  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_oe
    assign s_oe_qspi_csn_pad[i] = s_oe_qspi_csn[i][1:0];
  end

  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_out
    assign s_out_qspi_csn_pad[i] = s_out_qspi_csn[i][1:0];
  end

  for (genvar i = 0; i < N_SPI; i++) begin : assign_csn_subset_in
    assign s_in_qspi_csn[i][1:0] = s_in_qspi_csn_pad[i];
  end

  //
  // PAD FRAME
  //
  pad_frame i_pad_frame (
    .pad_cfg_i  (s_pad_cfg),
    .sys_clk_o  (s_sys_clk_glue),
    .ref_clk_o  (s_ref_clk_glue),
    .rstn_o     (s_rstn_glue),
    .jtag_tdo_i (s_jtag_tdo_glue),
    .jtag_tck_o (s_jtag_tck_glue),
    .jtag_tdi_o (s_jtag_tdi_glue),
    .jtag_tms_o (s_jtag_tms_glue),
    .jtag_trst_o(s_jtag_trst_glue),

    .oe_qspi_sdio_i   (s_oe_qspi_sdio),
    .oe_qspi_csn_i    (s_oe_qspi_csn_pad),
    .oe_qspi_sck_i    (s_oe_qspi_sck),
    .oe_spi_slv_sdio_i(s_oe_spi_slv_sdio),
    .oe_spi_slv_csn_i (s_oe_spi_slv_csn),
    .oe_spi_slv_sck_i (s_oe_spi_slv_sck),
    .oe_uart_rx_i     (s_oe_uart_rx),
    .oe_uart_tx_i     (s_oe_uart_tx),

    .oe_i2c0_sda_i(s_oe_i2c_sda[0]),
    .oe_i2c0_scl_i(s_oe_i2c_scl[0]),
    .oe_i2c1_sda_i(s_oe_i2c_sda[1]),
    .oe_i2c1_scl_i(s_oe_i2c_scl[1]),
    .oe_i2c2_sda_i(s_oe_i2c_sda[2]),
    .oe_i2c2_scl_i(s_oe_i2c_scl[2]),
    .oe_i2c3_sda_i(s_oe_i2c_sda[3]),
    .oe_i2c3_scl_i(s_oe_i2c_scl[3]),
    .oe_i2c4_sda_i(s_oe_i2c_sda[4]),
    .oe_i2c4_scl_i(s_oe_i2c_scl[4]),
    .oe_i2c5_sda_i(s_oe_i2c_sda[5]),
    .oe_i2c5_scl_i(s_oe_i2c_scl[5]),
    .oe_i2c6_sda_i(s_oe_i2c_sda[6]),
    .oe_i2c6_scl_i(s_oe_i2c_scl[6]),
    .oe_i2c7_sda_i(s_oe_i2c_sda[7]),
    .oe_i2c7_scl_i(s_oe_i2c_scl[7]),
    .oe_i2c8_sda_i(s_oe_i2c_sda[8]),
    .oe_i2c8_scl_i(s_oe_i2c_scl[8]),
    .oe_i2c9_sda_i(s_oe_i2c_sda[9]),
    .oe_i2c9_scl_i(s_oe_i2c_scl[9]),

    .out_qspi_sdio_i   (s_out_qspi_sdio),
    .out_qspi_csn_i    (s_out_qspi_csn_pad),
    .out_qspi_sck_i    (s_out_qspi_sck),
    .out_spi_slv_sdio_i(s_out_spi_slv_sdio),
    .out_spi_slv_csn_i (s_out_spi_slv_csn),
    .out_spi_slv_sck_i (s_out_spi_slv_sck),
    .out_uart_rx_i     (s_out_uart_rx),
    .out_uart_tx_i     (s_out_uart_tx),

    .out_i2c0_sda_i(s_out_i2c_sda[0]),
    .out_i2c0_scl_i(s_out_i2c_scl[0]),
    .out_i2c1_sda_i(s_out_i2c_sda[1]),
    .out_i2c1_scl_i(s_out_i2c_scl[1]),
    .out_i2c2_sda_i(s_out_i2c_sda[2]),
    .out_i2c2_scl_i(s_out_i2c_scl[2]),
    .out_i2c3_sda_i(s_out_i2c_sda[3]),
    .out_i2c3_scl_i(s_out_i2c_scl[3]),
    .out_i2c4_sda_i(s_out_i2c_sda[4]),
    .out_i2c4_scl_i(s_out_i2c_scl[4]),
    .out_i2c5_sda_i(s_out_i2c_sda[5]),
    .out_i2c5_scl_i(s_out_i2c_scl[5]),
    .out_i2c6_sda_i(s_out_i2c_sda[6]),
    .out_i2c6_scl_i(s_out_i2c_scl[6]),
    .out_i2c7_sda_i(s_out_i2c_sda[7]),
    .out_i2c7_scl_i(s_out_i2c_scl[7]),
    .out_i2c8_sda_i(s_out_i2c_sda[8]),
    .out_i2c8_scl_i(s_out_i2c_scl[8]),
    .out_i2c9_sda_i(s_out_i2c_sda[9]),
    .out_i2c9_scl_i(s_out_i2c_scl[9]),

    .in_qspi_sdio_o   (s_in_qspi_sdio),
    .in_qspi_csn_o    (s_in_qspi_csn_pad),
    .in_qspi_sck_o    (s_in_qspi_sck),
    .in_spi_slv_sdio_o(s_in_spi_slv_sdio),
    .in_spi_slv_csn_o (s_in_spi_slv_csn),
    .in_spi_slv_sck_o (s_in_spi_slv_sck),
    .in_uart_rx_o     (s_in_uart_rx),
    .in_uart_tx_o     (s_in_uart_tx),

    .in_i2c0_sda_o(s_in_i2c_sda[0]),
    .in_i2c0_scl_o(s_in_i2c_scl[0]),
    .in_i2c1_sda_o(s_in_i2c_sda[1]),
    .in_i2c1_scl_o(s_in_i2c_scl[1]),
    .in_i2c2_sda_o(s_in_i2c_sda[2]),
    .in_i2c2_scl_o(s_in_i2c_scl[2]),
    .in_i2c3_sda_o(s_in_i2c_sda[3]),
    .in_i2c3_scl_o(s_in_i2c_scl[3]),
    .in_i2c4_sda_o(s_in_i2c_sda[4]),
    .in_i2c4_scl_o(s_in_i2c_scl[4]),
    .in_i2c5_sda_o(s_in_i2c_sda[5]),
    .in_i2c5_scl_o(s_in_i2c_scl[5]),
    .in_i2c6_sda_o(s_in_i2c_sda[6]),
    .in_i2c6_scl_o(s_in_i2c_scl[6]),
    .in_i2c7_sda_o(s_in_i2c_sda[7]),
    .in_i2c7_scl_o(s_in_i2c_scl[7]),
    .in_i2c8_sda_o(s_in_i2c_sda[8]),
    .in_i2c8_scl_o(s_in_i2c_scl[8]),
    .in_i2c9_sda_o(s_in_i2c_sda[9]),
    .in_i2c9_scl_o(s_in_i2c_scl[9]),

    .bootsel_o          (bootsel_glue),
    .fc_fetch_en_valid_o(s_fc_fetch_en_valid_glue),
    .fc_fetch_en_o      (s_fc_fetch_en_glue),


    //EXT CHIP to PAD (previously pulp.sv top-level ports)
    .pad_qspi_sdio(w_spi_master_sdio),
    .pad_qspi_csn (w_spi_master_csn),
    .pad_qspi_sck (w_spi_master_sck),

    .pad_spi_slv_sdio(w_spi_slave_sdio),
    .pad_spi_slv_csn (w_spi_slave_csn),
    .pad_spi_slv_sck (w_spi_slave_sck),

    .pad_uart_rx(w_uart_tx),
    .pad_uart_tx(w_uart_rx),

    .pad_i2c0_sda(w_i2c_sda[0]),
    .pad_i2c0_scl(w_i2c_scl[0]),
    .pad_i2c1_sda(w_i2c_sda[1]),
    .pad_i2c1_scl(w_i2c_scl[1]),
    .pad_i2c2_sda(w_i2c_sda[2]),
    .pad_i2c2_scl(w_i2c_scl[2]),
    .pad_i2c3_sda(w_i2c_sda[3]),
    .pad_i2c3_scl(w_i2c_scl[3]),
    .pad_i2c4_sda(w_i2c_sda[4]),
    .pad_i2c4_scl(w_i2c_scl[4]),
    .pad_i2c5_sda(w_i2c_sda[5]),
    .pad_i2c5_scl(w_i2c_scl[5]),
    .pad_i2c6_sda(w_i2c_sda[6]),
    .pad_i2c6_scl(w_i2c_scl[6]),
    .pad_i2c7_sda(w_i2c_sda[7]),
    .pad_i2c7_scl(w_i2c_scl[7]),
    .pad_i2c8_sda(w_i2c_sda[8]),
    .pad_i2c8_scl(w_i2c_scl[8]),
    .pad_i2c9_sda(w_i2c_sda[9]),
    .pad_i2c9_scl(w_i2c_scl[9]),

    .pad_reset_n (w_rst_n),
    .pad_bootsel0(w_bootsel[0]),
    .pad_bootsel1(w_bootsel[1]),

    .pad_jtag_tck (w_tck),
    .pad_jtag_tdi (w_tdi),
    .pad_jtag_tdo (w_tdo),
    .pad_jtag_tms (w_tms),
    .pad_jtag_trst(w_trstn),

    .pad_xtal_in  (w_clk_ref),
    .pad_sysclk_in(w_clk_ref),  // TODO: fix this clock should be 600 MhZ

    .pad_fc_fetch_en_valid(w_fc_fetch_en_valid),
    .pad_fc_fetch_en      (w_fc_fetch_en)
  );


`ifdef USE_DPI
  generate
    if (CONFIG_FILE != "NONE") begin

      CTRL ctrl ();
      JTAG jtag ();
      UART uart ();
      CPI cpi ();

      QSPI qspi_0 ();
      QSPI_CS qspi_0_csn[0:1] ();

      GPIO gpio_22 ();

      assign s_rst_dpi_n             = ~ctrl.reset;

      assign w_bridge_tck            = jtag.tck;
      assign w_bridge_tdi            = jtag.tdi;
      assign w_bridge_tms            = jtag.tms;
      assign w_bridge_trstn          = jtag.trst;
      assign jtag.tdo                = w_bridge_tdo;

      assign w_uart_tx               = uart.tx;
      assign uart.rx                 = w_uart_rx;

      assign w_spi_master_sdio[0][0] = qspi_0.data_0_out;
      assign qspi_0.data_0_in        = w_spi_master_sdio[0][0];
      assign w_spi_master_sdio[0][1] = qspi_0.data_1_out;
      assign qspi_0.data_1_in        = w_spi_master_sdio[0][1];
      assign w_spi_master_sdio[0][2] = qspi_0.data_2_out;
      assign qspi_0.data_2_in        = w_spi_master_sdio[0][2];
      assign w_spi_master_sdio[0][3] = qspi_0.data_3_out;
      assign qspi_0.data_3_in        = w_spi_master_sdio[0][3];
      assign qspi_0.sck              = w_spi_master_sck[0];
      assign qspi_0_csn[0].csn       = w_spi_master_csn[0][0];
      assign qspi_0_csn[1].csn       = w_spi_master_csn[0][1];


      initial begin

        automatic tb_driver::tb_driver i_tb_driver = new;

        qspi_0.data_0_out = 'bz;
        qspi_0.data_1_out = 'bz;
        qspi_0.data_2_out = 'bz;
        qspi_0.data_3_out = 'bz;

        i_tb_driver.register_qspim_itf(0, qspi_0, qspi_0_csn);
        i_tb_driver.register_uart_itf(0, uart);
        i_tb_driver.register_jtag_itf(0, jtag);
        i_tb_driver.register_cpi_itf(0, cpi);
        i_tb_driver.register_ctrl_itf(0, ctrl);
        i_tb_driver.register_gpio_itf(22, gpio_22);
        i_tb_driver.build_from_json(CONFIG_FILE);

      end

    end

  endgenerate
`endif

  for (genvar i = 0; i < N_I2C; i++) begin : gen_pullup_i2c_scl
    pullup scl_pullup_i (w_i2c_scl[i]);
  end

  for (genvar i = 0; i < N_I2C; i++) begin : gen_pullup_i2c_sda
    pullup sda_pullup_i (w_i2c_sda[i]);
  end

  always_comb begin
    sim_jtag_enable = 1'b0;

    if (ENABLE_EXTERNAL_DRIVER) begin
      tmp_rst_n      = s_rst_dpi_n;
      tmp_clk_ref    = s_clk_ref;
      tmp_trstn      = w_bridge_trstn;
      tmp_tck        = w_bridge_tck;
      tmp_tdi        = w_bridge_tdi;
      tmp_tms        = w_bridge_tms;
      tmp_tdo        = w_tdo;
      tmp_bridge_tdo = w_tdo;

    end else if (ENABLE_OPENOCD) begin
      tmp_rst_n       = s_rst_n;
      tmp_clk_ref     = s_clk_ref;
      tmp_trstn       = sim_jtag_trstn;
      tmp_tck         = sim_jtag_tck;
      tmp_tdi         = sim_jtag_tdi;
      tmp_tms         = sim_jtag_tms;
      tmp_tdo         = w_tdo;
      tmp_bridge_tdo  = w_tdo;
      sim_jtag_enable = 1'b1;

    end else begin
      tmp_rst_n      = s_rst_n;
      tmp_clk_ref    = s_clk_ref;

      tmp_trstn      = s_trstn;
      tmp_tck        = s_tck;
      tmp_tdi        = s_tdi;
      tmp_tms        = s_tms;
      tmp_tdo        = w_tdo;
      tmp_bridge_tdo = w_tdo;

    end
  end

  assign w_rst_n      = tmp_rst_n;
  assign w_clk_ref    = tmp_clk_ref;
  assign w_trstn      = tmp_trstn;
  assign w_tck        = tmp_tck;
  assign w_tdi        = tmp_tdi;
  assign w_tms        = tmp_tms;
  assign s_tdo        = tmp_tdo;
  assign w_bridge_tdo = tmp_bridge_tdo;
  assign sim_jtag_tdo = tmp_tdo;

  // TODO: this should be set depending on the desired boot mode (JTAG, FLASH)
  assign w_bootsel    = s_bootsel;

  //assign w_fc_fetch_en_valid = s_fc_fetch_en_valid;
  //assign w_fc_fetch_en = s_fc_fetch_en;

  // JTAG DPI-based verification IP
  generate
    if (ENABLE_DPI == 1) begin
      jtag_dpi #(
        .TIMEOUT_COUNT(6'h2)
      ) i_jtag (
        .clk_i   (w_clk_ref),
        .enable_i(jtag_mux == JTAG_DPI),
        .tms_o   (s_vpi_tms),
        .tck_o   (s_vpi_tck),
        .trst_o  (s_vpi_trstn),
        .tdi_o   (s_vpi_tdi),
        .tdo_i   (s_tdo)
      );
    end
  endgenerate

  // SPI flash model (not open-source, from Spansion)
  if (USE_S25FS256S_MODEL == 1) begin
    for (genvar i = 0; i < N_SPI; i++) begin : gen_vip_spi_mem
      s25fs256s #(
        .TimingModel  ("S25FS256SAGMFI000_F_30pF"),
        .mem_file_name("slm_files/flash_stim.slm"),
        .UserPreload  (1)
      ) i_spi_flash_csn (
        .SI      (w_spi_master_sdio[i][0]),
        .SO      (w_spi_master_sdio[i][1]),
        .SCK     (w_spi_master_sck[i]),
        .CSNeg   (w_spi_master_csn[i][0]),
        .WPNeg   (w_spi_master_sdio[i][2]),
        .RESETNeg(w_spi_master_sdio[i][3])
      );
    end  // block: gen_vip_spi_mem
  end  // if (USE_S25FS256S_MODEL == 1)

  if (CONFIG_FILE == "NONE") begin : uart_sim_gen
    // UART receiver and sender
    uart_sim #(
      .BAUD_RATE(BAUDRATE),
      .PARITY_EN(0)
    ) i_uart_sim (
      .rx   (w_uart_rx),
      .rx_en(uart_tb_rx_en),
      .tx   (w_uart_tx)
    );
  end

  // I2C memory models
  if (USE_24FC1025_MODEL == 1) begin
    for (genvar i = 0; i < N_I2C; i++) begin : gen_vip_i2c_mem
      M24FC1025 i_i2c_mem (
        .A0   (1'b0),
        .A1   (1'b0),
        .A2   (1'b1),
        .WP   (1'b0),
        .SDA  (w_i2c_sda[i]),
        .SCL  (w_i2c_scl[i]),
        .RESET(1'b0)
      );
    end
  end

  // jtag calls from dpi
  SimJTAG #(
    .TICK_DELAY(1),
    .PORT      (4567)
  ) i_sim_jtag (
    .clock          (w_clk_ref),
    .reset          (~s_rst_n),
    .enable         (sim_jtag_enable),
    .init_done      (s_rst_n),
    .jtag_TCK       (sim_jtag_tck),
    .jtag_TMS       (sim_jtag_tms),
    .jtag_TDI       (sim_jtag_tdi),
    .jtag_TRSTn     (sim_jtag_trstn),
    .jtag_TDO_data  (sim_jtag_tdo),
    .jtag_TDO_driven(1'b1),
    .exit           (sim_jtag_exit)
  );


  // control_pulp module --> req/resp structs (no wrap)


  // 1. Define axi request (req) and response (resp) type structs for c07, r07 and sms in control_pulp


  // nci_cp_top Master
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_inp_ext_t, axi_data_inp_ext_t, axi_strb_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_inp_ext_t, axi_addr_ext_t, axi_id_inp_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_inp_ext_t, axi_data_inp_ext_t, axi_id_inp_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_inp_ext_t, axi_aw_inp_ext_t, axi_w_inp_ext_t, axi_ar_inp_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_inp_ext_t, axi_b_inp_ext_t, axi_r_inp_ext_t);

  // nci_cp_top Slave
  `AXI_TYPEDEF_AW_CHAN_T(axi_aw_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_W_CHAN_T(axi_w_oup_ext_t, axi_data_oup_ext_t, axi_strb_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_B_CHAN_T(axi_b_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_AR_CHAN_T(axi_ar_oup_ext_t, axi_addr_ext_t, axi_id_oup_ext_t, axi_user_ext_t);
  `AXI_TYPEDEF_R_CHAN_T(axi_r_oup_ext_t, axi_data_oup_ext_t, axi_id_oup_ext_t, axi_user_ext_t);

  `AXI_TYPEDEF_REQ_T(axi_req_oup_ext_t, axi_aw_oup_ext_t, axi_w_oup_ext_t, axi_ar_oup_ext_t);
  `AXI_TYPEDEF_RESP_T(axi_resp_oup_ext_t, axi_b_oup_ext_t, axi_r_oup_ext_t);

  // nci_cp_top Master
  axi_req_inp_ext_t from_ext_req;
  axi_resp_inp_ext_t from_ext_resp;
  // nci_cp_top Slave
  axi_req_oup_ext_t to_ext_req;
  axi_resp_oup_ext_t to_ext_resp;

  // Instantiate control-pulp module

  control_pulp_with_mem #(
    .CORE_TYPE(CORE_TYPE),
    .USE_FPU  (RISCY_FPU),
    .BEHAV_MEM(BEHAV_MEM),

    // nci_cp_top Master
    .axi_req_inp_ext_t (axi_req_inp_ext_t),
    .axi_resp_inp_ext_t(axi_resp_inp_ext_t),
    // nci_cp_top Slave
    .axi_req_oup_ext_t (axi_req_oup_ext_t),
    .axi_resp_oup_ext_t(axi_resp_oup_ext_t)

  ) i_dut (

    // control-pulp interaction ports with off-pmu objects
    // nci_cp_top Master
    .from_ext_req_i (from_ext_req),
    .from_ext_resp_o(from_ext_resp),
    // nci_cp_top Slave
    .to_ext_req_o   (to_ext_req),
    .to_ext_resp_i  (to_ext_resp),

    // on-pmu internal peripherals (soc)

    .pad_cfg_o  (s_pad_cfg),
    .ref_clk_i  (s_ref_clk_glue),
    .sys_clk_i  (s_sys_clk_glue),
    .rst_ni     (s_rstn_glue),
    .jtag_tdo_o (s_jtag_tdo_glue),
    .jtag_tck_i (s_jtag_tck_glue),
    .jtag_tdi_i (s_jtag_tdi_glue),
    .jtag_tms_i (s_jtag_tms_glue),
    .jtag_trst_i(s_jtag_trst_glue),

    .oe_qspi_sdio_o   (s_oe_qspi_sdio),
    .oe_qspi_csn_o    (s_oe_qspi_csn),
    .oe_qspi_sck_o    (s_oe_qspi_sck),
    .oe_spi_slv_sdio_o(s_oe_spi_slv_sdio),
    .oe_spi_slv_csn_o (s_oe_spi_slv_csn),
    .oe_spi_slv_sck_o (s_oe_spi_slv_sck),
    .oe_i2c_sda_o     (s_oe_i2c_sda),
    .oe_i2c_scl_o     (s_oe_i2c_scl),
    .oe_uart_rx_o     (s_oe_uart_rx),
    .oe_uart_tx_o     (s_oe_uart_tx),

    .out_qspi_sdio_o   (s_out_qspi_sdio),
    .out_qspi_csn_o    (s_out_qspi_csn),
    .out_qspi_sck_o    (s_out_qspi_sck),
    .out_spi_slv_sdio_o(s_out_spi_slv_sdio),
    .out_spi_slv_csn_o (s_out_spi_slv_csn),
    .out_spi_slv_sck_o (s_out_spi_slv_sck),
    .out_i2c_sda_o     (s_out_i2c_sda),
    .out_i2c_scl_o     (s_out_i2c_scl),
    .out_uart_rx_o     (s_out_uart_rx),
    .out_uart_tx_o     (s_out_uart_tx),

    .in_qspi_sdio_i   (s_in_qspi_sdio),
    .in_qspi_csn_i    (s_in_qspi_csn),
    .in_qspi_sck_i    (s_in_qspi_sck),
    .in_spi_slv_sdio_i(s_in_spi_slv_sdio),
    .in_spi_slv_csn_i (s_in_spi_slv_csn),
    .in_spi_slv_sck_i (s_in_spi_slv_sck),
    .in_i2c_sda_i     (s_in_i2c_sda),
    .in_i2c_scl_i     (s_in_i2c_scl),
    .in_uart_rx_i     (s_in_uart_rx),
    .in_uart_tx_i     (s_in_uart_tx),

    .bootsel_i          (bootsel_glue),
    .fc_fetch_en_valid_i(s_fc_fetch_en_valid_glue),
    .fc_fetch_en_i      (s_fc_fetch_en_glue)

  );

  // Directed verification: setup

  `define wait_for(signal) \
  do \
    @(posedge i_dut.i_control_pulp_structs.i_soc_domain.pulp_soc_i.s_soc_clk); \
  while (!signal);

  // Directed verification: testbench driver process

  // 1. Clock generation
  tb_clk_gen #(.CLK_PERIOD(REF_CLK_PERIOD)) i_ref_clk_gen (.clk_o(s_clk_ref));

  initial begin : timing_format
    $timeformat(-9, 0, "ns", 9);
  end : timing_format

  integer stim_fd;
  integer ret_code;

  assign                   w_spi_slave_sck  = w_spi_slave_sck_int;
  assign                   w_spi_slave_csn  = w_spi_slave_csn_int;
  assign (highz0, strong1) w_spi_slave_sdio = w_spi_slave_sdio_int;

  initial begin

    // SPI slave test
    logic [31:0] data_spi_rcv;
    logic [31:0] addr_spi_i;
    automatic logic [31:0] data_spi_snd = 64'h0000_0000_cafe_cafe;

    // Default SPI master signals values
    w_spi_slave_csn_int     = 1'b1;
    w_spi_slave_sck_int     = 1'b0;
    w_spi_slave_sdio_int[3] = 1'b0;
    w_spi_slave_sdio_int[2] = 1'b0;
    w_spi_slave_sdio_int[1] = 1'b0;
    w_spi_slave_sdio_int[0] = 1'b0;
    ////////

    from_ext_req            = '{default: '0};

    // Wait for reset
    $display("[TB] %t - Asserting hard reset", $realtime);
    s_rst_n = 1'b0;

    #1ns $display("[TB] %t - Releasing hard reset", $realtime);
    s_rst_n = 1'b1;

    #5us;

    @(posedge i_dut.i_control_pulp_structs.i_soc_domain.pulp_soc_i.s_soc_clk);


    // L2 address range from external view:
    //   start: 1C00_0000
    //   end: 1C08_0000

    // First and last address check

    $display("[TB] %t - Write to first address (SPI), WORD: %h", $realtime, data_spi_snd);
    spi_write_word(1'h0, 32'h1C00_0000, data_spi_snd);

    $display("[TB] %t - Read from first address (SPI)", $realtime);
    spi_read_word(1'h0, 32'h1C00_0000, data_spi_rcv);
    assert (data_spi_rcv == data_spi_snd) $display("[TB] %t - Successful transaction", $realtime);
    else begin
      $error("read first memory location");
      exit_status = EXIT_FAIL;
    end

    #1us;

    $display("[TB] %t - Write to last address (SPI), WORD: %h", $realtime, data_spi_snd);
    spi_write_word(1'h0, 32'h1C07_FFFC, data_spi_snd);

    $display("[TB] %t - Read from last address (SPI)", $realtime);
    spi_read_word(1'h0, 32'h1C07_FFFC, data_spi_rcv);
    assert (data_spi_rcv == data_spi_snd) $display("[TB] %t - Successful transaction", $realtime);
    else begin
      $error("read last memory location");
      exit_status = EXIT_FAIL;
    end

    #1us;


    // Probe range test
    // increment_aligned: 0x800
    // increment_unaligned: 0x801

    #5us stim_fd = $fopen("../rtl/tb/spi_slv_test_simvectors/stimuli_aligned_asic.txt", "r");
    if (stim_fd == 0) begin
      $fatal("Could not open stimuli file!");
    end

    while (!$feof(
      stim_fd
    )) begin
      @(posedge i_dut.i_control_pulp_structs.i_soc_domain.pulp_soc_i.s_soc_clk);
      ret_code = $fscanf(stim_fd, "%h,%h\n", addr_spi_i, data_spi_snd);

      $display("[TB] %t - Write to address %h", $realtime, addr_spi_i);
      spi_write_word(1'h0, addr_spi_i, data_spi_snd);

      $display("[TB] %t - Read from address %h", $realtime, addr_spi_i);
      spi_read_word(1'h0, addr_spi_i, data_spi_rcv);
      assert (data_spi_rcv == data_spi_snd) $display("[TB] %t - Successful transaction", $realtime);
      else begin
        $error("read last memory location");
        exit_status = EXIT_FAIL;
      end

    end

    $fclose(stim_fd);

    $stop;

  end  // initial begin

  `include "tb_spi_pkg.sv"

endmodule

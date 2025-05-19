// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed under the Creative Commons Public Domain, for
// any use, without warranty, 2017 by Wilson Snyder.
// SPDX-License-Identifier: CC0-1.0
//======================================================================

// Author: Wilson Snyder
//         Robert Balas (balasr@iis.ee.ethz.ch)

// Description: Verilator testbench toplevel for Control PULP. Needs at least
// verilator v4.200.

// For std::unique_ptr
#include <memory>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vpms_top.h"
#include "verilated_vcd_c.h"

// Legacy function required only so linking works on Cygwin and MSVC++
double sc_time_stamp()
{
    return 0;
}

enum rx_state { RX_IDLE, RX_DATA };

#define TIMEUNITS_PER_PERIOD (1000 * 10)
#define TICKS_PER_BAUD (868)

struct uart_state {
    enum rx_state rx_state;
    uint32_t rx_data;
    // how many bits we have read
    int rx_count;
    // once this counter hits zero we have a new symbol we should sample
    int baudcount;
    // number of data bits we expect to receive
    int bits;
    // number of parity bits we expect to receive
    int parity;
    // number of stop bits we expect to receive
    int stop;
};

void uart_tick(struct uart_state *uart, const int rx)
{
    if (uart->rx_state == RX_IDLE) {
        if (!rx) {
            uart->rx_state = RX_DATA;
            // sample first symbol after 1 and 1/2 bauds to skip over start bit
            uart->baudcount = TICKS_PER_BAUD + TICKS_PER_BAUD / 2 - 1;
            uart->rx_data   = 0;
            uart->rx_count  = 0;
        }
    } else if (uart->rx_state == RX_DATA && uart->baudcount <= 0) {
        uart->rx_data = ((rx & 1) << 31) | (uart->rx_data >> 1);
        uart->rx_count++;
        if (uart->rx_count >= uart->bits + uart->parity + uart->stop) {
            uart->rx_state = RX_IDLE;
            int shift      = 32 - (uart->bits + uart->parity + uart->stop);
            uint32_t data  = (uart->rx_data >> shift) & ((1 << uart->bits) - 1);
            printf("%c", (char)data);
            // TODO: check parity
        }
        uart->baudcount = TICKS_PER_BAUD - 1;
    } else if (uart->rx_state == RX_DATA && uart->baudcount > 0) {
        uart->baudcount--;
    } else {
        fprintf(stderr, "unreachable\n");
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char **argv, char **env)
{
    // Prevent unused variable warnings
    if (false && argc && argv && env) {
    }

    // Create logs/ directory in case we have traces to put under it
    Verilated::mkdir("logs");

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    // Set debug level, 0 is off, 9 is highest presently used
    // May be overridden by commandArgs argument parsing
    contextp->debug(0);

    // Randomization reset policy
    // May be overridden by commandArgs argument parsing
    contextp->randReset(2);

    // Verilator must compute traced signals
    contextp->traceEverOn(true);

    // Pass arguments so Verilated code can see them, e.g. $value$plusargs
    // This needs to be called before you create any model
    contextp->commandArgs(argc, argv);

    // Construct the Verilated model, from Vtop.h generated from Verilating
    // "pms_top.v". "TOP" will be the hierarchical name of the module.
    const std::unique_ptr<Vpms_top> top{new Vpms_top{contextp.get(), "TOP"}};

    struct uart_state uart = {};
    uart.rx_data           = 0;
    uart.rx_count          = 0;
    uart.baudcount         = 0;
    // 8n1
    uart.bits   = 8;
    uart.parity = 0;
    uart.stop   = 1;

    // Set printf to be unbuffered (i.e. dont buffer until newline). TODO: Make
    // this configurable.
    setbuf(stdout, NULL);

#if VM_TRACE
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 2); // Trace 99 levels of hierarchy
    tfp->open("logs/pms.vcd");

    Verilated::scopesDump();
#endif
    // Set Vpms_top's input signals
    top->rst_ni              = !0;
    top->sys_clk_i           = 0;
    top->ref_clk_i           = 0;
    top->bootsel_valid_i     = 1;
    top->bootsel_i           = 0;
    top->fc_fetch_en_valid_i = 1;
    top->fc_fetch_en_i       = 1;

    /*
    VL_IN8(&jtag_tck_i,0,0);
    VL_IN8(&jtag_trst_i,0,0);
    // VL_OUT8(&awid_mst_o,6,0);
    // VL_OUT8(&awlen_mst_o,7,0);
    // VL_OUT8(&awsize_mst_o,2,0);
    // VL_OUT8(&awburst_mst_o,1,0);
    // VL_OUT8(&awlock_mst_o,0,0);
    // VL_OUT8(&awcache_mst_o,3,0);
    // VL_OUT8(&awprot_mst_o,2,0);
    // VL_OUT8(&awqos_mst_o,3,0);
    // VL_OUT8(&awregion_mst_o,3,0);
    // VL_OUT8(&aw_atop_mst_o,5,0);
    // VL_OUT8(&awuser_mst_o,5,0);
    // VL_OUT8(&awvalid_mst_o,0,0);
    VL_IN8(&awready_mst_i,0,0);
    // VL_OUT8(&wstrb_mst_o,7,0);
    // VL_OUT8(&wlast_mst_o,0,0);
    // VL_OUT8(&wuser_mst_o,5,0);
    // VL_OUT8(&wvalid_mst_o,0,0);
    VL_IN8(&wready_mst_i,0,0);
    VL_IN8(&bid_mst_i,6,0);
    VL_IN8(&bresp_mst_i,1,0);
    VL_IN8(&buser_mst_i,5,0);
    VL_IN8(&bvalid_mst_i,0,0);
    // VL_OUT8(&bready_mst_o,0,0);
    // VL_OUT8(&arid_mst_o,6,0);
    // VL_OUT8(&arlen_mst_o,7,0);
    // VL_OUT8(&arsize_mst_o,2,0);
    // VL_OUT8(&arburst_mst_o,1,0);
    // VL_OUT8(&arlock_mst_o,0,0);
    // VL_OUT8(&arcache_mst_o,3,0);
    // VL_OUT8(&arprot_mst_o,2,0);
    // VL_OUT8(&arqos_mst_o,3,0);
    // VL_OUT8(&arregion_mst_o,3,0);
    // VL_OUT8(&aruser_mst_o,5,0);
    // VL_OUT8(&arvalid_mst_o,0,0);
    VL_IN8(&arready_mst_i,0,0);
    VL_IN8(&rid_mst_i,6,0);
    VL_IN8(&rresp_mst_i,1,0);
    VL_IN8(&rlast_mst_i,0,0);
    VL_IN8(&ruser_mst_i,5,0);
    VL_IN8(&rvalid_mst_i,0,0);
    // VL_OUT8(&rready_mst_o,0,0);
    VL_IN8(&awid_slv_i,5,0);
    VL_IN8(&awlen_slv_i,7,0);
    VL_IN8(&awsize_slv_i,2,0);
    VL_IN8(&awburst_slv_i,1,0);
    VL_IN8(&awlock_slv_i,0,0);
    VL_IN8(&awcache_slv_i,3,0);
    VL_IN8(&awprot_slv_i,2,0);
    VL_IN8(&awqos_slv_i,3,0);
    VL_IN8(&awregion_slv_i,3,0);
    VL_IN8(&aw_atop_slv_i,5,0);
    VL_IN8(&awuser_slv_i,5,0);
    VL_IN8(&awvalid_slv_i,0,0);
    // VL_OUT8(&awready_slv_o,0,0);
    VL_IN8(&wstrb_slv_i,7,0);
    VL_IN8(&wlast_slv_i,0,0);
    VL_IN8(&wuser_slv_i,5,0);
    VL_IN8(&wvalid_slv_i,0,0);
    // VL_OUT8(&wready_slv_o,0,0);
    // VL_OUT8(&bid_slv_o,5,0);
    // VL_OUT8(&bresp_slv_o,1,0);
    // VL_OUT8(&buser_slv_o,5,0);
    // VL_OUT8(&bvalid_slv_o,0,0);
    VL_IN8(&bready_slv_i,0,0);
    VL_IN8(&arid_slv_i,5,0);
    VL_IN8(&arlen_slv_i,7,0);
    VL_IN8(&arsize_slv_i,2,0);
    VL_IN8(&arburst_slv_i,1,0);
    VL_IN8(&arlock_slv_i,0,0);
    VL_IN8(&arcache_slv_i,3,0);
    VL_IN8(&arprot_slv_i,2,0);
    VL_IN8(&arqos_slv_i,3,0);
    VL_IN8(&arregion_slv_i,3,0);
    VL_IN8(&aruser_slv_i,5,0);
    VL_IN8(&arvalid_slv_i,0,0);
    // VL_OUT8(&arready_slv_o,0,0);
    // VL_OUT8(&rid_slv_o,5,0);
    // VL_OUT8(&rresp_slv_o,1,0);
    // VL_OUT8(&rlast_slv_o,0,0);
    // VL_OUT8(&ruser_slv_o,5,0);
    // VL_OUT8(&rvalid_slv_o,0,0);
    VL_IN8(&rready_slv_i,0,0);
    // VL_OUTW((&pad_cfg_o),191,0,6);
    // VL_OUT8(&jtag_tdo_o,0,0);
    VL_IN8(&jtag_tdi_i,0,0);
    VL_IN8(&jtag_tms_i,0,0);
    VL_IN8(&scg_irq_i,0,0);
    VL_IN8(&scp_irq_i,0,0);
    VL_IN8(&scp_secure_irq_i,0,0);
    // VL_OUT8(&out_i2c0_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c0_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c0_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c0_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c0_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c0_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2c0_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2c0_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2c0_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c1_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c1_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c1_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c1_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c1_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c1_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2c1_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2c1_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2c1_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c2_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c2_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c2_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c2_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c2_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c2_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2c2_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2c2_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2c2_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c3_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c3_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c3_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c3_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c3_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c3_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2c3_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2c3_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2c3_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c4_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c4_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c4_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c4_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c4_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c4_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2c4_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2c4_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2c4_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2cc_vrm_mst_scl_o,0,0);
    // VL_OUT8(&out_i2cc_vrm_mst_sda_o,0,0);
    // VL_OUT8(&out_i2cc_vrm_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2cc_vrm_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2cc_vrm_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2cc_vrm_mst_alert_o,0,0);
    VL_IN8(&in_i2cc_vrm_mst_scl_i,0,0);
    VL_IN8(&in_i2cc_vrm_mst_sda_i,0,0);
    VL_IN8(&in_i2cc_vrm_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c6_rtc_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c6_rtc_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c6_rtc_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c6_rtc_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c6_rtc_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c6_rtc_mst_alert_o,0,0);
    VL_IN8(&in_i2c6_rtc_mst_scl_i,0,0);
    VL_IN8(&in_i2c6_rtc_mst_sda_i,0,0);
    VL_IN8(&in_i2c6_rtc_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c7_bmc_slv_scl_o,0,0);
    // VL_OUT8(&out_i2c7_bmc_slv_sda_o,0,0);
    // VL_OUT8(&oe_i2c7_bmc_slv_scl_o,0,0);
    // VL_OUT8(&oe_i2c7_bmc_slv_sda_o,0,0);
    VL_IN8(&in_i2c7_bmc_slv_scl_i,0,0);
    VL_IN8(&in_i2c7_bmc_slv_sda_i,0,0);
    // VL_OUT8(&out_i2c8_os_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c8_os_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c8_os_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c8_os_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c8_os_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c8_os_mst_alert_o,0,0);
    VL_IN8(&in_i2c8_os_mst_scl_i,0,0);
    VL_IN8(&in_i2c8_os_mst_sda_i,0,0);
    VL_IN8(&in_i2c8_os_mst_alert_i,0,0);
    // VL_OUT8(&out_i2c9_pcie_pnp_mst_scl_o,0,0);
    // VL_OUT8(&out_i2c9_pcie_pnp_mst_sda_o,0,0);
    // VL_OUT8(&out_i2c9_pcie_pnp_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2c9_pcie_pnp_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2c9_pcie_pnp_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2c9_pcie_pnp_mst_alert_o,0,0);
    VL_IN8(&in_i2c9_pcie_pnp_mst_scl_i,0,0);
    VL_IN8(&in_i2c9_pcie_pnp_mst_sda_i,0,0);
    VL_IN8(&in_i2c9_pcie_pnp_mst_alert_i,0,0);
    // VL_OUT8(&out_i2ca_bios_mst_scl_o,0,0);
    // VL_OUT8(&out_i2ca_bios_mst_sda_o,0,0);
    // VL_OUT8(&out_i2ca_bios_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2ca_bios_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2ca_bios_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2ca_bios_mst_alert_o,0,0);
    VL_IN8(&in_i2ca_bios_mst_scl_i,0,0);
    VL_IN8(&in_i2ca_bios_mst_sda_i,0,0);
    VL_IN8(&in_i2ca_bios_mst_alert_i,0,0);
    // VL_OUT8(&out_i2cb_bmc_mst_scl_o,0,0);
    // VL_OUT8(&out_i2cb_bmc_mst_sda_o,0,0);
    // VL_OUT8(&out_i2cb_bmc_mst_alert_o,0,0);
    // VL_OUT8(&oe_i2cb_bmc_mst_scl_o,0,0);
    // VL_OUT8(&oe_i2cb_bmc_mst_sda_o,0,0);
    // VL_OUT8(&oe_i2cb_bmc_mst_alert_o,0,0);
    VL_IN8(&in_i2cb_bmc_mst_scl_i,0,0);
    VL_IN8(&in_i2cb_bmc_mst_sda_i,0,0);
    VL_IN8(&in_i2cb_bmc_mst_alert_i,0,0);
    VL_IN8(&in_qspi_flash_mst_csn0_i,0,0);
    VL_IN8(&in_qspi_flash_mst_csn1_i,0,0);
    VL_IN8(&in_qspi_flash_mst_sck_i,0,0);
    VL_IN8(&in_qspi_flash_mst_sdio_i,3,0);
    // VL_OUT8(&out_qspi_flash_mst_csn0_o,0,0);
    // VL_OUT8(&out_qspi_flash_mst_csn1_o,0,0);
    // VL_OUT8(&out_qspi_flash_mst_sck_o,0,0);
    // VL_OUT8(&out_qspi_flash_mst_sdio_o,3,0);
    // VL_OUT8(&oe_qspi_flash_mst_csn0_o,0,0);
    // VL_OUT8(&oe_qspi_flash_mst_csn1_o,0,0);
    // VL_OUT8(&oe_qspi_flash_mst_sck_o,0,0);
    // VL_OUT8(&oe_qspi_flash_mst_sdio_o,3,0);
    VL_IN8(&in_spi0_vrm_mst_csn0_i,0,0);
    VL_IN8(&in_spi0_vrm_mst_csn1_i,0,0);
    VL_IN8(&in_spi0_vrm_mst_sck_i,0,0);
    VL_IN8(&in_spi0_vrm_mst_si_i,0,0);
    VL_IN8(&in_spi0_vrm_mst_so_i,0,0);
    // VL_OUT8(&out_spi0_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&out_spi0_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&out_spi0_vrm_mst_sck_o,0,0);
    // VL_OUT8(&out_spi0_vrm_mst_si_o,0,0);
    // VL_OUT8(&out_spi0_vrm_mst_so_o,0,0);
    // VL_OUT8(&oe_spi0_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&oe_spi0_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&oe_spi0_vrm_mst_sck_o,0,0);
    // VL_OUT8(&oe_spi0_vrm_mst_si_o,0,0);
    // VL_OUT8(&oe_spi0_vrm_mst_so_o,0,0);
    VL_IN8(&in_spi1_vrm_mst_csn0_i,0,0);
    VL_IN8(&in_spi1_vrm_mst_csn1_i,0,0);
    VL_IN8(&in_spi1_vrm_mst_sck_i,0,0);
    VL_IN8(&in_spi1_vrm_mst_si_i,0,0);
    VL_IN8(&in_spi1_vrm_mst_so_i,0,0);
    // VL_OUT8(&out_spi1_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&out_spi1_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&out_spi1_vrm_mst_sck_o,0,0);
    // VL_OUT8(&out_spi1_vrm_mst_si_o,0,0);
    // VL_OUT8(&out_spi1_vrm_mst_so_o,0,0);
    // VL_OUT8(&oe_spi1_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&oe_spi1_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&oe_spi1_vrm_mst_sck_o,0,0);
    // VL_OUT8(&oe_spi1_vrm_mst_si_o,0,0);
    // VL_OUT8(&oe_spi1_vrm_mst_so_o,0,0);
    VL_IN8(&in_spi2_vrm_mst_csn0_i,0,0);
    VL_IN8(&in_spi2_vrm_mst_csn1_i,0,0);
    VL_IN8(&in_spi2_vrm_mst_sck_i,0,0);
    VL_IN8(&in_spi2_vrm_mst_si_i,0,0);
    VL_IN8(&in_spi2_vrm_mst_so_i,0,0);
    // VL_OUT8(&out_spi2_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&out_spi2_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&out_spi2_vrm_mst_sck_o,0,0);
    // VL_OUT8(&out_spi2_vrm_mst_si_o,0,0);
    // VL_OUT8(&out_spi2_vrm_mst_so_o,0,0);
    // VL_OUT8(&oe_spi2_vrm_mst_csn0_o,0,0);
    // VL_OUT8(&oe_spi2_vrm_mst_csn1_o,0,0);
    // VL_OUT8(&oe_spi2_vrm_mst_sck_o,0,0);
    // VL_OUT8(&oe_spi2_vrm_mst_si_o,0,0);
    // VL_OUT8(&oe_spi2_vrm_mst_so_o,0,0);
    VL_IN8(&in_spi3_vrm_mst_csn_i,0,0);
    VL_IN8(&in_spi3_vrm_mst_sck_i,0,0);
    VL_IN8(&in_spi3_vrm_mst_si_i,0,0);
    VL_IN8(&in_spi3_vrm_mst_so_i,0,0);
    // VL_OUT8(&out_spi3_vrm_mst_csn_o,0,0);
    // VL_OUT8(&out_spi3_vrm_mst_sck_o,0,0);
    // VL_OUT8(&out_spi3_vrm_mst_si_o,0,0);
    // VL_OUT8(&out_spi3_vrm_mst_so_o,0,0);
    // VL_OUT8(&oe_spi3_vrm_mst_csn_o,0,0);
    // VL_OUT8(&oe_spi3_vrm_mst_sck_o,0,0);
    // VL_OUT8(&oe_spi3_vrm_mst_si_o,0,0);
    // VL_OUT8(&oe_spi3_vrm_mst_so_o,0,0);
    VL_IN8(&in_spi4_vrm_mst_csn_i,0,0);
    VL_IN8(&in_spi4_vrm_mst_sck_i,0,0);
    VL_IN8(&in_spi4_vrm_mst_si_i,0,0);
    VL_IN8(&in_spi4_vrm_mst_so_i,0,0);
    VL_OUT8(&out_spi4_vrm_mst_csn_o,0,0);
    VL_OUT8(&out_spi4_vrm_mst_sck_o,0,0);
    VL_OUT8(&out_spi4_vrm_mst_si_o,0,0);
    VL_OUT8(&out_spi4_vrm_mst_so_o,0,0);
    VL_OUT8(&oe_spi4_vrm_mst_csn_o,0,0);
    VL_OUT8(&oe_spi4_vrm_mst_sck_o,0,0);
    VL_OUT8(&oe_spi4_vrm_mst_si_o,0,0);
    VL_OUT8(&oe_spi4_vrm_mst_so_o,0,0);
    // VL_IN8(&in_spi6_vrm_mst_csn_i,0,0);
    // VL_IN8(&in_spi6_vrm_mst_sck_i,0,0);
    // VL_IN8(&in_spi6_vrm_mst_si_i,0,0);
    // VL_IN8(&in_spi6_vrm_mst_so_i,0,0);
    VL_OUT8(&out_spi6_vrm_mst_csn_o,0,0);
    VL_OUT8(&out_spi6_vrm_mst_sck_o,0,0);
    VL_OUT8(&out_spi6_vrm_mst_si_o,0,0);
    VL_OUT8(&out_spi6_vrm_mst_so_o,0,0);
    VL_OUT8(&oe_spi6_vrm_mst_csn_o,0,0);
    VL_OUT8(&oe_spi6_vrm_mst_sck_o,0,0);
    VL_OUT8(&oe_spi6_vrm_mst_si_o,0,0);
    VL_OUT8(&oe_spi6_vrm_mst_so_o,0,0);
    // VL_IN8(&in_uart1_rxd_i,0,0);
    // VL_IN8(&in_uart1_txd_i,0,0);
    VL_OUT8(&out_uart1_rxd_o,0,0);
    VL_OUT8(&out_uart1_txd_o,0,0);
    VL_OUT8(&oe_uart1_rxd_o,0,0);
    VL_OUT8(&oe_uart1_txd_o,0,0);
    VL_OUT8(&out_i2c5_intr_sckt_scl_o,0,0);
    VL_OUT8(&out_i2c5_intr_sckt_sda_o,0,0);
    VL_OUT8(&out_i2c5_intr_sckt_alert_o,0,0);
    VL_OUT8(&oe_i2c5_intr_sckt_scl_o,0,0);
    VL_OUT8(&oe_i2c5_intr_sckt_sda_o,0,0);
    VL_OUT8(&oe_i2c5_intr_sckt_alert_o,0,0);
    // VL_IN8(&in_i2c5_intr_sckt_scl_i,0,0);
    // VL_IN8(&in_i2c5_intr_sckt_sda_i,0,0);
    // VL_IN8(&in_i2c5_intr_sckt_alert_i,0,0);
    // VL_IN8(&in_spi5_intr_sckt_csn_i,0,0);
    // VL_IN8(&in_spi5_intr_sckt_sck_i,0,0);
    // VL_IN8(&in_spi5_intr_sckt_si_i,0,0);
    // VL_IN8(&in_spi5_intr_sckt_so_i,0,0);
    // VL_IN8(&in_spi5_intr_sckt_alert_i,0,0);
    // VL_OUT8(&out_spi5_intr_sckt_csn_o,0,0);
    // VL_OUT8(&out_spi5_intr_sckt_sck_o,0,0);
    // VL_OUT8(&out_spi5_intr_sckt_si_o,0,0);
    // VL_OUT8(&out_spi5_intr_sckt_so_o,0,0);
    // VL_OUT8(&out_spi5_intr_sckt_alert_o,0,0);
    // VL_OUT8(&oe_spi5_intr_sckt_csn_o,0,0);
    // VL_OUT8(&oe_spi5_intr_sckt_sck_o,0,0);
    // VL_OUT8(&oe_spi5_intr_sckt_si_o,0,0);
    // VL_OUT8(&oe_spi5_intr_sckt_so_o,0,0);
    // VL_OUT8(&oe_spi5_intr_sckt_alert_o,0,0);
    // VL_OUT8(&out_slp_s3_l_o,0,0);
    // VL_OUT8(&out_slp_s4_l_o,0,0);
    // VL_OUT8(&out_slp_s5_l_o,0,0);
    // VL_OUT8(&out_sys_reset_l_o,0,0);
    // VL_OUT8(&out_sys_rsmrst_l_o,0,0);
    // VL_OUT8(&out_sys_pwr_btn_l_o,0,0);
    // VL_OUT8(&out_sys_pwrgd_in_o,0,0);
    // VL_OUT8(&out_sys_wake_l_o,0,0);
    // VL_OUT8(&out_cpu_pwrgd_out_o,0,0);
    // VL_OUT8(&out_cpu_throttle_o,2,0);
    // VL_OUT8(&out_cpu_thermtrip_l_o,0,0);
    // VL_OUT8(&out_cpu_errcode_o,3,0);
    // VL_OUT8(&out_cpu_reset_out_l_o,0,0);
    // VL_OUT8(&out_cpu_socket_id_o,1,0);
    // VL_OUT8(&out_cpu_strap_o,3,0);
    // VL_OUT8(&oe_slp_s3_l_o,0,0);
    // VL_OUT8(&oe_slp_s4_l_o,0,0);
    // VL_OUT8(&oe_slp_s5_l_o,0,0);
    // VL_OUT8(&oe_sys_reset_l_o,0,0);
    // VL_OUT8(&oe_sys_rsmrst_l_o,0,0);
    // VL_OUT8(&oe_sys_pwr_btn_l_o,0,0);
    // VL_OUT8(&oe_sys_pwrgd_in_o,0,0);
    // VL_OUT8(&oe_sys_wake_l_o,0,0);
    // VL_OUT8(&oe_cpu_pwrgd_out_o,0,0);
    // VL_OUT8(&oe_cpu_throttle_o,2,0);
    // VL_OUT8(&oe_cpu_thermtrip_l_o,0,0);
    // VL_OUT8(&oe_cpu_errcode_o,3,0);
    // VL_OUT8(&oe_cpu_reset_out_l_o,0,0);
    // VL_OUT8(&oe_cpu_socket_id_o,1,0);
    // VL_OUT8(&oe_cpu_strap_o,3,0);
    VL_IN8(&in_slp_s3_l_i,0,0);
    VL_IN8(&in_slp_s4_l_i,0,0);
    VL_IN8(&in_slp_s5_l_i,0,0);
    VL_IN8(&in_sys_reset_l_i,0,0);
    VL_IN8(&in_sys_rsmrst_l_i,0,0);
    VL_IN8(&in_sys_pwr_btn_l_i,0,0);
    VL_IN8(&in_sys_pwrgd_in_i,0,0);
    VL_IN8(&in_sys_wake_l_i,0,0);
    VL_IN8(&in_cpu_pwrgd_out_i,0,0);
    VL_IN8(&in_cpu_throttle_i,2,0);
    VL_IN8(&in_cpu_thermtrip_l_i,0,0);
    VL_IN8(&in_cpu_errcode_i,3,0);
    VL_IN8(&in_cpu_reset_out_l_i,0,0);
    VL_IN8(&in_cpu_socket_id_i,1,0);
    VL_IN8(&in_cpu_strap_i,3,0);

    VL_IN8(&bootsel_valid_i,0,0);
    VL_IN8(&bootsel_i,1,0);

    VL_IN8(&fc_fetch_en_valid_i,0,0);
    VL_IN8(&fc_fetch_en_i,0,0);

    // VL_OUT(&awaddr_mst_o,31,0);
    // VL_OUT(&araddr_mst_o,31,0);
    VL_IN(&awaddr_slv_i,31,0);
    VL_IN(&araddr_slv_i,31,0);
    VL_INW((&mbox_irq_i),71,0,3);
    VL_INW((&mbox_secure_irq_i),71,0,3);
    // VL_OUT64(&wdata_mst_o,63,0);
    VL_IN64(&rdata_mst_i,63,0);
    VL_IN64(&wdata_slv_i,63,0);
    // VL_OUT64(&rdata_slv_o,63,0);
    */

    // Simulate until $finish
    while (!contextp->gotFinish()) {
        contextp->timeInc(TIMEUNITS_PER_PERIOD / 2);

        // Toggle a fast (time/2 period) clock
        top->sys_clk_i = !top->sys_clk_i;
        top->ref_clk_i = !top->ref_clk_i;

        if (!top->sys_clk_i) {
            if (contextp->time() > 1 * TIMEUNITS_PER_PERIOD &&
                contextp->time() < 10 * TIMEUNITS_PER_PERIOD) {
                top->rst_ni = !1; // Assert reset
            } else {
                top->rst_ni = !0; // Deassert reset
            }
        }
        // Evaluate model
        // (If you have multiple models being simulated in the same
        // timestep then instead of eval(), call eval_step() on each, then
        // eval_end_step() on each. See the manual.)
        top->eval();

        if (top->ref_clk_i && !!top->rst_ni)
            uart_tick(&uart, top->out_uart1_txd_o);

#if VM_TRACE
        tfp->dump(contextp->time());
#endif
    }

    // Final model cleanup
    top->final();
#if VM_TRACE
    if (tfp)
        tfp->close();
#endif

        // Coverage analysis (calling write only after the test is known to
        // pass)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    contextp->coveragep()->write("logs/coverage.dat");
#endif

    // Don't use exit() or destructor won't get called
    return 0;
}

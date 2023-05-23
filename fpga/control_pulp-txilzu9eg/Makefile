SHELL=/bin/bash

PROJECT:=control_pulp-txilzu9eg
VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source scripts/prologue.tcl

ROOT_DIR = $(shell git rev-parse --show-toplevel)
FPGA_OUT_DIR:=$(ROOT_DIR)/fpga/output

# Create output directory. It contains:
# - bitstream, HDF (Vivado implementation)                   -> BOOT.BIN (present also separately)
# - fsbl.elf, pmufw.elf, uboot.elf zcu102 PS (Petalinux)     -> BOOT.BIN
# - Linux kernel image zcu102 (Petalinux)                    -> image.ub
# - Root filesystem zcu102 (Buildroot)                       -> rootfs.tar
$(FPGA_OUT_DIR):
	if [ ! -d "$@" ]; then mkdir -p $@; fi

include fpga-settings.mk

.DEFAULT_GOAL:=help

.PHONY: help bootrom rtl/fpga_autogen_rom.sv bit bit-gui ips \
	clean-ips clk clean-clk bram clean-bram clean-bootrom clean

bootrom: rtl/fpga_autogen_rom.sv

rtl/fpga_autogen_rom.sv:
	$(MAKE) -C ../../boot/ fpga_autogen_rom.sv
	cp ../../boot/fpga_autogen_rom.sv $@

bit: $(FPGA_OUT_DIR) ips rtl/fpga_autogen_rom.sv ## Generate the bitstream for control_pulp interfacing Zynq PS with vivado in batch mode.
	$(MAKE) -C ips/control_pulp_txilzu9eg package-control-pulp-ip # create custom Xilinx IP for control_pulp
	$(VIVADO) -mode batch -source tcl/control_pulp_exilzcu102.tcl # interface control_pulp with Zynq PS in a Vivado block design
	cp $(CURDIR)/control_pulp-exilzcu102.runs/impl_1/control_pulp_exilzcu102_wrapper.bit $(FPGA_OUT_DIR)/pms.bit # copy to output directory
	cp $(CURDIR)/control_pulp-txilzu9eg/control_pulp-txilzu9eg.sdk/control_pulp-txilzu9eg_wrapper.hdf $(FPGA_OUT_DIR)/pms.hdf # copy to output directory

bit-gui: $(FPGA_OUT_DIR) ips rtl/fpga_autogen_rom.sv ## Generate the bitstream for control_pulp interfacing Zynq PS with vivado in GUI mode.
	$(MAKE) -C ips/control_pulp_txilzu9eg package-control-pulp-ip-gui # create IP for control_pulp
	$(VIVADO) -mode gui -source tcl/control_pulp_exilzcu102.tcl # interface control_pulp with Zynq PS in a Vivado block design
	cp $(CURDIR)/control_pulp-exilzcu102.runs/impl_1/control_pulp_exilzcu102_wrapper.bit $(FPGA_OUT_DIR)/pms.bit # copy to output directory
	cp $(CURDIR)/control_pulp-txilzu9eg/control_pulp-txilzu9eg.sdk/control_pulp-txilzu9eg_wrapper.hdf $(FPGA_OUT_DIR)/pms.hdf # copy to output directory

# IPs synthesis
ips: clk ## Synthesizes necessary xilinx IP for control_pulp (clk_wizards)

clean: clean-ips clean-clk clean-vivado

clean-ips: clean-clk ## Clean all IPs

clk: ## Synthesizes the Xilinx Clocking Manager IPs
	cd ips/xilinx_clk_mngr; make all
	cd ips/xilinx_slow_clk_mngr; make all

clean-clk: ## Removes all Clocking Wizard IP outputs
	cd ips/xilinx_clk_mngr; make clean
	cd ips/xilinx_slow_clk_mngr; make clean

clean-vivado: clean-vivado-ip clean-vivado-bd

clean-vivado-ip:
	$(MAKE) -C ips/control_pulp_txilzu9eg clean-vivado-ip

clean-vivado-bd: ## Removes *.log files and vivado related files (rm -rf vivado*), keeping bitstream and hdf files for linux images generation only
	$(RM) -r .Xil
	$(RM) -r *.log
	$(RM) -r vivado*
	$(RM) -r control_pulp-exilzcu102.*
	$(RM) -r control_pulp-txilzu9eg

help:
	@grep -E -h '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

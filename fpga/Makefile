# Copyright 2023 ETH Zurich and University of Bologna
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#
# Robert Balas <balasr@iis.ee.ethz.ch>
# Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

SHELL=/bin/bash

ROOT_DIR = $(shell git rev-parse --show-toplevel)
FPGA_LINUX_DIR:=$(CURDIR)/linux
BR_OUT_DIR:=$(FPGA_LINUX_DIR)/buildroot-out
ARCH64_OUT_DIR:=$(FPGA_LINUX_DIR)/tc-har-olinux
FPGA_OUT_DIR:=$(ROOT_DIR)/fpga/output

.DEFAULT_GOAL:=help

.PHONY: all zcu102 zcu102-bitstream zcu102-boot-images zcu102-buildroot \
	boot-images tc-har-olinux buildroot clean-zcu102 \
	fw-upload fw-compile fw-clean \
	clean-zcu102-boot-images clean-zcu102-buildroot help

all: zcu102

zcu102: zcu102-bitstream zcu102-boot-images zcu102-buildroot ## Generates the bitstream and HDF files, Petalinux images and Linux environment with a single command.

zcu102-bitstream: ## Generates the bitstream and HDF files for the zcu102.
	$(MAKE) -C control_pulp-txilzu9eg bit

zcu102-boot-images: boot-images ## Generate bootable image files for the ARMv8 host of the zcu102 using Xilinx Petalinux, starting from the bitstream and the HDF files.

zcu102-buildroot: buildroot ## Generate embedded Linux environment using Buildroot.

## Linux and boot image

boot-images: $(FPGA_OUT_DIR)/BOOT.BIN $(FPGA_OUT_DIR)/image.ub

$(FPGA_OUT_DIR)/BOOT.BIN $(FPGA_OUT_DIR)/image.ub: $(FPGA_OUT_DIR)/pms.bit $(FPGA_OUT_DIR)/pms.hdf
	cd $(FPGA_LINUX_DIR)/petalinux && ./zcu102.sh
	cp $(FPGA_LINUX_DIR)/petalinux/zcu102/images/linux/{BOOT.BIN,image.ub} $(FPGA_OUT_DIR)

## Rootfs

buildroot: $(FPGA_OUT_DIR)/rootfs.tar

$(FPGA_OUT_DIR)/rootfs.tar: $(aarch64-binaries) $(FPGA_LINUX_DIR)/buildroot $(FPGA_OUT_DIR)/pms.bit
	@$(ROOT_DIR)/env/check_environment.sh
	mkdir -p $(BR_OUT_DIR)
	$(MAKE) O=$(BR_OUT_DIR) BR2_EXTERNAL=$(FPGA_LINUX_DIR) -C $(FPGA_LINUX_DIR)/buildroot har_exilzcu102_defconfig
	if [ -a $(ROOT_DIR)/local.cfg ]; then cat $(ROOT_DIR)/local.cfg >> $(BR_OUT_DIR)/.config; fi
	$(MAKE) -C $(BR_OUT_DIR)
	cp $(BR_OUT_DIR)/images/rootfs.tar $(FPGA_OUT_DIR)/rootfs.tar

$(FPGA_LINUX_DIR)/buildroot:
	if [ ! -d "$@" ]; then \
		cd $(FPGA_LINUX_DIR) && git clone https://github.com/buildroot/buildroot -b 2019.02.1; \
	fi;

## Compile Aarch64 Linux toolchain

tc-har-olinux: $(aarch64-binaries) ## Compile ARM Aarch64 Linux toolchain

aarch64-binaries = $(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-gcc \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-g++ \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-cpp \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-ar \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-as \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-ld \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-nm \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-ldd \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-elfedit \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-addr2line \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-objcopy \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-objdump \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-ranlib \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-readelf \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-size \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-strings \
	$(CPULP_INSTALL)/bin/aarch64-none-linux-gnu-strip

$(aarch64-binaries):
	@$(ROOT_DIR)/env/check_environment.sh; \
	mkdir -p $(ARCH64_OUT_DIR); \
	cd $(ARCH64_OUT_DIR) && $(ROOT_DIR)/fpga/toolchain/build.sh \
		$(ROOT_DIR)/fpga/toolchain/har-olinux.config # TODO missing something? See HERO script

## Compile and deploy PMS Firmware for FPGA


fw-upload: $(ROOT_DIR)/fw/Firmware.stim ## Upload the PMS Firmware to your FPGA. Point $FPGA_HOSTNAME to it.
	@echo "$${FPGA_HOSTNAME:?Set \$$FPGA_HOSTNAME to your FPGAs hostname.}"
	scp $^ root@$(FPGA_HOSTNAME):~/stim.txt

fw-compile: $(ROOT_DIR)/fw/Firmware.stim ## Compile the PMS Firmware for the FPGA.

$(ROOT_DIR)/fw/Firmware.stim:
	if [ ! -d "$(ROOT_DIR)/freertos" ]; then \
		$(MAKE) -C $(ROOT_DIR) freertos; \
	fi;
	if [ ! -d "$(ROOT_DIR)/fw" ]; then \
		$(MAKE) -C $(ROOT_DIR) fw; \
	fi;
	make -C $(ROOT_DIR)/fw \
		RISCV="/usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0-rc1" \
		CFLAGS="-Og -g3 -march=rv32imc_zfinx_xcorev -mabi=ilp32" \
		ASFLAGS="-Os -g3 -march=rv32imc_zfinx_xcorev -mabi=ilp32" \
		MAKE_FLAGS="-DCI_TEST_ITERATION=10 -DMEASURE_ACTIVE=2 -DDEBUG_ACTIVE \
		-DPCF_FREERTOS_TICK_RATE_HZ=2000 -DDEFAULT_SYSTEM_CLOCK=100000000u \
		-DCI_TEST -DCONTROL_DATA_TYPE=1 -DUSE_INSTRUCTIONS_COMPOSITION" \
		all

fw-clean: ## Clean PMS Firmware
	make -C $(ROOT_DIR)/fw clean

## Clean

clean-zcu102: ## Removes *.log files and vivado related files (rm -rf vivado*).
	$(MAKE) -C control_pulp-txilzu9eg clean-vivado

clean-zcu102-boot-images: ## Clean boot images
	$(RM) $(FPGA_OUT_DIR)/BOOT.BIN $(FPGA_OUT_DIR)/image.ub

clean-zcu102-buildroot: ## Clean buildroot
	$(RM) $(FPGA_OUT_DIR)/rootfs.tar
	$(MAKE) O=$(BR_OUT_DIR) BR2_EXTERNAL=$(FPGA_LINUX_DIR) -C $(FPGA_LINUX_DIR)/buildroot clean

help: ## Show this help message
	@echo "Control-PULP on FPGA"
	@echo ""
	@echo "- Call 'make zcu102-bitstream' to generate the bitstream for the zcu102 board with ControlPULP design."
	@echo "- By default make invokes 'vivado'  to start Xilinx Vivado. This behaviour can be overriden by setting the make variable 'VIVADO'"
	@echo "- E.g. make zcu102-bitstream VIVADO='vitis-2019.2 vivado' for ETH centos machines."
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

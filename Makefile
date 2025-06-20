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

# SPDX-License-Identifier: Apache-2.0

# Robert Balas <balasr@iis.ee.ethz.ch>
# Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

SHELL = /bin/bash

CTAGS  ?= ctags
BENDER ?= bender

ROOT_DIR        = $(strip $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))))
CPULP_SLINK_DIR := $(shell $(BENDER) path serial_link)

TARGET        ?= .
TARGET_ABS    = $(abspath $(lastword $(TARGET)))
REPORT        ?= 0
LINT_LOGS_DIR = $(ROOT_DIR)/util/verible/rpt

VLOG       = vlog
VLOG_FLAGS =
VOPT       = vopt
VOPT_FLAGS = +acc
VSIM       = vsim
VSIM_FLAGS =

VCS           = vcs
VCS_FLAGS     =
VCS_SIM_FLAGS =

ifeq ($(VERILATOR_ROOT),)
VERILATOR ?= verilator
else
export VERILATOR_ROOT
VERILATOR ?= $(VERILATOR_ROOT)/bin/verilator
endif
VERI_FLAGS     =
VERI_SIM_FLAGS =


SVLIB       = tb/remote_bitbang/librbs

SIM_TOP     = tb_sw

TEST_DIR  = $(ROOT_DIR)/sw/tests
BWRUNTEST = $(ROOT_DIR)/sw/pulp-runtime/scripts/bwruntests.py
PULP_RUNTIME = $(ROOT_DIR)/sw/pulp-runtime

# make variables visible in submake
# don't export variable if undefined/empty
define export_if_def
  ifneq ($(strip $(1)),)
    export $(1)
  endif
endef

export VSIM_PATH

$(export_if_def VSIM)
$(export_if_def VSIM_FLAGS)
$(export_if_def VLOG)
$(export_if_def VLOG_FLAGS)
$(export_if_def VOPT)
$(export_if_def VOPT_FLAGS)
$(export_if_def SIM_TOP)
$(export_if_def VERILATOR)
$(export_if_def QUESTA)

NONFREE_REMOTE = git@iis-git.ee.ethz.ch:pms/control-pulp-nonfree.git
NONFREE_COMMIT = ee818ec

.PHONY: nonfree-init
nonfree-init:
	git clone $(NONFREE_REMOTE) $(ROOT_DIR)/nonfree
	cd $(ROOT_DIR)/nonfree && git checkout $(NONFREE_COMMIT)

-include $(ROOT_DIR)/nonfree/nonfree.mk

.PHONY: all
## Compile RTL
all: build

.PHONY: all-opt
## Compile RTL with maximum optimizations for simulation speed
all-opt: build-opt

#
# HPC Cosim
#

.PHONY: hpc-cosim
hpc-cosim: sw/cosim
sw/cosim:
	git clone https://github.com/pulp-platform/pulp_hpc_cosim.git $@
	cd $@; \
	git checkout b822e95bbf0dc627d60898d6c91f9676d452fc40; \
	git submodule update --init --recursive

#
# VIP
#

tb/vip/vip-proprietary:
	cd tb/vip && ./get-vips.sh --yes

vip: tb/vip/vip-proprietary

#
# Re-generate file lists and scripts
#
BENDER_SIM_TARGETS += -t test
BENDER_SIM_TARGETS += -t simulation

BENDER_SYNTH_TARGETS += -t synthesis
BENDER_SYNTH_TARGETS += -t gf22

BENDER_BASE_TARGETS += -t rtl
BENDER_BASE_TARGETS += -t pulp
BENDER_BASE_TARGETS += -t cv32e40p_use_ff_regfile

.PHONY: gen
## (Re)generate file lists and compilation scripts. Use GEN_FLAGS=--help for help.
gen: update-serial-link
# Questa
	$(BENDER) script flist-plus $(BENDER_SIM_TARGETS) $(BENDER_BASE_TARGETS) > sim/gen/sim.f
	sed -i 's?$(ROOT_DIR)?\$$CPROOT?g' sim/gen/sim.f
# Verilator
	$(BENDER) script verilator $(BENDER_BASE_TARGETS) > sim/gen/veri.f
	sed -i 's?$(ROOT_DIR)?\$$ROOT?g' sim/gen/veri.f
# Vivado
	$(BENDER) script vivado $(BENDER_BASE_TARGETS) --define PULP_FPGA_EMUL > fpga/gen/vivado.tcl
	$(BENDER) script vivado $(BENDER_BASE_TARGETS) --define PULP_FPGA_EMUL --only-includes --no-simset > fpga/gen/vivado_includes.tcl
# Hack: rewrite fileset
	sed -i 's/current_fileset/get_filesets control_pulp_exilzcu102_pms_top_fpga_0_0/g' fpga/gen/vivado_includes.tcl
# Synthesis
	if [[ -d nonfree ]]; then \
	$(BENDER) script flist-plus $(BENDER_SYNTH_TARGETS) $(BENDER_BASE_TARGETS) > nonfree/gen/synopsys.f; \
	sed -i 's?$(ROOT_DIR)?\$$CPROOT?g' nonfree/gen/synopsys.f; \
	fi

.PHONY: update-serial-link
# Custom serial link
update-serial-link: $(ROOT_DIR)/hw/serial_link.hjson
	cp $< $(CPULP_SLINK_DIR)/src/regs/serial_link.hjson
	$(MAKE) -C $(CPULP_SLINK_DIR) update-regs BENDER="$(BENDER)"

.PHONY: gen-with-vip
## (Re)generate file lists and compilation scripts including all VIPs.
gen-with-vip: BENDER_SIM_TARGETS +=-t flash_vip -t i2c_vip
gen-with-vip: vip gen

#
# VSIM
#

.PHONY: build
## Build vsim RTL model
build:
	CPROOT=$(ROOT_DIR) \
	$(VLOG) -sv -64 -suppress 2583 -suppress 13314 -svinputport=compat $(VLOG_FLAGS) -f sim/gen/sim.f -work sim/work/
	$(VOPT) -timescale 1ps/1ps -o vopt_tb -work sim/work/ $(VOPT_FLAGS) $(SIM_TOP)

.PHONY: build-opt
# We only keep visibility to the exit_status signal so that we can figure out
# whether the simulation succeeded
## Build vsim RTL model with optimizations
build-opt: VOPT_FLAGS=-O5 +acc=n+'/$(SIM_TOP)/exit_status'
build-opt: build

.PHONY: sim
## Simulate RTL with Questasim (GUI)
sim: $(SVLIB).so
	cd sim && \
	$(VSIM) -64 -gui vopt_tb \
		-suppress vsim-3009 -suppress vsim-8386 \
		+UVM_NO_RELNOTES -stats -t ps \
		-sv_lib ../$(SVLIB) $(VSIM_FLAGS) $(SIM_FLAGS) \
		-do "set StdArithNoWarnings 1;set NumericStdNoWarnings 1"

# example: make simc VSIM_FLAGS="+stimuli=path-to-stim.txt"
.PHONY: simc
## Simulate RTL with Questasim
simc: $(SVLIB).so
	cd sim && \
	$(VSIM) -64 -c vopt_tb \
		-suppress vsim-3009 -suppress vsim-8386 \
		+UVM_NO_RELNOTES -stats -t ps \
		-sv_lib ../$(SVLIB) $(VSIM_FLAGS) $(SIM_FLAGS) \
		-do "set StdArithNoWarnings 1; set NumericStdNoWarnings 1" \
		-do "onfinish stop" \
		-do "run -all" \
		-do "if { [coverage attribute -concise -name TESTSTATUS] >= 3 } { quit -code 1 }" \
		-do 'set hier [env];set sim_top [lindex [split $$hier /] 1];\
quit -code [examine -radix decimal sim:/$$sim_top/exit_status]'


#
# VERILATOR
#

.PHONY: verilate
## Build verilator RTL model
verilate: sim/gen/veri.f sim/vcontrolpulp

.PHONY: sim/vcontrolpulp
sim/vcontrolpulp:
	ROOT=$(ROOT_DIR) \
	$(VERILATOR) --cc --exe --build -j 8 --threads 8 \
	-Wno-BLKANDNBLK -Wno-UNOPTFLAT -Wno-fatal \
	--x-assign '0' --x-initial '0' --x-initial-edge --timescale 1ps \
	--clk 'ref_clk_i' --clk 'sys_clk_i' \
	-GSIM_STDOUT=0 \
	--top pms_top -o vcontrolpulp \
	-f sim/gen/veri.f ../tb/tb_sw_axiboot.cpp $(VERI_FLAGS) \
	--Mdir sim/vobj_dir
	cp sim/vobj_dir/vcontrolpulp sim/vcontrolpulp

.PHONY: veri-build
## Build verilator RTL model
veri-build: verilate

.PHONY: veri-sim
## Simulate verilator RTL model
veri-sim:
	./sim/vcontrolpulp

#
# VCS
#

.PHONY: vcsify
## Build vcs RTL model
vcsify: sim/gen/sim.f
	cd sim && \
	CPROOT=$(ROOT_DIR) \
	$(VCS) -full64 -sverilog -assert svaext -j 8 -CFLAGS "-Os" -V +vcs+flush+log \
		$(if $(VERDI), -debug_access+all -kdb) -ntb_opts uvm-1.2 \
		-sim_res=1ps -timescale=1ps/1ps \
		-top $(SIM_TOP) $(VCS_FLAGS) -file ../$^

.PHONY: vcs-build
## Build vcs RTL model
vcs-build: vcsify

.PHONY: vcs-sim
## Simulate RTL with vcs (gui)
vcs-sim:
	cd sim && ./simv -gui +UVM_NO_RELNOTES -exitstatus $(VCS_SIM_FLAGS) $(SIM_FLAGS)

.PHONY: vcs-simc
## Simulate RTL with vcs
vcs-simc:
	cd sim && ./simv +UVM_NO_RELNOTES -exitstatus $(VCS_SIM_FLAGS) $(SIM_FLAGS)


#
# DPI libraries
#

$(SVLIB).so:
	$(MAKE) -C tb/remote_bitbang all

#
# Misc
#

.PHONY: clean
## Remove the RTL model files
clean:
	$(RM) -r sim/work sim/modelsim.ini
	$(RM) -r sim/simv sim/simv.daidir/ sim/vc_hdrs.h sim/csrc
	$(RM) -r sim/ucli.key sim/verdiLog sim/inter.fsdb
	$(RM) -r sim/vobj_dir sim/vcontrolpulp
	$(MAKE) -C tb/remote_bitbang clean


.PHONY: help
help: Makefile
	@printf "ControlPULP\n"
	@printf "Available targets\n\n"
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "%-15s %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

# maintenance options
.PHONY: import_bootcode
## Compile and import the latest bootcode from boot/.
import_bootcode: boot/boot_code.cde boot/boot_code_fpga.cde boot/fpga_autogen_rom.sv boot/asic_autogen_rom.sv
	mv boot/fpga_autogen_rom.sv fpga/control_pulp-txilzu9eg/rtl/fpga_autogen_rom.sv
	mv boot/asic_autogen_rom.sv ips/pulp_soc/rtl/pulp_soc/asic_autogen_rom.sv

boot/boot_code.cde: boot/boot_code.c boot/crt0.S boot/link.ld
	$(MAKE) -C boot boot_code.cde

boot/boot_code_fpga.cde: boot/boot_code.c boot/crt0.S boot/link.ld
	$(MAKE) -C boot boot_code_fpga.cde

boot/fpga_autogen_rom.sv: boot/boot_code_fpga.cde
	$(MAKE) -C boot fpga_autogen_rom.sv

boot/asic_autogen_rom.sv: boot/boot_code.cde
	$(MAKE) -C boot asic_autogen_rom.sv

install: $(INSTALL_HEADERS)

.PHONY: test
## run tests on local machine
test: test-gitlab


#
# Verible Formatter
#

# module_net_variable_alignment flush-left is not optimal but better than the
# ugly bracket expansion
.PHONY: verible-format
## Call verible-verilog-format tool
verible-format:
	find $(TARGET_ABS) -name '*.sv' -exec sh -c \
	'$(ROOT_DIR)/util/verible/bin/verible-verilog-format \
	--wrap_spaces 2 \
	--assignment_statement_alignment align \
	--module_net_variable_alignment flush-left \
	--named_parameter_alignment align \
	--named_port_alignment align \
	--port_declarations_alignment preserve \
	--inplace $$1' -- {} \;

# Syntax checker
.PHONY: verible-syntax
## Call verible-verilog-syntax tool
verible-syntax:
	find $(TARGET_ABS) -name '*.sv' -exec sh -c \
	'$(ROOT_DIR)/util/verible/bin/verible-verilog-syntax $$1' -- {} \;

# Linter
.PHONY: verible-lint
## Call verible-verilog-lint tool
verible-lint:
ifeq ($(REPORT), 1)
	find $(TARGET_ABS) -name '*.sv' -exec sh -c \
	'$(ROOT_DIR)/util/verible/bin/verible-verilog-lint \
		--rules_config $(ROOT_DIR)/util/verible/rules.vbl $$1 > \
		$(LINT_LOGS_DIR)/$$(basename $${1%.sv}-lint.log)' \
		-- {} \;
	$(ROOT_DIR)/util/verible/parse-lint-report.py --repdir $(LINT_LOGS_DIR)
	$(RM) $(LINT_LOGS_DIR)/*.log
else
	find $(TARGET_ABS) -name '*.sv' -exec sh -c \
	'$(ROOT_DIR)/util/verible/bin/verible-verilog-lint \
		--rules_config $(ROOT_DIR)/util/verible/rules.vbl $$1' \
		-- {} \;
endif

.PHONY: verible-all
## Call all supported verible tools on target
verible-all: verible-syntax verible-lint verible-format

.PHONY: verible-update
## Format unstaged/uncommitted modifications
verible-update:
	$(ROOT_DIR)/util/verible/bin/git-verible-verilog-format.sh && git add -u

.PHONY: verible-update-interactive
## Format unstaged/uncommitted modifications interactively
verible-update-interactive:
	$(ROOT_DIR)/util/verible/bin/git-verible-verilog-format.sh

.PHONY: verible-clean
verible-clean:
	$(RM) -r $(ROOT_DIR)/util/verible/rpt

#
# GITLAB CI
#

# continuous integration on gitlab
# special case for soc riscv tests
$(TEST_DIR)/runtime-tests/riscv_tests_soc: $(TEST_DIR)/runtime-tests
	cp -r $(TEST_DIR)/runtime-tests/riscv_tests/ $(TEST_DIR)/runtime-tests/riscv_tests_soc


.PHONY: test-rt-periph
## Run only test peripherals on pulp-runtime
test-rt-periph:
	source env/env.sh; \
	touch $(TEST_DIR)/runtime-tests/simplified-periph-runtime.xml; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 7200 --yaml --max-procs 2 \
		-o simplified-periph-runtime.xml periph-tests.yaml

.PHONY: test-rt-ml
## Run only ml tests on pulp-runtime
test-rt-ml: $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-ml.xml ml-tests.yaml

.PHONY: test-rt-riscv
## Run only riscv tests on pulp-runtime
test-rt-riscv: $(TEST_DIR)/runtime-tests $(TEST_DIR)/runtime-tests/riscv_tests_soc
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-riscv.xml riscv-tests.yaml

.PHONY: test-rt-seq-bare
## Run only sequential tests on pulp-runtime
test-rt-seq-bare: $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-sequential.xml sequential-bare-tests.yaml

.PHONY: test-rt-par-bare
## Run only parallel tests on pulp-runtime
test-rt-par-bare: $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-parallel.xml parallel-bare-tests.yaml

.PHONY: test-rt-control-pulp
## Run control pulp tests on pulp-runtime
test-rt-control-pulp: $(TEST_DIR)/control-pulp-tests
	source env/env.sh; \
	cd $(TEST_DIR)/control-pulp-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-control-pulp.xml control-pulp-tests.yaml

.PHONY: test-rt-tcdm
## Run tcdm tests on pulp-runtime
test-rt-tcdm: $(PULP_RUNTIME) $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-tcdm.xml tcdm-tests.yaml

.PHONY: test-rt-soc_interconnect
## Run soc_interconnect tests on pulp-runtime
test-rt-soc-interconnect: $(PULP_RUNTIME) $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-soc-interconnect.xml soc-interconnect-tests.yaml

.PHONY: test-rt-mchan
## Run mchan tests on pulp-runtime
test-rt-mchan: $(PULP_RUNTIME) $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-mchan.xml mchan-tests.yaml

.PHONY: test-rt-idma
## Run idma tests on pulp-runtime
test-rt-idma: $(PULP_RUNTIME) $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-mchan.xml idma-tests.yaml

.PHONY: test-rt-coremark
## Run coremark tests on pulp-runtime
test-rt-coremark: $(PULP_RUNTIME) $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-coremark.xml coremark-tests.yaml

.PHONY: test-rt-perfcounters
## Run performance counters sample test on pulp-runtime
test-rt-perfcounters: $(TEST_DIR)/runtime-tests
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) --proc-verbose -v \
		--report-junit -t 3600 --yaml --max-procs 2 \
		-o runtime-perf-counters.xml perf-counters-tests.yaml

.PHONY: test-rx-mchan
## Run tests to measure clock cycles required to receive data from the outside of the PMS (with and without DMA)
test-rx-mchan:
	source env/env.sh; \
	cd $(TEST_DIR)/control-pulp-tests/sensors_transfers && $(BWRUNTEST) \
		--proc-verbose -v --report-junit -t 9800 --yaml -o sensors-tests.xml sensors-tests.yaml

.PHONY: test-rx-idma
## Run tests to measure clock cycles required to receive data from the outside of the PMS (with and without DMA) in the cluster
test-rx-idma:
	source env/env.sh; \
	cd $(TEST_DIR)/control-pulp-tests/pvt_sensors_idma_cl && $(BWRUNTEST) \
		--proc-verbose -v --report-junit -t 9800 --yaml -o sensors-tests.xml sensors-tests.yaml

.PHONY: test-avs
## Run tests with AVS bus
test-avs:
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests/peripherals/avs && $(BWRUNTEST) \
		--proc-verbose -v --report-junit -t 9800 --yaml -o avs-tests.xml avs-tests.yaml

.PHONY: test-i2c-slv-irq
## Run tests with I2C slv with itnerrupt notification for end of transfer
test-i2c-slv-irq:
	source env/env.sh; \
	cd $(TEST_DIR)/runtime-tests && $(BWRUNTEST) \
		--proc-verbose -v --report-junit -t 9800 --yaml -o i2c-slv-tests.xml i2c-slv-tests.yaml

.PHONY: test-axislv
## Run tests with AXI slv
test-axislv:
	cd tb/simvectors/axi_slv && python3.6 axi_slv_stim_gen.py --target asic_sim
	$(MAKE) all simc SIM_TOP=tb_axi_slv

#
# Emacs
#

.PHONY: TAGS
TAGS:
	$(CTAGS) -R -e --language=systemverilog --exclude=boot/* \
		--exclude=freertos/* --exclude=fw/* --exclude=pkg/* \
		--exclude=$(PULP_RUNTIME)/* --exclude=pulp-sdk/* \
		--exclude=sdk-releases/* --exclude=$(TEST_DIR)/* \
		--exclude=util/* --exclude=install/* --exclude=env/* \
		--exclude=*.patch --exclude=*.md --exclude=*.log \
		--exclude=*.vds --exclude=*.adoc .

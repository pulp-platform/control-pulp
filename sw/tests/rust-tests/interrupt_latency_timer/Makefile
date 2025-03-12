# Copyright 2020 ETH Zurich
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
# Author: Noah Zarro (zarron@ethz.ch)

# Description: Makefile to build rust tests

# flags
RISCV		?= $(HOME)/.riscv
RISCV_PREFIX	?= $(RISCV)/bin/riscv32-unknown-elf-
CC		= $(RISCV_PREFIX)gcc
OBJCOPY		= $(RISCV_PREFIX)objcopy
OBJDUMP		= $(RISCV_PREFIX)objdump
SIZE		= $(RISCV_PREFIX)size
PLPSTIM   = $(PULP_SDK_HOME)/scripts/pulpstim


PROG=interrupt_latency
TARGET_FOLDER= $(if $(no_atomics), target/riscv32imc-unknown-none-elf/release, target/riscv32imac-unknown-none-elf/release)
PROG_PATH=$(TARGET_FOLDER)/$(PROG)
SIMDIR=sim

# compile process

.PHONY: all
all: compile $(PROG_PATH).srec $(PROG_PATH).lst $(PROG_PATH).dump misc-info


$(PROG_PATH).srec: $(PROG_PATH)
	$(OBJCOPY) -O srec $(PROG_PATH) $@

$(PROG_PATH).lst: $(PROG_PATH)
	$(OBJDUMP) --source --all-headers --demangle --line-numbers --wide --prefix-addresses \
		$(PROG_PATH) > $@

$(PROG_PATH).dump : $(PROG_PATH)
	$(OBJDUMP) -d --visualize-jumps $(PROG_PATH) > $@

misc-info:

.PHONY:
compile:
	cargo build --release $(if $(timer_measurement),--features timer_measurement,) $(if $(nxti),--features nxti,) $(if $(no_atomics),--target "riscv32imc-unknown-none-elf",--target "riscv32imac-unknown-none-elf")

# clean

.PHONY: clean
clean:
	rm -r target
	rm -r sim


# creating symlink farm because PULP/PULPissimo relies on hardcoded paths

$(SIMDIR)/work:
ifndef VSIM_PATH
	$(error "VSIM_PATH is undefined. Either call \
	'source $$YOUR_HW_DIR/setup/vsim.sh' or set it manually.")
endif
	ln -s $(VSIM_PATH)/work $@

$(SIMDIR)/boot:
ifndef VSIM_PATH
	$(error "VSIM_PATH is undefined. Either call \
	'source $$YOUR_HW_DIR/setup/vsim.sh' or set it manually.")
endif
	ln -s $(VSIM_PATH)/boot $@

$(SIMDIR)/tcl_files:
ifndef VSIM_PATH
	$(error "VSIM_PATH is undefined. Either call \
	'source $$YOUR_HW_DIR/setup/vsim.sh' or set it manually.")
endif
	ln -s $(VSIM_PATH)/tcl_files $@

$(SIMDIR)/waves:
ifndef VSIM_PATH
	$(error "VSIM_PATH is undefined. Either call \
	'source $$YOUR_HW_DIR/setup/vsim.sh' or set it manually.")
endif
	ln -s $(VSIM_PATH)/waves $@

$(SIMDIR)/stdout:
	mkdir -p -- $@

$(SIMDIR)/fs:
	mkdir -p -- $@

$(SIMDIR)/preload:
	mkdir -p -- $@

$(SIMDIR):
	mkdir -p -- $@

# default vsim flags for simulation
VSIM_RUN_FLAGS = -permit_unmatched_virtual_intf
VSIM_RUN_FLAGS += +srec=prog.srec +jtag_load_tap=pulp

.PHONY: run
run: all $(SIMDIR) $(SIMDIR)/boot $(SIMDIR)/tcl_files \
	$(SIMDIR)/waves \
	$(SIMDIR)/stdout $(SIMDIR)/fs $(SIMDIR)/work \
	$(DPI_LIBS) $(RUN_MORE)
ifndef VSIM_PATH
	$(error "VSIM_PATH is undefined. Either call \
	'source $$YOUR_HW_DIR/setup/vsim.sh' or set it manually.")
endif
	echo VSIM_PATH: $(VSIM_PATH)
	cp $(PROG_PATH) $(SIMDIR)
	cp $(PROG_PATH).srec $(SIMDIR)/prog.srec
	cp $(PROG_PATH).lst $(SIMDIR)
	if [[ -f $(PROG_PATH).veri ]]; then cp $(PROG_PATH).veri $(SIMDIR); fi;
	cd $(SIMDIR) && \
	export LD_LIBRARY_PATH="$(SUPPORT_LIB_DIR)" && \
	export VSIM_RUNNER_FLAGS="$(VSIM_RUN_FLAGS) $(VSIM_DPI) $(VSIM_ARGS)" && \
	export VOPT_ACC_ENA="YES" && \
	vsim -64 $(if $(gui),,-c) -do 'source $(VSIM_PATH)/tcl_files/config/run_and_exit.tcl' \
		-do $(if $(or $(gui),$(interactive)), \
				'source $(VSIM_PATH)/tcl_files/run.tcl; source waves/software.tcl; source waves/clic.tcl; source waves/timers.do; run 200000ns', \
				'source $(VSIM_PATH)/tcl_files/run.tcl; run_and_exit; ') $(VSIM_ARGS)

#include $(PROJ_ROOT)/default_targets.mk

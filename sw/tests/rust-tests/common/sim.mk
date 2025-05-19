# Copyright 2025 ETH Zurich
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
# Author: Noah Zarro (zarron@ethz.ch)
# Author: Alessandro Ottaviano (aottaviano@ethz.ch)

# Description: Makefrag to run Questasim simulation of rust tests

ifndef VSIM_PATH
$(error "VSIM_PATH is undefined. Call 'source $$YOUR_HW_DIR/env/env.sh'.")
endif

$(SIMDIR)/work:
	ln -s $(VSIM_PATH)/work $@

$(SIMDIR)/boot:
	ln -s $(VSIM_PATH)/boot $@

$(SIMDIR)/tcl_files:
	ln -s $(VSIM_PATH)/tcl_files $@

$(SIMDIR)/waves:
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
	$(SIMDIR)/waves $(SIMDIR)/stdout $(SIMDIR)/fs $(SIMDIR)/work \
	$(DPI_LIBS) $(RUN_MORE)
	echo VSIM_PATH: $(VSIM_PATH)
	cp $(PROG_PATH) $(SIMDIR)
	cp $(PROG_PATH).srec $(SIMDIR)/prog.srec
	cp $(PROG_PATH).lst $(SIMDIR)
	if [[ -f $(PROG_PATH).veri ]]; then cp $(PROG_PATH).veri $(SIMDIR); fi;
	cd $(SIMDIR) && \
	export LD_LIBRARY_PATH="$(SUPPORT_LIB_DIR)" && \
	export VSIM_RUNNER_FLAGS="$(VSIM_RUN_FLAGS) $(VSIM_DPI) $(VSIM_ARGS)" && \
	vsim -64 $(if $(gui),,-c) -do 'source $(VSIM_PATH)/tcl_files/config/run_and_exit.tcl' \
		-do $(if $(or $(gui),$(interactive)), \
			'source $(VSIM_PATH)/tcl_files/run.tcl; source waves/software.tcl; source waves/clic.tcl; source waves/timers.do; run 200000ns', \
			'source $(VSIM_PATH)/tcl_files/run.tcl; run_and_exit;') \
		$(VSIM_ARGS)

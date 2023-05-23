# Copyright 2022 ETH Zurich and University of Bologna
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

# Author: Robert Balas (balasr@iis.ee.ethz.ch)


ifeq ($(VERILATOR_ROOT),)
VERILATOR ?= verilator
else
export VERILATOR_ROOT
VERILATOR ?= $(VERILATOR_ROOT)/bin/verilator
endif

.PHONY: lint
## Run verilator linting
lint:
	$(VERILATOR) --lint-only --cdc -Wno-BLKANDNBLK -Wno-fatal \
	--x-assign '0' --x-initial '0' --x-initial-edge --timescale 1ps \
	--clk 'ref_clk_i' --clk 'sys_clk_i' \
	-GSIM_STDOUT=0 \
	--top pms_top -o vpms \
	-f ../../sim/flist/src_ips_veri.f -f ../../sim/flist/src_rtl_veri.f \
	$(VERI_FLAGS)

.PHONY: clean
## Delete generated reports
clean:
	$(RM) -r obj_dir/

.PHONY: help
help: Makefile
	@printf "Control PULP\n"
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

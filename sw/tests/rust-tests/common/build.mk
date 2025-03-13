
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

# Description: Makefrag to build rust tests

PROG_PATH     = $(TARGET_FOLDER)/$(PROG)

.PHONY: all compile

all: compile $(PROG_PATH).srec $(PROG_PATH).lst $(PROG_PATH).dump

compile:
	cargo build --release \
		$(if $(timer_measurement),--features timer_measurement,) \
		$(if $(nxti),--features nxti,) \
		$(if $(no_atomics),--target "riscv32imc-unknown-none-elf",--target "riscv32imac-unknown-none-elf")
	cargo expand --target riscv32imac-unknown-none-elf \
		> target/riscv32imac-unknown-none-elf/release/expand.rs

$(PROG_PATH).srec: $(PROG_PATH)
	$(OBJCOPY) -O srec $(PROG_PATH) $@

$(PROG_PATH).lst: $(PROG_PATH)
	$(OBJDUMP) --source --all-headers --demangle --line-numbers --wide --prefix-addresses \
	$(PROG_PATH) > $@

$(PROG_PATH).dump: $(PROG_PATH)
	$(OBJDUMP) -d --visualize-jumps $(PROG_PATH) > $@

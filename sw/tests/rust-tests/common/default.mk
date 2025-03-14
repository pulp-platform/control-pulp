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

# Description: Makefile to build and run rust tests

RISCV         ?= $(HOME)/.riscv
RISCV_PREFIX  ?= $(RISCV)/bin/riscv32-unknown-elf-
OBJCOPY       = $(RISCV_PREFIX)objcopy
OBJDUMP       = $(RISCV_PREFIX)objdump
TARGET_FOLDER = $(if $(no_atomics), \
                    target/riscv32imc-unknown-none-elf/release, \
                    target/riscv32imac-unknown-none-elf/release)
SIMDIR        = sim

# Build
include ../common/build.mk

# Run
include ../common/sim.mk

.PHONY: clean
clean:
	rm -rf target sim

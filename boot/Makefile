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
# Author: Robert Balas (balasr@iis.ee.ethz.ch)

# -flto, normal			text 4378 rodata 394	4772
# withouth no-jump-tables	text 4144 rodata 562	4706
# with save-restore			text 4156 rodata 546	4702

PYTHON  = python3.6
CTAGS   = ctags

RISCV		?= $(HOME)/.riscv
RISCV_PREFIX	?= $(RISCV)/bin/riscv32-unknown-elf-
CC		= $(RISCV_PREFIX)gcc
OBJCOPY		= $(RISCV_PREFIX)objcopy
OBJDUMP		= $(RISCV_PREFIX)objdump
SIZE		= $(RISCV_PREFIX)size

ARCH = -march=rv32imc -mabi=ilp32

#CFLAGS   = $(ARCH) -Os -g -fno-jump-tables -UARCHI_CORE_HAS_PULPV2 -DRV_ISA_RV32
CFLAGS   = $(ARCH) -Os -g3 -UARCHI_CORE_HAS_PULPV2 -DRV_ISA_RV32
CFLAGS	+= -Wall -Wextra -Wno-unused-parameter -Wno-clobbered
CFLAGS  += -ffunction-sections -fdata-sections -ffreestanding
CFLAGS  += -mno-save-restore

# zforth interpreter options
# remove -DENABLE_ZFORTH_BOOT to disable the forth fallback boot mode. This
# makes the bootrom somewhat smaller
CPPFLAGS  += -DENABLE_ZFORTH_BOOT
# UDMA UART periperal id and desired baudrate
CPPFLAGS  += -DUART_ID=0
CPPFLAGS  += -DUART_BAUDRATE=115200
# UDMA SPI periperhal id and max supported clock frequency
CPPFLAGS  += -DSPI_ID=7
CPPFLAGS  += -DSPI_MAX_CLK=25000000

CPPFLAGS  += -DEXIT_REG_ADDR=0x1a1040a0
# Make error message more verbose instead of the default single letter error
# markers. Increases uart output bandwidth.
CPPFLAGS  += -DZF_VERBOSE_ERRORS
# clock speed of peripheral domain, needed to configure uart and spi clock
# dividers correctly


CPPFLAGS += -I$(CURDIR) -I$(CURDIR)/include -I$(CURDIR)/include/hal \
	-I$(CURDIR)/include/archi -I$(CURDIR)/zforth \
	-I$(CURDIR)/zforth-riscv

ASFLAGS  = $(CFLAGS) -DLANGUAGE_ASSEMBLY

LDFLAGS  = -Tlink.ld -nostdlib -Wl,--gc-sections -Wl,-Map,boot_code.map $(ARCH)
LDFLAGS  += -Wl,--print-gc-sections
LDLIBS = -lgcc

CFLAGS  += -flto
LDFLAGS += -flto

BOOTCODE = boot_code
BOOTCODE_FPGA = boot_code_fpga

OBJS =  boot_code.o crt0.o \
	zforth-riscv/zforth-main.o zforth-riscv/libc.o zforth-riscv/udma.o \
	zforth-riscv/setjmp.o zforth/zforth.o kk_srec.o

all-formats: $(BOOTCODE) $(BOOTCODE).srec $(BOOTCODE).ihex $(BOOTCODE).vmem \
	$(BOOTCODE_FPGA) $(BOOTCODE_FPGA).srec $(BOOTCODE_FPGA).ihex $(BOOTCODE_FPGA).vmem

all: $(BOOTCODE) $(BOOTCODE_FPGA) $(BOOTCODE).objdump $(BOOTCODE_FPGA).objdump boot.rtl boot.gvsoc

# ASIC bootrom 100 MHz periph freq
$(BOOTCODE):      CPPFLAGS += -DPERIPH_FREQUENCY=100000000
$(BOOTCODE):      $(OBJS)

# FPGA bootrom 10 MHz periph freq
# need separate objects
$(BOOTCODE_FPGA): CPPFLAGS += -DPERIPH_FREQUENCY=10000000
$(BOOTCODE_FPGA): $(addsuffix .2,$(OBJS))

# Makefile implicit rules for .o
# %.o: %.c
# COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
# OUTPUT_OPTION = -o $@
# $(COMPILE.c) $(OUTPUT_OPTION) $<

# %.o: %.S
# COMPILE.S = $(CC) $(ASFLAGS) $(CPPFLAGS) $(TARGET_MACH) -c
# $(COMPILE.S) -o $@ $<

# %: %.o
# LINK.o = $(CC) $(LDFLAGS) $(TARGET_ARCH)
# $(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@

# Makefile custom rules for .o.2 (fpga)
%.o.2: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c -o $@ $<

%.o.2: %.S
	$(CC) $(ASFLAGS) $(CPPFLAGS) $(TARGET_MACH) -c -o $@ $<

%_fpga: %.o.2
	$(CC) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o $@

boot.gvsoc: rom.bin

# gvsoc bootrom
rom.bin: $(BOOTCODE)
	./stim_utils.py  \
		--binary=$(BOOTCODE) \
		--stim-bin=rom.bin \
		--area=0x1a000000:0x01000000

# srec dump of bootrom
%.srec: %
	$(OBJCOPY) -O srec $^ $@

%.ihex: %
	$(OBJCOPY) -O ihex $^ $@

%.vmem: %
	$(OBJCOPY) -O verilog $^ $@

%.bin: %
	$(OBJCOPY) -O binary $^ $@

# The rtl bootrom is just a verilog dump of the elf file
boot.rtl: boot_code.cde boot_code_fpga.cde

%.objdump: %
	$(OBJDUMP) -Sr $^ > $@

%.cde: %
	$(OBJCOPY) --srec-len 1 --output-target=srec $^ $^.s19
	./s19toboot.py $^.s19 $@ pulpissimo
	$(SIZE) -A $^

asic_autogen_rom.sv: boot_code.bin
	$(PYTHON) gen_rom.py $^ $@ --title "ASIC Bootrom for control_pulp" --pad 8192

fpga_autogen_rom.sv: boot_code_fpga.bin
	$(PYTHON) gen_rom.py $^ $@ --title "FPGA Bootrom for control_pulp" --pad 8192


.PHONY: clean
clean:
	$(RM) $(BOOTCODE) $(BOOTCODE_FPGA) $(OBJS) $(addsuffix .2,$(OBJS)) \
		boot_code.cde boot_code.sv rom.bin \
		boot_code.map asic_autogen_rom.sv fpga_autogen_rom.sv \
		boot_code.srec boot_code_fpga.srec \
		 *.cde  *.ihex *.vmem *.s19

.PHONY: TAGS
TAGS:
	$(CTAGS) -R -e .

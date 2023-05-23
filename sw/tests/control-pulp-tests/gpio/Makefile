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

# Common code
#------------------------------------

# ARE WE IN DEVELOPMENT ?
ACTIVE_DEVELOP = 1
###

APP = gpio
APP_SRCS 	= main.c
APP_SRCS 	+= gpio_task.c

APP_CFLAGS  +=

# Include Paths
INC_PATH	+= ./
INC_PATH	+= ./Config

INCLUDES = $(foreach f, $(INC_PATH), -I$f)

# indicate this repository's root folder
# set some project specific path variables
ifndef FREERTOS_PROJ_ROOT
$(error "FREERTOS_PROJ_ROOT is unset. Run source env/platform-you-want.sh from \
	the freertos project's root folder.")
endif

CONFIG_CLUSTER=no
# good defaults for many environment variables
include $(FREERTOS_PROJ_ROOT)/default_flags.mk

# rtos and pulp sources
include $(FREERTOS_PROJ_ROOT)/default_srcs.mk

# FreeRTOS Definitions:
#CPPFLAGS += -DPCF_FREERTOS_TICK_RATE_HZ=1000
CPPFLAGS += -DDEFAULT_SYSTEM_CLOCK=20000000u

# ARE WE IN DEVELOPMENT ?
CPPFLAGS += -DDEBUG_ACTIVE
#####

#Uncomment this to print information via printf
CPPFLAGS += -DPRINTF_ACTIVE
CPPFLAGS += -DDEBUG_PRINTF
CPPFLAGS += -UATOS_EMULATION
CPPFLAGS += -DHRO_PRINTF

# Uncomment to add debug option
#CPPFLAGS += -g

CPPFLAGS += -DINITIAL_WAITING_ITERATIONS=1000
CPPFLAGS += -DINITIAL_WAITING_OVERFLOWS=4
#2*ms
CPPFLAGS += -DSYSTICK_WAITING_ITERATIONS=80000
CPPFLAGS += -DSYSTICK_WAITING_OVERFLOWS=0


#####################
#Last One
#Make flags:
CPPFLAGS += $(MAKE_FLAGS)

# application name
PROG = gpio

# application/user specific code
USER_SRCS = $(APP_SRCS)
CPPFLAGS += $(INCLUDES)

# point to irq handler
CPPFLAGS += -DportasmHANDLE_INTERRUPT=vSystemIrqHandler

CPPFLAGS += $(addprefix -I$(USER_DIR)/, ".")

#todo remove
#to fix compiler
#RISCV = /usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0-rc1
#CFLAGS = -Os -g3 -march=rv32imc_zfinx_xcorev -mabi=ilp32 -mno-pulp-hwloop
#ASFLAGS = -Os -g3 -march=rv32imc_zfinx_xcorev -mabi=ilp32 -mno-pulp-hwloop

# compile, simulation and analysis targets
include $(FREERTOS_PROJ_ROOT)/default_targets.mk

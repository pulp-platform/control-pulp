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

USE_CLUSTER ?= 1

PULP_APP = test

ifeq ($(USE_CLUSTER), 1)
PULP_APP_SRCS 	= cl_main.c
else
PULP_APP_SRCS 	= soc_main.c
endif

PULP_APP_SRCS 	+= ./IO/imp_comms.c ./IO/imp_dataLib.c ./PerfCounter/measure.c
PULP_APP_SRCS 	+= ./Config/cfg_constants.c
PULP_APP_SRCS	+= ./ctrl_math.c

# Include Paths
INC_PATH	+= ./
INC_PATH 	+= ./Config
INC_PATH	+= ./IO
INC_PATH	+= ./PerfCounter

INCLUDES = $(foreach f, $(INC_PATH), -I$f)

PULP_CFLAGS = -O2 -g $(INCLUDES)

# indicate this repository's root folder
# set some project specific path variables
#ifndef FREERTOS_PROJ_ROOT
#$(error "FREERTOS_PROJ_ROOT is unset. Run source env/platform-you-want.sh from \
#	the freertos project's root folder.")
#endif

# good defaults for many environment variables
#include $(FREERTOS_PROJ_ROOT)/default_flags.mk

# rtos and pulp sources
#include $(FREERTOS_PROJ_ROOT)/default_srcs.mk

# FreeRTOS Definitions:
CPPFLAGS += -DPCF_FREERTOS_TICK_RATE_HZ=1000
CPPFLAGS += -DDEFAULT_SYSTEM_CLOCK=500000000u


# Uncomment to add debug option
#CPPFLAGS += -g

#Code Congiguration through Flags:

#Uncomment this to use float
CPPFLAGS += -DCONTROL_DATA_TYPE=1

#Uncomment this for the CI_TEST
CPPFLAGS += -DCI_TEST
#and the number of iterations
CPPFLAGS += -DCI_TEST_ITERATION=8

#Uncomment this for the Perf Counter Test
#Validation Test
#CPPFLAGS += -DMEASURE_ACTIVE=2

#Measurement test
CPPFLAGS += -DMEASURE_ACTIVE=1
#and the number of iterations for the measurement test
CPPFLAGS += -DMEASURE_N_ITERATION=8
#and the number of measurements per iteration for the measurement test
CPPFLAGS += -DMEASURE_N_OUTPUTS=12
#the type of measure
#TODO: sadly the MEASURE_CSR value is target dependant. Still I don't know how to do otherwise
CPPFLAGS += -DMEASURE_CSR=0 -DMEASURE_ZEROING=0

#Uncomment this to print information via printf
CPPFLAGS += -DDEBUG_ACTIVE

#####################
#Last One
#Make flags:
CPPFLAGS += $(MAKE_FLAGS)

# application name
PROG = Programmino

# application/user specific code
USER_SRCS = $(APP_SRCS)
CPPFLAGS += $(INCLUDES)

# user headers
CPPFLAGS += $(addprefix -I$(VPATH)/, ".")

# point to irq handler
CPPFLAGS += -DportasmHANDLE_INTERRUPT=vSystemIrqHandler
# For the cluster
CPPFLAGS += -DUSE_STDIO

PULP_CFLAGS = $(CPPFLAGS)

# compile, simulation and analysis targets
#include $(FREERTOS_PROJ_ROOT)/default_targets.mk
include $(PULP_SDK_HOME)/install/rules/pulp_rt.mk

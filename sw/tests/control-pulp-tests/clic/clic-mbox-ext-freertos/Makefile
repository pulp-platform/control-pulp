# Common code
#------------------------------------

# ARE WE IN DEVELOPMENT ?
ACTIVE_DEVELOP = 1
###

APP = clic-mbox-ps-freertos
APP_SRCS 	= clic-mbox-ps-freertos.c

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

# good defaults for many environment variables
include $(FREERTOS_PROJ_ROOT)/default_flags.mk

# rtos and pulp sources
include $(FREERTOS_PROJ_ROOT)/default_srcs.mk

# ARE WE IN DEVELOPMENT ?
CPPFLAGS += -DDEBUG_ACTIVE
#####

# FreeRTOS Definitions:
#CPPFLAGS += -DPCF_FREERTOS_TICK_RATE_HZ=1000
CPPFLAGS += -DDEFAULT_SYSTEM_CLOCK=20000000u

# ARE WE IN DEVELOPMENT ?
CPPFLAGS += -DDEBUG_ACTIVE
#####

#Uncomment this to print information via printf
CPPFLAGS += -DPRINTF_ACTIVE
CPPFLAGS += -DDEBUG_PRINTF
CPPFLAGS += -UDUMP_ONLY
CPPFLAGS += -DHRO_PRINTF

CPPFLAGS += -DALPHA_DEBUG 
# Uncomment to add debug option
CPPFLAGS += -g

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
PROG = clic-mbox-ps-ft

# application/user specific code
USER_SRCS = $(APP_SRCS)
CPPFLAGS += $(INCLUDES)

# point to irq handler
CPPFLAGS += -DportasmHANDLE_INTERRUPT=vSystemIrqHandler

CPPFLAGS += -I../../shared/include
CPPFLAGS += $(addprefix -I$(USER_DIR)/, ".")

CFLAGS += -Og -g3 -march=rv32imac_zfinx_xcorev -mabi=ilp32 -DFEATURE_CLUSTER=1 -D__PULP__=1 -DDEBUG
#ADV
SRCS += ./handler.S

ASFLAGS=-Os -g3 -march=rv32imac_zfinx_xcorev -mabi=ilp32

# compile, simulation and analysis targets
include $(FREERTOS_PROJ_ROOT)/default_targets.mk
    

	# make RISCV="/usr/pack/riscv-1.0-kgf/pulp-gcc-2.5.0-rc1"
	#  CFLAGS=""  clean all

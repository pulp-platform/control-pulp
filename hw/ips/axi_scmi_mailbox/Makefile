# Copyright ETH Zurich
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# Author: Alessandro Ottaviano

# Generate C header file

PYTHON_VER = python3.6

NUM_CHANNELS = 1

REGTOOL=../register_interface/vendor/lowrisc_opentitan/util/regtool.py

all: rtl/axi_scmi_mailbox.sv scmi.hjson headers registers

rtl/axi_scmi_mailbox.sv: rtl/axi_scmi_mailbox.sv.tpl
	$(PYTHON_VER) scmi.py -s $(NUM_CHANNELS) < $< > $@

scmi.hjson: scmi.hjson.tpl
	$(PYTHON_VER) scmi.py -s $(NUM_CHANNELS) < $< > $@

headers: scmi.h

scmi.h: scmi.hjson
	$(REGTOOL)  --cdefines $< > $@

registers: scmi.hjson
	$(REGTOOL) -r -t rtl/ $<

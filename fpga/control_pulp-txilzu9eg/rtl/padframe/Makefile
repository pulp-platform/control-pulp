ROOT_DIR = $(shell git rev-parse --show-toplevel)
FPGA_DIR:= $(ROOT_DIR)/fpga/control_pulp-txilzu9eg
RTL_DIR:= $(FPGA_DIR)/rtl
TCL_DIR:= $(FPGA_DIR)/tcl
CONSTR_DIR:= $(FPGA_DIR)/constraints
PYTHON:=python3.6

.DEFAULT_GOAL:=help

.PHONY: all
all: $(RTL_DIR)/pad_frame_fpga.sv $(CONSTR_DIR)/zcu102_peripherals.xdc $(TCL_DIR)/zcu102_pins_bd.tcl $(CURDIR)/example_pad_frame_inst.sv

$(RTL_DIR)/pad_frame_fpga.sv: pad-frame example-pad-frame-inst ## Generate pad_frame.sv module and an example of its instantiation from the pads_fpga.txt source file.
	mv pad_frame_fpga.sv $@

.PHONY: pad-frame
pad-frame:
	$(PYTHON) gen_pad_frame_fpga.py pads_fpga.txt pad_frame_fpga.sv \
	--title	"PAD frame for Control PULP, FPGA environment"

.PHONY: example-pad-frame-inst
example-pad-frame-inst:
	$(PYTHON) gen_pad_frame_instance.py pads_fpga.txt

.PHONY: fpga-periph-constraints
fpga-periph-constraints:
	$(PYTHON) gen_periph_constraints_fpga.py pads_fpga.txt

$(CONSTR_DIR)/zcu102_peripherals.xdc: fpga-periph-constraints ## Generate zcu102 constraints for PMS peripheral pads
	mv zcu102_peripherals.xdc $@

$(TCL_DIR)/zcu102_pins_bd.tcl: fpga-periph-constraints ## Generate zcu102 tcl for making PMS peripheral pads external in Vivado BD
	mv zcu102_pins_bd.tcl $@

.PHONY: help
help:
	@grep -E -h '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

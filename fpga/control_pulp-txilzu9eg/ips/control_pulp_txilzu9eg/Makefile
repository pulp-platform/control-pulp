PROJECT:=control_pulp-txilzu9eg
VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source scripts/prologue.tcl

include ../../fpga-settings.mk

package-control-pulp-ip:
	$(VIVADO) -mode batch -source control_pulp_txilzu9eg.tcl

package-control-pulp-ip-gui:
	$(VIVADO) -mode gui -source control_pulp_txilzu9eg.tcl

clean-vivado-ip:
	rm -rf .Xil
	rm -rf *.log
	rm -rf vivado*
	rm -rf control_pulp_ip
	rm -rf control_pulp-txilzu9eg.*

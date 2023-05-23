set project control_pulp-exilzcu102
set CONTROL_PULP_IP_DIR ./ips/control_pulp_txilzu9eg/control_pulp_ip

# Detect board
if [info exists ::env(BOARD)] {
    set BOARD $::env(BOARD)
} else {
    puts "Please execute 'source ../sourceme.sh first before you start vivado in order to setup necessary environment variables."
    exit
}
if [info exists ::env(XILINX_BOARD)] {
    set XILINX_BOARD $::env(XILINX_BOARD)
}

## Set number of CPUs, default to 8 if system's getconf doesn't work
set CPUS [exec getconf _NPROCESSORS_ONLN]
if { ![info exists CPUS] } {
  set CPUS 8
}

## Set up meaningfull errors
source tcl/messages.tcl

## Create vivado project
create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $XILINX_BOARD [current_project]

## Add control_pulp IP to Vivado's IP catalog
set_property ip_repo_paths $CONTROL_PULP_IP_DIR [current_project]
update_ip_catalog

## Create block design
create_bd_design "control_pulp_exilzcu102"
update_compile_order -fileset sources_1

##########################################################################################################

## Instantiate Zynq PS IP
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 i_zynq_ps
#set_property name i_zynq_ps [get_bd_cells zynq_ultra_ps_e_0]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  \
    [get_bd_cells i_zynq_ps]

# define PS AXI ports (S_AXI_HP0_FPD, M_AXI_HPM0_FPD)
set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP1 {0} \
    CONFIG.PSU__USE__S_AXI_GP0 {0} \
    CONFIG.PSU__USE__S_AXI_GP1 {0} \
    CONFIG.PSU__USE__S_AXI_GP2 {1} \
    CONFIG.PSU__USE__S_AXI_GP3 {0} \
    CONFIG.PSU__USE__S_AXI_GP4 {0} \
    CONFIG.PSU__USE__S_AXI_GP5 {0}] \
    [get_bd_cells i_zynq_ps]

# set PS AXI data width to 64 bits
set_property -dict [list \
    CONFIG.PSU__MAXIGP0__DATA_WIDTH {64} \
    CONFIG.PSU__SAXIGP2__DATA_WIDTH {64}] [get_bd_cells i_zynq_ps]

# set PS output clock
set_property -dict [list CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {125}] [get_bd_cells i_zynq_ps]

## Instantiate control_pulp
create_bd_cell -type ip -vlnv ethz.ch:user:pms_top_fpga:1.0 pms_top_fpga_0; #todo: change
set_property name i_pms_top_fpga [get_bd_cells pms_top_fpga_0]

# connect PL clk to PS clock (clk_pl_i, clk_ps_o)
connect_bd_net [get_bd_pins i_pms_top_fpga/ref_clk] [get_bd_pins i_zynq_ps/pl_clk0]

# connect PL rst to PS rst (active low)
connect_bd_net [get_bd_pins i_zynq_ps/pl_resetn0] [get_bd_pins i_pms_top_fpga/pad_reset]

# connect PL AXI mst to PS AXI slv
connect_bd_intf_net [get_bd_intf_pins i_pms_top_fpga/pl_axi_mst] \
    [get_bd_intf_pins i_zynq_ps/S_AXI_HP0_FPD]

# connect PL AXI slv to PS axi mst
connect_bd_intf_net [get_bd_intf_pins i_pms_top_fpga/pl_axi_slv] \
    [get_bd_intf_pins i_zynq_ps/M_AXI_HPM0_FPD]

# connect PL AXI mst/slv clock (soc_clk_o) to PS AXI mst/slv clocks (maxihpm0_fpd_aclk, saxihp0_fpd_aclk)
connect_bd_net [get_bd_pins i_pms_top_fpga/soc_clk_o] [get_bd_pins i_zynq_ps/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins i_pms_top_fpga/soc_clk_o] [get_bd_pins i_zynq_ps/saxihp0_fpd_aclk]

# make pad pins external
source tcl/zcu102_pins_bd.tcl

# Constraints
add_files -fileset constrs_1 -norecurse {./constraints/zcu102_timing.xdc ./constraints/zcu102_peripherals.xdc}
set_property used_in_synthesis false [get_files ./constraints/zcu102_peripherals.xdc]

############################################################################################################

## Define address maps

# PL slave
assign_bd_address [get_bd_addr_segs {i_pms_top_fpga/pl_axi_slv_addr_map/l2_periph_addr_block }]
set_property offset 0x00A0000000 [get_bd_addr_segs {i_zynq_ps/Data/SEG_i_pms_top_fpga_l2_periph_addr_block}]
set_property range 256M [get_bd_addr_segs {i_zynq_ps/Data/SEG_i_pms_top_fpga_l2_periph_addr_block}]

# PL master
assign_bd_address [get_bd_addr_segs {i_zynq_ps/SAXIGP2/HP0_DDR_LOW }]
set_property offset 0x0000000000 \
    [get_bd_addr_segs {i_pms_top_fpga/pl_axi_mst_addr_space/SEG_i_zynq_ps_HP0_DDR_LOW}]
set_property range 2G \
    [get_bd_addr_segs {i_pms_top_fpga/pl_axi_mst_addr_space/SEG_i_zynq_ps_HP0_DDR_LOW}]

##########################################################################################################

## Save and validate design
save_bd_design
validate_bd_design

## Wrap top-level block design
make_wrapper -files [get_files \
    ./control_pulp-exilzcu102.srcs/sources_1/bd/control_pulp_exilzcu102/control_pulp_exilzcu102.bd] -top

add_files -norecurse \
    ./control_pulp-exilzcu102.srcs/sources_1/bd/control_pulp_exilzcu102/hdl/control_pulp_exilzcu102_wrapper.v

## Create targets and runs for IPs
generate_target all \
  [get_files ./control_pulp-exilzcu102.srcs/sources_1/bd/control_pulp_exilzcu102/control_pulp_exilzcu102.bd]

export_ip_user_files -of_objects \
  [get_files ./control_pulp-exilzcu102.srcs/sources_1/bd/control_pulp_exilzcu102/control_pulp_exilzcu102.bd] \
  -no_script -sync -force -quiet

create_ip_run [get_files -of_objects [get_fileset sources_1] \
  ./control_pulp-exilzcu102.srcs/sources_1/bd/control_pulp_exilzcu102/control_pulp_exilzcu102.bd]

export_ip_user_files -of_objects [get_ips control_pulp_exilzcu102_control_pulp_txilzu9eg_vivado_0_0] \
  -no_script -sync -force -quiet

##########################################################################################################

# Setup include files for PULP again
source ../gen/vivado_includes.tcl

# Set Verilog defines for PULP again
set DEFINES "PULP_FPGA_EMUL=1"
if { $BOARD == "zcu102" } {
    set DEFINES "$DEFINES zcu102=1"
}
set_property verilog_define $DEFINES [get_filesets control_pulp_exilzcu102_pms_top_fpga_0_0]; #todo

# Run Synthesis
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value -sfcu -objects [get_runs synth_1]
launch_runs synth_1 -jobs $CPUS; # <---------- SYNTHESIS
wait_on_run synth_1

open_run synth_1 -name netlist_1
set_property needs_refresh false [get_runs synth_1]

opt_design

# Cluster I$ DRC issue
connect_net -hierarchical -net [get_nets control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_cluster_domain/cluster_i/cluster_peripherals_i/icache_ctrl_unit_i/r_rdata[31]_i_19_n_0] -objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_cluster_domain/cluster_i/cluster_peripherals_i/icache_ctrl_unit_i/r_rdata_reg[5]_i_5/DI[0]]
connect_net -hierarchical -net [get_nets control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_cluster_domain/cluster_i/cluster_peripherals_i/icache_ctrl_unit_i/r_rdata[31]_i_19_n_0] -objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_cluster_domain/cluster_i/cluster_peripherals_i/icache_ctrl_unit_i/r_rdata_reg[7]_i_6/DI[0]]

### Implement

set_property "steps.opt_design.args.is_enabled" true [get_runs impl_1]
set_property "steps.phys_opt_design.args.is_enabled" true [get_runs impl_1]
set_property "steps.phys_opt_design.args.directive" "ExploreWithHoldFix" [get_runs impl_1]
set_property "steps.post_route_phys_opt_design.args.is_enabled" true [get_runs impl_1]
set_property "steps.post_route_phys_opt_design.args.directive" "ExploreWithAggressiveHoldFix" [get_runs impl_1]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

set_property strategy Congestion_SpreadLogic_low [get_runs impl_1]
launch_runs impl_1 -jobs $CPUS
wait_on_run impl_1

## Generate bitstream
#set_property STEPS.WRITE_BITSTREAM.TCL.PRE {/home/aottaviano/projects/pulp_pmu/control-pulp/fpga/control_pulp-txilzu9eg/tcl/drc_issue.tcl} [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs $CPUS
wait_on_run impl_1

#Check timing constraints
open_run impl_1
set timingrep [report_timing_summary -no_header -no_detailed_paths -return_string]
if {! [string match -nocase {*timing constraints are met*} $timingrep]} {
  send_msg_id {USER 1-1} ERROR {Timing constraints were not met.}
  return -code error
}


# Export Hardware Definition file.
file mkdir ./control_pulp-txilzu9eg/control_pulp-txilzu9eg.sdk
write_hwdef -force  -file ./control_pulp-txilzu9eg/control_pulp-txilzu9eg.sdk/control_pulp-txilzu9eg_wrapper.hdf

set project control_pulp-txilzu9eg
set RTL ../../../../rtl
set IPS ../../../../ips
set CONSTRS ../../constraints
set CONTROL_PULP_IP_DIR ./control_pulp_ip

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
source ../../tcl/messages.tcl

# Create vivado project
create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $XILINX_BOARD [current_project]

#########################################################################################################################

## Set up includes, rtl and ips source files

# NB 'make gen' had generated tcl scripts for ips and rtl sources inside 'fpga/gen'

# # setup and add RTL includes and rtl source files
source ../../../gen/vivado.tcl

# Replace modules not supported in the FPGA (clock FLLs, interleaved/private \
# memory banks etc) with xilinx IPs

# Override IPSApprox default variables
set FPGA_RTL ../../rtl
set FPGA_IPS ../../ips

# remove duplicate incompatible modules
remove_file $IPS/tech_cells_generic/pad_functional_xilinx.sv

# Set Verilog Defines.
set DEFINES "PULP_FPGA_EMUL=1"
if { $BOARD == "zcu102" } {
    set DEFINES "$DEFINES zcu102=1"
}
set_property verilog_define $DEFINES [current_fileset]

# detect target clock
if [info exists ::env(FC_CLK_PERIOD_NS)] {
    set FC_CLK_PERIOD_NS $::env(FC_CLK_PERIOD_NS)
} else {
    set FC_CLK_PERIOD_NS 10.000
}
set CLK_HALFPERIOD_NS [expr ${FC_CLK_PERIOD_NS} / 2.0]

# Add toplevel wrapper
add_files -norecurse $FPGA_RTL/pms_top_fpga.v

# Add Xilinx IPs
# Clock generators
read_ip $FPGA_IPS/xilinx_clk_mngr/ip/xilinx_clk_mngr.xci
read_ip $FPGA_IPS/xilinx_slow_clk_mngr/ip/xilinx_slow_clk_mngr.xci

# Add wrappers and xilinx specific techcells
add_files -norecurse $FPGA_RTL/pad_frame_fpga.sv
add_files -norecurse $FPGA_RTL/fpga_clk_gen.sv
add_files -norecurse $FPGA_RTL/fpga_slow_clk_gen.sv
#add_files -norecurse $FPGA_RTL/fpga_interleaved_ram.sv
#add_files -norecurse $FPGA_RTL/fpga_private_ram.sv
add_files -norecurse $FPGA_RTL/fpga_autogen_rom.sv
add_files -norecurse $FPGA_RTL/pad_functional_xilinx.sv
add_files -norecurse $FPGA_RTL/pulp_clock_gating_xilinx.sv

# set control_pulp as top
set_property top pms_top_fpga [current_fileset]; #

# needed only if used in batch mode
update_compile_order -fileset sources_1

# Constraints
add_files -fileset constrs_1 -norecurse {../../constraints/zcu102_timing.xdc ../../constraints/zcu102_peripherals.xdc}
set_property used_in_synthesis false [get_files $CONSTRS/zcu102_peripherals.xdc]

## IP packaging

# Create and package pulp IP
ipx::package_project -root_dir $CONTROL_PULP_IP_DIR -vendor ethz.ch \
    -library user -taxonomy /UserIP -import_files -set_current true; #use 'set_current true' to avoid errors

## Clock interface for soc_clk, to drive AXI ports (mst)
ipx::add_bus_interface soc_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
set_property display_name soc_clk [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
set_property description {clock that drives AXI mst and slv ports} [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]
set_property physical_name soc_clk_o [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces soc_clk -of_objects [ipx::current_core]]]

## define PL AXI mst interface
ipx::add_bus_interface pl_axi_mst [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property display_name pl_axi_mst [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property description {PL AXI port master} [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_READ_OUTSTANDING [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_WRITE_OUTSTANDING [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
ipx::add_port_map WLAST [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_w_last_o [ipx::get_port_maps WLAST -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map BREADY [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_b_ready_o [ipx::get_port_maps BREADY -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWLEN [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_len_o [ipx::get_port_maps AWLEN -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWQOS [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_qos_o [ipx::get_port_maps AWQOS -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWREADY [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_ready_i [ipx::get_port_maps AWREADY -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARBURST [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_burst_o [ipx::get_port_maps ARBURST -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWPROT [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_prot_o [ipx::get_port_maps AWPROT -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RRESP [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_resp_i [ipx::get_port_maps RRESP -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARPROT [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_prot_o [ipx::get_port_maps ARPROT -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RVALID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_valid_i [ipx::get_port_maps RVALID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARLOCK [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_lock_o [ipx::get_port_maps ARLOCK -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_id_o [ipx::get_port_maps AWID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RLAST [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_last_i [ipx::get_port_maps RLAST -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_id_o [ipx::get_port_maps ARID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWCACHE [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_cache_o [ipx::get_port_maps AWCACHE -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map WREADY [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_w_ready_i [ipx::get_port_maps WREADY -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map WSTRB [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_w_strb_o [ipx::get_port_maps WSTRB -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map BRESP [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_b_resp_i [ipx::get_port_maps BRESP -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map BID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_b_id_i [ipx::get_port_maps BID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWUSER [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_user_o [ipx::get_port_maps AWUSER -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARLEN [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_len_o [ipx::get_port_maps ARLEN -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARQOS [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_qos_o [ipx::get_port_maps ARQOS -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RDATA [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_data_i [ipx::get_port_maps RDATA -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map BVALID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_b_valid_i [ipx::get_port_maps BVALID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARCACHE [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_cache_o [ipx::get_port_maps ARCACHE -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RREADY [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_ready_o [ipx::get_port_maps RREADY -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWVALID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_valid_o [ipx::get_port_maps AWVALID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARSIZE [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_size_o [ipx::get_port_maps ARSIZE -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map WDATA [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_w_data_o [ipx::get_port_maps WDATA -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARUSER [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_user_o [ipx::get_port_maps ARUSER -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWSIZE [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_size_o [ipx::get_port_maps AWSIZE -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map RID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_r_id_i [ipx::get_port_maps RID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARADDR [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_addr_o [ipx::get_port_maps ARADDR -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWADDR [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_addr_o [ipx::get_port_maps AWADDR -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARREADY [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_ready_i [ipx::get_port_maps ARREADY -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map WVALID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_w_valid_o [ipx::get_port_maps WVALID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map ARVALID [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_ar_valid_o [ipx::get_port_maps ARVALID -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWLOCK [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_lock_o [ipx::get_port_maps AWLOCK -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]
ipx::add_port_map AWBURST [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]
set_property physical_name ps_slv_aw_burst_o [ipx::get_port_maps AWBURST -of_objects [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]]

# associate clock to PL mst axi interface
ipx::associate_bus_interfaces -busif pl_axi_mst -clock soc_clk [ipx::current_core]

# define PL AXI slv interface
ipx::add_bus_interface pl_axi_slv [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property display_name pl_axi_slv [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property description {PL AXI port slave} [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_READ_OUTSTANDING [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
ipx::add_bus_parameter NUM_WRITE_OUTSTANDING [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
ipx::add_port_map WLAST [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_w_last_i [ipx::get_port_maps WLAST -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map BREADY [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_b_ready_i [ipx::get_port_maps BREADY -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWLEN [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_len_i [ipx::get_port_maps AWLEN -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWQOS [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_qos_i [ipx::get_port_maps AWQOS -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWREADY [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_ready_o [ipx::get_port_maps AWREADY -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARBURST [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_burst_i [ipx::get_port_maps ARBURST -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWPROT [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_prot_i [ipx::get_port_maps AWPROT -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RRESP [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_resp_o [ipx::get_port_maps RRESP -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARPROT [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_prot_i [ipx::get_port_maps ARPROT -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RVALID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_valid_o [ipx::get_port_maps RVALID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARLOCK [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_lock_i [ipx::get_port_maps ARLOCK -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_id_i [ipx::get_port_maps AWID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RLAST [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_last_o [ipx::get_port_maps RLAST -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_id_i [ipx::get_port_maps ARID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWCACHE [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_cache_i [ipx::get_port_maps AWCACHE -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map WREADY [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_w_ready_o [ipx::get_port_maps WREADY -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map WSTRB [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_w_strb_i [ipx::get_port_maps WSTRB -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map BRESP [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_b_resp_o [ipx::get_port_maps BRESP -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map BID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_b_id_o [ipx::get_port_maps BID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWUSER [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_user_i [ipx::get_port_maps AWUSER -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARLEN [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_len_i [ipx::get_port_maps ARLEN -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARQOS [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_qos_i [ipx::get_port_maps ARQOS -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RDATA [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_data_o [ipx::get_port_maps RDATA -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map BVALID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_b_valid_o [ipx::get_port_maps BVALID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARCACHE [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_cache_i [ipx::get_port_maps ARCACHE -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RREADY [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_ready_i [ipx::get_port_maps RREADY -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWVALID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_valid_i [ipx::get_port_maps AWVALID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARSIZE [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_size_i [ipx::get_port_maps ARSIZE -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map WDATA [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_w_data_i [ipx::get_port_maps WDATA -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARUSER [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_user_i [ipx::get_port_maps ARUSER -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWSIZE [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_size_i [ipx::get_port_maps AWSIZE -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map RID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_r_id_o [ipx::get_port_maps RID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARADDR [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_addr_i [ipx::get_port_maps ARADDR -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWADDR [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_addr_i [ipx::get_port_maps AWADDR -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARREADY [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_ready_o [ipx::get_port_maps ARREADY -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map WVALID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_w_valid_i [ipx::get_port_maps WVALID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map ARVALID [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_ar_valid_i [ipx::get_port_maps ARVALID -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWLOCK [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_lock_i [ipx::get_port_maps AWLOCK -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]
ipx::add_port_map AWBURST [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]
set_property physical_name ps_mst_aw_burst_i [ipx::get_port_maps AWBURST -of_objects [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]]

# associate clock to PL slv axi interface
ipx::associate_bus_interfaces -busif pl_axi_slv -clock soc_clk [ipx::current_core]

## Address ranges

# PL master

# Address space
ipx::add_address_space pl_axi_mst_addr_space [ipx::current_core]
set_property master_address_space_ref pl_axi_mst_addr_space \
    [ipx::get_bus_interfaces pl_axi_mst -of_objects [ipx::current_core]]

set_property width 49 \
    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects [ipx::current_core]]

set_property range_format long \
    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects [ipx::current_core]]

set_property range 16E \
    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects [ipx::current_core]];

## Segments
## 1. DDR low segment
#ipx::add_segment ddr_low_segment \
#    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects [ipx::current_core]]
#
#set_property range 16777216 \
#    [ipx::get_segments ddr_low_segment -of_objects \
#    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects \
#    [ipx::current_core]]]; #16MB
#
#set_property address_offset_format string \
#    [ipx::get_segments ddr_low_segment -of_objects \
#    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects \
#    [ipx::current_core]]]
#
#set_property address_offset 00000000000000 \
#    [ipx::get_segments ddr_low_segment -of_objects \
#    [ipx::get_address_spaces pl_axi_mst_addr_space -of_objects \
#    [ipx::current_core]]]

# PL slave

# Address map
ipx::add_memory_map pl_axi_slv_addr_map [ipx::current_core]
set_property slave_memory_map_ref pl_axi_slv_addr_map \
    [ipx::get_bus_interfaces pl_axi_slv -of_objects [ipx::current_core]]

# Blocks
# L2 + periph block
ipx::add_address_block l2_periph_addr_block \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects [ipx::current_core]]

set_property width 40 \
    [ipx::get_address_blocks l2_periph_addr_block -of_objects \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects \
    [ipx::current_core]]]

set_property range_format long \
    [ipx::get_address_blocks l2_periph_addr_block -of_objects \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects \
    [ipx::current_core]]]

set_property range 268435456 \
    [ipx::get_address_blocks l2_periph_addr_block -of_objects \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects \
    [ipx::current_core]]]; # 256MB

set_property base_address_format string \
    [ipx::get_address_blocks l2_periph_addr_block -of_objects \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects \
    [ipx::current_core]]]

set_property base_address 00A0000000 \
    [ipx::get_address_blocks l2_periph_addr_block -of_objects \
    [ipx::get_memory_maps pl_axi_slv_addr_map -of_objects \
    [ipx::current_core]]]

# Package IP
set_property core_revision 2 [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

## Close project

# NB 'close_project' closes the main one, since no additional project \
# is created when packaging the IP from command line, differently from \
# calling IP packager with the GUI, where you need to use 'close_project' \
# twice

#close_project; #-delete

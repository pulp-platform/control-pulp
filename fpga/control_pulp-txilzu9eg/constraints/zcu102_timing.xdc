# Timing constraints

# JTAG
create_clock -period 100.000 -name tck -waveform {0.000 50.000} [get_ports jtag_tck_i_0]
set_input_jitter tck 1.000
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jtag_tck_i_0]

# minimize routing delay

set_max_delay -to [get_ports jtag_tdo_o_0] 20.000
set_max_delay -from [get_ports jtag_tms_i_0] 20.000
set_max_delay -from [get_ports jtag_tdi_i_0] 20.000

# JTAG CDC



# Timers

# Periphs
set_false_path -to [get_pins {control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_spim_gen[*].i_spim/u_spictrl/i_edgeprop/sync_a_reg[*]/D}]

# CDC FIFOs in UDMA
set_max_delay -through [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_*/*dc*/i_cdc_fifo/i_*/i_spill_register/spill_register_flushable_i/*reg*/D] 50.000
set_max_delay -through [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_*/*dc*/i_cdc_fifo/i_*/i_spill_register/spill_register_flushable_i/*reg*/C] 50.000
set_max_delay -through [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_*/*dc*/i_cdc_fifo/i_*/*i_sync/*reg*/D] 50.000
set_max_delay -through [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_*/*dc*/i_cdc_fifo/i_*/*reg*/D] 50.000

# reset signal

# Set ASYNC_REG attribute for ff synchronizers to place them closer together and
# increase MTBF
set_property ASYNC_REG true [get_cells {control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim0/u_in_stage/r_ls_clk_sync_reg[0]}]
set_property ASYNC_REG true [get_cells {control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim0/u_in_stage/r_ls_clk_sync_reg[1]}]
set_property ASYNC_REG true [get_cells {control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_apb_adv_timer/u_tim0/u_in_stage/r_ls_clk_sync_reg[2]}]
set_property ASYNC_REG true [get_cells control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_control_pulp/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_apb_timer_unit/s_ref_clk*]

# Create asynchronous clock group between slow-clk and SoC clock. Those clocks
# are considered asynchronously and proper synchronization regs are in place
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_system_clk_rst_gen/i_fpga_clk_gen/i_clk_manager/inst/mmcme4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_system_clk_rst_gen/i_slow_clk_gen/i_slow_clk_mngr/inst/mmcme4_adv_inst/CLKOUT0]]

# Create asynchronous clock group between Per Clock  and SoC clock. Those clocks
# are considered asynchronously and proper synchronization regs are in place
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_system_clk_rst_gen/i_fpga_clk_gen/i_clk_manager/inst/mmcme4_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_system_clk_rst_gen/i_fpga_clk_gen/i_clk_manager/inst/mmcme4_adv_inst/CLKOUT1]]

### Create asynchronous clock group between JTAG TCK and SoC clock.
set_clock_groups -asynchronous -group [get_clocks tck] -group [get_clocks -of_objects [get_pins control_pulp_exilzcu102_i/i_pms_top_fpga/inst/i_control_pulp_fpga/i_system_clk_rst_gen/i_fpga_clk_gen/i_clk_manager/inst/mmcme4_adv_inst/CLKOUT0]]


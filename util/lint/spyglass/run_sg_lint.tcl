# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

set PROJECT   pms
set TIMESTAMP [exec date +%Y%m%d_%H%M%S]

# Add ignored files to this list
#set IgnoredFiles [list [exec bender path cva6]/core/include/axi_intf.sv]

new_project sg_projects/${PROJECT}_${TIMESTAMP}
current_methodology $env(SPYGLASS_HOME)/GuideWare/latest/block/rtl_handoff

# Ignore re-defined files
#foreach file $IgnoredFiles {
#  set_option ignorefile $file
#}

# Read the RTL
read_file -type sourcelist cp_sg.f

# Read constraints
read_file -type sgdc func.sgdc

# Set options
set_option enableSV12 yes
set_option language_mode mixed
set_option designread_disable_flatten no
set_option mthresh 32768
set_option top pms_top

# Link Design
current_design pms_top
compile_design

# Set lint_rtl goal and run
current_goal lint/lint_rtl
run_goal

# Create a link to the results
exec rm -rf sg_projects/${PROJECT}
exec ln -sf ${PROJECT}_${TIMESTAMP} sg_projects/${PROJECT}

# Ciao!
exit -save
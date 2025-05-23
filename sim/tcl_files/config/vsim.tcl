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

# Define vsim path and custom variables passed via make
if {[info exists ::env(VSIM_PATH)]} {
    quietly set VSIM_SCRIPTS_PATH $::env(VSIM_PATH)
} {
    quietly set VSIM_SCRIPTS_PATH ./
}

if {[info exists ::env(VSIM_FLAGS)]} {
    quietly set VSIM_FLAGS_TCL $::env(VSIM_FLAGS)
} {
    quietly set VSIM_FLAGS_TCL ""
}

if {[info exists ::env(VSIM_RUNNER_FLAGS)]} {
    quietly set VSIM_FLAGS_TCL "$VSIM_FLAGS_TCL $::env(VSIM_RUNNER_FLAGS)"
}

quietly set warning_args "\
  +nowarnTRAN \
  +nowarnTSCALE \
  +nowarnTFMPC \
  "

quietly set define_args "\
  +UVM_NO_RELNOTES \
  "

quietly set common_args "\
  $warning_args \
  $define_args \
  "

quietly set custom_args "\
  $VSIM_FLAGS_TCL \
  "

quietly set vsim_custom_args "\
  "


set vsim_cmd "vsim -c -quiet $TB \
                -suppress 3009 -suppress 8386 \
                -t ps \
                $common_args \
                $custom_args \
                $vsim_custom_args \
                "

eval $vsim_cmd

# Added these variables to avoid dummy warnings in the FLL
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

# check exit status in tb and quit the simulation accordingly
proc run_and_exit {} {
    onfinish stop
    run -all

    if {[info exists ::env(VSIM_EXIT_SIGNAL)]} {
        quit -code [examine -radix decimal sim:$::env(VSIM_EXIT_SIGNAL)]
    } elseif {[coverage attribute -concise -name TESTSTATUS] >= 3} {
        # exit with error if we had a $fatal somewhere
        quit -code 1
    } else {
        # try to figure out what the testbenchs names is and assume there is an
        # exit_status signal that contains the status of the simulation
        set hier [env]
        # 0 is sim:
        # 1 is the first module in the hierarchy (the testbench)
        set sim_top [lindex [split $hier /] 1]
        quit -code [examine -radix decimal sim:/$sim_top/exit_status]
    }
}

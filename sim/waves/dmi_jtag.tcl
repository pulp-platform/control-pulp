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

# add dmi_jtag
set dmi [find instances -recursive -bydu dmi_jtag -nodu]
set dmi_tap  [find instances -recursive -bydu dmi_jtag_tap -nodu]

if {$dmi ne ""} {
  add wave -group "DMI"                                     $dmi/*
}
if {$dmi_tap ne ""} {
  add wave -group "DMI" -group "dmi_tap"                    $dmi_tap/*
}


configure wave -namecolwidth  250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

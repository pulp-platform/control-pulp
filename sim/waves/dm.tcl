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

# add dm
set dm [find instances -recursive -bydu dm_top -nodu]
set dm_mem  [find instances -recursive -bydu dm_mem -nodu]
set dm_csrs [find instances -recursive -bydu dm_csrs -nodu]
set dm_sba  [find instances -recursive -bydu dm_sba -nodu]

if {$dm ne ""} {
  add wave -group "DM"                                     $dm/*
}
if {$dm_mem ne ""} {
  add wave -group "DM" -group "dm_mem"                     $dm_mem/*
}
if {$dm_csrs ne ""} {
  add wave -group "DM" -group "dm_csrs"                    $dm_csrs/*
}
if {$dm_sba ne ""} {
  add wave -group "DM" -group "dm_sba"                     $dm_sba/*
}

configure wave -namecolwidth  250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

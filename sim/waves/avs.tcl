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

add wave -radix hexadecimal -group "pad_frame" /tb_pulp/i_dut/i_pulp_txilzu9eg_0/i_pad_frame/*
add wave -radix hexadecimal -group "spi0" -group "top" /tb_pulp/i_dut/i_pulp_txilzu9eg_0/i_control_pulp_txilzu9eg/i_control_pulp_with_mem/i_control_pulp_structs/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_spim_gen[0]/i_spim/*
add wave -radix hexadecimal -group "spi0" -group "spi_ctrl" /tb_pulp/i_dut/i_pulp_txilzu9eg_0/i_control_pulp_txilzu9eg/i_control_pulp_with_mem/i_control_pulp_structs/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_spim_gen[0]/i_spim/u_spictrl/*
add wave -radix hexadecimal -group "spi0" -group "spi_reg_intf" /tb_pulp/i_dut/i_pulp_txilzu9eg_0/i_control_pulp_txilzu9eg/i_control_pulp_with_mem/i_control_pulp_structs/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_spim_gen[0]/i_spim/u_reg_if/*
add wave -radix hexadecimal -group "spi0" -group "spi_txrx" /tb_pulp/i_dut/i_pulp_txilzu9eg_0/i_control_pulp_txilzu9eg/i_control_pulp_with_mem/i_control_pulp_structs/i_soc_domain/pulp_soc_i/soc_peripherals_i/i_udma/i_spim_gen[0]/i_spim/u_txrx/*
add wave -radix hexadecimal -group "tb_pulp" /tb_pulp/*

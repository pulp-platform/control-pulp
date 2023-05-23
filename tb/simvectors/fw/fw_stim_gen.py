#!/usr/bin/python3

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
#
# SPDX-License-Identifier: Apache-2.0

import numpy as np
import struct


def float_to_hex(f):
    return hex(struct.unpack('<I', struct.pack('<f', f))[0])

def convert_and_write(idx, start, data, textfile):
    hex_out = float_to_hex(float(data))
    if (hex_out[2:0] == 0.0):
        textfile.write(f'{hex(start + idx*4)[2:]}_{00000000}\n')
    else:
        textfile.write(f'{hex(start + idx*4)[2:]}_{hex_out[2:]}\n')

def list_iter(list_name, start, textfile):
    for idx, data in enumerate(list_name):
        convert_and_write(idx, start, data, textfile)
    textfile.write(f'{hex(start + (idx+1)*4)[2:]}_{"cafecafe"}\n')

def explode_data(list_name, jump):
    tile_list = []
    unrolled_list = []
    for idx in range(len(list_name)):
        tile_list = list_name[idx*jump:(idx+1)*jump]
        tile_list *= 4
        unrolled_list += tile_list

    return unrolled_list


# Read comp_freq
with open('./freq_to_compare.txt') as f:
    freq_to_compare = f.read().splitlines()

# Read temperature
with open('./temperature.txt') as f:
    temperature = f.read().splitlines()

# Read power CPU
with open('./power_measured.txt') as f:
    power_meas = f.read().splitlines()

# Read wl measured
with open('./wl_measure.txt') as f:
    wl_meas = f.read().splitlines()

# Read commands

## Read target freq
with open('./target_freq.txt') as f:
    target_freq = f.read().splitlines()

## Read power budget
with open('./power_budget.txt') as f:
    power_budget = f.read().splitlines()

## Read core bindings
with open('./core_bindings.txt') as f:
    core_bindings = f.read().splitlines()

###########################################################################

textfile1 = open('./freq_to_compare_out.txt', 'w')
textfile2 = open('./temperature_out.txt', 'w')
textfile3 = open('./power_measured_out.txt', 'w')
textfile4 = open('./wl_measure_out.txt', 'w')
textfile5 = open('./target_freq_out.txt', 'w')
textfile6 = open('./power_budget_out.txt', 'w')
textfile7 = open('./core_bindings_out.txt', 'w')


# Addresses

## Output
start_freq_comp = 0x2000_0000

## Input
start_temperature = 0x3000_0000
start_meas_instr = 0x3700_0000
start_pwr_meas = 0x3E00_0000

## Commands
start_target_freq = 0x4000_0000
start_pwr_budget = 0x4100_0000
start_bindings = 0x4200_0000


## For 9 cores:

## Convert input .txt files

#list_iter(freq_to_compare, start_freq_comp, textfile1)
#list_iter(temperature, start_temperature, textfile2)
list_iter(power_meas, start_pwr_meas, textfile3)
#list_iter(wl_meas, start_meas_instr, textfile4)
#list_iter(target_freq, start_target_freq, textfile5)
list_iter(power_budget, start_pwr_budget, textfile6)
#list_iter(core_bindings, start_bindings, textfile7)


## For 36 cores:

freq_to_compare_exp = explode_data(freq_to_compare, 9)
list_iter(freq_to_compare_exp, start_freq_comp, textfile1)

temperature_exp = explode_data(temperature, 9)
list_iter(temperature_exp, start_temperature, textfile2)

#power_meas_exp = explode_data(power_meas)
#list_iter(power_meas_exp, start_pwr_meas, textfile3)

wl_meas_exp = explode_data(wl_meas, 9)
list_iter(wl_meas_exp, start_meas_instr, textfile4)

target_freq_exp = explode_data(target_freq, 18)
list_iter(target_freq_exp, start_target_freq, textfile5)

#power_budget_exp = explode_data(power_budget)
#list_iter(power_budget_exp, start_pwr_budget, textfile6)

core_bindings_exp = explode_data(core_bindings, 18)
list_iter(core_bindings_exp, start_bindings, textfile7)

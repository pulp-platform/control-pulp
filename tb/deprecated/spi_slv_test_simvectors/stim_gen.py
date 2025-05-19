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

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--target', type=str, default='asic_sim', help='Generate stimuli for control_pulp AXI slave port top_level targeting asic. Options are `asic_sim`, `fpga_sim` or `all`')
opt = parser.parse_args()
print(opt)

if opt.target == 'asic_sim':
    path1 = "./stimuli_aligned_asic.txt"
    path2 = "./stimuli_unaligned_asic.txt"
    textfile1 = open(path1, 'w')
    textfile2 = open(path2, 'w')
    
if opt.target == 'fpga_sim':
    path1 = "./stimuli_aligned_fpga.txt"
    path2 = "./stimuli_unaligned_fpga.txt"
    textfile1 = open(path1, 'w')
    textfile2 = open(path2, 'w')

if opt.target == 'all':
    path1 = "./stimuli_aligned_asic.txt"
    path2 = "./stimuli_unaligned_asic.txt"
    path3 = "./stimuli_aligned_fpga.txt"
    path4 = "./stimuli_unaligned_fpga.txt"
    textfile1 = open(path1, 'w')
    textfile2 = open(path2, 'w')
    textfile3 = open(path3, 'w')
    textfile4 = open(path4, 'w')

##################################################################################################
# Probe_range stim generator

# Stimuli generation (address, data) for a probe_range axi master test
# The address range is sampled "num_samples" times and addresses are generated accordingly
# For data, here data(i+1) = data(i) + 1
# This version is for a short spi slave test, in which asic sim has a short range of adresses (for asic_sim)
##################################################################################################

# Start and end addresses of L2 + peripherals from the point of view of c07, n07 and sms

increment_aligned = 0x800
increment_unaligned = 0x801
first_data = 0xcafe_dead
    
if opt.target == 'asic_sim':
    start_asic = 0x00_1C00_0000
    end_asic = 0x00_1C00_8000
    num_samples1 = int((end_asic - start_asic)/increment_aligned)
    num_samples2 = int((end_asic - start_asic)/increment_unaligned)
    
if opt.target == 'fpga_sim':
    start_fpga = 0x00_A200_0000
    end_fpga = 0x00_A208_0000
    num_samples1 = int((end_fpga - start_fpga)/increment_aligned)
    num_samples2 = int((end_fpga - start_fpga)/increment_unaligned)
    
if opt.target == 'all':
    start_asic = 0x00_1C00_0000
    end_asic = 0x00_1C08_0000
    
    start_fpga = 0x00_A200_0000
    end_fpga = 0x00_A208_0000

    num_samples1 = int((end_asic - start_asic)/increment_aligned)
    num_samples2 = int((end_asic - start_asic)/increment_unaligned)

if opt.target == 'asic_sim':
    # Aligned case
    for idx in range(num_samples1):
        textfile1.write(f'{hex(start_asic + idx*increment_aligned)[2:]}, {hex(first_data+idx)[2:]}\n')
    
    # Unaligned case
    for idx in range(num_samples2):
        textfile2.write(f'{hex(start_asic + idx*increment_unaligned)[2:]}, {hex(first_data+idx)[2:]}\n')

if opt.target == 'fpga_sim':
    # Aligned case
    for idx in range(num_samples1):
        textfile1.write(f'{hex(start_fpga + idx*increment_aligned)[2:]}, {hex(first_data+idx)[2:]}\n')
    
    # Unaligned case
    for idx in range(num_samples2):
        textfile2.write(f'{hex(start_fpga + idx*increment_unaligned)[2:]}, {hex(first_data+idx)[2:]}\n')

if opt.target == 'all':
    # Aligned case asic
    for idx in range(num_samples1):
        textfile1.write(f'{hex(start_asic + idx*increment_aligned)[2:]}, {hex(first_data+idx)[2:]}\n')
    
    # Unaligned case asic
    for idx in range(num_samples2):
        textfile2.write(f'{hex(start_asic + idx*increment_unaligned)[2:]}, {hex(first_data+idx)[2:]}\n')

    # Aligned case fpga
    for idx in range(num_samples1):
        textfile3.write(f'{hex(start_fpga + idx*increment_aligned)[2:]}, {hex(first_data+idx)[2:]}\n')
    
    # Unaligned case fpga
    for idx in range(num_samples2):
        textfile4.write(f'{hex(start_fpga + idx*increment_unaligned)[2:]}, {hex(first_data+idx)[2:]}\n')


##################################################################################################
# todo: scan_range stim generator

# Divide the address range in block_sizes and write/read from each address inside each block







##################################################################################################




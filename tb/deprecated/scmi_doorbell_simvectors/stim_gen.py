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

##################################################################################################
# AXI sim mem init values

# Generate initial values for AXI sim mem. This is handled here by a file and
# the memory is initialized with '1 (SCMI channel free for caller)
# TODO Change this and initialize the memory properly
##################################################################################################

path = "./scmi_db_mem_init.mem"
textfile = open(path, 'w')

increment_aligned = 0x20

start_asic = 0x2000_0000
num_samples = 147

for idx in range(num_samples):
    textfile.write(f'@{hex(start_asic + 0x4 + idx*increment_aligned)[2:]} {hex(0x0000_0000)[2:]}\n')
    textfile.write(f'@{hex(start_asic + 0x18 + idx*increment_aligned)[2:]} {hex(0x0108_4000)[2:]}\n')

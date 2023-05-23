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

import argparse
import os.path
import sys

parser = argparse.ArgumentParser(
    description='Convert binary file to C array')
parser.add_argument('filename', metavar='filename', type=str,
                    help='name of input binary')
parser.add_argument('outname', metavar='outname', type=str,
                    help='name of output file')

args = parser.parse_args()
file = args.filename

if not os.path.isfile(file):
    print("File {} does not exist.".format(args.filename))
    sys.exit(1)


def read_bin():
    with open(args.filename, 'rb') as f:
        rom = f.read()

    # align to 32 bits
    align = (int((len(rom) + 3) / 4)) * 4

    for i in range(len(rom), align):
        rom += b'\x00'

    return rom


with open(args.outname, 'w') as f:
    rbin = read_bin()
    c_str = ""
    c_str += "uint32_t pulp_bin[] = {\n"
    for i in range(int(len(rbin)/4)):
        c_str += "    0x%08x" % (int.from_bytes(rbin[i*4:i*4+4][::-1], "big"))
        c_str += ",\n"
    c_str += "};\n"

    f.write(c_str)

#!/usr/bin/env bash

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

this_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
control_pulp_root_dir="${this_dir}/../../../../"

control_pulp_config_file=${control_pulp_root_dir}/local.cfg # control_pulp Config File
control_pulp_petalinux_dir=${control_pulp_root_dir}/fpga/control_pulp-txilzu9eg/linux_boot/petalinux/zcu102 # control_pulp Petalinux Folder

usage () {
  echo "Usage: $0 [-h | -i <hw_server_ip> | -p <hw_server_port>] -- Reset from XSDB/JTAG"
  echo "Arguments:"
  echo "  -h                   Show this help text"
  echo "  -i <hw_server_ip>    Xilinx HW Server IP   (default: 127.0.0.1)"
  echo "  -p <hw_server_port>  Xilinx HW Server Port (default: 3121)"
  exit 0
}

# HW Server Default Configuration
hw_server_ip=127.0.0.1
hw_server_port=3121

while getopts "hi:p:" option; do
  case "$option" in
    i)  hw_server_ip="$OPTARG" ;;
    p)  hw_server_port="$OPTARG" ;;
    h)  # it's always useful to provide some help
        usage
        exit 0
        ;;
    :)  echo "Error: -$OPTARG requires an argument"
        usage
        exit 1
        ;;
    ?)  echo "Error: unknown option -$OPTARG"
        usage
        exit 1
        ;;
  esac
done

# Print informations
echo "Resetting board at ${hw_server_ip}:${hw_server_port}"

# Send Reset Commands through XSDB
cat <<EOF | vitis-2020.2 xsdb
connect -host ${hw_server_ip} -port ${hw_server_port}

puts "Reset board"
targets -set -nocase -filter {name =~ "*PSU*"}
stop
rst -system
after 2000
targets -set -nocase -filter {name =~ "*PMU*"}
stop
rst -system
after 2000
targets -set -nocase -filter {name =~ "*PSU*"}
stop
rst -system
after 2000
mwr 0xFFCA0038 0x1ff
targets -set -nocase -filter {name =~ "*MicroBlaze PMU*"}
dow "${control_pulp_petalinux_dir}/images/linux/pmufw.elf"
after 2000
con
exit
EOF

# That's all folks!!

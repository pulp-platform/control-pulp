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
#
# Robert Balas <balasr@iis.ee.ethz.ch>
# Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>


THIS_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

set -e

# Initialize Python environment suitable for PetaLinux.
python3.6 -m venv .venv
ln -sf python3.6 .venv/bin/python3
source .venv/bin/activate

if [ -n "$NO_IIS" ]; then
  PETALINUX_VER=''
else
  if [ -z "$PETALINUX_VER" ]; then
    PETALINUX_VER="vitis-2019.2"
  fi
fi
readonly PETALINUX_VER
readonly TARGET=zcu102

cd `pwd -P`

echo "create proj"
# create project
if [ ! -d "$TARGET" ]; then
    $PETALINUX_VER petalinux-create -t project -n "$TARGET" --template zynqMP
fi
cd "$TARGET"

#initialize and set necessary configuration from config and local config
$PETALINUX_VER petalinux-config --defconfig scmi_defconfig --get-hw-description "$THIS_DIR/../../control_pulp-txilzu9eg/control_pulp-txilzu9eg/control_pulp-txilzu9eg.sdk"

cd build

mkdir -p components/ext_sources
cd components/ext_sources
if [ ! -d "linux-xlnx" ]; then
  git clone --depth 1 --single-branch --branch linux-scmi git://github.com/Antoniodv/linux-xlnx
fi
cd linux-xlnx

# write kernel configuration 
sed -i "s/plnx_kernel.cfg/scmi_plnx_kernel.cfg/" $THIS_DIR/zcu102/project-spec/meta-plnx-generated/recipes-kernel/linux/linux-xlnx_%.bbappend

echo " ====== KERNEL CONFIG WRITTEN ======"

# add new command and then set it as default (so that if bootcmd is called in boot.scr, it works normally)
sed -i '/PSSERIAL0 /a\    "run_script_cmd=load mmc 0:1 $loadaddr boot.scr; source $loadaddr\\0" \\' $THIS_DIR/zcu102/project-spec/meta-plnx-generated/recipes-bsp/u-boot/configs/platform-auto.h
sed -i 's/#define CONFIG_BOOTCOMMAND	"run default_bootcmd"/#define CONFIG_BOOTCOMMAND	"run run_script_cmd"/' $THIS_DIR/zcu102/project-spec/meta-plnx-generated/recipes-bsp/u-boot/configs/platform-auto.h

echo " ====== CONTROL PULP AUTOFLASH COMMAND CREATED ======"


if [[ ! -f "$THIS_DIR/../board/xilzcu102/control_pulp.dtsi" ]]; then
    echo "error: control_pulp.dtsi not found"
    exit 1
fi

cd $THIS_DIR/zcu102

echo "
/include/ \"system-conf.dtsi\"
/include/ \"$THIS_DIR/../board/xilzcu102/control_pulp.dtsi\"
/ {
};
" > project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi


echo " ====== DTSI SOURCED ====== "


# start build
set +e
$PETALINUX_VER petalinux-build
echo "First build might fail, this is expected..."
set -e
mkdir -p build/tmp/work/aarch64-xilinx-linux/external-hdf/1.0-r0/git/plnx_aarch64/
cp project-spec/hw-description/system.hdf build/tmp/work/aarch64-xilinx-linux/external-hdf/1.0-r0/git/plnx_aarch64/


$PETALINUX_VER petalinux-build

mkdir -p build/tmp/work/aarch64-xilinx-linux/external-hdf/1.0-r0/git/plnx_aarch64/

cd images/linux
if [ ! -f regs.init ]; then
  echo ".set. 0xFF41A040 = 0x3;" > regs.init
fi

echo " ====== PETALINUX BUILD DONE ====== "


# add bitstream from local config
if [ -f "$THIS_DIR/../../output/pms.bit" ]; then
  cp "$THIS_DIR/../../output/pms.bit" "control_pulp_exil${TARGET}_wrapper.bit"
  echo "
the_ROM_image:
{
  [init] regs.init
  [bootloader] zynqmp_fsbl.elf
  [pmufw_image] pmufw.elf
  [destination_device=pl] control_pulp_exil${TARGET}_wrapper.bit
  [destination_cpu=a53-0, exception_level=el-3, trustzone] bl31.elf
  [destination_cpu=a53-0, exception_level=el-2] u-boot.elf
}
" > bootgen.bif

  $PETALINUX_VER petalinux-package --boot --force \
    --fsbl zynqmp_fsbl.elf \
    --fpga control_pulp_exil${TARGET}_wrapper.bit \
    --u-boot u-boot.elf \
    --pmufw pmufw.elf \
    --bif bootgen.bif
else
  echo "FPGA bitstream (pms.bit) not found in fpga/output"
  exit 1
fi

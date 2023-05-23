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

THIS_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

if [[ -z "${CPULP_INSTALL}" ]]; then
    echo "Error: CPULP_INSTALL variable is not set (set it to toolchain installation path)"
    return
fi
export PATH=${CPULP_INSTALL}/bin:$PATH

if [[ -z "${CPULP_TARGET_HOST}" ]]; then
  export CPULP_TARGET_PATH="/mnt/root/"
fi

export PLATFORM=ZYNQMP
export BOARD=ZYNQMP

export ARCH="aarch64"
export CPULP_TOOLCHAIN_HOST_TARGET="${ARCH}-none-linux-gnu"
export CROSS_COMPILE="${CPULP_TOOLCHAIN_HOST_TARGET}-"

export CPULP_TOOLCHAIN_HOST_LINUX_ARCH="${ARCH}"
export KERNEL_ARCH=${ARCH}
export KERNEL_CROSS_COMPILE=${CROSS_COMPILE}

# TODO: determine correct sysroot in ToolChain
unset LDFLAGS
export CFLAGS="--sysroot=${CPULP_INSTALL}/aarch64-none-linux-gnu/"

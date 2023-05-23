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

mkdir -p "${TARGET_DIR}/lib/firmware"
eval BR2_CPULP_BITSTREAM=$(grep BR2_CPULP_BITSTREAM ${BR2_CONFIG} | sed 's/.*=//' | tr -d '"')
if [ -z "$BR2_CPULP_BITSTREAM" ]; then
  exit
fi

# Write optional bitstream in firmware directory
cd "${BINARIES_DIR}"
cp "$BR2_CPULP_BITSTREAM" fpga.bit
"${HOST_DIR}/bin/mkbootimage" --zynqmp "${BR2_EXTERNAL_CPULP_PATH}/board/xilzcu102/bitstream.bif" \
			      "${TARGET_DIR}/lib/firmware/fpga-default.bin"

# Install init.d load script
cp "${BR2_EXTERNAL_CPULP_PATH}/board/xilzcu102/S95fpga" "${TARGET_DIR}/etc/init.d/"

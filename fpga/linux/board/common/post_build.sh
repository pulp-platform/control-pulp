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

echo "Removing NFS init.d script"
rm -f $1/etc/init.d/S60nfs

echo "Installing optional custom mount script"
EXT_MOUNT=$(grep BR2_CPULP_EXT_MOUNT ${BR2_CONFIG} | sed -e 's/.*=//' -e 's/^"//' -e 's/"$//')
if [ -z "$EXT_MOUNT" ]; then
  rm $1/etc/init.d/S99extroot
else
  sed -i "s|EXTERNAL_MOUNT_POINT|${EXT_MOUNT}|" $1/etc/init.d/S99extroot
fi

echo "Installing optional authorized key files"
AUTH_KEYS=$(grep BR2_CPULP_AUTHORIZED_KEYS ${BR2_CONFIG} | sed -e 's/.*=//' -e 's/^"//' -e 's/"$//')
if [ ! -z "$AUTH_KEYS" ]; then
  mkdir -p ${TARGET_DIR}/root/.ssh/
  cp $AUTH_KEYS ${TARGET_DIR}/root/.ssh/authorized_keys
fi

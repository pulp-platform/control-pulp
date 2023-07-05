#! /usr/bin/env bash

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

# Install script for VIPs. This only works if you have access to the servers.
# Otherwise you will have to do the installation manually, as indicated in the
# respective READMEs
set -o errexit -o pipefail -o noclobber -o nounset

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)

GITLAB=iis-git.ee.ethz.ch
VIP_DIR=vip-proprietary
AGREE_LICENSE=0
USE_GITLAB=0

cd "$ROOT"

while [[ "$#" -gt 0 ]]; do case $1 in
  -y|--yes) AGREE_LICENSE=1;;
  -g|--gitlab) USE_GITLAB=1;;
  *) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done

if [[ "$AGREE_LICENSE" -ne "1" ]]; then
    echo "You need to agree to all the licenses of all the VIPs in the tb/vip
    folder. If you do, pass --yes to this script"
    exit 0
fi
if [[ ! -d "vip-proprietary" ]]; then
    if [[ "$USE_GITLAB" -eq "1" ]]; then
	git clone https://gitlab-ci-token:${CI_JOB_TOKEN}@${GITLAB}/pulp-open/pulp-vip-proprietary \
	    "$VIP_DIR"
    else
	git clone git@iis-git.ee.ethz.ch:pulp-open/pulp-vip-proprietary.git \
	    "$VIP_DIR"
    fi
else
    echo "The directory ${VIP_DIR} already exists, skipping git clone"
fi
echo "Installing i2c eeprom model"
cp --verbose "$VIP_DIR"/24FC1025-i2c-eeprom/*.v i2c_eeprom/
echo "Installing spi flash model"
mkdir -p spi_flash/S25fs256s
cp --verbose -r "$VIP_DIR"/S25fs256s-spi-flash/* spi_flash/S25fs256s

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

################################################################################
#
# zynq mkbootimage
#
################################################################################

ZYNQ_MKBOOTIMAGE_VERSION = 4ee42d782a9ba65725ed165a4916853224a8edf7
ZYNQ_MKBOOTIMAGE_SITE = $(call github,antmicro,zynq-mkbootimage,$(ZYNQ_MKBOOTIMAGE_VERSION))
ZYNQ_MKBOOTIMAGE_LICENSE = BSD-2-Clause
ZYNQ_MKBOOTIMAGE_LICENSE_FILES = LICENSE
HOST_ZYNQ_MKBOOTIMAGE_DEPENDENCIES = host-pcre host-elfutils

define HOST_ZYNQ_MKBOOTIMAGE_BUILD_CMDS
    $(HOST_MAKE_ENV) $(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D)
endef

define HOST_ZYNQ_MKBOOTIMAGE_INSTALL_CMDS
    $(INSTALL) -D -m 0755 $(@D)/mkbootimage $(HOST_DIR)/bin
endef

$(eval $(host-generic-package))

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

################################################################################
#
# pmsrst tools
#
################################################################################

PMSRST_VERSION = 0.1
PMSRST_SITE_METHOD = local
PMSRST_SITE = $(BR2_EXTERNAL_CPULP_PATH)/pmsrst
PMSRST_LICENSE = GPL
PMSRST_INSTALL_TARGET = YES
PMSRST_DEPENDENCIES =

PMSRST_CXXFLAGS = -O2
PMSRST_CXXFLAGS += -DDEBUG_LEVEL=$(BR2_PACKAGE_PMSRST_DEBUG_LEVEL)
ifneq ($(BR2_PACKAGE_PMSRST_DEBUG_LEVEL),0)
PMSRST_CXXFLAGS += -g
endif
PMSRST_CXXFLAGS += -DPLATFORM=$(BR2_PACKAGE_CPULP_PLATFORM)

PMSRST_MK_OPTS = CXX="$(TARGET_CXX)" CC="$(TARGET_CC)" \
	LD="$(TARGET_LD)" CXXFLAGS="$(PMSRST_CXXFLAGS)"
PMSRST_TARGET_MAKE_ENV =

define PMSRST_CLEAN_BUILD
	$(PMSRST_TARGET_MAKE_ENV) $(MAKE) $(PMSRST_MK_OPTS) -C $(@D) clean
endef
PMSRST_PRE_BUILD_HOOKS += PMSRST_CLEAN_BUILD

define PMSRST_BUILD_CMDS
	$(PMSRST_TARGET_MAKE_ENV) $(MAKE) $(PMSRST_MK_OPTS) -C $(@D) all
endef

define PMSRST_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/pmsrst $(TARGET_DIR)/usr/bin/pmsrst
endef

$(eval $(generic-package))

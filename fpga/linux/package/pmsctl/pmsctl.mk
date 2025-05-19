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
# pmsctl tools
#
################################################################################

PMSCTL_VERSION = 0.1
PMSCTL_SITE_METHOD = local
PMSCTL_SITE = $(BR2_EXTERNAL_CPULP_PATH)/pmsctl
PMSCTL_LICENSE = GPL
PMSCTL_INSTALL_TARGET = YES
PMSCTL_DEPENDENCIES =

PMSCTL_CXXFLAGS = -O2
PMSCTL_CXXFLAGS += -DDEBUG_LEVEL=$(BR2_PACKAGE_PMSCTL_DEBUG_LEVEL)
ifneq ($(BR2_PACKAGE_PMSCTL_DEBUG_LEVEL),0)
PMSCTL_CXXFLAGS += -g
endif
PMSCTL_CXXFLAGS += -DPLATFORM=$(BR2_PACKAGE_CPULP_PLATFORM)

PMSCTL_MK_OPTS = CXX="$(TARGET_CXX)" CC="$(TARGET_CC)" \
	LD="$(TARGET_LD)" CXXFLAGS="$(PMSCTL_CXXFLAGS)"
PMSCTL_TARGET_MAKE_ENV =

define PMSCTL_CLEAN_BUILD
	$(PMSCTL_TARGET_MAKE_ENV) $(MAKE) $(PMSCTL_MK_OPTS) -C $(@D) clean
endef
PMSCTL_PRE_BUILD_HOOKS += PMSCTL_CLEAN_BUILD

define PMSCTL_BUILD_CMDS
	$(PMSCTL_TARGET_MAKE_ENV) $(MAKE) $(PMSCTL_MK_OPTS) -C $(@D) all
endef

define PMSCTL_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/pmsctl $(TARGET_DIR)/usr/bin/pmsctl
endef

$(eval $(generic-package))

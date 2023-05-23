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

# Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

PULP_APP = fc_idma_basic

TEST_SRCS ?= fc_idma_basic.c
PULP_APP_SRCS = $(TEST_SRCS)
PULP_APP_FC_SRCS = $(TEST_FC_SRCS)
ifdef TEST_FC_SRCS
pulpFc=1
endif

space :=
space +=

#BUILD_DIR = $(subst $(space),_,$(CURDIR)/build/$(TEST_SRCS))

PULP_CFLAGS += -O3 -DVERBOSE
stackSize = 4096

include $(PULP_SDK_HOME)/install/rules/pulp.mk

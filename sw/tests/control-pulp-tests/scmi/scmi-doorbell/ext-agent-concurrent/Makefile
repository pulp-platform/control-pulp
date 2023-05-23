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

# Robert Balas <balasr@iis.ee.ethz.ch>
# Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

PULP_APP = test-scmi-ext-agent-int-conc
PULP_APP_FC_SRCS = scmi-ext-agent-conc.c
PULP_APP_HOST_SRCS = scmi-ext-agent-conc.c
PULP_APP_ASM_SRCS = ../../../../shared/handler.S
PULP_CFLAGS = -Os -g3 -Wall -Wextra -I../../../../shared/include \
	-Wno-unused-parameter -Wno-unused-function -Wno-unused-variable \
	-Wnull-dereference -Wformat=2

VERBOSE=1
include $(PULP_SDK_HOME)/install/rules/pulp_rt.mk


.PHONY: pulptrace
pulptrace: traced.log

traced.log: build/trace_core_000003e0.log build/scmi-ext-agent-conc/scmi-ext-agent-conc
	pulptrace2 build/trace_core_000003e0.log build/scmi-ext-agent-conc/scmi-ext-agent-conc > $@

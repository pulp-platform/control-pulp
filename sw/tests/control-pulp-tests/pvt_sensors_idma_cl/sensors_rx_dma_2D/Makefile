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

PULP_APP = test
PULP_APP_SRCS = test_rx_dma.c
PULP_CFLAGS = -O3 -g -DNUM_CORES=1 -DAXI_N_SAMPLES=1000

include $(PULP_SDK_HOME)/install/rules/pulp.mk

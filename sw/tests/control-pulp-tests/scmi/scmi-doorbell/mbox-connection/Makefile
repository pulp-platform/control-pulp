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

PULP_APP = mbox_connection
PULP_APP_FC_SRCS = mbox_connection_test.c
PULP_APP_HOST_SRCS = mbox_connection_test.c
PULP_CFLAGS = -Os -g3 -Wall -Wextra -I../../../shared/include \
	-Wno-unused-parameter -Wno-unused-function -Wno-unused-variable \
	-Wnull-dereference -Wformat=2 #-DDEBUG

include $(PULP_SDK_HOME)/install/rules/pulp_rt.mk


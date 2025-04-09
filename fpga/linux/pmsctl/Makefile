# Copyright 2021 ETH Zurich
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
# Author: Robert Balas (balasr@iis.ee.ethz.ch)

CXX=aarch64-none-linux-gnu-g++
C=aarch64-none-linux-gnu-gcc

all: pmsctl scmictl setspeed

pmsctl: pmsctl.cc $(wildcard physmem/inc/*)
	$(CXX) -std=c++11 -Wall -I. $(CXXFLAGS) $(CPPFLAGS) $< -o $@;

scmictl: scmictl.cc $(wildcard physmem/inc/*)
	$(CXX) -std=c++11 -Wall -I. $(CXXFLAGS) $(CPPFLAGS) $< -o $@;

setspeed: setspeed.c $(wildcard physmem/inc/*)
	$(C) -std=c11 -Wall -I. $(CFLAGS) $(CPPFLAGS) $< -o $@;

.PHONY: clean

clean:
	$(RM) pmsctl
	$(RM) scmictl
	$(RM) setspeed

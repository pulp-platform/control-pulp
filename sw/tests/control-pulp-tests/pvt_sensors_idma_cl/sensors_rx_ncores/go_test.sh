#!/bin/bash

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


if [ -e res.log ]
then
    rm res.log
fi

exec 3> res.log

for(( j=100; j<=1000; j=j+100 ))
do
    echo "TEST NO DMA: ${j} registers"
    echo "TEST NO DMA: ${j} registers" >&3
    for (( i=1; i<9; i=i+7 ))
    do
	sed -i "s/\-DNUM_CORES=[0-9]* \-DAXI_N_SAMPLES=[0-9]*/-DNUM_CORES=${i} -DAXI_N_SAMPLES=${j}/" Makefile
	make clean all run > res_${i}core.log
	awk '/\[STDOUT\-CL0_PE[[:alnum:]]\] TEST/ {
	  if ($4 == "FAIL" )
	    { split($2, subfield, "PE")
	      print "TEST NO DMA: core",substr(subfield[2],1,1),"failed";
	      exit;
	    }
	}' res_${i}core.log
	sed -n "s/# \[STDOUT\-CL0_PE[[:alnum:]]\] CORE/TEST ${i}  core --> CORE/p" res_${i}core.log >&3
	rm res_${i}core.log
    done
done

exec 3<&-

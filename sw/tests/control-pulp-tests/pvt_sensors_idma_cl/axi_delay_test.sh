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

run_test () {
    
    echo "TEST $1 $2: $3 delay cycles"
    echo "TEST $1 $2: $3 delay cycles" >&$5
    
    for (( i=1; i<$4; i=i+7 ))
    do
        sed -i "s/\-DNUM_CORES=[0-9]* \-DAXI_N_SAMPLES=[0-9]*/-DNUM_CORES=${i} -DAXI_N_SAMPLES=500/" Makefile
        make clean all run > res_${i}core.log
        awk '/\[STDOUT\-CL0_PE[[:alnum:]]\] TEST/ {
          if ($4 == "FAIL" ) 
            { split($2, subfield, "PE")
              print "TEST: core",substr(subfield[2],1,1),"failed";
              exit;
            }
        }' res_${i}core.log
        sed -n "s/# \[STDOUT\-CL0_PE[[:alnum:]]\] CORE/TEST ${i}  core --> CORE/p" res_${i}core.log >&$5
        rm res_${i}core.log
    done
    }

cd sensors_rx_ncores
if [ -e res_del.log ]
then
    rm res_del.log
fi
exec {id1}> res_del.log

cd ../sensors_rx_dma
if [ -e res_del.log ]
then
    rm res_del.log
fi
exec {id2}> res_del.log

cd ../sensors_rx_dma_2D
if [ -e res_del.log ]
then
    echo "$(pwd)"
    rm res_del.log
fi
echo "$(pwd)"
exec {id3}> res_del.log

cd ..

for(( j=100; j<=1000; j=j+100 ))
do
    cd ../../../rtl/tb
    sed -i "s/FixedDelay\(.*\)put = [0-9]*/FixedDelay\1put = ${j}/" tb_sw_axiboot.sv
    echo $(sed -n "/FixedDelay\(.*\)put = [0-9]*/p" tb_sw_axiboot.sv)
    cd ../../sim
    make clean all
    cd ../tests/control-pulp-tests/sensors_transfers/sensors_rx_ncores
    run_test NO DMA $j 9 ${id1}
    cd ../sensors_rx_dma
    run_test DMA 1D $j 9 ${id2}
    cd ../sensors_rx_dma_2D
    run_test DMA 2D $j 2 ${id3}
    cd ..
done

exec 3<&${id1}-
exec 4<&${id2}-
exec 5<&${id3}-

exec 3<&-
exec 4<&-
exec 5<&-


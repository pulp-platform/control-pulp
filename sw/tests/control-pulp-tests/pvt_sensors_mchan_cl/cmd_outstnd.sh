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
    
    echo "TEST $1 $2: $3 queues depth"
    echo "TEST $1 $2: $3 queues depth" >&$5
    
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

cd sensors_rx_dma
if [ -e res_cmd_outsnd.log ]
then
    rm res_cmd_outsnd.log
fi
exec {id1}> res_cmd_outsnd.log

cd ../../../../rtl/tb
sed -i "s/FixedDelay\(.*\)put = [0-9]*/FixedDelay\1put = 100/" tb_sw_axiboot.sv
echo $(sed -n "/FixedDelay\(.*\)put = [0-9]*/p" tb_sw_axiboot.sv)
cd ../../tests/control-pulp-tests/sensors_transfers

for(( j=2; j<=2**7; j=j*2 ))
do
  cd ../../../rtl/includes
  sed -i "s/\`define DMA_QUEUE_DEPTH  [0-9]*/\`define DMA_QUEUE_DEPTH  ${j}/" pulp_soc_defines.sv
  sed -i "s/\`define NB_OUTSND_BURSTS [0-9]*/\`define NB_OUTSND_BURSTS 16/" pulp_soc_defines.sv
  cd ../../sim
  make clean all
  cd ../tests/control-pulp-tests/sensors_transfers/sensors_rx_dma
  run_test DMA 1D $j 9 ${id1}
  cd ..
done

exec 3<&${id1}-

exec 3<&-


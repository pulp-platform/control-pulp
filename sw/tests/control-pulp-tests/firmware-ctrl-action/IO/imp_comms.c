/*
* Copyright 2023 ETH Zurich and University of Bologna
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: Apache-2.0
*/
/* FreeRTOS Inclusions. */


/* Libraries Inclusion */
#include "imp_comms.h"
#include "imp_dataLib.h"

#include "cfg_types.h"
#include "cfg_system.h"
#include "cfg_constants.h"


varBool_e bImpCommsInit(void) {

    //nothing to do here:

    no_io_uiIndex = 0;
    no_io_uiCounter = 0;
    no_io_periodicIndex = 0;
    no_io_periodicCounter = 0;

    return PCF_TRUE;
}


varBool_e bImpSendCoreFreq(varValue *i_computed_freq) {

    no_io_periodicCounter++;
    if (no_io_periodicCounter > NO_IO_PERIODIC_STEPS_WAIT)
    {
        // We do this below.
        //no_io_periodicCounter = 0;

        varFor l_num_core = g_SysConfigTable.num_core;

        for (int i = 0; i < l_num_core; i++)
        {
            no_io_computedFreq[no_io_periodicIndex][i] = i_computed_freq[i];

            #ifdef NO_IO_FREQ_COMPARE
            no_io_freqDiff[no_io_periodicIndex][i] = no_io_recordedFreqOut[no_io_periodicIndex][i] - i_computed_freq[i];
            #endif
        }
    }

    return PCF_TRUE;
}

varBool_e bImpReadTempRequest(varValue *o_measured_temp) {


    varFor l_num_core = g_SysConfigTable.num_core;

    for (varFor i = 0; i < l_num_core; i++)
        o_measured_temp[i] = no_io_measuredTemp[no_io_periodicIndex][i];


    //no_io_periodicIndex++;
    if (no_io_periodicIndex >= NO_IO_PERIODIC_TOT_STEPS)
    {
        no_io_periodicIndex = 0;
    }

    return PCF_TRUE;
}

varBool_e bImpReadInputParameters(ctrl_parameter_table_t* i_input_table) {

        no_io_uiCounter++;

        if (no_io_uiCounter > NO_IO_UI_STEPS_WAIT)
        {
            no_io_uiCounter = 0;

            varFor l_num_core = g_SysConfigTable.num_core;

            for (varFor i = 0; i < l_num_core; i++)
            {
                i_input_table->target_freq[i] = no_io_uiTargetFreq[no_io_uiIndex][i];

                if (no_io_workload[no_io_uiIndex][i] == 0.5333)
          {
                        i_input_table->perc_workload[i][0] = 100;
                        i_input_table->perc_workload[i][1] = 0;
                        i_input_table->perc_workload[i][2] = 0;
                        i_input_table->perc_workload[i][3] = 0;
                }
          else if (no_io_workload[no_io_uiIndex][i] == 1.2444)
                {
                        i_input_table->perc_workload[i][0] = 0;
                        i_input_table->perc_workload[i][1] = 100;
                        i_input_table->perc_workload[i][2] = 0;
                        i_input_table->perc_workload[i][3] = 0;
                }
          else if (no_io_workload[no_io_uiIndex][i] == 1.3798)
          {
            i_input_table->perc_workload[i][0] = 0;
            i_input_table->perc_workload[i][1] = 0;
            i_input_table->perc_workload[i][2] = 100;
            i_input_table->perc_workload[i][3] = 0;
          }
                else if (no_io_workload[no_io_uiIndex][i] == 1.7778)
                {
                        i_input_table->perc_workload[i][0] = 0;
                        i_input_table->perc_workload[i][1] = 0;
                        i_input_table->perc_workload[i][2] = 0;
                        i_input_table->perc_workload[i][3] = 100;
                }
          else
                {
                        i_input_table->perc_workload[i][0] = 100;
                        i_input_table->perc_workload[i][1] = 0;
                        i_input_table->perc_workload[i][2] = 0;
                        i_input_table->perc_workload[i][3] = 0;
                }
            }

            i_input_table->total_power_budget = no_io_uiPowerBudget[no_io_uiIndex];

            no_io_uiIndex++;

            if (no_io_uiIndex >= NO_IO_NUMBER_OF_COMMANDS)
            {
                #ifdef NO_IO_AUTO_RUN
                no_io_uiIndex = 0;
                #else
                //TBC
                vTaskSuspend(taskHandles[0]);
                vTaskSuspend(NULL);
                #endif
            }
        }

        //o_telemetry->chip_avg_measured_power = no_io_simPower[no_io_periodicIndex]; //[no_io_uiIndex * NO_IO_UI_STEPS + no_io_uiCounter];

        //no_io_uiFreqRedMap[no_io_uiIndex * NO_IO_UI_STEPS + no_io_uiCounter] = o_telemetry->frequency_reduction_map[0];
        //no_io_uiErrorMap[no_io_uiIndex * NO_IO_UI_STEPS + no_io_uiCounter] = 0;

        return PCF_TRUE;
}

varBool_e bImpReadInstructionComposition(ctrl_parameter_table_t* i_input_table)
{
    return PCF_TRUE;
}
varBool_e bImpReadPowerMeasure(ctrl_parameter_table_t* i_input_table)
{
    return PCF_TRUE;
}

//TODO: remove this probably.
varBool_e bImpWriteFreqRedMap(telemetry_t* i_telemetry)
{
    return PCF_TRUE;
}

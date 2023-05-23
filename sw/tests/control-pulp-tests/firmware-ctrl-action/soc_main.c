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

/*  1: import the code and separate it in several #ifdef
 *   2: import the PerfCounter (but both pulpopen and cv32)
 *   3: ipmort/create an API cluster offload to switch between the two
 *quer
 *
 *
 */

/* FreeRTOS Inclusions. */
//#include <FreeRTOS.h>

#include "pulp.h"

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

/* Libraries Inclusion */
#include "cfg_types.h"
#include "cfg_firmware.h"
#include "cfg_system.h"
#include "cfg_control.h"
#include "cfg_constants.h"
//
#include "imp_comms.h"
#include "ctrl_math.h"
#include "measure.h"
//#include "tgt_cluster.h"
//
//#include "cl_dma.h"

#define FOR_OUT 2
#define FOR_IN  3

sys_config_table_t g_SysConfigTable =
  {
    .num_core                               = MAX_NUM_CORE,
    .num_quad                               = MAX_NUM_QUAD,
    .num_pw_domains                         = SYS_PW_DOMAIN_NUM,
    .num_chip_proc                          = 1,
    .num_socket_sys                         = 1,

    /* Parameters of the Cores */
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
    .core_critical_temperature              = 358.0f,
    .core_idle_power                        = 0.1f,
    .core_max_power_single                  = 4.0f,
    .core_min_frequency                     = 0.8f,
    .core_max_frequency                     = 3.5f,
    .core_wl_states_num                     = SYS_CORE_WL_STATES,
    .base_power_coeff						=
    { {0.13333f, 0.5333f}, {0.13333f, 1.2444f}, {0.13333f, 1.379894f}, {0.13333f, 1.77778f} },

    /* Initialization Values */
    .init_core_freq                         = 1.0f,
    .init_core_volt                         = 0.75f,
    .init_core_workload                     = 0.5333f,
    .init_core_ceff                         = 0.6f
#else
    .core_critical_temperature              = 358,
    .core_idle_power                        = 0,
    .core_max_power_single                  = 4,
    .core_min_frequency                     = 0,
    .core_max_frequency                     = 3,
    .core_wl_states_num                     = SYS_CORE_WL_STATES,
    .base_power_coeff						=
    { {0, 0}, {0, 1}, {1, 1}, {0, 2} },

    /* Initialization Values */
    .init_core_freq                         = 1,
    .init_core_volt                         = 1,
    .init_core_workload                     = 1,
    .init_core_ceff                         = 1
#endif
  };

code_config_table_t g_CodeConfigTable =
  {
    /***** Code configuration *****/
    .use_watchdogs							= PCF_TRUE,
    .use_secure_io							= PCF_TRUE,
    .use_tests_on_numbers					= PCF_TRUE,

    /*** Telemetry Configuration **/
    .use_frequency_reduction_map			= PCF_TRUE,
    .use_error_map							= PCF_TRUE,
  };

ctrl_config_table_t g_ControlConfigTable =
  {

    /***** CTRL Configuration *****/
    .use_lms								= PCF_TRUE,
    .use_freq_binding						= PCF_TRUE,
    .use_quadrant_pw_budget					= PCF_TRUE,

    /***** PID Configuration ******/
    .use_pid_integral_action				= PCF_TRUE,
    .use_pid_derivative_action				= PCF_FALSE,
    .use_pid_saturation						= PCF_TRUE,
    .use_pid_ff_action						= PCF_TRUE,
    .use_pid_anti_windup_sat				= PCF_TRUE,

    /* Initialization Values */
    // They have to be defined even if PID_CONFIG_x is disabled //TODO: fix this?
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
    .pid_kp									= 0.05f, //2,
    .pid_ki									= 10.0f,
    .pid_kd									= 3.0f,
    .pid_dt									= 0.005f,
    .pid_anti_windup_sat_coeff				= -0.75f,
    .pid_anti_windup_sat_up					= 0.4f,

    /*** Other Control Values *****/
    .pid_temperature_margin					= 10.0f,
    .freq_max_gradient						= 0.25f,
    .alpha_max_value						= 2.0f,
    .alpha_error_base_value                 = 0.5f,
    .hyst_high_temp_limit					= 357.0f,
    .hyst_low_temp_limit					= (358.0f - 10.0f - 1.0f),
    .max_pw_diff							= 0.25f,
    .pid_integral_reduction_coeff			= 1.0f,

    /* Initialization Values */
    .init_total_power_budget                = 22.5f
#else
    .pid_kp									= 1, //2,
    .pid_ki									= 10,
    .pid_kd									= 3,
    .pid_dt									= 1,
    .pid_anti_windup_sat_coeff				= -1,
    .pid_anti_windup_sat_up					= 1,

    /*** Other Control Values *****/
    .pid_temperature_margin					= 10,
    .freq_max_gradient						= 1,
    .alpha_max_value						= 2,
    .alpha_error_base_value                 = 1,
    .hyst_high_temp_limit					= 357,
    .hyst_low_temp_limit					= (358 - 10 - 1),
    .max_pw_diff							= 1,
    .pid_integral_reduction_coeff			= 1,

    /* Initialization Values */
    .init_total_power_budget                = 22
#endif

  };

ctrl_lms_config_table_t g_LmsConfigTable =
  {
    /** Configuration **/
    //uint16_t coeff_num,
    .batch_iteration_num = 8,

    /* Values */
    // Forgetting Factor
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
    .lambda = 0.948f, //0.955,
    .bound_limits =
    {{1.5f,  1.0f}, {1.5f,  1.0f}, {1.5f, 1.0f}, {1.5f, 1.0f}}
#else
    .lambda = 1, //0.955,
    .bound_limits =
    {{1,  1}, {1,  1}, {1, 1}, {1, 1}}
#endif
  };

//

ctrl_parameter_table_t g_TasksCtrlParameter;
telemetry_t g_ChipTelemetry;

ctrl_parameter_table_t* ctrl_param_addr;
telemetry_t* telemetry_addr;

//

void power_comp (void* arg);
void alpha_comp (void* arg);
void pid_comp (void* arg);
void freq_comp (void* arg);

varBool_e bSecureControlParamSetup(void);

////

// Control Variables
varValue computed_core_frequency[MAX_NUM_CORE] = {0};
varValue computed_core_voltage[MAX_NUM_CORE] = {0};
varValue measured_temperature[MAX_NUM_CORE] = {0};
varValue target_core_power[MAX_NUM_CORE]= {0};
varValue reduced_core_power[MAX_NUM_CORE] = {0};

varValue delta_power = 0;
varValue estimated_total_power = 0;

varBool_e hyst_thresh_reached[MAX_NUM_CORE];
varValue pid_cmd[MAX_NUM_CORE];

//TODO: because there is also the same strucure in power compute, maybe we can optimize
varValue lpower_formula_coeff[POWER_FORMULA_COEFF_NUM];

// Internal to Global Variables
ctrl_parameter_table_t l_ctrl_parameter_table;
telemetry_t l_accumulation_telemetry;
varFor l_num_core = 36;//g_SysConfigTable.num_core;
varFor l_num_quad = 2; //g_SysConfigTable.num_quad;
varValue l_hyst_high_temp_limit;
varValue l_hyst_low_temp_limit;

uint32_t l_error_map;

uint32_t id = 1;

//JO_TBR
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define ALPHA_MIN_INIT 1.1f
#else
#define ALPHA_MIN_INIT 2
#endif


//JO_TBR
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define ALPHA_MIN_INIT 1.1f
#else
#define ALPHA_MIN_INIT 2
#endif


/*-----------------------------------------------*/
/******************* Functions *******************/
/*-----------------------------------------------*/

varValue lCorePowerComputation(varValue *o_target_core_power, ctrl_parameter_table_t *i_ctrl_parameter_table, telemetry_t* i_telemetry_struct, varValue *i_pid_cmd){

  varValue total_power = 0;
  varValue lpower_formula_coeff[POWER_FORMULA_COEFF_NUM];

  //TODO: CUGV

  //TBD: here we can also pass the pointer to the array and call the function only 1 time. The function will do for and sum.
  for (varFor i = 0; i < g_SysConfigTable.num_core; i++)
    {
      //printf("%d: %d\n", i, i_ctrl_parameter_table->Workload[i]);
#ifdef USE_INSTRUCTIONS_COMPOSITION
      for (varFor k = 0; k < POWER_FORMULA_COEFF_NUM; k++)
        {
          lpower_formula_coeff[k] = 0;

          for (varFor j = 0; j < SYS_CORE_WL_STATES; j++)
            {
              lpower_formula_coeff[k] += i_ctrl_parameter_table->power_formula_coeff[ j ][k] * (varValue)i_ctrl_parameter_table->perc_workload[i][j] / VD_100_PERC;
            }
        }
#else
      lpower_formula_coeff[0] = i_ctrl_parameter_table->power_formula_coeff[0][0];
      lpower_formula_coeff[1] = i_ctrl_parameter_table->core_ceff[i];
      //    printf("\nworkload:   %f   %f\n", lpower_formula_coeff[0], lpower_formula_coeff[1]);
#endif

      //    printf("l_ctrl_parameter_table.target_freq: %f\n", l_ctrl_parameter_table.target_freq[i]);

      varValue core_power = lMathPowerCompute(i_ctrl_parameter_table->target_freq[i], lpower_formula_coeff);

      //    printf("core_power: %f\n", core_power);

      if (core_power < o_target_core_power[i] - g_ControlConfigTable.max_pw_diff)
        {
          i_pid_cmd[i] = core_power / o_target_core_power[i];
        }
      else if (core_power > o_target_core_power[i] + g_ControlConfigTable.max_pw_diff)
        {
          i_pid_cmd[i] = core_power / o_target_core_power[i];
        }
      else
        {
          i_pid_cmd[i] = VD_ZERO;
        }

      o_target_core_power[i] = core_power;
      //    printf("o_target_core_power: %f\n", o_target_core_power[i]);
      //    printf("core_idle_power: %f\n", g_SysConfigTable.core_idle_power);

      //test_on_number
      if (o_target_core_power[i] < g_SysConfigTable.core_idle_power)
        {
#ifdef DEBUG_ACTIVE
          printf("Number issue, computed_core_power core %d: %f\n\r", i, o_target_core_power[i]);
#endif

          o_target_core_power[i] = g_SysConfigTable.core_idle_power;
        } else if (o_target_core_power[i] > g_SysConfigTable.core_max_power_single)
        {
          o_target_core_power[i] = g_SysConfigTable.core_max_power_single;

          //Bitmap of Frequency Reduction.
          i_telemetry_struct->frequency_reduction_map[i] |= BM_FRM_MAX_SINGLE_POW_SAT;
        }
      total_power += o_target_core_power[i];
      //TODO: for quadrants, we should change this to reflect quadrants disposition so we can add quadrant power also inside this for
      //printf("CtP r: %d\n", (int)o_target_core_power[i]);
      //Saturation check for single Core PowerMax Margin

    }

  //printFloat(o_target_core_power[0]);

  return total_power;
}

varValue lAlphaPowerReduction(varValue *o_reduced_core_power, varValue *i_target_core_power, varValue *i_measured_temperature,
                              varValue i_delta_power, ctrl_parameter_table_t *i_ctrl_parameter_table, telemetry_t* i_telemetry_struct){

  varFor l_num_core = g_SysConfigTable.num_core;
  varValue l_core_critical_temperature = g_SysConfigTable.core_critical_temperature;
  varValue l_alpha_max_value = g_ControlConfigTable.alpha_max_value;
  varValue Alpha[MAX_NUM_CORE];
  varValue TotalAlpha = 0;

  varValue TotalPower = 0;

  //Compute Alpha
  for (varFor i = 0; i < l_num_core; i++)
    {
      //test_on_number //MUST do always, not only when test on numbers, and it is not a ToN Error!
      if ((l_core_critical_temperature - i_measured_temperature[i]) < 0)
        {
#ifdef DEBUG_ACTIVE
          printf("Number issue, i_measured_temperature > l_core_critical_temperature, core %d: %f\n\r", i, i_measured_temperature[i]);
#endif

          i_measured_temperature[i] = l_core_critical_temperature - (1 / l_alpha_max_value);
        }

      Alpha[i] = 1 / (l_core_critical_temperature - i_measured_temperature[i]);
      //test_on_number
      if (Alpha[i] <= 0)
        {
          /* TODO:
          //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
          ErrorMap |= BM_ERROR_NUMBERS_VALUE;
          #endif
          */

#ifdef DEBUG_ACTIVE
          printf("Number issue, Alpha<0, core %d: %f\n\r", i, Alpha[i]);
#endif

          Alpha[i] = g_ControlConfigTable.alpha_error_base_value; //TBD: we are whitin an ERROR!!! do not put 0.01!

        } else if (Alpha[i] > l_alpha_max_value)
        {
          /* TODO:
          //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
          ErrorMap |= BM_ERROR_NUMBERS_VALUE;
          #endif
          */
#ifdef DEBUG_ACTIVE
          printf("Number issue, Alpha>1, core %d: %f\n\r", i, Alpha[i]);
#endif

          Alpha[i] = l_alpha_max_value;
        }

      TotalAlpha += Alpha[i];
      //TODO: for quadrants, we should change this to reflect quadrants disposition so we can add quadrant power also inside this for
    }

  if (g_ControlConfigTable.use_freq_binding == PCF_TRUE)
    {
      //TBU: This uint16+ is VERY delicate, it has to change with the
      //	typedef struct _ctrl_parameter_table, so it could need a better design
      uint16_t* i_core_binding_vector = i_ctrl_parameter_table->core_binding_vector;
      varValue min_group_alpha[(MAX_NUM_CORE / 2) + 1]; // +1 cuz of 0

      //Resetting
      TotalAlpha = 0;

      //TODO: Optimize This
      //Initialization
      for (varFor i = 0; i < (l_num_core / 2) +1; i++ )
        min_group_alpha[i] = ALPHA_MIN_INIT;

      // Scan
      for (varFor i = 0; i < l_num_core; i++)
        {
          if (i_core_binding_vector[i] != 0)
            {
              //test_on_number
              if ((i_core_binding_vector[i] > (l_num_core/2)) /*|| (i_core_binding_vector[i] < 0) since it is unsigned, is never <0*/)
                {
                  //TODO
                  //ErrorMap |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
                  printf("Number issue, i_core_binding_vector>l_num_core/2, core %d: %f\n\r", i, i_core_binding_vector[i]);
#endif

                  i_core_binding_vector[i] = 0;
                }

              if ((Alpha[i] < min_group_alpha[i_core_binding_vector[i]]))
                {
                  min_group_alpha[i_core_binding_vector[i]] = Alpha[i];
                }
            }
        }	//for

      // Apply
      for (varFor i = 0; i < l_num_core; i++)
        {
          if (i_core_binding_vector[i] != 0)
            {
              Alpha[i] = min_group_alpha[i_core_binding_vector[i]];

              //todo
              i_telemetry_struct->frequency_reduction_map[i] |= BM_FRM_BINDING_RED;
            }

          TotalAlpha += Alpha[i];
        }

    } //end, if (g_ControlConfigTable.use_freq_binding == PCF_TRUE)

  //Normalize Alpha
  for (varFor i = 0; i < l_num_core; i++)
    {
      // Alpha Normalized. For optimization we use Alpha[i]
      Alpha[i] = Alpha[i] / TotalAlpha;
      //test_on_number
      if (Alpha[i] <= 0)
        {
          /* TODO:
          //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
          ErrorMap |= BM_ERROR_NUMBERS_VALUE;
          #endif
          */
#ifdef DEBUG_ACTIVE
          printf("Number issue, Alpha<0, core %d: %f\n\r", i, Alpha[i]);
#endif

          Alpha[i] = g_ControlConfigTable.alpha_error_base_value; //TBD: we are whitin an ERROR!!! do not put 0.01!

        } else if (Alpha[i] >= 1)
        {
          /* TODO:
          //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
          ErrorMap |= BM_ERROR_NUMBERS_VALUE;
          #endif
          */
#ifdef DEBUG_ACTIVE
          printf("Number issue, Alpha>1, core %d: %f\n\r", i, Alpha[i]);
#endif

          Alpha[i] = g_ControlConfigTable.alpha_error_base_value; //TBD: we are whitin an ERROR!!! do not put 0.99!
        }

      // Here Christian added this: [?????]
      /*
        if (i_delta_power*Alpha[i] > i_target_core_power[i])
        {
        Alpha[i] = i_target_core_power[i] / i_delta_power;
        }*/
    }

  //Apply Alpha Reduction
  for (varFor i = 0; i < l_num_core; i++)
    {
      // Updated target_core_power
      o_reduced_core_power[i] = i_target_core_power[i] - (Alpha[i] * i_delta_power);
      //test_on_number
      if (o_reduced_core_power[i] <= 0)
        {
          /* TODO:
          //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
          ErrorMap |= BM_ERROR_NUMBERS_VALUE;
          #endif
          */
#ifdef DEBUG_ACTIVE
          printf("Number issue, o_reduced_core_power<0, core %d: %f\n\r", i, o_reduced_core_power[i]);
#endif

          o_reduced_core_power[i] = g_SysConfigTable.core_idle_power;
        }

      //todo
      i_telemetry_struct->frequency_reduction_map[i] |= BM_FRM_ALPHA_RED;

      //TODO: if no bindings (def) we should compute here the new estimated_total_power += target_core_power[i];, otherwise do after bindings
      //#ifndef EPI_CONFIG_FREQ_BINDING //TODO: remove this and remove the return.
      TotalPower += o_reduced_core_power[i];
      //#endif
    }

  return TotalPower;
}

void vCoreBindingReduction(varValue *i_array, ctrl_parameter_table_t *i_ctrl_parameter_table, telemetry_t* i_telemetry_struct){

  // The Way I thought about the binding, to save both cycles and memeory is that the EPI OS give us information about the parallelization
  //  Inside a vector of dimension N_EPI_CORE. Each core that needs to be binded with another one has the same number (from 1 to (N_EPI_CORE/2)),
  //  0 if there is no binding. We scan the array looking for the minimum value per each group with the same number, and then
  //  we do a second scan by applying this minimum value.

  varFor l_num_core = g_SysConfigTable.num_core;
  varValue min_group_freq[(MAX_NUM_CORE / 2) + 1]; // +1 cuz of 0
  varValue l_core_min_frequency = g_SysConfigTable.core_min_frequency;
  varValue l_core_max_frequency = g_SysConfigTable.core_max_frequency;
  varValue high_freq_value = l_core_max_frequency * 2; //just a high number to minimize
  uint16_t* i_core_binding_vector = i_ctrl_parameter_table->core_binding_vector;

  //TODO: Optimize This
  //Initialization
  for (varFor i = 0; i < (MAX_NUM_CORE / 2) +1; i++ )
    min_group_freq[i] = high_freq_value;

  // Scan
  for (varFor i = 0; i < l_num_core; i++)
    {
      if (i_core_binding_vector[i] != 0)
        {
          //test_on_number
          if ((i_core_binding_vector[i] > (l_num_core/2)) /*|| (i_core_binding_vector[i] < 0) since it is unsigned, is never <0*/)
            {
              //ErrorMap |= BM_ERROR_NUMBERS_VALUE; //todo
#ifdef DEBUG_ACTIVE
              printf("Number issue, i_core_binding_vector>l_num_core/2, core %d: %f\n\r", i, i_core_binding_vector[i]);
#endif

              i_core_binding_vector[i] = 0;
            }

          if ((i_array[i] < min_group_freq[i_core_binding_vector[i]]))
            {
              min_group_freq[i_core_binding_vector[i]] = i_array[i];

              //test_on_number
              if ((min_group_freq[i_core_binding_vector[i]] < l_core_min_frequency) ||
                  (min_group_freq[i_core_binding_vector[i]] > l_core_max_frequency)) //TBC
                {
                  //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
                  //ErrorMap |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
                  printf("Number issue, min_group_freq, core %d: %f\n\r", i, min_group_freq[i_core_binding_vector[i]]);
#endif

                  min_group_freq[i_core_binding_vector[i]] = l_core_min_frequency; //TBD: put min even if > MAX_FREQ?
                }
            }
        } //if (i_core_binding_vector[i] != 0)
    } //for

  // Apply
  for (varFor i = 0; i < l_num_core; i++)
    {
      if (i_core_binding_vector[i] != 0)
        {
          i_array[i] = min_group_freq[i_core_binding_vector[i]];

          i_telemetry_struct->frequency_reduction_map[i] |= BM_FRM_BINDING_RED;
        }
    }

  // Christian Bindings: To check if J starts from 1 or from i.
  // the problem I thought about transitivity (A linked with B and B linked with C, so we also have to link A with C) is not present
  // since in the matrix also A is linked with C.
  //TODO: Evaluate which is more optimal
  /*
    % %
    for i=1:length(PT)
    for j=1:length(PT)
    if B_mat(i,j)==1 && abs(i-j)>0
    PT_temp(i)=min(PT_temp(i),PT_temp(j));
    PT_temp(j)=min(PT_temp(i),PT_temp(j));
    end
    end
    end
  */
}

int main(void)
{

  /*-----------------------------------------------*/
  /*************** 2: Read Values(k) ***************/
  /*-----------------------------------------------*/

  if (bImpReadTempRequest(measured_temperature) != PCF_TRUE)
    {
      //TODO

#ifdef DEBUG_ACTIVE
      printf("Error in reading Temperatures\n\r");
#endif
    }

  bSecureControlParamSetup();
  l_ctrl_parameter_table = g_TasksCtrlParameter;


  for (varFor i = 0; i < l_num_core; i++)
    {
      //TODO: this is a semplicistic init, since the init freq and Volt may be different per core
      //TODO: CUGV
      computed_core_frequency[i]                                     = g_SysConfigTable.init_core_freq;
      computed_core_voltage[i]                                     = g_SysConfigTable.init_core_volt;
      reduced_core_power[i]                                         = target_core_power[i];
      //
      l_accumulation_telemetry.core_avg_estimated_power[i]         = g_SysConfigTable.core_idle_power;
      l_accumulation_telemetry.core_avg_sensor_data[i].frequency    = g_SysConfigTable.init_core_freq;
      l_accumulation_telemetry.core_avg_sensor_data[i].voltage     = g_SysConfigTable.init_core_volt;
      l_accumulation_telemetry.core_avg_sensor_data[i].temperature = VD_TEMP_INIT;
      l_accumulation_telemetry.frequency_reduction_map[i]            = BM_RESET;
      //
      hyst_thresh_reached[i]                                         = 0;
      pid_cmd[i]                                                     = 0;
    }
  for (varFor i = 0; i < l_num_quad; i++)
    {
      l_accumulation_telemetry.quad_avg_estimated_power[i] = 0;
    }
  l_accumulation_telemetry.chip_avg_estimated_power                = 0;
  l_accumulation_telemetry.chip_avg_measured_power                 = 0;
  l_accumulation_telemetry.power_budget_exceed_us                    = 0;

  vMeasureInit(mCycles);
  vMeasureStart();

  uint32_t perf_cycle[4*FOR_OUT*FOR_IN + 1];
  int perf_counter = 0;

  for (varFor i = 0; i < FOR_OUT; i++) {
    printf("Power computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      power_comp(NULL);
      perf_cycle[perf_counter++] = lMeasureReadCycle(0);
    }
    printf("Alpha computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      alpha_comp(NULL);
      perf_cycle[perf_counter++] = lMeasureReadCycle(0);
    }
    printf("PID computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      pid_comp(NULL);
      perf_cycle[perf_counter++] = lMeasureReadCycle(0);
    }
    printf("Frequency computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      freq_comp(NULL);
      perf_cycle[perf_counter++] = lMeasureReadCycle(0);
    }
  }

  for (varFor i = 0; i < FOR_OUT; i++) {
    printf("\n Iteration #%d: \n", i);
    for (varFor j = i*4*FOR_IN; j < (i + 1)*FOR_IN*4; j++) {
      printf("Perf. Cycles: %d\n", perf_cycle[j]);
      if (j % FOR_IN == FOR_IN - 1) {
        printf("\n");
      }
    }
  }
  return 0;
}

void power_comp (void* arg)
{

  //    ctrl_parameter_table_t l_ctrl_parameter_table;
  //    varValue target_core_power[MAX_NUM_CORE]= {0};

  //    pi_cl_dma_cmd(ctrl_param_addr, &l_ctrl_parameter_table, (uint32_t)sizeof(ctrl_parameter_table_t),
  //(uint32_t ext, uint32_t loc, uint32_t size, pi_cl_dma_dir_e dir, pi_cl_dma_cmd_t *cmd);

  //    printf("l_ctrl_parameter_table.target_freq: %f\n", l_ctrl_parameter_table.target_freq[0]);
  //    printf("target_core_power: %f\n", target_core_power);

  estimated_total_power = lCorePowerComputation(target_core_power, &l_ctrl_parameter_table, &l_accumulation_telemetry, pid_cmd);

  //test_on_number
  if (estimated_total_power <= 0)
    {
      l_error_map |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
      printf("Number issue, estimated_total_power: %f\n\r", (int)estimated_total_power);
#endif

      estimated_total_power = g_SysConfigTable.core_idle_power * (varValue)l_num_core;
      for (varFor i = 0; i < l_num_core; i++)
        {
          target_core_power[i] = g_SysConfigTable.core_idle_power;
        }
    }

  /*** C.2: Compute Delta Power ***/
  delta_power = estimated_total_power - l_ctrl_parameter_table.total_power_budget;
}
void alpha_comp (void* arg)
{

  //  printf("power_value: %d   %d\n", delta_power, target_core_power[0]);

  //Copy Data from DMA.

  /*-----------------------------------------------*/
  /********** 3: Compute Frequency Values **********/
  /*-----------------------------------------------*/

  /*** 3.A: Power Dispatching Layer ***/
  // Started Above: C.1, C.2
  //If necessary, we Reduce Power of each Core to meet Global Power Budget

  if  (delta_power > 0)
    {
      lAlphaPowerReduction(reduced_core_power, target_core_power, measured_temperature, delta_power, &l_ctrl_parameter_table, &l_accumulation_telemetry);
    }
  else
    {
      for (varFor i = 0; i < l_num_core; i++)
        reduced_core_power[i] = target_core_power[i];
    }

}
void pid_comp (void* arg)
{

  //Copy Data from DMA.

  /*** 3.B: Compute PID Values ***/
  for (varFor i = 0; i < l_num_core; i++)
    {
      varValue core_prev_value = reduced_core_power[i]; //TODO: Optimize this....

      //PID
      reduced_core_power[i] = lMathPidCompute(reduced_core_power[i], measured_temperature[i], i, pid_cmd[i]);

      //TestOnNumber
      if ( (reduced_core_power[i] <= 0) || (reduced_core_power[i] > target_core_power[i]) )
        {
          l_error_map |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
          printf("Number issue, reduced_core_power, core %d: %f\n\r", i, reduced_core_power[i]);
#endif

          reduced_core_power[i] = g_SysConfigTable.core_idle_power; //TBD: maybe too much conservative in case > ?? (consider still there is an error!)
        }

      if (reduced_core_power[i] < core_prev_value) //TODO
        {
          l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_PID_TEMP_RED;
        }
    }

}
void freq_comp (void* arg)
{

  //Copy Data from DMA.

  /*** 3.C: Compute Frequence/Duty Cycle ***/
  // Frequency from Power. (newton rapton) (vdd is in function of f )
  for (varFor i = 0; i < l_num_core; i++)
    {
#ifdef USE_INSTRUCTIONS_COMPOSITION
      for (varFor k = 0; k < POWER_FORMULA_COEFF_NUM; k++)
        {
          lpower_formula_coeff[k] = 0;
          for (varFor j = 0; j < SYS_CORE_WL_STATES; j++)
            {
              lpower_formula_coeff[k] += l_ctrl_parameter_table.power_formula_coeff[ j ][k] * (varValue)l_ctrl_parameter_table.perc_workload[i][j] / VD_100_PERC;
            }
        }
#else
      lpower_formula_coeff[0] = l_ctrl_parameter_table.power_formula_coeff[0][0];
      lpower_formula_coeff[1] = l_ctrl_parameter_table.core_ceff[i];
#endif

      varValue target_single_frequency = lMathFrequencyCompute(reduced_core_power[i], lpower_formula_coeff);

      //Naif Way to smooth the Frequency increase
      //TODO: improve this
      if (target_single_frequency > computed_core_frequency[i] + g_ControlConfigTable.freq_max_gradient)
        {
          computed_core_frequency[i] += g_ControlConfigTable.freq_max_gradient;
          l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_MAX_GRADIENT;
        }
      else
        computed_core_frequency[i] = target_single_frequency;

      //TODO: can I optimize this formula? Because I have to pass all the time the address of the Formula Coeff which are fixed per 2 iteration of the control task

      //Hysteresis Check for the temperature going higher than threshold
      //ATTENTION!!! Not thought values can make the PID not to work!
      l_hyst_high_temp_limit = g_ControlConfigTable.hyst_high_temp_limit;
      l_hyst_low_temp_limit = g_ControlConfigTable.hyst_low_temp_limit;
      if ( (measured_temperature[i] >= l_hyst_high_temp_limit) || (hyst_thresh_reached[i]) )
        {
          if (measured_temperature[i] < l_hyst_low_temp_limit)
            {
              hyst_thresh_reached[i] = 0;
            }
          else
            {
              hyst_thresh_reached[i] = 1;
              computed_core_frequency[i] = g_SysConfigTable.core_min_frequency;

              l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_HYST_EMERG;
            }
        }

      if (computed_core_frequency[i] < g_SysConfigTable.core_min_frequency)
        {
          //TBC: is this really an error value?
          l_error_map |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
          printf("Number issue, computed_core_frequency, core %d: %f\n\r", i, computed_core_frequency[i]);
#endif

          computed_core_frequency[i] = g_SysConfigTable.core_min_frequency;

        }else if (computed_core_frequency[i] > g_SysConfigTable.core_max_frequency)
        {
          //TBC: is this really an error value?
          l_error_map |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
          printf("Number issue, computed_core_frequency, core %d: %f\n\r", i, computed_core_frequency[i]);
#endif

          computed_core_frequency[i] = g_SysConfigTable.core_max_frequency;
        }
    }//for
}


//___________________________________________________________________________________________//


varBool_e bSecureControlParamSetup(void)
{
  //CUGV: commonly-used-global-vars
  varFor l_num_wl_states  = g_SysConfigTable.core_wl_states_num;
  varFor l_num_core     = g_SysConfigTable.num_core;
  varFor l_num_quad     = g_SysConfigTable.num_quad;
  varFor l_num_pw_domains = g_SysConfigTable.num_pw_domains;

  varBool_e return_value = PCF_TRUE;

  uint32_t l_error_map = BM_RESET;


  //TODO: should I have to call the functions to read/write? (the locks??)
  /*** Parameter_Tables and Vars Initialization ***/
  // I do it here instead of the main, because I could want to recall initialization
  //		task as a soft reset.
  /* zeroing */ //for the case num_* < MAX_NUM_*
  for (varFor i = 0; i < MAX_NUM_CORE; i++)
    {
      g_TasksCtrlParameter.target_freq[i]         = 0;
      g_TasksCtrlParameter.core_ceff[i]                   = 0;

      for (varFor j = 1; j < SYS_CORE_WL_STATES; j++)
        {
          g_TasksCtrlParameter.perc_workload[i][j]		= 0;
        }
      g_TasksCtrlParameter.core_binding_vector[i]     = 0;

      //telemetry
      g_ChipTelemetry.core_avg_sensor_data[i].frequency   = 0;
      g_ChipTelemetry.core_avg_sensor_data[i].voltage   = 0;
      g_ChipTelemetry.core_avg_sensor_data[i].temperature = 0;

      g_ChipTelemetry.core_avg_estimated_power[i]     = 0;

      //FreqRedMap
      g_ChipTelemetry.frequency_reduction_map[i]			= BM_RESET;
    }
  for (varFor j = 0; j < SYS_CORE_WL_STATES; j++)
    for (varFor k = 0; k < POWER_FORMULA_COEFF_NUM; k++)
      {
        g_TasksCtrlParameter.power_formula_coeff[j][k]  = 0;
      }
  for (varFor q = 0; q < MAX_NUM_QUAD; q++)
    {
      g_TasksCtrlParameter.quadrant_power_budget[q]     = 0;
      g_ChipTelemetry.quad_avg_estimated_power[q]			= 0;
    }
  g_TasksCtrlParameter.total_power_budget					= 0;
  g_ChipTelemetry.chip_avg_estimated_power				= 0;
  g_ChipTelemetry.power_budget_exceed_us					= 0;
  for (varFor j = 0; j < SYS_PW_DOMAIN_NUM; j++)
    {
      g_TasksCtrlParameter.measured_power[j]              = 0;
    }

  /* (non-config) Global Var Initialization */
  //CUGV
  varValue l_init_core_freq = g_SysConfigTable.init_core_freq;
  varValue l_init_core_volt = g_SysConfigTable.init_core_volt;
  varValue l_init_core_ceff = g_SysConfigTable.init_core_ceff;
  varValue l_core_idle_power = g_SysConfigTable.core_idle_power;
  varBool_e l_use_freq_binding = g_ControlConfigTable.use_freq_binding;
  for (varFor i = 0; i < l_num_core; i++)
    {
      g_TasksCtrlParameter.target_freq[i]         = l_init_core_freq;
      g_TasksCtrlParameter.core_ceff[i]                   = l_init_core_ceff;

      g_TasksCtrlParameter.perc_workload[i][0]			= 100; //g_SysConfigTable.init_core_workload; //TODO
      for (varFor j = 1; j < l_num_wl_states; j++)
        {
          g_TasksCtrlParameter.perc_workload[i][j]		= 0;
        }
      if (l_use_freq_binding == PCF_TRUE)
        {
          //TODO
          if ((i==3)||(i==4)||(i==5)||(i==6))
            g_TasksCtrlParameter.core_binding_vector[i]   = 0;
          else
            g_TasksCtrlParameter.core_binding_vector[i]   = 0;

        }
      else
        {
          for (varFor j = 0; j < l_num_wl_states; j++)
            {
              g_TasksCtrlParameter.core_binding_vector[i]	= 0;
            }
        }

      //telemetry
      g_ChipTelemetry.core_avg_sensor_data[i].frequency   = l_init_core_freq;
      g_ChipTelemetry.core_avg_sensor_data[i].voltage   = l_init_core_volt;
      g_ChipTelemetry.core_avg_sensor_data[i].temperature = VD_TEMP_INIT;

      g_ChipTelemetry.core_avg_estimated_power[i]     = l_core_idle_power;
    }
  for (varFor j = 0; j < l_num_wl_states; j++)
    for (varFor k = 0; k < POWER_FORMULA_COEFF_NUM; k++)
      {
        g_TasksCtrlParameter.power_formula_coeff[j][k]  = g_SysConfigTable.base_power_coeff[j][k];
      }
  //for (varFor j = 0; j < l_num_pw_domains; j++)
  //{ //TODO: this initialization.
  g_TasksCtrlParameter.measured_power[0]                 = l_num_core * l_core_idle_power;
  g_TasksCtrlParameter.measured_power[1]                 = 40; //random number, TODO.
  //}
  //TODO:
  /*#ifdef EPI_CONFIG_QUADRANTS
    float QuadrantPowerBudget[EPI_N_QUADRANTS];
    #endif
  */
  g_TasksCtrlParameter.total_power_budget         = g_ControlConfigTable.init_total_power_budget;
  g_ChipTelemetry.chip_avg_estimated_power				= g_SysConfigTable.core_idle_power * (varValue)l_num_core;

  /* Set PID Parameters */
  if(bMathPidSetParameters(g_ControlConfigTable.pid_kp, g_ControlConfigTable.pid_ki, g_ControlConfigTable.pid_kd, g_ControlConfigTable.pid_dt,
                           g_SysConfigTable.core_critical_temperature, g_ControlConfigTable.pid_temperature_margin, g_SysConfigTable.core_idle_power) != PCF_TRUE) // TOCHECK: is it proper? How should I do?
    {
#ifdef DEBUG_ACTIVE
      printf("Initialization Error\n");
#endif
      //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
      l_error_map |= BM_ERROR_INITIALIZATION;

      return_value = PCF_FALSE;
    }

  ctrl_param_addr = &g_TasksCtrlParameter;
  telemetry_addr = &g_ChipTelemetry;

  return return_value;
}

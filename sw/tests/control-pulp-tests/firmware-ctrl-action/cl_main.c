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

#define FOR_OUT 1
#define FOR_IN  5

L1_DATA sys_config_table_t g_SysConfigTable =
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

L1_DATA code_config_table_t g_CodeConfigTable =
  {
    /***** Code configuration *****/
    .use_watchdogs							= PCF_TRUE,
    .use_secure_io							= PCF_TRUE,
    .use_tests_on_numbers					= PCF_TRUE,

    /*** Telemetry Configuration **/
    .use_frequency_reduction_map			= PCF_TRUE,
    .use_error_map							= PCF_TRUE,
  };

L1_DATA ctrl_config_table_t g_ControlConfigTable =
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

L1_DATA ctrl_lms_config_table_t g_LmsConfigTable =
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

L1_DATA ctrl_parameter_table_t g_TasksCtrlParameter;
L1_DATA telemetry_t g_ChipTelemetry;

L1_DATA ctrl_parameter_table_t* ctrl_param_addr;
L1_DATA telemetry_t* telemetry_addr;

//

void power_comp (void* arg);
void alpha_comp (void* arg);
void pid_comp (void* arg);
void freq_comp (void* arg);

varBool_e bSecureControlParamSetup(void);

////

// Control Variables
L1_DATA varValue computed_core_frequency[MAX_NUM_CORE] = {0};
L1_DATA varValue computed_core_voltage[MAX_NUM_CORE] = {0};
L1_DATA varValue measured_temperature[MAX_NUM_CORE] = {0};
L1_DATA varValue target_core_power[MAX_NUM_CORE]= {0};
L1_DATA varValue reduced_core_power[MAX_NUM_CORE] = {0};

L1_DATA varValue delta_power = 0;
L1_DATA varValue estimated_total_power = 0;

L1_DATA varBool_e hyst_thresh_reached[MAX_NUM_CORE];
L1_DATA varValue pid_cmd[MAX_NUM_CORE];

//TODO: because there is also the same strucure in power compute, maybe we can optimize
L1_DATA varValue lpower_formula_coeff[POWER_FORMULA_COEFF_NUM];

// Internal to Global Variables
L1_DATA ctrl_parameter_table_t l_ctrl_parameter_table;
L1_DATA telemetry_t l_accumulation_telemetry;
L1_DATA varFor l_num_core = MAX_NUM_CORE;//g_SysConfigTable.num_core;
L1_DATA varFor l_num_quad = 2; //g_SysConfigTable.num_quad;
L1_DATA varValue l_hyst_high_temp_limit;
L1_DATA varValue l_hyst_low_temp_limit;

L1_DATA uint32_t l_error_map;

L1_DATA uint32_t id = 1;

//global parallelization
L1_DATA varValue total_power[9] = {0};
L1_DATA int executions[9] = {0};
L1_DATA varValue Alpha[MAX_NUM_CORE];
L1_DATA varValue TotalAlpha[9] = {0};
L1_DATA varValue TotalPower[9] = {0}; // ale

L1_DATA int num_cluster_cores;

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

int main(void)
{

  if (rt_cluster_id() != 0) {
    reset_timer();
    start_timer();
    return bench_cluster_forward(0);
  }

  num_cluster_cores = 8;

  //if (rt_is_fc()) // for using the soc
  //{

  /*-----------------------------------------------*/
  /*************** 2: Read Values(k) ***************/
  /*-----------------------------------------------*/

  if (rt_core_id() == 0) {

     stop_timer();
     printf("Cluster offload time: %d\n", timer_count_get(timer_base_fc(0, 1)));


//    if (bImpReadTempRequest(measured_temperature) != PCF_TRUE)
//      {
//        //TODO
//
//#ifdef DEBUG_ACTIVE
//        printf("Error in reading Temperatures\n\r");
//#endif
//      }

    for (int i=0; i<l_num_core; i++)
      measured_temperature[i] = 310.0f + i*10/l_num_core;

    bSecureControlParamSetup();
    l_ctrl_parameter_table = g_TasksCtrlParameter;

    printf("ok\n");
    for (varFor i = 0; i < l_num_core; i++)
      {
        //      printf("bella");
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
        l_accumulation_telemetry.quad_avg_estimated_power[i]        = 0;
      }
    l_accumulation_telemetry.chip_avg_estimated_power                = 0;
    l_accumulation_telemetry.chip_avg_measured_power                 = 0;
    l_accumulation_telemetry.power_budget_exceed_us                    = 0;

    //vMeasureInit(mCycles);
    //vMeasureStart();

    //reset_timer();
    //start_timer();
  }

  uint32_t perf_cycle[4*FOR_OUT*FOR_IN + 1];
  int perf_counter = 0;

  synch_barrier();

  //if (rt_core_id() >= 7) {
  //  synch_barrier();
  //  return 0; // we don't need cores with id's higher than num_cluster_cores
  //}

  for (varFor i = 0; i < FOR_OUT; i++) {
    //printf("Power computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      if (rt_core_id() == 0) {
        reset_timer();
        start_timer();
        }
      synch_barrier();
      power_comp(NULL);
      synch_barrier();
      if (rt_core_id() == 0) {
        stop_timer();
        perf_cycle[perf_counter++] = timer_count_get(timer_base_fc(0, 1));
        }
    }
    synch_barrier();
    //printf("Alpha computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      if (rt_core_id() == 0) {
        reset_timer();
        start_timer();
        }
      synch_barrier();
      alpha_comp(NULL);
      synch_barrier();
      if (rt_core_id() == 0) {
        stop_timer();
        perf_cycle[perf_counter++] = timer_count_get(timer_base_fc(0, 1));
        }
    }
    synch_barrier();
    //printf("PID computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      if (rt_core_id() == 0) {
        reset_timer();
        start_timer();
        }
      synch_barrier();
      pid_comp(NULL);
      synch_barrier();
      if (rt_core_id() == 0) {
        stop_timer();
        perf_cycle[perf_counter++] = timer_count_get(timer_base_fc(0, 1));
        }
    }
    synch_barrier();
    //printf("Frequency computation, iter: %d\n", i);
    for (varFor j = 0; j < FOR_IN; j++) {
      if (rt_core_id() == 0) {
        reset_timer();
        start_timer();
        }
      synch_barrier();
      freq_comp(NULL);
      synch_barrier();
      if (rt_core_id() == 0) {
        stop_timer();
        perf_cycle[perf_counter++] = timer_count_get(timer_base_fc(0, 1));
        }
    }
    synch_barrier();
  }

  synch_barrier();

  stop_timer();

  //printf("ok\n");
  if (rt_core_id() == 0) {
    for (varFor i = 0; i < FOR_OUT; i++) {
      printf("\n Iteration #%d: \n", i);
      for (varFor j = i*4*FOR_IN; j < (i + 1)*FOR_IN*4; j++) {
        printf("Perf. Cycles: %d\n", perf_cycle[j]);
        if (j % FOR_IN == FOR_IN - 1) {
          printf("\n");
        }
      }
    }
  }
  return 0;
}

void power_comp (void* arg)
{

  varValue lpower_formula_coeff[POWER_FORMULA_COEFF_NUM];
  //varFor l_num_core = 36;

  int l_num_ext_cores = l_num_core;
  int l_num_cluster_cores = num_cluster_cores;
  int coreid = get_core_id();
  int chunk = l_num_ext_cores / l_num_cluster_cores;
  int chunk_rem = l_num_ext_cores % l_num_cluster_cores;
  if (chunk_rem != 0)
    chunk += 1;

  //varFor Start = coreid * chunk;
  //varFor End = Start + chunk;
  varFor Start = coreid;
  varFor Increment = l_num_cluster_cores;
  varFor End = Start + Increment * chunk;

  // Handle odd core number
  if (End > l_num_ext_cores)
    End = l_num_ext_cores;

  for (varFor i = Start; i < End; i+=Increment)
    {
      //printf("%d: %d\n", i, i_ctrl_parameter_table->Workload[i]);
#ifdef USE_INSTRUCTIONS_COMPOSITION
      for (varFor k = 0; k < POWER_FORMULA_COEFF_NUM; k++)
        {
          lpower_formula_coeff[k] = 0;

          for (varFor j = 0; j < SYS_CORE_WL_STATES; j++)
            {
              lpower_formula_coeff[k] += l_ctrl_parameter_table->power_formula_coeff[ j ][k] * (varValue)l_ctrl_parameter_table->perc_workload[i][j] / VD_100_PERC;
            }
        }
#else
      lpower_formula_coeff[0] = l_ctrl_parameter_table.power_formula_coeff[0][0];
      lpower_formula_coeff[1] = l_ctrl_parameter_table.core_ceff[i];
#endif

      varValue core_power = lMathPowerCompute(l_ctrl_parameter_table.target_freq[i], lpower_formula_coeff);

      //      if (coreid == 2) {
      //        printf("core_power: %f   target_frequency: %f   pfc1: %f   pfc2: %f\n", core_power, l_ctrl_parameter_table.target_freq[i], lpower_formula_coeff[0], lpower_formula_coeff[1]);
      //      }

      if (core_power < target_core_power[i] - 10)
        {
          pid_cmd[i] = core_power / target_core_power[i];
        }
      else if (core_power > target_core_power[i] + 10)
        {
          pid_cmd[i] = core_power / target_core_power[i];
        }
      else
        {
          pid_cmd[i] = 0;
        }

      target_core_power[i] = core_power;
      //      if (coreid == 2) {
      //        printf("target_core_power: %f\n", target_core_power[i]);
      //      }

      //test_on_number
      if (target_core_power[i] < 0)
        {
#ifdef DEBUG_ACTIVE
          printf("Number issue, computed_core_power core %d: %f\n\r", i, target_core_power[i]);
#endif

          target_core_power[i] = 0.3;
        } else if (target_core_power[i] > 4)
        {
          target_core_power[i] = 4;

          //Bitmap of Frequency Reduction.
          l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_MAX_SINGLE_POW_SAT;
        }
      total_power[coreid] += target_core_power[i];

      //      if (coreid == 2) {
      //        printf("total_power [%d]: %f \n", coreid, total_power[coreid]);
      //      }

      //TODO: for quadrants, we should change this to reflect quadrants disposition so we can add quadrant power also inside this for
      //printf("CtP r: %d\n", (int)target_core_power[i]);
      //Saturation check for single Core PowerMax Margin

      executions[coreid]++;
    }

  synch_barrier();

  if (coreid==0)
    {
      estimated_total_power=0;
      executions[0]=0;
      for (varFor i=1; i<7; i++){
        estimated_total_power += total_power[i];
        //printf("estimated total_power: %f \n", estimated_total_power);
        //printf("Total power [%d]: %f\n", i, total_power[i]);
        executions[0] += executions[i];
        executions[i] = 0;
        total_power[i] = 0;
      }

      //printf("#executions:  %d\n", executions[0]);

      //test_on_number
      if (estimated_total_power <= 0)
        {
          l_error_map |= BM_ERROR_NUMBERS_VALUE;
#ifdef DEBUG_ACTIVE
          printf("Number issue, estimated_total_power: %f\n\r", estimated_total_power);
#endif

          ///GLOBAL QUAGGIù!!!
          estimated_total_power = /*g_SysConfigTable.core_idle_power*/ 0.2 * (varValue)l_num_core;
          for (varFor i = 0; i < l_num_core; i++)
            {
              ///GLOBAL QUAGGIù!!!
              target_core_power[i] = /*g_SysConfigTable.core_idle_power*/ 0.2;
            }
        }

      /*** C.2: Compute Delta Power ***/
      delta_power = estimated_total_power - l_ctrl_parameter_table.total_power_budget;

    } //core 0

}
void alpha_comp (void* arg)
{

  //varFor l_num_core = 36;
  varValue l_core_critical_temperature = 380;
  varValue l_alpha_max_value = 1;
  int coreid = rt_core_id();
  delta_power = 6.0f;

  if  (delta_power > 0)
    {

      int l_num_ext_cores = l_num_core;
      int l_num_cluster_cores = get_core_num();
      int coreid = get_core_id();
      int chunk = l_num_ext_cores / l_num_cluster_cores;
      int chunk_rem = l_num_ext_cores % l_num_cluster_cores;
      if (chunk_rem != 0)
        chunk += 1;

      //varFor Start = coreid * chunk;
      //varFor End = Start + chunk;

      varFor Start = coreid;
      varFor Increment = l_num_cluster_cores;
      varFor End = Start + Increment * chunk;

      // Handle odd core number
      if (End > l_num_ext_cores)
        End = l_num_ext_cores;

      //Compute Alpha
      for (varFor i = Start; i < End; i+=Increment)
        {
          //test_on_number //MUST do always, not only when test on numbers, and it is not a ToN Error!
          if ((l_core_critical_temperature - measured_temperature[i]) < 0)
            {
#ifdef DEBUG_ACTIVE
              printf("Number issue, i_measured_temperature > l_core_critical_temperature, core %d: %f\n\r", i, measured_temperature[i]);
#endif

              measured_temperature[i] = l_core_critical_temperature - (1 / l_alpha_max_value);
            }

          Alpha[i] = 1 / (l_core_critical_temperature - measured_temperature[i]);
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

              Alpha[i] = 0.2; //TBD: we are whitin an ERROR!!! do not put 0.01!

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

          TotalAlpha[coreid] += Alpha[i];
          //TODO: for quadrants, we should change this to reflect quadrants disposition so we can add quadrant power also inside this for
        }

      synch_barrier();

      if (coreid==0){
        if (0 == PCF_TRUE)
          {
            //TBU: This uint16+ is VERY delicate, it has to change with the
            //    typedef struct _ctrl_parameter_table, so it could need a better design
            uint16_t* i_core_binding_vector = l_ctrl_parameter_table.core_binding_vector;
            varValue min_group_alpha[(MAX_NUM_CORE / 2) + 1]; // +1 cuz of 0

            //Resetting
            for (varFor a=1; a<8; a++)
              TotalAlpha[a] = 0;

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
              }    //for

            // Apply
            for (varFor i = 0; i < l_num_core; i++)
              {
                if (i_core_binding_vector[i] != 0)
                  {
                    Alpha[i] = min_group_alpha[i_core_binding_vector[i]];

                    //todo
                    l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_BINDING_RED;
                  }

                TotalAlpha[1] += Alpha[i];
                executions[coreid]++;
              }

          } //end, if (g_ControlConfigTable.use_freq_binding == PCF_TRUE)

        //if (coreid==0)
        executions[0] = 0;
        TotalAlpha[0]=0;
        for (varFor i=1; i<8; i++){
          TotalAlpha[0] += TotalAlpha[i];
          executions[0] += executions[i];
          executions[i] = 0;
          TotalAlpha[i]=0;
          TotalPower[i] = 0;
        }

        //printf("#executions:  %d\n", executions[0]);
      }//coreid==0

      synch_barrier();

      //Normalize Alpha
      for (varFor i = Start; i < End; i+=Increment)
        {
          // Alpha Normalized. For optimization we use Alpha[i]
          Alpha[i] = Alpha[i] / TotalAlpha[0];
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

              Alpha[i] = 0.2; //TBD: we are whitin an ERROR!!! do not put 0.01!

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

              Alpha[i] = 0.2; //TBD: we are whitin an ERROR!!! do not put 0.99!
            }

          // Here Christian added this: [?????]
          /*
            if (i_delta_power*Alpha[i] > i_target_core_power[i])
            {
            Alpha[i] = i_target_core_power[i] / i_delta_power;
            }*/
        }


      //Apply Alpha Reduction
      for (varFor i = Start; i < End; i+=Increment)
        {
          // Updated target_core_power
          reduced_core_power[i] = target_core_power[i] - (Alpha[i] * delta_power);
          //test_on_number
          if (reduced_core_power[i] <= 0)
            {
              /* TODO:
              //if (g_CodeConfigTable.use_error_map == PCF_TRUE)
              ErrorMap |= BM_ERROR_NUMBERS_VALUE;
              #endif
              */
#ifdef DEBUG_ACTIVE
              printf("Number issue, o_reduced_core_power<0, core %d: %f\n\r", i, reduced_core_power[i]);
#endif

              reduced_core_power[i] = 0.3;
            }

          //todo
          l_accumulation_telemetry.frequency_reduction_map[i] |= BM_FRM_ALPHA_RED;

          //TODO: if no bindings (def) we should compute here the new estimated_total_power += target_core_power[i];, otherwise do after bindings
          //#ifndef EPI_CONFIG_FREQ_BINDING //TODO: remove this and remove the return.
          TotalPower[coreid] += reduced_core_power[i];
          //#endif
        }

      synch_barrier();

      if (coreid==0){
        //if (coreid==0)
        executions[0] = 0;
        TotalPower[0]=0;
        for (varFor i=1; i<8; i++){
          TotalPower[0] += TotalPower[i];
          executions[0] += executions[i];
          executions[i] = 0;
          TotalPower[i]=0;
        }

        //printf("#executions:  %d\n", executions[0]);
      }//coreid==0

    }
  else
    {
      if (coreid==0){
        for (varFor i = 0; i < l_num_core; i++)
          reduced_core_power[i] = target_core_power[i];
      }
    }
  synch_barrier();

}
void pid_comp (void* arg)
{

  int l_num_ext_cores = l_num_core;
  int l_num_cluster_cores = get_core_num();
  int coreid = get_core_id();
  int chunk = l_num_ext_cores / l_num_cluster_cores;
  int chunk_rem = l_num_ext_cores % l_num_cluster_cores;
  if (chunk_rem != 0)
    chunk += 1;

  //varFor Start = coreid * chunk;
  //varFor End = Start + chunk;

  varFor Start = coreid;
  varFor Increment = l_num_cluster_cores;
  varFor End = Start + Increment * chunk;

  // Handle odd core number
  if (End > l_num_ext_cores)
    End = l_num_ext_cores;

  /*** 3.B: Compute PID Values ***/
  for (varFor i = Start; i < End; i+=Increment)
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

  synch_barrier();

}
void freq_comp (void* arg)
{

  int l_num_ext_cores = l_num_core;
  int l_num_cluster_cores = get_core_num();
  int coreid = get_core_id();
  int chunk = l_num_ext_cores / l_num_cluster_cores;
  int chunk_rem = l_num_ext_cores % l_num_cluster_cores;
  if (chunk_rem != 0)
    chunk += 1;

  //varFor Start = coreid * chunk;
  //varFor End = Start + chunk;

  varFor Start = coreid;
  varFor Increment = l_num_cluster_cores;
  varFor End = Start + Increment * chunk;

  // Handle odd core number
  if (End > l_num_ext_cores)
    End = l_num_ext_cores;

  for (varFor i = Start; i < End; i+=Increment)
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

  synch_barrier();
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
      g_TasksCtrlParameter.target_freq[i]         = 3.0f; //l_init_core_freq;
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

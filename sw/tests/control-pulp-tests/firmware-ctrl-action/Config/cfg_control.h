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
/********************************************************/
/*
* File: cfg_control.h
* Notes: This files holds the definitions, structs and
*           global var regarding the control algorithm.
* Written by: Eventine (UNIBO)
*
*********************************************************/

#ifndef _PCF_CTRL_CONFIG_H_
#define _PCF_CTRL_CONFIG_H_


/* Libraries Inclusion */
#include "cfg_types.h"
#include "cfg_system.h"


/** Definitions **/
#define LMS_CN									(SYS_CORE_WL_STATES*POWER_FORMULA_COEFF_NUM)
#define LMS_CNxCN								(LMS_CN*LMS_CN)


/******************************/
/*** Control Configuration ****/
/******************************/
typedef struct _ctrl_parameter_table {
	//TODO: maybe divide commands and measured values?
	//Commands
	varValue target_freq[MAX_NUM_CORE];
	varValue total_power_budget;
    varValue quadrant_power_budget[MAX_NUM_QUAD];
    uint16_t core_binding_vector[MAX_NUM_CORE]; //TODO: can we optimize this? we actually need only half of the matrix.

	// Measures
	varValue power_formula_coeff[SYS_CORE_WL_STATES][POWER_FORMULA_COEFF_NUM];
	varValue measured_power[SYS_PW_DOMAIN_NUM];
	//TODO: maybe implement a define to not occupy memory since only one of the two implementation are generelly used.
	// Implementation 1:
	uint8_t perc_workload[MAX_NUM_CORE][SYS_CORE_WL_STATES];
	// Implementation 2:
	varValue core_ceff[MAX_NUM_CORE];
} ctrl_parameter_table_t;


typedef struct _setup_parameter_table {

    //TODO if needed

} setup_parameter_table_t;


typedef struct _ctrl_config_table {

	/***** CTRL Configuration *****/
	varBool_e use_lms;
	varBool_e use_freq_binding;					// to use Frequency Bindings between Cores
    varBool_e use_quadrant_pw_budget;

	/***** PID Configuration ******/
	varBool_e use_pid_integral_action;					// to use Integral Action inside PID
	varBool_e use_pid_derivative_action;				// to use Derivative Action inside PID
	varBool_e use_pid_saturation;						// to use Output Saturation inside PID
	//TBC: Since our implementation of the PID, maybe is better to not make this definable, but to FORCE it active.
	varBool_e use_pid_ff_action;						// to use FeedForward Action inside PID
	varBool_e use_pid_anti_windup_sat;					// to use Anti Wind-up of the Integrator, Saturation kind

	/* Initialization Values */
	// They have to be defined even if PID_CONFIG_x is disabled //TODO: fix this?
	varValue pid_kp;
	varValue pid_ki;
	varValue pid_kd;
	varValue pid_dt;
	varValue pid_anti_windup_sat_coeff;
	varValue pid_anti_windup_sat_up;

	/*** Other Control Values *****/
	varValue pid_temperature_margin;			// A margin to the above Temperature
	varValue freq_max_gradient;
	varValue alpha_max_value;
	varValue alpha_error_base_value;
	varValue hyst_high_temp_limit;
	varValue hyst_low_temp_limit;
	varValue max_pw_diff;
	varValue pid_integral_reduction_coeff;

    /* Initialization Values */
    varValue init_total_power_budget;

} ctrl_config_table_t;


typedef struct _ctrl_lms_config_table {
	/** Configuration **/
	//uint16_t coeff_num;
	uint16_t batch_iteration_num;

	/* Values */
	// Forgetting Factor
	varValue lambda;
	varValue bound_limits[SYS_CORE_WL_STATES][POWER_FORMULA_COEFF_NUM];
} ctrl_lms_config_table_t;



/******************************/
/***** Global Variables *******/
/******************************/
extern ctrl_config_table_t g_ControlConfigTable;
extern ctrl_lms_config_table_t g_LmsConfigTable;







#endif //lib #ifdef

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
*
*/

/********************************************************/
/*
* File: cfg_firmware.h
* Notes: This files holds the definitions, structs and
*           global var regarding the firmware structure and
*           code.
*
* Written by: Eventine (UNIBO)
*
*********************************************************/

#ifndef _PCF_FIRMWARE_CONFIG_H_
#define _PCF_FIRMWARE_CONFIG_H_

/* FreeRTOS Inclusions. */
//#include "FreeRTOS.h"
//#include "task.h"

/* Libraries Inclusion */
#include "cfg_types.h"
#include "cfg_system.h"


/** Definitions **/
/* these has to be manually changed */
/** Tasks **/
// Max Number of Tasks
#define MAX_NUM_TASKS 						7 //(5 tasks+1debug+1idle)

/****** Private ******/
/* NOT CONFIGURABLE */
/** Code Configuration **/
//#define LMS_ACTIVE
//#define DEBUG_ACTIVE
//#define MEASURE_ACTIVE						2 // 1: N measurements, 2: Validation
//#define MEASURE_N_ITERATION 				8 // This is needed for both debug and Measure
//#define MEASURE_N_OUTPUTS					10 // This is the number of outputted measures
//#define GPIO_TEST
//#define CI_TEST
//#define CI_TEST_ITERATION					8
#define JO_TBR	//I Include in this stuff that must be removed once the GAP8 is overcome. I started using this 6/7/20 so some stuff before this date
                // may not be included in this


/** GAP8 SPI **/
#define SPI_SPEED_MUL						10000 // default: 1500
/** GAP8 Cluster **/
//#define PULP_USE_CLUSTER
// the stack dimension in bytes for data of each PCore
#define PCORE_STACK_SIZE 					2048
/****** Private END ******/


/******************************/
/** Firmware Configuration ****/
/******************************/
typedef struct _tasks_config_table {

	/**** Tasks Configuration *****/
	uint16_t tap_period_us; 						// Time in us //when change this also hange TELEMETRY_POLLING_FREQUENCY
	//following values will be floored down to a multiple of the tap period.
    uint16_t periodic_ctrl_period_us;
	uint16_t task_os_period_us;

	// Priority
	uint16_t periodic_ctrl_task_priority;
	uint16_t rear_ctrl_task_priority;
	uint16_t comms_task_priority;
	uint16_t main_task_priority;
	uint16_t user_defined_task_priority;
	#if (defined(DEBUG_ACTIVE) || (MEASURE_ACTIVE == 1))
		uint16_t debug_task_priority;
	#endif

	/*** Telemetry Configuration **/
	uint32_t telemetry_polling_period_ms;
} tasks_config_table_t;


typedef struct _code_config_table {

	/***** Code configuration *****/
	varBool_e use_watchdogs;
	varBool_e use_secure_io;
	varBool_e use_tests_on_numbers;		//TODO: configASSERT seem not to work

	/*** Telemetry Configuration **/
	varBool_e use_frequency_reduction_map;				// to collect the information on the Frequency Reduction causes
	varBool_e use_error_map;
} code_config_table_t;


typedef struct _telemetry {
	//TODO: Need to adjust this because we are passing only 1 Power (either Total or Mean)
	sensor_data_t core_avg_sensor_data[MAX_NUM_CORE];
	varValue core_avg_estimated_power[MAX_NUM_CORE];
	varValue chip_avg_estimated_power;
	varValue quad_avg_estimated_power[MAX_NUM_QUAD];

	varValue chip_avg_measured_power;
	uint32_t power_budget_exceed_us;

	uint16_t frequency_reduction_map[MAX_NUM_CORE];

	//uint8_t core_perf_grade[MAX_NUM_CORE];

    //TODO: add all the other values.
} telemetry_t;


/******************************/
/***** Global Variables *******/
/******************************/
extern tasks_config_table_t g_TaskConfigTable;
extern code_config_table_t g_CodeConfigTable;

/* Utilities to control tasks */
//extern TaskHandle_t taskHandles[MAX_NUM_TASKS];
extern int16_t g_tasks_mul_factor[MAX_NUM_TASKS]; //signed because counters are signed

#ifdef CI_TEST
extern int ci_test_counter;
extern int ci_test_tasks_exec[MAX_NUM_TASKS];
#endif



#endif //lib #ifdef

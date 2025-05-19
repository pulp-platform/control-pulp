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
* File: cfg_types.h
* Notes: This file holds the general data type, struct and
*           enum.
*
* Written by: Eventine (UNIBO)
*
*********************************************************/

#ifndef _CFG_TYPES_H_
#define _CFG_TYPES_H_

/* Libraries Inclusion */

/* Others */
#include <stdint.h>

//#define CONTROL_DATA_TYPE     1

/*******************/
/*** Data Types ****/
/*******************/

#define PMS_MAX_INT 4000000000

//TODO: These below are Target-dependent!!

// varBool_e
typedef enum
{
    PCF_FALSE                 = 0x0,	 // False / Inactive / No
    PCF_TRUE                  = 0x1 // True / Active / Yes
} varBool_e;

// varValue
#if (CONTROL_DATA_TYPE == 1)    //float
typedef float 	varValue;
#elif (CONTROL_DATA_TYPE == 2)  //float16
//typedef float16 varValue;
#elif (CONTROL_DATA_TYPE == 3)  //fixed int
//typedef ... varValue;
#else
typedef int 	varValue;
#endif

// varFor
typedef int 	varFor;

// varShInt
//typedef int 	varShortInt;

// varShUnsInt
//typedef uint32_t 	varShortUInt;

// varCounter
typedef int32_t 	varCounter;

// varShCounter
typedef int16_t 	varShortCounter;

// varError
typedef uint32_t    varError;

// varFreqRedMap
typedef uint16_t    varFreqRedMap;



/* Enum */
typedef enum
{
    G_EMPTY_VAR,
    G_CTRL_PARAMETER_TABLE,
    G_SETUP_PARAMETER_TABLE,
    G_CTRL_CONFIG_TABLE,
    G_CTRL_LMS_CONFIG_TABLE,
    G_TASKS_CONFIG_TABLE,
    G_CODE_CONFIG_TABLE,
    G_SYS_CONFIG_TABLE,
    //
    G_TELEMETRY
} pcf_global_var_e;

typedef enum
{
    GLOBAL_WRITE_NOTHING,
    GLOBAL_WRITE_ALL,
    //
    GLOBAL_WRITE_TARGET_FREQ,
    GLOBAL_WRITE_TOTAL_POWER_BUDGET,
    GLOBAL_WRITE_QUADRANT_POWER_BUDGET,
    GLOBAL_WRITE_CORE_BINDING_VECTOR,
    GLOBAL_WRITE_PERC_WORKLOAD,
    GLOBAL_WRITE_POWER_FORMULA_COEFF
} global_var_write_cmd_e;


/*******************/
/*** Data Struct ***/
/*******************/
typedef struct _sensor_data {
	varValue frequency;
	varValue voltage;
	varValue temperature;
	//uint16_t Core; //TBD
} sensor_data_t;



/*******************/
/*** Enum Struct ***/
/*******************/
enum pcf_tasks_e
{
    /** ATTENTION! **/
    /* Put first the periodic tasks, and after the non-periodic tasks */
    /* First of the periodi task is PERIODIC_CONTROL_TASK */
    //TBD: is this safe enough????

    //Periodic Tasks
    PERIODIC_CONTROL_TASK,
    REAR_CONTROL_TASK,
    FAST_CONTROL_TASK,
    COMMS_TASK,
    MAIN_TASK,
    USER_DEFINED_TASK,

    //Non-Periodic Tasks
    #if (defined(DEBUG_ACTIVE) || (MEASURE_ACTIVE == 1))
    DEBUG_TASK
    #endif
};


/***************************************/
/*** Defined Values ***/
#define VD_MAX_UINT   4294967295
//TBC: should I put 0xFFFFFFFF?
//#define VAR_VALUE_BYTES_NUM 4

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_100_PERC 100.0f
#else
#define VD_100_PERC 100
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_ZERO 0.0f
#else
#define VD_ZERO 0
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_ONE 1.0f
#else
#define VD_ONE 1
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_TEMP_INIT 300.0f
#else
#define VD_TEMP_INIT 300
#endif


#endif //lib #ifdef

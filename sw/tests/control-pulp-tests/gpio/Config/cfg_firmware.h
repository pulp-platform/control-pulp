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
#include "FreeRTOS.h"
#include "task.h"

/* Libraries Inclusion */
#include "cfg_types.h"


/** Definitions **/
/* these has to be manually changed */
/** Tasks **/
// Max Number of Tasks
#define MAX_NUM_TASKS 						3

/****** Private ******/
/* NOT CONFIGURABLE */
/** Code Configuration **/

/****** Private END ******/


/******************************/
/** Firmware Configuration ****/
/******************************/


/******************************/
/***** Global Variables *******/
/******************************/

uint32_t systick_iterations;
uint32_t systick_overflows;

uint32_t g_time_counter_systick_hms;
uint32_t g_time_counter_systick_min;
uint32_t g_signal_on;
uint32_t g_signal_received;
uint32_t g_SLP_STATE;
uint32_t g_overtime;

/* Utilities to control tasks */
extern TaskHandle_t taskHandles[MAX_NUM_TASKS];
//extern int16_t g_tasks_mul_factor[MAX_NUM_TASKS]; //signed because counters are signed


#endif //lib #ifdef

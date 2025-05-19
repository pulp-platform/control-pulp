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
* File: cfg_system.h
* Notes: This files holds the definitions, structs and
*           global var regarding the system, processors,
*           cores and Motherboard.
*
* Written by: Eventine (UNIBO)
*
*********************************************************/


#ifndef _PCF_SYS_CONFIG_H_
#define _PCF_SYS_CONFIG_H_

/* Libraries Inclusion */
#include "cfg_types.h"

/** Definitions **/
/* these has to be manually changed */
#define MAX_NUM_CORE 	               	72
#define MAX_NUM_QUAD	               	1
#define SYS_CORE_WL_STATES 			   	4
#define POWER_FORMULA_COEFF_NUM		   	2
#define SYS_PW_DOMAIN_NUM				2

//#define USE_INSTRUCTIONS_COMPOSITION


/******************************/
/* Configuration of Processor */
/******************************/
typedef struct _sys_config_table {

	uint16_t num_core;							// Number of Cores of each chiplet
	uint16_t num_quad;							// Number of Quadrants of each Chiplet (if cores are divided in quadrants)
	uint16_t num_pw_domains;					// Number of Power Domains
	uint16_t num_chip_proc;						// Number of Chiplet per each Processor
	uint16_t num_socket_sys;					// Number of Processor/Socket per Motherboard

	/* Parameters of the Cores */
	varValue core_critical_temperature;			// Max Temperature for each Core in Kelvin
	varValue core_idle_power;					// Min Power for a Single Core to stay alive
	varValue core_max_power_single; 			// Max Power for each Core
	varValue core_min_frequency;
	varValue core_max_frequency;
	uint16_t core_wl_states_num;
    varValue base_power_coeff[SYS_CORE_WL_STATES][POWER_FORMULA_COEFF_NUM];

	/* Initialization Values */
	varValue init_core_freq;
	varValue init_core_volt;
	varValue init_core_workload;
	varValue init_core_ceff;

} sys_config_table_t;


/******************************/
/***** Global Variables *******/
/******************************/
extern sys_config_table_t g_SysConfigTable;






#endif //lib #ifdef

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
* File:
* Date:
* Notes:
*
* Written by: Eventine (UNIBO)
*
*********************************************************/

#ifndef _PCF_CONST_H_
#define _PCF_CONST_H_


/*** Definitions ***/

/** BitMap Definition **/
/* Frequency Reduction Map */
#define BM_RESET				    0x0
//
#define BM_FRM_MAX_SINGLE_POW_SAT	0b1
#define BM_FRM_ALPHA_RED 			(0b1 << 1)
#define BM_FRM_PID_TEMP_RED			(0b1 << 2)
#define BM_FRM_BINDING_RED			(0b1 << 3)
#define BM_FRM_MAX_SINGLE_FREQ		(0b1 << 4)
#define BM_FRM_HYST_EMERG			(0b1 << 5)
#define BM_FRM_MAX_GRADIENT         (0b1 << 6)
//20, 40, 80, 100
//quadrants


/* Error Map */
// 1st 8 bits
#define BM_ERROR_FREERTOS_MEMORY_ALLOCATION_TASK 	0b1
#define BM_ERROR_FREERTOS_MEMORY_ALLOCATION_OBJ 	(0b1 << 1)
#define BM_ERROR_REACHED_EOT						(0b1 << 2)
#define BM_ERROR_INITIALIZATION						(0b1 << 3)
// 2nd 8 bits
#define BM_ERROR_CRITICAL							(0b1 << 8)
#define BM_ERROR_PROBLEMATIC						(0b1 << 9)
#define BM_ERROR_LIGHT								(0b1 << 10)
//3rd 8 bits
#define BM_ERROR_SHARED_VAR_READ					(0b1 << 16)
#define BM_ERROR_SHARED_VAR_WRITE					(0b1 << 17)
#define BM_ERROR_NUMBERS_VALUE						(0b1 << 18)

//4th 8 bits, left for debug
#define BM_ERROR_D_SPI_R_HS							(0b1 << 24)
#define BM_ERROR_D_SPI_W_HS							(0b1 << 25)
#define BM_ERROR_D_SPI_R_INDEX						(0b1 << 26)
#define BM_ERROR_D_SPI_W_INDEX						(0b1 << 27)
#define BM_ERROR_D_SPI_TOS_HS						(0b1 << 28)
#define BM_ERROR_D_SPI_TOS_INDEX					(0b1 << 29)
//


/*** Global Constants ***/




#endif //lib #ifdef

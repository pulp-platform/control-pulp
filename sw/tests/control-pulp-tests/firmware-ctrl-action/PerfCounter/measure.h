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

#ifndef _MEASURE_LIBRARY_
#define _MEASURE_LIBRARY_


#include "cfg_firmware.h"

/* Data Struct */
typedef struct _Timer_Data {
	char where;
	//int time;
	int cycle;
} Timer_Data_t;

typedef enum
{
	//things
    mCycles 		= 0b1,
	mInstr			= 0b10,
	mLoad			= 0b100,
	mStore			= 0b1000,
	mJump			= (0b1UL << 5),
	mBranch			= (0b1UL << 6),
	mCInstr			= (0b1UL << 7),

	//Stalls and  Misses
	mLdStall		= (0b1UL << 8),
	mStStall		= (0b1UL << 9),
	mInstrMiss		= (0b1UL << 10),
	mJmpStall		= (0b1UL << 11),
	mBrchTaken		= (0b1UL << 12),
	mPipeStall		= (0b1UL << 13),
	mApuDependStall = (0b1UL << 14),

	//APU
	mApuTypeConfl	= (0b1UL << 15),
	mApuContention	= (0b1UL << 16),
	mApuWriteBack	= (0b1UL << 17),

} measure_type_e;

void vMeasureInit (measure_type_e type);
void vMeasureStart (void);
void vMeasureStop (void);

//typedef struct { unsigned value : 12; } uint12;
extern inline uint32_t lMeasureReadCsr(int zeroing);
//I would use it as: lMeasureReadCsr(MEASURE_CSR, MEASURE_ZEROING)
//#define lMeasureReadCsr( CSRCODE, ZEROING )				\
	lMeasureReadCycle(ZEROING) // maybe here ; ??


//inline generally is defined inside the header.h file, but since they are
//	Target-dependant, they are defined in the .c file inside the Target folder.
extern inline uint32_t lMeasureReadCycle ( int zeroing );
extern inline uint32_t lMeasureReadInstr ( int zeroing );
extern inline uint32_t lMeasureReadLdStall ( int zeroing );
extern inline uint32_t lMeasureReadInstrMiss ( int zeroing );
extern inline uint32_t lMeasureReadLoad ( int zeroing );
extern inline uint32_t lMeasureReadStore ( int zeroing );

#if (MEASURE_ACTIVE == 1)
extern int lPerformanceCheck;
extern int CSCheck;
extern int Timerindex;
extern Timer_Data_t timerBuffer[MEASURE_N_OUTPUTS*MEASURE_N_ITERATION+7];
#endif
#if (MEASURE_ACTIVE == 2)
extern uint32_t g_I_cycle_prev;
extern uint32_t g_cycle_valid_comparison;
extern uint32_t g_mes_comp_value;
#endif


#endif //Lib

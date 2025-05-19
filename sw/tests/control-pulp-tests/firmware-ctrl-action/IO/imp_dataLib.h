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

#ifndef _DATA_LIB_H_
#define _DATA_LIB_H_


#include "cfg_firmware.h"
#include "cfg_types.h"
#include "cfg_system.h"

/**** CHANGE TO CONFIGURE ****/

#define NO_IO_AUTO_RUN             //if enabled the firmware will keep going, if commented the firmware should stop after all output matrixes are filled.
//#define NO_IO_FREQ_COMPARE         //if enabled it will also directly compare the freq.
//for now keep it commented


/** OTHERS NOT TO BE CHANGED **/
#define NO_IO_NUMBER_OF_COMMANDS               4
#define NO_IO_PERIODIC_TOT_STEPS               7 //(NO_IO_NUMBER_OF_COMMANDS * NO_IO_UI_STEPS * 2) //todo: this 2 = TASKS_OS_PERIODICITY_MUL_FACTOR
#define NO_IO_PERIODIC_STEPS_WAIT              1 //200

//
#define NO_IO_UI_STEPS_WAIT                    (NO_IO_PERIODIC_TOT_STEPS * NO_IO_PERIODIC_STEPS_WAIT / NO_IO_NUMBER_OF_COMMANDS / 2)

extern int no_io_uiIndex;
extern int no_io_uiCounter;
extern int no_io_periodicIndex;
extern int no_io_periodicCounter;



/************ DATA WILL BE OUTPUTTED HERE **************/

//extern varValue no_io_uiFreqRedMap[NO_IO_NUMBER_OF_COMMANDS * NO_IO_UI_STEPS];
//extern varValue no_io_uiErrorMap[NO_IO_NUMBER_OF_COMMANDS * NO_IO_UI_STEPS];

extern varValue no_io_computedFreq[NO_IO_PERIODIC_TOT_STEPS][MAX_NUM_CORE];
//actually these values above are a bit different because of approximation
//in fact to pass the data thorugh the spi I pass it as a short unsigned int
//so I make at the 4th decimal. BTW in the new implementation this should not
//be a problem since I stepped the freq with 100Mhz steps---

#ifdef NO_IO_FREQ_COMPARE
extern varValue no_io_freqDiff[NO_IO_PERIODIC_TOT_STEPS][MAX_NUM_CORE];
#endif

/*************** INSERT HERE THE DATA *****************/

//The temperature measured by the sensor and received by the fimware. One temp for each core for each step
extern varValue no_io_measuredTemp[NO_IO_PERIODIC_TOT_STEPS][MAX_NUM_CORE]; //Insert here!

//The taget frequency per core (input) for each different input command
extern varValue no_io_uiTargetFreq[NO_IO_NUMBER_OF_COMMANDS][MAX_NUM_CORE]; //Insert here!

//The target workload per core (input) for each different input command
extern varValue no_io_workload[NO_IO_NUMBER_OF_COMMANDS][MAX_NUM_CORE]; //Insert here!

//The target power budget (unique, not per core) for each different input command
extern varValue no_io_uiPowerBudget[NO_IO_NUMBER_OF_COMMANDS]; //Insert here!

//The actual recorded total power consumed by the model - If you do not have the data just put 0, it should be fine for now
extern varValue no_io_simPower[NO_IO_PERIODIC_TOT_STEPS]; //[NO_IO_NUMBER_OF_COMMANDS * NO_IO_UI_STEPS]; //Insert here!

#ifdef NO_IO_FREQ_COMPARE
//If you want to compare, insert here the data of the Outputted freq per core for each step.
extern varValue no_io_recordedFreqOut[NO_IO_PERIODIC_TOT_STEPS][MAX_NUM_CORE]; //Insert here!
#endif




#endif  //DATA_LIB_H_H

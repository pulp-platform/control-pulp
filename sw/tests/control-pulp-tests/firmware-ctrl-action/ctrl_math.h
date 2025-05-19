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
/***************************************************/
/*
* Math and Control Functions Library
*
*
*/


#ifndef _CTRL_MATH_H_
#define _CTRL_MATH_H_

//#include "FreeRTOS_util.h"
#include "cfg_types.h"
#include "cfg_firmware.h"

#include <stdint.h>

#ifdef JO_TBR
#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define V_Fixed                             0.75f
#else
#define V_Fixed                             1
#endif
#endif

/* Functions Declaration */
varValue lMathPidCompute(varValue i_target_power, varValue i_measured_temperature, varFor i_core_number, varValue i_integr_red);
varBool_e bMathPidSetParameters(varValue kp, varValue ki, varValue kd, varValue dt, varValue Tcrit, varValue Tmargin, varValue Pidle);

varValue lMathPowerCompute(varValue i_target_frequency, varValue* i_formula_coeff);
varValue lMathFrequencyCompute(varValue i_core_target_power, varValue* i_formula_coeff);
//pid_parameters_t TablePIDParameters; //TBD: to create a struc for PID parameters

varValue lMathLmsRecursive(varValue *o_param, varValue *o_Pcurr, varValue *i_prev_param, varValue *i_Pprev, varValue *i_input_value, varValue i_error, varValue i_lambda);
void vMathLmsStoreP (varValue *o_param, varValue *i_input_value);

void MatMul(varValue *O, varValue *iA, varValue *iB, uint16_t r1, uint16_t col1, uint16_t col2);


#endif

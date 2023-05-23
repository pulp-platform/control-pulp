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


/* Header include. */
#include "ctrl_math.h"

#include "cfg_types.h"
#include "cfg_system.h"
#include "cfg_control.h"
#include "cfg_firmware.h" //todo remove, just for v_fixed

/* Other Inclusion */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>


/* Global Variables Declaration */
// Keep Global variables as few as possible, Higher cost
//TODO: Proper allocation in the right memory.
//TBC: why static???
static varValue _pid_integral_error[MAX_NUM_CORE] = {0};
static varValue _ki;
static varValue _pid_previous_error[MAX_NUM_CORE] = {0};
static varValue _kd;
static varValue _saturation_max;
static varValue _Pidle;

static varValue _kp, _Tcrit_pid;  //TODO: initialization of all var


varValue lMathPidCompute(varValue i_target_power, varValue i_measured_temperature, varFor i_core_number, varValue i_integr_red) {

	varValue output_pid = 0;

	/* Compute Error */
	varValue error = _Tcrit_pid - i_measured_temperature;
	//test_on_number
	//if ( (abs(error) - _Tcrit_pid) > 0)
	//{
		/* TODO:
		#ifdef ERROR_MAP
		ErrorMap |= BM_ERROR_NUMBERS_VALUE;
		#endif
		*/

		//error = ?? //TODO
	//}

	//printf("er: ");
	//printFloat(error);
	/* Proportional Term */
	output_pid = _kp * error;
/*
	if ((i_measured_temperature> EPI_CORE_CRITICAL_TEMPERATURE - 50) && (i_core_number == 0))
	{
		printf("asd  ");
		printFloat(output_pid);
	}*/

	/* Integral Term */
	if (g_ControlConfigTable.use_pid_integral_action == PCF_TRUE)
	{
		//TODO:
		// switch (iComm)
		// {
		// 	case 1:
		// 		_pid_integral_error[i_core_number] *= 0.5;
		// 		break;
		// 	case 2:
		// 		_pid_integral_error[i_core_number] *= 1.5;
		// 		break;
		// 	default:
		// 		break;
		// }
		if (i_integr_red != 0)
		{
			_pid_integral_error[i_core_number] = 0;
			//_pid_integral_error[i_core_number] =* i_integr_red * PID_INT_RED_COEFF;
		}

		_pid_integral_error[i_core_number] += error * _ki;

		//TODO: this saturation is problematic because it depends on the Target power.
		if (g_ControlConfigTable.use_pid_anti_windup_sat == PCF_TRUE)
		{
			if (_pid_integral_error[i_core_number] > g_ControlConfigTable.pid_anti_windup_sat_up ) //TBD: Should I parametrize this 0?
				_pid_integral_error[i_core_number] = g_ControlConfigTable.pid_anti_windup_sat_up;
			else if (_pid_integral_error[i_core_number] < (g_ControlConfigTable.pid_anti_windup_sat_coeff * i_target_power)) //TODO: var conversion
			{
				_pid_integral_error[i_core_number] = g_ControlConfigTable.pid_anti_windup_sat_coeff * i_target_power; //TODO: var conversion
			}
		}
		output_pid += _pid_integral_error[i_core_number];
	}

	/* Derivative Term */
	if (g_ControlConfigTable.use_pid_derivative_action == PCF_TRUE)
	{
		output_pid += _kd * (error - _pid_previous_error[i_core_number]);

		/* Update Error Global Variable */
		_pid_previous_error[i_core_number] = error;
	}
/*
	if ((i_measured_temperature> EPI_CORE_CRITICAL_TEMPERATURE - 6.2) && (i_core_number == 0))
	{
		printf("asd  ");
		printFloat(i_target_power);
		printFloat(output_pid);
	}
*/
	/* Saturation */
	if (g_ControlConfigTable.use_pid_saturation == PCF_TRUE)
	{
		if (output_pid > _saturation_max)
			output_pid = _saturation_max;
		else if (output_pid < (-(i_target_power - _Pidle)) )
			output_pid = -(i_target_power - _Pidle);
	}

	//printf("outpid: %d, itargetpow: %d\n", (int)output_pid, (int)i_target_power);
	//pid ff action
		output_pid = i_target_power + output_pid;

	/* Do this directly is the main to avoid also var assage bug
	#ifdef USE_TESTS_ON_NUMBERS
	if ( (output_pid <= 0) || (output_pid > i_target_power) )
	{
		#ifdef ERROR_MAP
		ErrorMap |= BM_ERROR_NUMBERS_VALUE;
		#endif

		output_pid = EPI_CORE_IDLE_POWER; //TBD: maybe too much conservative in case > ?? (consider still there is an error!)
	}
	#endif
	*/
	return output_pid;
}

varBool_e bMathPidSetParameters(varValue kp, varValue ki, varValue kd, varValue dt, varValue Tcrit, varValue Tmargin, varValue Pidle){ //TBD: better to pass by copy or by reference?

	/* Start BARRIER */ //TODO: implement barrier

	_kp = kp;
	_ki = ki*dt;
	_kd = kd*dt;

	_Tcrit_pid = Tcrit - Tmargin;
	_saturation_max = 0; //TODO
	_Pidle = Pidle;

	/* End BARRIER */

	//TODO: check, if everything is ok then
	return PCF_TRUE;// TBD: void or boolean?
}

varValue lMathPowerCompute(varValue i_target_frequency, varValue* i_formula_coeff){ //TBD: better to pass by copy or by reference? (same for output)

	/* Formula: P = K1*f*V^2 + K2 + (K3 + K4*f)*w^K5 */

	//return (i_formula_coeff[0] * i_target_frequency * (V_Fixed*V_Fixed) ) + i_formula_coeff[1] +
	//		( (i_formula_coeff[2] + (i_formula_coeff[3] * i_target_frequency)) * iWorkload ); //TODO: Formula miss k5
			//Same formula as Christian. checked.

	//printf("pc: " );
	//printFloat((Icc + (iWorkload * (i_target_frequency /*/ 1000000000.0*/) * V_Fixed) ) * V_Fixed );
	//return ( (Icc + (iWorkload * (i_target_frequency /*/ 1000000000.0*/) * V_Fixed) ) * V_Fixed );

	//printFloat(i_formula_coeff[0]);
	//printFloat(i_formula_coeff[1]);
	//printFloat((i_formula_coeff[0] + (i_formula_coeff[1] * (i_target_frequency /*/ 1000000000.0*/) * V_Fixed) ) * V_Fixed );

  //  printf("target_frequency_coeff_math:   %f     %f     %f    %f\n", i_target_frequency, i_formula_coeff[0], i_formula_coeff[1], V_Fixed);
// 
//  varValue i_target_frequency1 = 3.0f;
//  varValue i_formula_coeff1[2] = {15.0f, 23.0f};
  
  //varValue core_power_hand =  ((0.13333f + (0.6f * (1.0f /*/ 1000000000.0*/) * 0.75f) ) * 0.75f );
  //  varValue core_power = (i_formula_coeff1[0] + (i_formula_coeff1[1] * (i_target_frequency1 /*/ 1000000000.0*/) * V_Fixed) ) * V_Fixed;
  
  //    printf("core_power_math_comp: %f\n", core_power);
  //  printf("core_power_math_hand: %f\n", core_power_hand);
  
  return ( (i_formula_coeff[0] + (i_formula_coeff[1] * (i_target_frequency /*/ 1000000000.0*/) * V_Fixed) ) * V_Fixed );
  //	return ( core_power );

	/* Formula:
	* P = Pd + Ps
	* Pd = Ceff*f*Vdd^2
	* Ceff = [Weights]T * [PerfCounters]
	*/

	//Simulation //TODO: Change Formula
	//Assume Vdd = 10 fixed
	//return i_formula_coeff[0] * i_target_frequency * (10 * 10);

}

varValue lMathFrequencyCompute(varValue i_core_target_power, varValue* i_formula_coeff) {

	//TBC: Check formula. Miss (^k5) in the end
	/*return (i_core_target_power - i_formula_coeff[1] - i_formula_coeff[2] * iWorkload) /
								(V_Fixed * V_Fixed * i_formula_coeff[0] + i_formula_coeff[3] * iWorkload);
	*/

	#ifdef JO_TBR
	#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
	//printf("ciaddo\n" );
	//return ( ((i_core_target_power - (Icc*V_Fixed)) / iWorkload / (V_Fixed*V_Fixed)) /* *1000000000.0*/);
	varValue step = 10.0f;

	varValue frequency = ( ((i_core_target_power - (i_formula_coeff[0]*V_Fixed)) / i_formula_coeff[1] / (V_Fixed*V_Fixed)));
	frequency = (frequency +0.06f) * step;
	uint32_t step_frequency = (uint32_t) frequency;
	#else
	//return ( ((i_core_target_power - (Icc*V_Fixed)) / iWorkload / (V_Fixed*V_Fixed)) /* *1000000000.0*/);
	varValue step = 10;

	varValue frequency = ( ((i_core_target_power - (i_formula_coeff[0]*V_Fixed)) / i_formula_coeff[1] / (V_Fixed*V_Fixed)));
	frequency = (frequency) * step;
	uint32_t step_frequency = (uint32_t) frequency;
	#endif

	return ((varValue) step_frequency / step);
	#endif
}

varValue lMathLmsRecursive(varValue *o_param, varValue *o_Pcurr, varValue *i_prev_param, varValue *i_Pprev, varValue *i_input_value, varValue i_error, varValue i_lambda) {

	// p_est = p_est(prev) + K*error;
	// error = measured_power - power_computed_with_prev_paramenters;
	// k = P*[V, VVF]
	// P = P(prev)/lambda/(t-1) - P(prev)*[V, VVF]*[V, VVF]T*P(prev)/(t-1)/(lambda*(lambda*(t-1) + [V, VVF]T*P(prev)*[V, VVF])))

	varValue T2[LMS_CN];
	varValue T3[LMS_CNxCN];
	varValue T4[LMS_CNxCN];
	varValue K[LMS_CN];
	//float coeff1 = (iPass/(iPass-1))/i_lambda;
	varValue coeff2 = 0;

	MatMul(T2, i_Pprev, i_input_value, LMS_CN, LMS_CN, 1);
	MatMul(T3, T2, i_input_value, LMS_CN, 1, LMS_CN); //since the vector is Nx1, no need to do the Transpose since the Matrix is implemented as an array
	MatMul(T4, T3, i_Pprev, LMS_CN, LMS_CN, LMS_CN);

	// is a number, maybe is worth to create its own function
	//MatMul(coeff2, i_input_value, T2, 1, iN, 1); //since the vector is Nx1, no need to do the Transpose since the Matrix is implemented as an array
	for (int i = 0; i < LMS_CN; i++) //here leave int vs varFor
	{
		coeff2 += i_input_value[i] * T2[i];
	}

	coeff2 = (coeff2 + i_lambda) * i_lambda;

	// MatSum, but optimized!
	const varValue cMATRIX_LIM = 52; //TODO
	for (int i = 0; i < LMS_CNxCN; i++)
	{
		varValue Pcurr_app = ((i_Pprev[i] / i_lambda) - (T4[i] / coeff2));

		//TODO: this limitation are meh
		if (Pcurr_app > cMATRIX_LIM)
			Pcurr_app = cMATRIX_LIM;
		else if (Pcurr_app < -cMATRIX_LIM)
			Pcurr_app = -cMATRIX_LIM;

		o_Pcurr[i] = Pcurr_app;
	}

	MatMul(K, o_Pcurr, i_input_value, LMS_CN, LMS_CN, 1);

	// MatSum, but optimized!
	for (int i = 0; i < LMS_CN; i++)
	{
		o_param[i] = i_prev_param[i] + K[i] * i_error;
	}

	return 0; //here you should return maybe diff between parameters? a value for errors?
}

void vMathLmsStoreP (varValue *o_param, varValue *i_input_value)
{
	varValue T2[POWER_FORMULA_COEFF_NUM*POWER_FORMULA_COEFF_NUM];

	MatMul(T2, i_input_value, i_input_value, POWER_FORMULA_COEFF_NUM, 1, POWER_FORMULA_COEFF_NUM);

	for (int i=0; i < POWER_FORMULA_COEFF_NUM*POWER_FORMULA_COEFF_NUM; i++)
		o_param[i] += T2[i];

	return;
}


void MatMul(varValue *O, varValue *iA, varValue *iB, uint16_t r1, uint16_t col1, uint16_t col2)
{
	uint16_t r2 = col1;

	for (int i = 0; i < r1; i++)
	  for (int j = 0; j < col2; j++)
	  {
		varValue sum = 0.0;
		for (int k = 0; k < r2; k++)
		{
		  sum += iA[i*col1 + k] * iB[k*col2 + j];
		}

		O[i*col2 + j] = sum;
		//sum = 0.0;
	  }

	 return;
}

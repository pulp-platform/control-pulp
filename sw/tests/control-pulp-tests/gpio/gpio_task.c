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
/* FreeRTOS Inclusions. */
#include <FreeRTOS.h>
#include <task.h>
#include <semphr.h>

/* Libraries Inclusion */
#include "gpio_task.h"
#include "cfg_types.h"
#include "cfg_firmware.h"
#include "cfg_constants.h"


/* Others */
#ifdef PRINTF_ACTIVE
#include <stdio.h>
#endif
// TODO: DELETE:
#include "os.h" //for pmsis_exit
#include <stdint.h>

/* system includes */
#include "system.h"
#include "gpio.h"

/* pmsis */
//#include "target.h"


void vAtosTask(void *parameters)
{
	int ret, read_val;

	/* C: Send out the signal for done initialization/System start */

	/* D: Do nothing */

	/* E: Wait for signal (either reset or stop?) */

#ifdef ATOS_EMULATION
	uint32_t l_hms = 4 * configTICK_RATE_HZ; // 4s
#else
	uint32_t l_hms = 5; // 5*500us
#endif

	uint32_t l_min = 0;

	for (;;) {
		ulTaskNotifyTake(pdTRUE, // xClearCountOnExit: if pdTRUE =
					 // Binary Semaphore; if number =
					 // Counting Semaphore (# of times to be
					 // called before exit).
				 2);	 // xTicksToWait

		// if gpio signal is received:
		if ((g_signal_received) && (g_signal_on)) {
			// printf("SLP_STATE: %d\n", g_SLP_STATE);
			if ((g_time_counter_systick_hms >= l_hms) &&
			    (g_SLP_STATE == 56)) {

#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
				printf("[PMS] Forced POWER DOWN (S0 -> S5) request\n\r");
				printf("[PMS] Set SLP[3:5] = 3'b000, S5 state\n\r");
#endif

				// Forced Power Off (long>4 press)
				gpio_pin_set_raw(GPIO_SLP_S3, 0);
				gpio_pin_set_raw(GPIO_SLP_S4, 0);
				gpio_pin_set_raw(GPIO_SLP_S5, 0);

				g_SLP_STATE = 0;

				g_signal_received = 0;
				g_signal_on = 0;
				g_overtime = 1;

				systick_iterations = 0;
				systick_overflows = 0;
			} else if (g_SLP_STATE == 0) {

#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
				printf("[PMS] POWER ON (S5 -> S0) request\n\r");
				printf("[PMS] Set SLP[3:5] = 3'b111, S0 state\n\r");
#endif

				// Power on (short press)
				/* Write SLP[3:5] */
				gpio_pin_set_raw(GPIO_SLP_S3, 1);
				gpio_pin_set_raw(GPIO_SLP_S4, 1);
				gpio_pin_set_raw(GPIO_SLP_S5, 1);

				g_SLP_STATE = 56;

				g_signal_received = 0;

				systick_iterations = 0;
				systick_overflows = 0;
			}
		}

		/** Task End **/

		/* taskYIELD is used in case of Cooperative Scheduling, to
		 * allow/force Contex Switches */
#if configUSE_PREEMPTION == 0
		taskYIELD();
#endif
	}

	/* Cannot and Shouldn't reach this point, but If so... */

	pmsis_exit(-1);

	// TODO: SIGNAL HAZARDOUS ERROR, FAILURE!
	vTaskDelete(NULL);
}

void vPollingTask(void *parameters)
{
	int ret, read_val;

	for (;;) {

		// check GPIO
		read_val = gpio_pin_get_raw(GPIO_SYS_PWR_BTN);
		// if gpio signal is received:
		if (!read_val) {
			if (g_overtime) {
				g_signal_on = 0;
			} else {
				g_signal_on = 1;
				g_signal_received = 1;
			}
		} else {
			g_signal_on = 0;
			g_overtime = 0;
		}

		//      if ((!g_signal_received) && (!read_val) &&
		//      (prev_read_val))
		//        g_signal_received = 1;
		//
		//      prev_read_val = read_val;

		/** Task End **/

		/* taskYIELD is used in case of Cooperative Scheduling, to
		 * allow/force Contex Switches */
		// taskYIELD();
		// atm no idle task is executing: it may be a problem.
	}

	/* Cannot and Shouldn't reach this point, but If so... */

	pmsis_exit(-1);

	// TODO: SIGNAL HAZARDOUS ERROR, FAILURE!
	vTaskDelete(NULL);
}

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
 */
/********************************************************/

/* FreeRTOS Inclusions. */
#include <FreeRTOS.h>
#include <task.h>

/* Firmware Config */
#include "cfg_types.h"
#include "cfg_firmware.h"
#include "cfg_constants.h"

#include "gpio_task.h"

//
/* system includes */
#include "system.h"
#include "gpio.h"

/* pmsis */
#include "target.h"

/* Others */
#ifdef PRINTF_ACTIVE
#include <stdio.h>
#endif
// TODO: DELETE:
#include "os.h" //for pmsis_exit
#include <stdint.h>

/* Prototypes for the standard FreeRTOS callback/hook functions implemented
   within this file.  See https://www.freertos.org/a00016.html */
void vApplicationMallocFailedHook(void);
void vApplicationIdleHook(void);
void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName);
void vApplicationTickHook(void);

/* Tasks Management Var */
TaskHandle_t taskHandles[MAX_NUM_TASKS] = {NULL};

uint32_t systick_iterations = 0;
uint32_t systick_overflows = 0;

uint32_t g_time_counter_systick_hms = 0;
uint32_t g_time_counter_systick_min = 0;
uint32_t g_signal_received = 0;
uint32_t g_signal_on = 0;
uint32_t g_SLP_STATE = 0;
uint32_t g_overtime = 0;

void configure_pin(uint32_t pin, uint32_t direction)
{
	uint32_t ret;
	ret = gpio_pin_configure(pin, direction);
	if (ret != 0) {
#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
		printf("pin config output failed");
#endif
	}
}


/* Program Entry */
int main(void)
{
	// --------------------------------------------------------------- //
	/*** Initialization  ***/
	// --------------------------------------------------------------- //

	// Local Variables
	uint32_t iterations_while_waiting = 0;
	uint32_t counting_overflows = 0;

	int ret, read_val;

	/** Hardware Init **/
	system_init();

#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
	printf("[PMS] Configure PWR_BTN GPIO as input\n\r");
#endif

	/* Hardware Init pt.2 - Comms*/
	/* Configure PWR_BTN GPIO as input*/
	configure_pin(GPIO_SYS_PWR_BTN, GPIO_INPUT);

#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
	printf("[PMS] Configure SLP[3:5] GPIOs as output\n\r");
#endif

	/* Configure SLP[3:5] as output */
	configure_pin(GPIO_SLP_S3, GPIO_OUTPUT);
	configure_pin(GPIO_SLP_S4, GPIO_OUTPUT);
	configure_pin(GPIO_SLP_S5, GPIO_OUTPUT);


	/* Memory Allocation */


	/*** FreeRTOS Setup ***/
	for (varFor i = 0; i < MAX_NUM_TASKS; i++) {
		taskHandles[i] = NULL;
	}

	if (xTaskCreate(vAtosTask, "Atos Task",
			(configMINIMAL_STACK_SIZE * 2), // TBD
			NULL, 5, &taskHandles[0]) != pdPASS) {
#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
		printf("Failed Task creation, Task is NULL!\n\r");
#endif


		pmsis_exit(-4096);
	}

	if (xTaskCreate(vPollingTask, "Polling Task",
			(configMINIMAL_STACK_SIZE * 2), // TBD
			NULL, tskIDLE_PRIORITY + 1,
			&taskHandles[1]) != pdPASS) {
#if (defined(PRINTF_ACTIVE) && defined(DEBUG_PRINTF))
		printf("Failed Task creation, Task is NULL!\n\r");
#endif


		pmsis_exit(-4096);
	}


	/*** Firmware Setup ***/


	/*** Control Parameter Setup ***/


	/*** Tests Setup ***/


	/** Check & Start **/


	/** ATOS start **/

	/* A: Polling on the GPIO */


	// A2: Do we need to send the signal to the slave PMS? How do we decide
	// which is which?

	/* After signal is received we need to initialize the system */

	/* B: Fake sytem initiation */

	// B2: wait for handshake with slave

	// Actually we will also start the scheduler (should have done before
	// waiting for the signal probably, but ok.
	/* Start the Scheduler */
	vTaskStartScheduler();


	pmsis_exit(-1);

	return -1;
}


/*-----------------------------------------------------------*/

void vApplicationTickHook(void)
{

	BaseType_t xHigherPriorityTaskWoken = pdFALSE;
	int ret, read_val;

#ifndef ATOS_EMULATION
	//"Measure" "time"
	systick_iterations++;
	if (systick_iterations >= PMS_MAX_INT) {
		systick_overflows++;
		systick_iterations = 0;
	}
	// Check: if we cannot read after a while, return with an error
	if ((systick_iterations >= SYSTICK_WAITING_ITERATIONS) &&
	    (systick_overflows >= SYSTICK_WAITING_OVERFLOWS)) {
#ifdef PRINTF_ACTIVE
		printf("Signal not received after: %d x 4.000.000.000 + %d polling iterations. \n\r",
		       systick_overflows, systick_iterations);
#endif
		pmsis_exit(255);
	}
#endif

	// check GPIO
	// read_val = gpio_pin_get_raw(GPIO_SYS_PWR_BTN);
	// Do corresponding stuff and exit.
	// if gpio signal is received:
	if (g_signal_on == 1) {
		/* Write SLP[3:5] */
		g_time_counter_systick_hms++;
		if (g_time_counter_systick_hms > 60 * configTICK_RATE_HZ) {
			g_time_counter_systick_hms = 0;
			g_time_counter_systick_min++;
		}
	} else {
		g_time_counter_systick_hms = 0;
		g_time_counter_systick_min = 0;
	}

	vTaskNotifyGiveFromISR(taskHandles[0], &xHigherPriorityTaskWoken);

	/* If xHigherPriorityTaskWoken is now set to pdTRUE then a context
	   switch should be performed to ensure the interrupt returns directly
	   to the highest priority task.  The macro used for this purpose is
	   dependent on the port in use and may be called
	   portEND_SWITCHING_ISR(). */
	portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
}


/*-----------------------------------------------------------*/

void vApplicationMallocFailedHook(void)
{
	/* vApplicationMallocFailedHook() will only be called if
	   configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is
	   a hook function that will get called if a call to pvPortMalloc()
	   fails. pvPortMalloc() is called internally by the kernel whenever a
	   task, queue, timer or semaphore is created.  It is also called by
	   various parts of the demo application.  If heap_1.c or heap_2.c are
	   used, then the size of the heap available to pvPortMalloc() is
	   defined by configTOTAL_HEAP_SIZE in FreeRTOSConfig.h, and the
	   xPortGetFreeHeapSize() API function can be used to query the size of
	   free heap space that remains (although it does not provide
	   information on how the remaining heap might be fragmented). */

	// TODO
	taskDISABLE_INTERRUPTS();

	// I choose not to include this in HRO/DEBUG cuz it is so important to
	// always show
#ifdef PRINTF_ACTIVE
	printf("error: application malloc failed\n\r");
#endif
	__asm volatile("ebreak");
	for (volatile int i = 0; i < PMS_MAX_INT; i++)
		;

	pmsis_exit(-16);
}
/*-----------------------------------------------------------*/

void vApplicationIdleHook(void)
{
	/* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is
	   set to 1 in FreeRTOSConfig.h.  It will be called on each iteration of
	   the idle task.  It is essential that code added to this hook function
	   never attempts to block in any way (for example, call xQueueReceive()
	   with a block time specified, or call vTaskDelay()).  If the
	   application makes use of the vTaskDelete() API function (as this demo
	   application does) then it is also important that
	   vApplicationIdleHook() is permitted to return to its calling
	   function, because it is the responsibility of the idle task to clean
	   up memory allocated by the kernel to any task that has since been
	   deleted. */

	// TODO
}
/*-----------------------------------------------------------*/

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName)
{
	(void)pcTaskName;
	(void)pxTask;

	/* Run time stack overflow checking is performed if
	   configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	   function is called if a stack overflow is detected. */

	// TODO

	// I choose not to include this in HRO/DEBUG cuz it is so important to
	// always show
#ifdef PRINTF_ACTIVE
	printf("task overflow! task Handler: %x  -  %s\n\r", pxTask,
	       pcTaskName);
#endif

	taskDISABLE_INTERRUPTS();
	__asm volatile("ebreak");
	for (volatile int i = 0; i < PMS_MAX_INT; i++)
		;

	pmsis_exit(-256);
}
/*-----------------------------------------------------------*/

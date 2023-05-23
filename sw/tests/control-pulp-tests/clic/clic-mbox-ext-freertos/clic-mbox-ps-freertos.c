/*
 * Copyright 2021 ETH Zurich
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by apclicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 * Author: Robert Balas (balasr@iis.ee.ethz.ch)
 */

/* PL waits for the doorbell interrupt to be triggered by PS,
   then reads the message from the mailbox in order to return the requested
   values in the mailbox */

/* FreeRTOS kernel includes. */
#include <FreeRTOS.h>
#include <task.h>

/* c stdlib */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <inttypes.h>

/* system includes */
#include "system.h"
#include "io.h"
#include "timer.h"
#include "timer_hal.h"
#include "timer_irq.h"
#include "fll.h"
#include "irq.h"
#include "gpio.h"
#include "csr.h"
#include "clic.h"
#include "scmi.h"


/* pmsis */
#include "target.h"
#include "os.h"

void vApplicationMallocFailedHook(void);
void vApplicationIdleHook(void);
void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName);
void vApplicationTickHook(void);

#define MBOX_START_ADDRESS 0xFFFF0000

#define INTR_ID 32

#define CLIC_BASE_ADDR 0x1A200000
#define CLIC_END_ADDR  0x1A20FFFF

#define assert(expression)                                                     \
	do {                                                                   \
		if (!(expression)) {                                           \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

void clic_setup_mtvec(void);
void clic_setup_mtvt(void);

void (*clic_isr_hook[1])(void);


/* need void functions for isr table entries */
void exit_success(void)
{
	puts("someone wrote to mailbox!");
	callee_scmi_handler();
	exit(0);
}

void exit_fail(void)
{
	exit(1);
}

void callee_scmi_handler(void)
{
	uint32_t data = 0x0;
	uint32_t address = 0x0;
	uint32_t status = 0x0;
	uint32_t response = 0x0;
	uint32_t protocol_id = 0x0;
	uint32_t message_id = 0x0;

	data = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET);
	printf("payload: %x\n", data);

	data = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET);
	protocol_id = (data & 0x3fc00) >> 10;
	message_id = data & 0xff;

	printf("protocol_id: %x\n", protocol_id);
	printf("message_id: %x\n", message_id);

	if ((protocol_id == 0x10) && (message_id == 0x00)) {
		status = 0;
		response = 0x20000;
		puts("protocol version asked and answered");
	} else {
		status = -1;
		response = 0;
		puts("unknown message id or protocol id");
	}
	// write the header back
	writew(data, MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET);
	// write status
	writew(status, MBOX_START_ADDRESS + SCMI_CHANNEL_STATUS_C0_REG_OFFSET);
	// write payload for return values
	writew(response,
	       MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET);
	// channel free
	writew(MBOX_START_ADDRESS + SCMI_DOORBELL_C0_REG_OFFSET, 0x1);

	// verification prints
	data = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET);
	// print header
	printf("header: %x\n", data);
	// print length
	data = readw(MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);
	printf("length: %x\n", data);
	// print return payload
	data = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET);
	printf("return payload: %x\n", data);
}


int main(void)
{

	/* Init board hardware. */
	system_init();


	/*
	 * global address map
	 * CLIC_START_ADDR      32'h1A20_0000
	 * CLIC_CTRL_END_ADDR   32'h1A20_FFFF
	 * See clic.h for register map
	 */

	/* This tests works with edge triggered interrupts as default.
	 * It uses clicintip[i] CLIC register to assert pending interrupt via
	 * SW, even though the corresponding lines are not asserted in HW.
	 *
	 * If the trigger is switched to level-sensitive mode,
	 * pending interrupts must be excited by asserting the corresponding
	 * line in HW.
	 */

	/* TODO: hook illegal insn handler to exit(1) */

	printf("test csr accesses\n");
	uint32_t thresh = 0xffaa;
	uint32_t cmp = 0;
	csr_write(CSR_MINTTHRESH, thresh);
	cmp = csr_read(CSR_MINTTHRESH);
	csr_write(CSR_MINTTHRESH, 0);	/* reset threshold */
	assert(cmp == (thresh & 0xff)); /* only lower 8 bits are writable */


	/* redirect vector table to our custom one */
	printf("set up vector table\n");
	clic_setup_mtvec();
	clic_setup_mtvt();

	/* enable selective hardware vectoring */
	printf("set shv\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(INTR_ID));

	/* set trigger type to edge-triggered */
	printf("set trigger type: edge-triggered\n");
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
		       readw(CLIC_BASE_ADDR +
			     CLIC_CLICINTATTR_REG_OFFSET(INTR_ID)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(INTR_ID));

	/* set number of bits for level encoding:
	 * nlbits
	 */
	printf("set nlbits\n");
	writeb((0x4 << CLIC_CLICCFG_NLBITS_OFFSET),
	       CLIC_BASE_ADDR + CLIC_CLICCFG_REG_OFFSET);

	/* set interrupt level and priority*/
	printf("set interrupt priority and level\n");
	writew(0xaa, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(INTR_ID));

	/* raise interrupt threshold to max and check that the interrupt doesn't
	 * fire yet */
	printf("raise interrupt threshold to max (no interrupt should happen)\n");
	csr_write(CSR_MINTTHRESH, 0xff); /* 0xff > 0xaa */
	clic_isr_hook[0] = exit_fail; /* if we take an interrupt then we failed
				       */

	printf("enable interrupt\n");

	/* enable interrupt globally */
	irq_clint_global_enable();

	/* enable interrupt on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(INTR_ID));

	printf("lower interrupt threshold (interrupt should happen)\n");
	clic_isr_hook[0] = exit_success;
	csr_write(CSR_MINTTHRESH, 0); /* 0 < 0xaa */

	for (int i = 0; i < 100000; i++)
		;

	printf("Interrupt took too long\n");


	return 1;
}

void vApplicationMallocFailedHook(void)
{
	/* vApplicationMallocFailedHook() will only be called if
	configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a
	hook function that will get called if a call to pvPortMalloc() fails.
	pvPortMalloc() is called internally by the kernel whenever a task,
	queue, timer or semaphore is created.  It is also called by various
	parts of the demo application.  If heap_1.c or heap_2.c are used, then
	the size of the heap available to pvPortMalloc() is defined by
	configTOTAL_HEAP_SIZE in FreeRTOSConfig.h, and the
	xPortGetFreeHeapSize() API function can be used to query the size of
	free heap space that remains (although it does not provide information
	on how the remaining heap might be fragmented). */
	taskDISABLE_INTERRUPTS();
	printf("error: application malloc failed\n\r");
	__asm volatile("ebreak");
	for (;;)
		;
}

void vApplicationIdleHook(void)
{
	/* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is
	set to 1 in FreeRTOSConfig.h.  It will be called on each iteration of
	the idle task.  It is essential that code added to this hook function
	never attempts to block in any way (for example, call xQueueReceive()
	with a block time specified, or call vTaskDelay()).  If the application
	makes use of the vTaskDelete() API function (as this demo application
	does) then it is also important that vApplicationIdleHook() is permitted
	to return to its calling function, because it is the responsibility of
	the idle task to clean up memory allocated by the kernel to any task
	that has since been deleted. */
}

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName)
{
	(void)pcTaskName;
	(void)pxTask;

	/* Run time stack overflow checking is performed if
	configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	function is called if a stack overflow is detected. */
	taskDISABLE_INTERRUPTS();
	printf("error: stack overflow\n\r");
	__asm volatile("ebreak");
	for (;;)
		;
}

void vApplicationTickHook(void)
{
}

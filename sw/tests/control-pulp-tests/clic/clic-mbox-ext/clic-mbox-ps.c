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

/* Test basic functionality of the clic (peripheral and core side). Especially
 * check if the interrupt thresholding works. */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "pulp.h"
#include "csr.h"
#include "io.h"

#include "clic.h"
#include "scmi.h"

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

	/* enable interrupt on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(INTR_ID));

	printf("lower interrupt threshold (interrupt should happen)\n");
	clic_isr_hook[0] = exit_success;
	csr_write(CSR_MINTTHRESH, 0); /* 0 < 0xaa */
	while (1)
		;

	for (int i = 0; i < 100000; i++)
		;

	printf("Interrupt took too long\n");


	return 1;
}

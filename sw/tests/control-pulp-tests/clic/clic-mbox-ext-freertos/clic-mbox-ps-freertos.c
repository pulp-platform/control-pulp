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

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName);
void vApplicationMallocFailedHook(void);
void vApplicationIdleHook(void);
void vApplicationTickHook(void);

#define MBOX_START_ADDRESS 0xFFFF0000

#define INTR_ID 35

#define CLIC_BASE_ADDR 0x1A200000
#define CLIC_END_ADDR  0x1A20FFFF

#define SUCCESS  0x0

#define FC_TIMER_BASE_ADDR  0x1B200400
#define ARCHI_TIMER_SIZE  0x00000800
#define FC_TIMER_ADDR (0x1A100000  0x0000B000)
#define DRAM_BASE_ADDR 0x20000000


// volatile int *timestamp2 = (int *)(DRAM_BASE_ADDR + sizeof(int));

#define assert(expression)                                                     \
	do {                                                                   \
		if (!(expression)) {                                           \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

int first = 0;

volatile uint32_t ft = 1;

volatile int set_cnt = 0;

void clic_setup_mtvec(void);
void clic_setup_mtvt(void);

void (*clic_isr_hook[1])(void);



void exit_fail(void)
{
	exit(1);
}

void exit_success(void)
{
	// printf("someone wrote to mailbox!\r\n");	
	callee_scmi_handler();
	exit(0);  	//---------------------------REMOVE THIS LINE IF IT IS NOT A SIMULATION
}


void complete_msg(uint32_t header, uint32_t agent_id){
	// write the header back
	writew(header, MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET);

	// write channel status to free
	writew(0x0, MBOX_START_ADDRESS + SCMI_CHANNEL_STATUS_C0_REG_OFFSET);

	// ring the completion
	writew(agent_id, MBOX_START_ADDRESS + SCMI_COMPLETION_INTERRUPT_C0_REG_OFFSET);
}


void callee_scmi_handler(void)
{	

	// set_cnt++;
	// printf("set_cnt: %d\r\n", set_cnt);
	

	uint32_t agent_id = 0x0;
	uint32_t data = 0x0;
	uint32_t response = 0x0;
	uint32_t protocol_id = 0x0;
	uint32_t message_id = 0x0;
	uint32_t payload0 = 0x0;
	// uint32_t payload1 = 0x0;
	// uint32_t payload2 = 0x0;

	// read agent_id from doorbell 
	agent_id = readw(MBOX_START_ADDRESS + SCMI_DOORBELL_C0_REG_OFFSET);
	
	// clear doorbell TODO: doorbell must be cleared after reading the whole message not here
	writew(0x0, MBOX_START_ADDRESS + SCMI_DOORBELL_C0_REG_OFFSET);

	// read header
	data = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET);
	protocol_id = (data & 0x3fc00) >> 10;
	message_id = data & 0xff;

	// read payload
	payload0 = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);
	// payload1 = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET);
	// payload2 = readw(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_2_C0_REG_OFFSET);

	// printf("prot_id: %u\r\n",protocol_id);
	// printf("mess_id: %u\r\n",message_id);
	// printf("payload0: %u\r\n",payload0);
	// printf("payload1: %u\r\n",payload1);
	// printf("payload2: %u\r\n",payload2);
	// printf("	\r\n");
//////////////////////////////////////////////////////////////////////////////////////////
//
//
//					PROTOCOL 0x10
//
//
//////////////////////////////////////////////////////////////////////////////////////////

	if(protocol_id == 0x10){
		if(message_id == 0x00){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x20000;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);
			
			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);				
			complete_msg(data, agent_id);
		}else if(message_id == 0x01){
			response = SUCCESS;
			writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);
				
			response = 0x0101;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x03){ //vendor
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x41;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);	
		}else if(message_id == 0x04){ //subvendor
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x41;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x05){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);
					
			response = 0x1;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x06){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			if (first == 0){
				first = 1;	

				response = 0x3;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

				response = 0x141311;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

				writew(8+4*2,
					MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);	
			}else{
				response = 0x0;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	
				
				response = 0x0;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	
				
				writew(8+4*0,
					MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);	
			}
			
			complete_msg(data, agent_id);
		}else if(message_id == 0x07){
				response = SUCCESS;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

				response = 0x1;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

				response = 0x43;
				writew(response,
					MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);

				writew(8+4*2,
					MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}
//////////////////////////////////////////////////////////////////////////////////////////
//
//
//					PROTOCOL 0x13
//
//
//////////////////////////////////////////////////////////////////////////////////////////

	}else if(protocol_id == 0x13){
		if(message_id == 0x00){ //protocol version
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x30000;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x01){ //protocol attributes
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x10001; //power consumption in mW, 1 perf domain
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0x0; //upper statistics address
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			response = 0x0; //lower statistics address
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);	

			response = 0x0; //length
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 16);	

			writew(8+4*4,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x03){ //performance domain attributes
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x40000000;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 1000; // minimum time between requests in usec
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);					

			response = 1; //sustained freq in kHz
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);		

			response = 0x1; //performance level corresponding to sustained freq
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 16);		

			response = 0x41;						
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 20);	

			writew(8+4*5,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);	
		}else if(message_id == 0x04){ //performance describe levels
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x3; //n of returned perf levels
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);

			response = 1;//performance level 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);		

			response = 1;//power cost
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);	

			response = 500;//transition latency in usec
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 16);	

			response = 2;//performance level 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 20);		

			response = 2;//power cost
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 24);	

			response = 500;//transition latency in usec
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 28);	

			response = 3;//performance level 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 32);		

			response = 3;//power cost
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 36);	

			response = 500;//transition latency in usec
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 40);	

			writew(8+4*10,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);	
		}else if(message_id == 0x07){ //perf level set
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			writew(8+4*0,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			ft = payload0;

			complete_msg(data, agent_id);	
		}else if(message_id == 0x08){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = ft;
			
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}			
//////////////////////////////////////////////////////////////////////////////////////////
//
//
//					PROTOCOL 0x14
//
//
//////////////////////////////////////////////////////////////////////////////////////////	
	}else if(protocol_id == 0x14){
		if(message_id == 0x00){ //protocol version
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x20000;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x01){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x10001;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x03){ 
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x01; //clock options, clock enable
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0x41; //ascii clock name
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			response = 1000; //clock latency to enable this clock in usec
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);	

			writew(8+4*3,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x04){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x1001; 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0; //lowest rate 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			response = 1000; //highest rate
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);
			
			response = 1000; //step size
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 16);	

			writew(8+4*4,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if(message_id == 0x06){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 1000; //lower 32 bit of physical rate in Hz
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0000; //upper 32 bit of physical rate in Hz
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			writew(8+4*2,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}		
//////////////////////////////////////////////////////////////////////////////////////////
//
//
//					PROTOCOL 0x11
//
//
//////////////////////////////////////////////////////////////////////////////////////////

	}else if(protocol_id == 0x11){
		if(message_id == 0x00){ //protocol version
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x30000;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}else if (message_id == 0x01){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x01; //n of power domains
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0x00; 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			response = 0x00; 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 12);	

			response = 0x00; 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 16);					

			writew(8+4*4,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		
		}else if (message_id == 0x03){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x40000000; //asynchronus support
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);	

			response = 0x41; 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			writew(8+4*2,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
			
		}else if (message_id == 0x05){
			response = SUCCESS;
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

			response = 0x00; //context is preserved, ON state 
			writew(response,
				MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 8);	

			writew(8+4*1,
				MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

			complete_msg(data, agent_id);
		}
	}else{
		response = -1;
		writew(response,
			MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET);

		response = 0x11;
		writew(response,
			MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET + 4);
		complete_msg(data, agent_id);
	}			
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

	printf("test csr accesses\r\n");
	uint32_t thresh = 0xffaa;
	uint32_t cmp = 0;
	csr_write(CSR_MINTTHRESH, thresh);
	cmp = csr_read(CSR_MINTTHRESH);
	csr_write(CSR_MINTTHRESH, 0);	/* reset threshold */
	assert(cmp == (thresh & 0xff)); /* only lower 8 bits are writable */


	/* redirect vector table to our custom one */
	printf("set up vector table\r\n");
	clic_setup_mtvec();
	clic_setup_mtvt();

	/* enable selective hardware vectoring */
	// printf("set shv\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(INTR_ID));

	/* set trigger type to edge-triggered */
	// printf("set trigger type: edge-triggered\n");
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
		       readw(CLIC_BASE_ADDR +
			     CLIC_CLICINTATTR_REG_OFFSET(INTR_ID)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(INTR_ID));

	/* set number of bits for level encoding:
	 * nlbits
	 */
	// printf("set nlbits\n");
	writeb((0x4 << CLIC_CLICCFG_NLBITS_OFFSET),
	       CLIC_BASE_ADDR + CLIC_CLICCFG_REG_OFFSET);

	/* set interrupt level and priority*/
	// printf("set interrupt priority and level\n");
	writew(0xaa, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(INTR_ID));

	/* raise interrupt threshold to max and check that the interrupt doesn't
	 * fire yet */
	// printf("raise interrupt threshold to max (no interrupt should happen)\n");
	csr_write(CSR_MINTTHRESH, 0xff); /* 0xff > 0xaa */
	clic_isr_hook[0] = exit_fail; /* if we take an interrupt then we failed */

	// printf("enable interrupt\n");

	// int *timestamp1 = (int *)(DRAM_BASE_ADDR);
	
	/* enable interrupt globally */
	irq_clint_global_enable();

	ft = 1;
	/* enable interrupt on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(INTR_ID));

	// printf("lower interrupt threshold\n");
	clic_isr_hook[0] = exit_success;
	csr_write(CSR_MINTTHRESH, 0); /* 0 < 0xaa */


    for(volatile int i=0; i < 1000000; i++); //---------------------------REMOVE THIS LINE IF IT IS NOT A SIMULATION
	while(1);
	

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
	// printf("error: application malloc failed\n\r");
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
	// printf("error: stack overflow\n\r");
	__asm volatile("ebreak");
	for (;;)
		;
}

void vApplicationTickHook(void)
{
}

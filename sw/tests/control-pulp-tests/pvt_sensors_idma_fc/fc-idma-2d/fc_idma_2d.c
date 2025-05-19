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
*
* Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>
*/
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include "pulp.h"
#include <stdio.h>

#define VERBOSE

L2_DATA static uint32_t loc[AXI_N_SAMPLES];

#define TCDM_DATA_ADDR ((unsigned int)loc)

#define assert(expression)                                                     \
	do {                                                                   \
		if (!expression) {                                             \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

/* probe address range "samples" time, evenly spaced */
void probe_range(uintptr_t from, uintptr_t to, unsigned int samples)
{
	volatile unsigned int id;
	assert(samples > 0);
	assert(to > from);

	unsigned int error = 0;
	uintptr_t incr = 400; // 4 bytes * 100 locations
	uintptr_t addr = from + incr * ((uintptr_t)samples);
	
	uintptr_t tcdm_addr =
		((uintptr_t)TCDM_DATA_ADDR);
	uint32_t expected;
	uint32_t read;
	unsigned int get_time0 = 0;
	unsigned int get_time1 = 0;

        printf("Writing to external addresses by means of AXI port\n");

	for (unsigned int i = 0; i < samples; i++) {

		expected = ((uint32_t)0xcafedead) + ((uint32_t)i);
		*(volatile uint32_t *)addr = expected;
		read = *(volatile uint32_t *)addr;
		// printf("writing at %p, data[%d] = %.8x\n",
		// addr,i,read);
		if (read != expected) {
			printf("Error!!! Write: %.8x, expected: %.8x, address: %p, Index: %d \n ",
			       read, expected, addr, i);
			error++;
		}
		addr += incr;
	}

	addr = from + incr * ((uintptr_t)samples);

	printf("Reading back data using DMA (2D), core samples = %d\n",
	       samples);
	reset_timer();
	// printf("CORE %d: Total read clock cycles (after reset timer)
	// = %d\n", ((unsigned int)get_core_id()), get_time());
	start_timer();

	unsigned int dma_rx_id = pulp_fc_idma_memcpy_2d( 
		(unsigned int)(tcdm_addr), ((unsigned int)addr), 4,
		(unsigned short int)4, (unsigned short int)incr,
		(unsigned short int)samples * 4);
	//plp_dma_wait(dma_rx_id);

	stop_timer();
	printf("Total read clock cycles (after stop timer) = %d\n", get_time());

	for (int i = 0; i < samples; i++) {
		read = 0;
		expected = ((uint32_t)0xcafedead) + ((uint32_t)i);
		// printf("read at %p, before = %.8x, expected =
		// %.8x\n",(uint32_t*)(tcdm_addr +
		// i*4),read,i,expected);
		read = *(uint32_t *)(tcdm_addr + i * 4);
		if (expected != read) {
			printf("Error!!! Read: %.8x, Test:%.8x, Index: %d \n ",
			       read, expected, i);
			error++;
		}
		// printf("read after = %.8x, expected =
		// %.8x\n",read,expected);
	}

	if (error == 0) {
		printf("TEST SUCCESS\n");
		exit(0);
	} else {
		printf("TEST FAIL\n");
		exit(1);
	}

	// printf("fc dma programming execution time = %d\n",
	// get_time1-get_time0);
}

int main(void)
{
        int error = 0;
	int core_id;

	volatile uint32_t *ext_base_addr = (uint32_t *)0x20000000;
	volatile uint32_t *ext_end_addr = (uint32_t *)0x20200000;

	probe_range((uintptr_t)ext_base_addr, (uintptr_t)ext_end_addr,
		    (unsigned int)AXI_N_SAMPLES);
	return 0;
}

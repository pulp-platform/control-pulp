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

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "pulp.h"


/* quickly scan the given address range with AXI_N_SAMPLES */
//#ifndef AXI_N_SAMPLES
//#    define AXI_N_SAMPLES 80
//#endif

L2_DATA static uint32_t ext[AXI_N_SAMPLES];
L1_DATA static uint32_t loc[AXI_N_SAMPLES];

#define EXT_DATA_ADDR  ((unsigned int)ext)
#define TCDM_DATA_ADDR ((unsigned int)loc)

#define assert(expression)                                                     \
	do {                                                                   \
		if (!expression) {                                             \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

/* Number of cores */
#ifndef NUM_CORES
#error "NUM_CORES must be defined"
#endif

/* probe address range "samples" time, evenly spaced */
void probe_range(uintptr_t from, uintptr_t to, int samples)
{

	assert(samples > 0);
	assert(to > from);

	// Divide the number of all samples by the number of available cores
	unsigned int core_samples = samples / ((unsigned int)NUM_CORES);
	unsigned int error = 0;
	uintptr_t incr = 400; // 4 bytes * 100 locations
	uintptr_t addr = from + incr * ((uintptr_t)core_samples) *
					((uintptr_t)get_core_id());
	uintptr_t tcdm_addr =
		((uintptr_t)TCDM_DATA_ADDR) +
		4 * ((uintptr_t)core_samples) * ((uintptr_t)get_core_id());
	uint32_t expected;
	uint32_t axi_read;

	if (((unsigned int)get_core_id()) < NUM_CORES) {

		printf("Writing to external addresses by means of AXI port\n");

		for (unsigned int i =
			     ((unsigned int)get_core_id()) * core_samples;
		     i < (((unsigned int)get_core_id()) + 1) * core_samples;
		     i++) {

			expected = ((uint32_t)0xcafedead) + ((uint32_t)i);
			*(volatile uint32_t *)addr = expected;
			axi_read = *(volatile uint32_t *)addr;
			// printf("writing at %p, data[%d] = %.8x\n",
			// addr,i,axi_read);
			if (axi_read != expected) {
				printf("Error!!! Write: %.8x, expected: %.8x, Index: %d \n ",
				       axi_read, expected, i);
				error++;
			}
			addr += incr;
		}

		addr = from +
		       incr * ((uintptr_t)core_samples) *
			       ((uintptr_t)((unsigned int)get_core_id()));
	}

	synch_barrier();

	if (((unsigned int)get_core_id()) == 0) {
		printf("Reading back data\n");
		reset_timer();
		// printf("CORE %d: Total read clock cycles (after reset timer)
		// = %d\n", ((unsigned int)get_core_id()), get_time());
		start_timer();
	}

	synch_barrier();

	if (((unsigned int)get_core_id()) < ((unsigned int)NUM_CORES)) {

		for (unsigned int i = 0; i < core_samples; i++) {
			*(uint32_t *)(tcdm_addr + i * 4) =
				*(volatile uint32_t *)addr;
			addr += incr;
		}
	}

	synch_barrier();

	if (((unsigned int)get_core_id()) == 0) {
		stop_timer();
		printf("CORE %d: Total read clock cycles (after stop timer) = %d\n",
		       ((unsigned int)get_core_id()), get_time());
	}

	if (((unsigned int)get_core_id()) == 0) {

		for (int i = 0; i < core_samples * ((unsigned int)NUM_CORES);
		     i++) {
			axi_read = 0;
			expected = ((uint32_t)0xcafedead) + ((uint32_t)i);
			// printf("read at %p, before = %.8x, expected =
			// %.8x\n",(uint32_t*)(tcdm_addr +
			// i*4),axi_read,expected);
			axi_read = *(uint32_t *)(tcdm_addr + i * 4);
			if (expected != axi_read) {
				printf("Error!!! Read: %.8x, Test:%.8x, Index: %d \n ",
				       axi_read, expected, i);
				error++;
			}
			// printf("read after = %.8x, expected =
			// %.8x\n",axi_read,expected);
		}

		if (error == 0)
			printf("TEST SUCCESS\n");
		else {
			printf("TEST FAIL\n");
			exit(1);
		}
	}
}


int main(void)
{
	if (rt_cluster_id() != 0) {
		return bench_cluster_forward(0);
	} else {

		int error = 0;
		int core_id;

		volatile uint32_t *ext_base_addr = (uint32_t *)0x20000000;
		volatile uint32_t *ext_end_addr = (uint32_t *)0x20200000;

		core_id = (int)get_core_id();

		probe_range((uintptr_t)ext_base_addr, (uintptr_t)ext_end_addr,
			    (unsigned int)AXI_N_SAMPLES);

		if (get_core_id() == 0) {

			printf("done\n");
		}
	}
	return 0;
}

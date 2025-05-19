/*
 * Copyright (C) 2021 ETH Zurich and University of Bologna
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
 */

#include <math.h>
#include "pulp.h"
#include <stdio.h>

#define MAX_BUFFER_SIZE 0x400

L2_DATA static unsigned char loc[MAX_BUFFER_SIZE * 8];

#define TCDM_DATA_ADDR ((unsigned int)loc)

int test_idma(uint32_t src_addr, uint32_t dst_addr,
	      unsigned int num_bytes);

int main()
{
	int error_count = 0;
	volatile uint32_t *ext    = (uint32_t *)0x20000000;

#ifdef VERBOSE
	printf("Sensor dma basic test\n");
#endif
	for (int i = 1; i < MAX_BUFFER_SIZE; i = 2 * i) {
		error_count +=
		    test_idma(ext,
				  TCDM_DATA_ADDR,
				  i);
	}
	for (int i = 1; i < MAX_BUFFER_SIZE; i = 2 * i) {
		error_count +=
		    test_idma(TCDM_DATA_ADDR,
				  ext,
				  i);
	}

	return error_count;
}

int test_idma(uint32_t src_addr, uint32_t dst_addr,
	      unsigned int num_bytes)
{

#ifdef VERBOSE
	printf("STARTING TEST FOR %d TRANSFERS FROM %p TO %p\n", num_bytes,
	       src_addr, dst_addr);
#endif

	for (int i = 0; i < num_bytes; i++) {
		pulp_write32((unsigned char *)src_addr + i, i & 0xFF);
	}

	for (int i = 0; i < num_bytes + 16; i++) {
		pulp_write32((unsigned char *)dst_addr + i, 0);
	}

	unsigned int dma_tx_id =
	      pulp_fc_idma_memcpy(dst_addr, src_addr, num_bytes);

	//plp_fc_dma_wait(dma_tx_id);

	unsigned int test, read;
	unsigned int error = 0;

	for (int i = 0; i < num_bytes; i++) {
		test = i & 0xFF;
		read = *(volatile unsigned char *)(dst_addr + i);
		if (test != read) {
			printf("Error!!! Read: %x, Test:%x, Index: %d \n ",
			       read, test, i);
			error++;
		}
	}

	for (int i = num_bytes; i < num_bytes + 16; i++) {

		test = 0;
		read = pulp_read8((unsigned char *)(dst_addr + i));

		if (test != read) {
			printf("Error!!! Read: %x, Test:%x, Index: %d \n ",
			       read, test, i);
			error++;
		}
	}

	if (get_core_id() == 0) {
		if (error == 0)
			printf("Test OK\n");
		else
			printf("Test not OK\n");
	}

	return error;
}

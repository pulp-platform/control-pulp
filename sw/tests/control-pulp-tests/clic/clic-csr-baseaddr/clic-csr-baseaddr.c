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
 * Author: Diyou Shen (dishen@student.ethz.ch)
 */

/* 
 * Test whether we can access read only CLIC MCLICBASE CSR.
 * This base address can be configrued in fc_subsystem.sv when instantiate the 
 * cv32e40p_wapper/cv32e40p_core module.
 *    
 * This test file is possible to be merged into the clic-csr test.  
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "pulp.h"
#include "csr.h"
#include "io.h"

#include "clic.h"

#define assert(expression)                                                     \
	do {                                                                   \
		if (!(expression)) {                                           \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

int main(void)
{
	uint32_t mclicbase;

	printf("\ntest CSR_MCLICBASE\n");
	/* read the CLIC memory mapped registers' base address */ 
	mclicbase = csr_read(CSR_MCLICBASE); 
    printf("the readed CSR value is: %lx\n", mclicbase);
	assert(mclicbase == 0x1a200000); /* the address for the current implementation is 1A20_0000 */

	return 0;
}

/*
 * Copyright 2022 ETH Zurich
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

/* Test if we can access shadow csrs */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

#include "pulp.h"
#include "csr.h"
#include "io.h"

#include "clic.h"
#include "mem.h"
#include "utils.h"

void clic_setup_mtvec(void);
void clic_setup_mtvt(void);

void (*clic_isr_hook[1])(void);

/* need void functions for isr table entries */
void exit_success(void)
{
	register void *sp asm("sp");
	printf("dumping stack at %p ...\n", sp);
	for (int i = 0; i < 32; i++) {
		printf("%p: 0x%08" PRIx32 "\n", sp, *((volatile uint32_t *)sp));
		sp += 4;
	}
	exit(0);
}

void exit_fail(void)
{
	exit(1);
}

int main(void)
{
	printf("test shadow saving mode csr\n");
	/* can enable disable */
	uint32_t reg = 0;
	csr_write(CSR_MSHWINT, 0x1);
	reg = csr_read(CSR_MSHWINT);
	assert(reg == 1);

	csr_write(CSR_MSHWINT, 0x0);
	reg = csr_read(CSR_MSHWINT);
	assert(reg == 0);

	/* check whether there are 3 config bits */
	csr_write(CSR_MSHWINT, 0xffffffff);
	reg = csr_read(CSR_MSHWINT);
	assert(reg = 0x7);

	return 0;
}

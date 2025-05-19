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

/* Test if two pending interrupts are handled correctly. Second has lower
 * priority (i.e. doens't preempt) */

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
	/* redirect vector table to our custom one */
	clic_setup_mtvec();
	clic_setup_mtvt();

	printf("configure irq 31: shv, edge-triggred, nlbits, prio and level, enable\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(31));
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
		       readw(CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(31)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(31));
	writeb((0x4 << CLIC_CLICCFG_NLBITS_OFFSET),
	       CLIC_BASE_ADDR + CLIC_CLICCFG_REG_OFFSET);
	/* priority and level */
	writew(0xaa, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(31));
	/* enable interrupt 31 on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(31));

	printf("configure irq 30: shv, edge-triggred, nlbits, prio and level, enable\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32));
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
		       readw(CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32));
	writeb((0x4 << CLIC_CLICCFG_NLBITS_OFFSET),
	       CLIC_BASE_ADDR + CLIC_CLICCFG_REG_OFFSET);
	/* priority and level */
	writew(0xaa, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(32));
	/* enable interrupt 32 on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(32));

	/* raise interrupt threshold to max and check that the interrupt doesn't
	 * fire yet */
	csr_write(CSR_MINTTHRESH, 0xff); /* 0xff > 0xaa */
	clic_isr_hook[0] = exit_fail; /* if we take an interrupt then we failed
				       */
	printf("enable shadow saving mode\n");
	csr_write(CSR_MSHWINT, 0x1);

	register void *sp asm("sp");
	printf("stack pointer is %p\n", sp);

	/* no interrupt should happen */
	for (volatile int i = 0; i < 10000; i++)
		;

	printf("lower interrupt threshold (interrupt should happen)\n");
	clic_isr_hook[0] = exit_success;
	csr_write(CSR_MINTTHRESH, 0); /* 0 < 0xaa */

	/* pend irq31 via SW by writing to clicintip31 */
	printf("set irq31 pending: set clicintip31 bit\n");
	writeb(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIP_REG_OFFSET(31));

	for (volatile int i = 0; i < 10000; i++)
		;

	printf("Interrupt took too long\n");

	return 1;
}

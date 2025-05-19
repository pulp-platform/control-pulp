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
 * Author: Alessandro Ottaviano (aottaviano@iis.ee.ethz.ch)
 */

/* Test level/priority semantic
 * irq_1: L1, P1, ip1, ie1
 * irq_2: L2, P2, ip2, ie2
 * case 1: if (ip1 && ie1) && ~(ip2 && ie2), irq1 fires level/prio agnostic
 * case 2: if (ip1 && ie1) && (ip2 && ie2) && L1 > L2, irq_1 fires
 * case 3: if (ip1 && ie1) && (ip2 && ie2) && L1 == L2 && P1 > P2, irq_1 fires
 * case 4: if (ip1 && ie1) && (ip2 && ie2) && L1 == L2 && P1 == P2, higest
 irq_id interrupt fires

 * NOTE: The test **requires** tb_irq_axiboot.sv as a testbench

 */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

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

#define CLIC_BASE_ADDR 0x1A200000
#define CLIC_END_ADDR  0x1A20FFFF

void clic_setup_mtvec(void);
void clic_setup_mtvt(void);

static bool interrupt_happened = false;

/* some handlers we use to test */
__attribute__((interrupt("machine"))) void inline_handler(void)
{
	for (volatile int i = 0; i < 10; i++)
		;
}

__attribute__((noinline)) void dummy_loop()
{
	for (volatile int i = 0; i < 10; i++)
		;
}

__attribute__((interrupt("machine"))) void c_handler(void)
{
	dummy_loop();
}

static void print_clic_csr_state(void)
{
	uint32_t mcause = csr_read(CSR_MCAUSE);
	uint32_t mintstatus = csr_read(CSR_MINTSTATUS);
	printf("mcause:      %08lx\n", mcause);
	printf("  interrupt: %ld\n", mcause >> 31 & 1);
	printf("  minhv    : %ld\n", mcause >> 30 & 1);
	printf("  mpp      : %ld\n", mcause >> 28 & 3);
	printf("  mpie     : %ld\n", mcause >> 27 & 1);
	printf("  mpil     : %02lx\n", mcause >> 16 & 0xff);
	printf("  excode   : %03lx\n", mcause & 0xfff);
	printf("mintthresh:  %08lx\n", csr_read(CSR_MINTTHRESH));
	printf("mintstatus:  %08lx\n", mintstatus);
	printf("  mil      : %02lx\n", mintstatus >> 24 & 0xff);
}

__attribute__((interrupt("machine"))) void check_status_handler(void)
{
	printf("CLIC CSR STATE DURING INTERRUPT\n");
	print_clic_csr_state();
	interrupt_happened = true;
}

void irq_level_prio_setup(uint32_t lp_1, uint32_t lp_2)
{

	/* set interrupt level and priority for interrupt 33 */
	printf("set interrupt 33 priority and level\n");
	writew(lp_1, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(33));

	/* set interrupt level and priority for interrupt 32 */
	printf("set interrupt 32 priority and level\n");
	writew(lp_2, CLIC_BASE_ADDR + CLIC_CLICINTCTL_REG_OFFSET(32));
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

	uint32_t mintstatus_before;
	uint32_t mintstatus_after;

	/* redirect vector table to our custom one */
	printf("set up vector table\n");
	clic_setup_mtvec();
	clic_setup_mtvt();

	/* enable selective hardware vectoring */
	printf("set shv for irq32\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32));

	/* enable selective hardware vectoring */
	printf("set shv for irq33\n");
	writew((0x1 << CLIC_CLICINTATTR_SHV_BIT),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(33));


#ifdef PENDING_PRECEDENCE

	/* set trigger type to edge-triggered */
	printf("set trigger type: edge-triggered\n");
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
	       readw(CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(32));

	/* enable irq32 via SW by writing to clicintip32 */
	printf("enable irq32: set clicintip32 bit\n");
	writeb(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIP_REG_OFFSET(32));

	/* set trigger type to edge-triggered */
	printf("set trigger type: edge-triggered\n");
	writeb((0x1 << CLIC_CLICINTATTR_TRIG_OFFSET) |
	       readw(CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(33)),
	       CLIC_BASE_ADDR + CLIC_CLICINTATTR_REG_OFFSET(33));

	/* enable irq33 via SW by writing to clicintip31 */
	printf("enable irq33: set clicintip33 bit\n");
	writeb(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIP_REG_OFFSET(33));

#endif

	/* set number of bits for level encoding:
	 * nlbits
	 */

	printf("set nlbits\n");
	writeb((0x4 << CLIC_CLICCFG_NLBITS_OFFSET),
	       CLIC_BASE_ADDR + CLIC_CLICCFG_REG_OFFSET);

#ifdef PENDING_PRECEDENCE
	irq_level_prio_setup(0x88, 0xaa); // first pending && enabled interrupt
					  // fires
#endif

#if SAME_LEVEL
#if SAME_PRIO
	irq_level_prio_setup(0x88, 0x88); // L1 == L2, P1 == P2, irq_id
					  // determines firing
#else
	irq_level_prio_setup(0x8a, 0x88); // L1 == L2, P1 > P2, irq_1 fires
#endif
#else
	irq_level_prio_setup(0xaa, 0x88); // L1 > L2, irq_1 fires
#endif

	/* raise interrupt threshold to max and check that the interrupt doesn't
	 * fire yet */
	printf("raise interrupt threshold to max (no interrupt should happen)\n");
	csr_write(CSR_MINTTHRESH, 0xff);

	printf("enable interrupt 33: set clicintie33\n");
	/* enable interrupt 33 on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(33));

	printf("enable interrupt 32: set clicintie32\n");
	/* enable interrupt 32 on clic */
	writew(0x1, CLIC_BASE_ADDR + CLIC_CLICINTIE_REG_OFFSET(32));

#ifndef PENDING_PRECEDENCE
	// Test-only: signal that irq lines can be set from external
	volatile uint32_t *db_addr = (uint32_t *)0x20000000;
	*(volatile uint32_t *)db_addr = 1;
#endif

	// no interrupt should happen
	for (volatile int i = 0; i < 1000; i++)
		;

	printf("lower interrupt threshold (interrupt should happen)\n");
	csr_write(CSR_MINTTHRESH, 0); /* 0 < 0xaa */

	/* check that handler toggled flag and that we are in a good state */
	assert(interrupt_happened);

	/* raise interrupt threshold to max to prevent interrupts to fire
	 * further*/
	printf("raise interrupt threshold to max (no interrupt should happen)\n");
	csr_write(CSR_MINTTHRESH, 0xff);

	return 0;
}

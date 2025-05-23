/*
* Copyright 2021 ETH Zurich
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
* Author: Robert Balas (balasr@iis.ee.ethz.ch)
*/

#include "clic.h"

.section .text.int
.balign 8 /* probably not needed */

/* TODO: consider __riscv_32e */
/* regular integer abi */
.global __handle_clic_int
.func
__handle_clic_int:
	addi sp, sp, -(4 * 16)
	sw ra, 0(sp)
	sw t0, 4(sp)
	sw t1, 8(sp)
	sw t2, 12(sp)
	sw a0, 16(sp)
	sw a1, 20(sp)
	sw a2, 24(sp)
	sw a3, 28(sp)
	sw a4, 32(sp)
	sw a5, 36(sp)
	sw a6, 40(sp)
	sw a7, 44(sp)
	sw t3, 48(sp)
	sw t4, 52(sp)
	sw t5, 56(sp)
	sw t6, 60(sp)

	la   t0, clic_isr_hook
	lw   t0, 0(t0) /* load function pointer */

	jalr t0 /* vector into hook */

	/* TODO: write to completion register */

	lw ra, 0(sp)
	lw t0, 4(sp)
	lw t1, 8(sp)
	lw t2, 12(sp)
	lw a0, 16(sp)
	lw a1, 20(sp)
	lw a2, 24(sp)
	lw a3, 28(sp)
	lw a4, 32(sp)
	lw a5, 36(sp)
	lw a6, 40(sp)
	lw a7, 44(sp)
	lw t3, 48(sp)
	lw t4, 52(sp)
	lw t5, 56(sp)
	lw t6, 60(sp)
	addi sp, sp, (4 * 16)
	mret

.section .text.int
.global clic_setup_mtvec
.type clic_setup_mtvec,@function
clic_setup_mtvec:
	la t0, __clic_vector_table
	or t0, t0, 1 /* enable vectored mode TODO: should be clic mode */
	csrw mtvec, t0
	ret

.section .text.int
.global clic_setup_mtvt
.type clic_setup_mtvt,@function
clic_setup_mtvt:
	la t0, __clic_vector_table
	or t0, t0, 1 /* enable vectored mode TODO: should be clic mode */
	csrw 0x307, t0 /* mtvt=0x307 */
	ret

.section .text.vectors
default_exception_handler:
	j default_exception_handler
software_handler:
	j software_handler
timer_handler:
	j timer_handler
external_handler:
	j external_handler
__no_irq_handler:
	j __no_irq_handler

.section .text.vectors
.option norvc
.balign 1024
.global __clic_vector_table

__clic_vector_table: //up to id 107 
	j default_exception_handler
	j __no_irq_handler
	j __no_irq_handler
	j software_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j timer_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j external_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __no_irq_handler
	j __handle_clic_int


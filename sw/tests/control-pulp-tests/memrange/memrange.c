/*
 * Copyright 2020 ETH Zurich
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

/* test L2 address range by issuing systematic read/writes with random data */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "pulp.h"

#define assert(expression)                                                     \
	do {                                                                   \
		if (!expression) {                                             \
			printf("%s:%d: assert error\n", __FILE__, __LINE__);   \
			exit(1);                                               \
		}                                                              \
	} while (0)

/* simple linear congruent random number generator */
int random(int seed)
{
	int m = 2147483648;
	int a = 1103515245;
	int c = 12345;
	return (a * seed + c) % m;
}

int main(void)
{
	uintptr_t l2_base_addr = 0x1c000000;
	/* we try to roughly skip the .text and .data section. The smart and
	 * correct way would be to refer to a linker script defined variable */
	l2_base_addr += 0x10000;
	uintptr_t l2_end_addr = 0x1c080000;
	int iv = 0xdeadbeef;
	int seed = iv;

	/* write memory range */
	for (uintptr_t addr = l2_base_addr; addr < l2_end_addr; addr += 1024) {
		*((volatile uint32_t *)addr) = seed;
#ifndef NDEBUG
		printf("Wrote %08x at %08x\n", seed, addr);
#endif
		seed = random(seed);
	}

	/* read memory range and check */
	seed = iv;
	for (uintptr_t addr = l2_base_addr; addr < l2_end_addr; addr += 1024) {
		uint32_t val = *((volatile uint32_t *)addr);
		assert(val == seed);
#ifndef NDEBUG
		printf("Read %08x at %08x\n", val, addr);
#endif
		seed = random(seed);
	}

	printf("done\n");
	return 0;
}

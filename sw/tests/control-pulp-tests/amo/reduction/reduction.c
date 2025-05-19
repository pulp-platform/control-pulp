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

/* Test basic functionality of the clic (peripheral and core side). Especially
 * check if the interrupt thresholding works. */

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "pulp.h"

L1_DATA thread_sum[8] = {0};
L1_DATA red = 0;

static inline unsigned amo_add(void volatile *const address, unsigned value)
{
	unsigned ret;
	__asm__ __volatile__("" : : : "memory");
	asm volatile("amoadd.w  %0, %1, (%2)"
		     : "=r"(ret)
		     : "r"(value), "r"(address));
	__asm__ __volatile__("" : : : "memory");
	return ret;
}

int main(void)
{
	int s = 9;
	int ret;
	int golden_red = s * 8;
	int coreid = rt_core_id();

	if (rt_cluster_id() != 0) {
		return bench_cluster_forward(0);
	}

	// reduction, i.e. sum the values from each core into a shared variable
	// atomically

#ifdef AMO
	// Each core atomically adds up to red
	amo_add(&red, s);

	synch_barrier();

	if (coreid == 0) {
		printf("Reduction sum, AMO: %d\n", red);
		if (red == golden_red)
			ret = 0;
		else
			ret = 1;
	}
#else
	// each core has to fill an element of an array
	thread_sum[coreid] += s;

	// master core then sums it up
	if (coreid == 0) {
		for (int i = 0; i < 8; i++) {
			red += thread_sum[i];
		}
		printf("Reduction sum: %d\n", red);
		if (red == golden_red)
			ret = 0;
		else
			ret = 1;
	}
#endif

	return ret;
}

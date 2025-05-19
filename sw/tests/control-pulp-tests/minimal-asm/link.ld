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
 *
 * SPDX-License-Identifier: Apache-2.0
 * Author: Robert Balas (balasr@iis.ee.ethz.ch)
 */

OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY
{
  L2           : ORIGIN = 0x1c000004, LENGTH = 0x0007fffc
  L2_aliased   : ORIGIN = 0x00000004, LENGTH = 0x00003ffc
  L1           : ORIGIN = 0x10000004, LENGTH = 0x0000fffc
  L1_aliased   : ORIGIN = 0x00000004, LENGTH = 0x0000fffc
}

/*
 * This linker script try to put FC data in L2 private bank0 and FC code
 * in L2 private bank1 to avoid contention between FC code and data
 * as FC has no instruction cache and is so often accessing L2 to
 * get instructions. Everything can be shifted in case one bank is full.
 *
 * Cluster code and initialized data are put in shared banks to not polute
 * private banks which are quite small, and also avoid contentions between
 * cluster cache refill and FC.
 */


SECTIONS
{

  PROVIDE(__boot_address = 0x1c000880);
  /* stack and heap related settings */
  __stack_size = DEFINED(__stack_size) ? __stack_size : 0x4;
  PROVIDE(__stack_size = __stack_size);

  .vectors MAX(0x1c000800, ALIGN(256)) : /* lets leak the first 2k free for now "half zero page" */
  {
    __irq_vector_base = .;
    __vector_start = .;
    KEEP(*(.vectors))
  } > L2

  /* private bank0 */
  .text __boot_address :
  {
    _stext = .;
    *(.text.start)
    *(.text)
    *(.text.*)
    _etext = .; /* man 3 end: first addr after text */
    *(.lit)
    *(.shdata)
    _endtext = .;
    . = ALIGN(4);
  } > L2

  /* private bank1 */
  /* make sure we start filling fc data into the correct bank */
  /* read-only sections */
  .rodata MAX(0x1c008000, ALIGN(4)) :
  {
    *(.rodata .rodata.* .gnu.linkonce.r.*)
  } > L2
  .rodata1        :
  {
    *(.rodata1)
  } > L2

  .data : ALIGN(4)
  {
    sdata  =  .;
    _sdata  =  .;
    __data_begin = .;
    *(.data_fc)
    *(.data_fc.*)
    *(.data);
    *(.data.*)
    __sdata_begin = .;
    *(.sdata);
    *(.sdata.*)
    *(.sdata2.*) /* FreeRTOS xISRStackTop, __global_impure_ptr */
    *(.heapl2ram)
    *(.fcTcdm)
    *(.fcTcdm.*)
    *(.fcTcdm_g)
    *(.fcTcdm_g.*)
    . = ALIGN(4);
    edata  =  .;
    _edata  =  .; /* man 3 end: first addr after data */
  } > L2

  .bss : ALIGN(8)
  {
    _bss_start = .;
    __bss_start = .;
    *(.shbss) /* don't even know where this is from */
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
    _bss_end = .;
    _end = .; /* man 3 end: first addr after bss */
  } > L2

  /* The compiler uses this to access data in the .sdata, .data, .sbss and .bss
     sections with fewer instructions (relaxation). This reduces code size. */
    PROVIDE(__global_pointer$ = MIN(__sdata_begin + 0x800,
			    MAX(__data_begin + 0x800, __bss_end - 0x800)));

  .stack : ALIGN(16)
  {
    stack_start = .;
    __stack_bottom = .;
    . += __stack_size;
    __stack_top = .;
    stack = .;
  } > L2


}

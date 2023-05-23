// Copyright (c) 2022 ETH Zurich and University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
//

#include "simple_system_common.h"
#include <stdbool.h>

int main(int argc, char **argv) {
  
  int volatile  * plic_prio, * plic_en;
  
  unsigned val_1 = 0x00001808;  // Set global interrupt enable in ibex regs
  unsigned val_2 = 0x00000800;  // Set external interrupts

  // Enabling ibex irqs 
  asm volatile("csrw  mstatus, %0\n" : : "r"(val_1)); 
  asm volatile("csrw  mie, %0\n"     : : "r"(val_2));

  // Enabling the interrupt controller and the mbox irq
  plic_prio  = (int *) 0x480001C0;  // Priority reg
  plic_en    = (int *) 0x4800030C;  // Enable reg

 *plic_prio  = 1;                   // Set mbox interrupt priority to 1
 *plic_en    = 0x00000010;          // Enable interrupt                       


  /////////////////////////// shared memory test start ///////////////////////////////

  while(1) asm volatile ("wfi"); // Ready to receive a command from the Agent --> Jump to the External_Irq_Handler 

  return 0;
  
}

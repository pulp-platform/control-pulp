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

void external_irq_handler(void)  {
   
  int mbox_id = 100;
  int a, b, c, e, d;
  int volatile * p_reg, * p_reg1, * p_reg2, * p_reg3, * p_reg4, * p_reg5, * plic_check;

  // Init pointer to check memory
  p_reg  = (int *) 0x50000004;
  p_reg1 = (int *) 0x50000008;
  p_reg2 = (int *) 0x50000010;
  p_reg3 = (int *) 0x50000014;
  p_reg4 = (int *) 0x50000018;
  p_reg5 = (int *) 0x5000001C;
  
  plic_check = (int *) 0x4800031C;
  while(*plic_check != mbox_id);   // Check wether the irq comes form the mbox
  
  p_reg = (int *) 0x50000020;
 *p_reg = 0x00000000;              // Clearing the pending irq
 
 *plic_check = mbox_id;            // Completing interrupt

  //////////////////////////// Memory test///////////////////////////////
 
  a = *p_reg1;
  b = *p_reg2;
  c = *p_reg3;
  d = *p_reg4;
  e = *p_reg5;
  
  
  if( a == 0xBAADC0DE && b == 0xBAADC0DE && c == 0xBAADC0DE && d == 0xBAADC0DE && e == 0xBAADC0DE){
      p_reg = (int *) 0x50000024; // completion interrupt to ariane agent
     *p_reg = 0x00000001;
  }
  else{
      sim_halt();
      }
  return;
}

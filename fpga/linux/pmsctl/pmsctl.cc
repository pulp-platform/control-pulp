// Copyright 2023 ETH Zurich and University of Bologna
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0
//
// Robert Balas <balasr@iis.ee.ethz.ch>
// Alessandro Ottaviano<aottaviano@iis.ee.ethz.ch>

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <bitset>

#include "physmem/inc/physmem.hpp"

int main() {

  PhysMem pulp_periph(0xA0000000, 0x1FFFFFF);
  PhysMem pulp_l2(0xA2000000, 0x3FFFFFF);

  // Things to control:

  // 0. reset fetch_enable/boot address
  // 1. select boot mode
  // 2. load L2
  // 3. write entry point to boot address
  // 4. assert fetch_enable

  // 1. reset fetch_enable/boot address/EOC reg

  //std::cout << "Reset fetch enable before starting \n";
  //// address: 1A10_4000 + 0x08 --> 1A10_4008 --> A0104008 from PS viewpoint (see ips/pulp_soc/rtl/components/apb_soc_ctrl.sv)
  //pulp_periph.write_u32(0xA0104008, 0x00000000);
  //// Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u32(0xA0104008) << "\n";
  //
  //std::cout << "Reset boot address before starting \n"; //<------ why not u64?? Says `bus error`
  //// address: 1A10_4000 + 0x04 --> 1A10_4004 --> A0104004 from PS viewpoint (see ips/pulp_soc/rtl/components/apb_soc_ctrl.sv)
  //pulp_periph.write_u64(0xA0104000, 0x0000000000000000); //<----- enables 64 bit write
  //// Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u32(0xA0104004) << "\n";
  //
  //std::cout << "Reset EOC register \n";
  //pulp_periph.write_u32(0xA01040A0, 0x00000000);
  //// Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u64(0xA01040A0) << "\n";

  // 1. select boot mode
  std::cout << "Select PRELOADED bootmode\n";
  // address: 1A10_4000 + 0x08 --> 1A10_4008 --> A0104008 from PS viewpoint (see ips/pulp_soc/rtl/components/apb_soc_ctrl.sv)
  pulp_periph.write_u32(0xA01040C4, 0x00000003);
  // Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u32(0xA0104008) << "\n";

  // 2. load L2
  std::cout << "Load L2 memory from stimuli file \n";

  
  std::string line;
  std::ifstream myfile;
  myfile.open("stim.txt");

  if(!myfile.is_open()) {
      perror("Error open");
      exit(EXIT_FAILURE);
  }

  while(getline(myfile, line)) {

    //std::cout << line  << "\n"; // print line
    std::string s_axi_addr32_pl   = line.substr(0, 8); //32 bit address
    std::string s_axi_data64      = line.substr(9); //64 bit data

    //std::cout << s_axi_addr32_pl << "\n";
    //std::cout << s_axi_data64 << "\n\n";

    //convert strings to hex
    std::stringstream buffer1;
    buffer1 << std::hex << s_axi_addr32_pl;
    std::uint32_t axi_addr32_pl;
    buffer1 >> axi_addr32_pl;
    //std::cout << axi_addr32_pl << "\n";

    std::stringstream buffer2;
    buffer2 << std::hex << s_axi_data64;
    std::uint64_t axi_data64;
    buffer2 >> axi_data64;
    //std::cout << axi_data64 << "\n\n";

    // Make address PS compliant
    std::uint32_t axi_pl_start_addr = 0x1a000000;
    std::uint32_t axi_ps_start_addr = 0xa0000000;
    std::uint32_t axi_addr32_ps;
    axi_addr32_ps = axi_addr32_pl + (axi_ps_start_addr - axi_pl_start_addr);
    //std::cout << axi_addr32_ps << "\n";

    // Write 64 bit instruction to L2
    pulp_l2.write_u64(axi_addr32_ps, axi_data64);
    // Read data back (check)
    //std::cout << std::hex << "0x" << pulp_l2.read_u64(axi_addr32_ps) << "\n\n";
  }

  std::cout << "Application loaded into L2\n";

  // 3. Entry point

  std::cout << "Write entry point into boot address \n"; //<------ why not u64?? Says `bus error`
  // address: 1A10_4000 + 0x04 --> 1A10_4004 --> A0104004 from PS viewpoint (see ips/pulp_soc/rtl/components/apb_soc_ctrl.sv)
  pulp_periph.write_u64(0xA0104000, 0x1C00088000000000); //freertos
  // Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u32(0xA0104004) << "\n";

  //std::cout << "Read data from status and EOC register \n";
  //std::cout << std::hex << "0x" << pulp_periph.read_u64(0xA01040A0) << "\n";

  // 4. Fetch enable

  std::cout << "Assert fetch enable\n";
  // address: 1A10_4000 + 0x08 --> 1A10_4008 --> A0104008 from PS viewpoint (see ips/pulp_soc/rtl/components/apb_soc_ctrl.sv)
  pulp_periph.write_u32(0xA0104008, 0x00000001);
  // Read data back (check)
  //std::cout << std::hex << "0x" << pulp_periph.read_u32(0xA0104008) << "\n";

  std::cout << "Application starts executing\n";

  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // Check if code executes correctly (comment if Firmware)

  // stop computation and exit
  std::uint64_t axi_data64_eoc = 0;
  std::uint64_t axi_data64_end;

  std::bitset<64> b_axi_data64(axi_data64_eoc);

  // the computation starts; wait for computation to end
  std::cout << "Waiting for end of computation (application body is running) \n";

  while(b_axi_data64[31] == 0) {
    axi_data64_end = pulp_periph.read_u64(0xA01040A0);
    //    std::cout << "Read data from status and EOC register \n";
    //std::cout << std::hex << "0x" << axi_data64_end << "\n";
    b_axi_data64 = std::bitset<64>(axi_data64_end);
    //    std::cout << "I am in while\n";
    //std::cout << b_axi_data64 << "\n";
  }

  if (axi_data64_end != 0) {
    std::cout << "Exit success \n";
  }
  else {
    std::cout << "Exit fail \n";
  }
  std::cout << "Received exit status core: " << std::hex << "0x" << axi_data64_end << "\n" ;

  std::cout << "End of application \n";

//  // Read from addresses
//  std::cout << "Read data from control_pulp memory \n";
//  std::cout << std::hex << "0x" << pulp_l2.read_u32(0xA2010C00) << "\n";
//
//  std::cout << "Read data from control_pulp memory \n";
//  std::cout << std::hex << "0x" << pulp_l2.read_u32(0xA2013800) << "\n";
//
//  std::cout << "Read data from control_pulp memory \n";
//  std::cout << std::hex << "0x" << pulp_l2.read_u32(0xA2019000) << "\n";

  return 0;
}

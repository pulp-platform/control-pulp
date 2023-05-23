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

/*Basic test to ring the doorbell interrupt line in scmi mailbox from ARM cores in Zynq Soc*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <bitset>

#include "physmem/inc/physmem.hpp"

int main() {
  std::cout << "Application started...\n";

  PhysMem scmi_mailbox(0xA6000000, 0x1FFFFFFF);

  std::uint32_t axi_ps_scmi_mailbox_doorbell_address;
  std::uint32_t axi_scmi_mailbox_payload;

  /*
  std::cout << "Writing flags\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x10;
  axi_scmi_mailbox_payload = 0x00000000;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );

  std::cout << "Writing length\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x14;
  axi_scmi_mailbox_payload = 0x00000008;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );

  std::cout << "Writing header\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x18;
  axi_scmi_mailbox_payload = 0x00004000;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );

  std::cout << "Writing payload\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x1c;
  axi_scmi_mailbox_payload = 0xCAFECAFE;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );

  std::cout << "Mark channel as busy\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x04;
  axi_scmi_mailbox_payload = 0x00000000;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );
  */

  std::cout << "Ring the doorbell\n";
  axi_ps_scmi_mailbox_doorbell_address = 0xA6000000 + 0x20;
  axi_scmi_mailbox_payload = 0x00000001;
  scmi_mailbox.write_u32( axi_ps_scmi_mailbox_doorbell_address, axi_scmi_mailbox_payload );

  return 0;
}

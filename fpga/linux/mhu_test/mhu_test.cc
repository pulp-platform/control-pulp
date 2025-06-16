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
/*Basic test to write to a specific address in the scmi mailbox from ARM cores in Zynq Soc*/


#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <bitset>
#include <cstdint>
#include "physmem/inc/physmem.hpp"

void printUsage(const char* programName) {
    std::cout << "Usage: " << programName << " <address_offset> <message_value>\n";
    std::cout << "  <address_offset>: Offset from base address 0xA6000000 (in hex without 0x prefix)\n";
    std::cout << "  <message_value>: Value to write to the address (in hex without 0x prefix)\n";
    std::cout << "Example: " << programName << " 20 00000001\n";
}

bool parseHexValue(const std::string& str, std::uint32_t& value) {
    std::istringstream iss(str);
    iss >> std::hex >> value;
    return !iss.fail();
}

int main(int argc, char* argv[]) {
    std::cout << "Application started...\n";
    
    // Check command line arguments
    if (argc != 3) {
        std::cout << "Error: Invalid number of arguments.\n";
        printUsage(argv[0]);
        return 1;
    }
    
    // Parse offset address and payload from arguments
    std::uint32_t offsetAddress;
    std::uint32_t payload;
    
    if (!parseHexValue(argv[1], offsetAddress)) {
        std::cout << "Error: Invalid address offset format. Use hex format without 0x prefix.\n";
        printUsage(argv[0]);
        return 1;
    }
    
    if (!parseHexValue(argv[2], payload)) {
        std::cout << "Error: Invalid message value format. Use hex format without 0x prefix.\n";
        printUsage(argv[0]);
        return 1;
    }
    
    // Base address of the SCMI mailbox
    const std::uint32_t baseAddress = 0xA6000000;
    
    // Map the physical memory
    PhysMem scmi_mailbox(baseAddress, 0x1FFFFFFF);
    
    // Calculate the absolute address
    std::uint32_t absoluteAddress = baseAddress + offsetAddress;
    
    std::cout << "Writing to address: 0x" << std::hex << absoluteAddress 
              << " (Base + 0x" << offsetAddress << ")\n";
    std::cout << "Writing value: 0x" << std::hex << payload << "\n";
    
    // Write the payload to the specified address
    scmi_mailbox.write_u32(absoluteAddress, payload);
    
    std::cout << "Write operation completed.\n";
    
    return 0;
}
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <bitset>
#include <cstdint>
#include <unistd.h> // For sysconf
#include "physmem/inc/physmem.hpp"

void printUsage(const char* programName) {
    std::cout << "Usage: " << programName << " <absolute_address> <message_value>\n";
    std::cout << "  <absolute_address>: Physical address to write to (in hex without 0x prefix)\n";
    std::cout << "  <message_value>: Value to write (in hex without 0x prefix)\n";
    std::cout << "Example: " << programName << " a6000020 00000001\n";
}

bool parseHexValue(const std::string& str, std::uint32_t& value) {
    std::istringstream iss(str);
    iss >> std::hex >> value;
    return !iss.fail();
}

int main(int argc, char* argv[]) {
    std::cout << "Application started...\n";

    if (argc != 3) {
        std::cout << "Error: Invalid number of arguments.\n";
        printUsage(argv[0]);
        return 1;
    }

    std::uint32_t absoluteAddress;
    std::uint32_t payload;

    if (!parseHexValue(argv[1], absoluteAddress)) {
        std::cout << "Error: Invalid address format. Use hex format without 0x prefix.\n";
        printUsage(argv[0]);
        return 1;
    }

    if (!parseHexValue(argv[2], payload)) {
        std::cout << "Error: Invalid message value format. Use hex format without 0x prefix.\n";
        printUsage(argv[0]);
        return 1;
    }

    // Get system page size (typically 4096 bytes)
    std::size_t pageSize = sysconf(_SC_PAGESIZE);
    std::uint32_t alignedBase = absoluteAddress & ~(pageSize - 1);
    std::uint32_t offsetInPage = absoluteAddress - alignedBase;

    std::cout << "Mapping physical address range aligned to page size.\n";
    std::cout << "  Aligned base address: 0x" << std::hex << alignedBase << "\n";
    std::cout << "  Offset in page:       0x" << std::hex << offsetInPage << "\n";

    // Map only one page for efficiency
    PhysMem physmem(alignedBase, pageSize);

    std::cout << "Writing value 0x" << std::hex << payload
              << " to physical address 0x" << absoluteAddress << "\n";

    // Write the payload
    physmem.write_u32(alignedBase + offsetInPage, payload);

    std::cout << "Write operation completed.\n";
    return 0;
}


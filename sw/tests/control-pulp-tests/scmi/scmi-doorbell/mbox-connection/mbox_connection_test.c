/*
* Copyright 2023 ETH Zurich and University of Bologna
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
*
*/

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "pulp.h"
#include "scmi.h"

#define MBOX_START_ADDRESS 0xFFFF0000

int main(void)
{
	int exit = 0;
	uint32_t channel_status, reserved2, channel_flags, length,
		message_header, message_payload;

	puts("Testing axi connection by accessing mailboxes and "
	     "reading values back\n");

	// write mailbox (shared memory area) fields

	// Channel status, 4B
	pulp_write32(MBOX_START_ADDRESS + SCMI_CHANNEL_STATUS_C0_REG_OFFSET,
		     0xBAADC0DE);

	// Reserved region, 4B
	pulp_write32(MBOX_START_ADDRESS + SCMI_RESERVED_2_C0_REG_OFFSET,
		     0xBAADC0DE);

	// Channel flags, 4B
	pulp_write32(MBOX_START_ADDRESS + SCMI_CHANNEL_FLAGS_C0_REG_OFFSET,
		     0xBAADC0DE);

	// Length, 4B
	pulp_write32(MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET, 0xBAADC0DE);

	// Message header, 4B
	pulp_write32(MBOX_START_ADDRESS + SCMI_MESSAGE_HEADER_C0_REG_OFFSET,
		     0xBAADC0DE);

	// Payload (assume 4B payload, byte legth is N from specs)
	pulp_write32(MBOX_START_ADDRESS + SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET,
		     0xBAADC0DE);

	// ring the doorbell
	printf("ringing the doorbell\n");
	pulp_write32(MBOX_START_ADDRESS + SCMI_DOORBELL_C0_REG_OFFSET,
		     0x00000001);

	// read from mailbox
	channel_status = pulp_read32(MBOX_START_ADDRESS +
				     SCMI_CHANNEL_STATUS_C0_REG_OFFSET);
	printf("channel_status: %lx\n", channel_status);


	reserved2 =
		pulp_read32(MBOX_START_ADDRESS + SCMI_RESERVED_2_C0_REG_OFFSET);

	channel_flags =
		pulp_read32(MBOX_START_ADDRESS + SCMI_CHANNEL_FLAGS_C0_REG_OFFSET);

	length = pulp_read32(MBOX_START_ADDRESS + SCMI_LENGTH_C0_REG_OFFSET);

	message_header = pulp_read32(MBOX_START_ADDRESS +
				     SCMI_MESSAGE_HEADER_C0_REG_OFFSET);

	message_payload = pulp_read32(MBOX_START_ADDRESS +
				      SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET);
	// check
	if ((channel_status == 0xBAADC0DE) && (reserved2 == 0xBAADC0DE) &&
	    (channel_flags == 0xBAADC0DE) && (length == 0xBAADC0DE) &&
	    (message_header == 0xBAADC0DE) && (message_payload == 0xBAADC0DE)) {
		exit = 0;
	} else {
		exit = 1;
	}
	return exit;
}

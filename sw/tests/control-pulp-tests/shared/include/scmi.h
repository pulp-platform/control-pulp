// Generated register defines for scmi

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _SCMI_REG_DEFS_
#define _SCMI_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define SCMI_PARAM_REG_WIDTH 32

// Reserved, must be 0
#define SCMI_RESERVED_1_C0_REG_OFFSET 0x0

// Indicates which entity has access to the Shared Memory
#define SCMI_CHANNEL_STATUS_C0_REG_OFFSET 0x4
#define SCMI_CHANNEL_STATUS_C0_CHANNEL_FREE_BIT 0
#define SCMI_CHANNEL_STATUS_C0_CHANNEL_ERROR_BIT 1
#define SCMI_CHANNEL_STATUS_C0_FIELD1_MASK 0x3fffffff
#define SCMI_CHANNEL_STATUS_C0_FIELD1_OFFSET 2
#define SCMI_CHANNEL_STATUS_C0_FIELD1_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_CHANNEL_STATUS_C0_FIELD1_MASK, .index = SCMI_CHANNEL_STATUS_C0_FIELD1_OFFSET })

// Reserved, implementation defined (32 bits over 64)
#define SCMI_RESERVED_2_C0_REG_OFFSET 0x8

// Reserved, implementation defined (32 bits over 64)
#define SCMI_RESERVED_3_C0_REG_OFFSET 0xc

// Defines wheter interrupts or polling is used for communication
#define SCMI_CHANNEL_FLAGS_C0_REG_OFFSET 0x10
#define SCMI_CHANNEL_FLAGS_C0_INTR_ENABLE_BIT 0
#define SCMI_CHANNEL_FLAGS_C0_FIELD1_MASK 0x7fffffff
#define SCMI_CHANNEL_FLAGS_C0_FIELD1_OFFSET 1
#define SCMI_CHANNEL_FLAGS_C0_FIELD1_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_CHANNEL_FLAGS_C0_FIELD1_MASK, .index = SCMI_CHANNEL_FLAGS_C0_FIELD1_OFFSET })

// Lenght of payload + header
#define SCMI_LENGTH_C0_REG_OFFSET 0x14

// Defines which commanad the message contains
#define SCMI_MESSAGE_HEADER_C0_REG_OFFSET 0x18
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_ID_MASK 0xff
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_ID_OFFSET 0
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_ID_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_MESSAGE_HEADER_C0_MESSAGE_ID_MASK, .index = SCMI_MESSAGE_HEADER_C0_MESSAGE_ID_OFFSET })
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_TYPE_MASK 0x3
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_TYPE_OFFSET 8
#define SCMI_MESSAGE_HEADER_C0_MESSAGE_TYPE_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_MESSAGE_HEADER_C0_MESSAGE_TYPE_MASK, .index = SCMI_MESSAGE_HEADER_C0_MESSAGE_TYPE_OFFSET })
#define SCMI_MESSAGE_HEADER_C0_PROTOCOL_ID_MASK 0xff
#define SCMI_MESSAGE_HEADER_C0_PROTOCOL_ID_OFFSET 10
#define SCMI_MESSAGE_HEADER_C0_PROTOCOL_ID_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_MESSAGE_HEADER_C0_PROTOCOL_ID_MASK, .index = SCMI_MESSAGE_HEADER_C0_PROTOCOL_ID_OFFSET })
#define SCMI_MESSAGE_HEADER_C0_TOKEN_MASK 0x3ff
#define SCMI_MESSAGE_HEADER_C0_TOKEN_OFFSET 18
#define SCMI_MESSAGE_HEADER_C0_TOKEN_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_MESSAGE_HEADER_C0_TOKEN_MASK, .index = SCMI_MESSAGE_HEADER_C0_TOKEN_OFFSET })
#define SCMI_MESSAGE_HEADER_C0_FIELD1_MASK 0xf
#define SCMI_MESSAGE_HEADER_C0_FIELD1_OFFSET 28
#define SCMI_MESSAGE_HEADER_C0_FIELD1_FIELD \
  ((bitfield_field32_t) { .mask = SCMI_MESSAGE_HEADER_C0_FIELD1_MASK, .index = SCMI_MESSAGE_HEADER_C0_FIELD1_OFFSET })

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_0_C0_REG_OFFSET 0x1c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_1_C0_REG_OFFSET 0x20

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_2_C0_REG_OFFSET 0x24

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_3_C0_REG_OFFSET 0x28

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_4_C0_REG_OFFSET 0x2c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_5_C0_REG_OFFSET 0x30

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_6_C0_REG_OFFSET 0x34

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_7_C0_REG_OFFSET 0x38

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_8_C0_REG_OFFSET 0x3c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_9_C0_REG_OFFSET 0x40

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_10_C0_REG_OFFSET 0x44

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_11_C0_REG_OFFSET 0x48

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_12_C0_REG_OFFSET 0x4c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_13_C0_REG_OFFSET 0x50

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_14_C0_REG_OFFSET 0x54

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_15_C0_REG_OFFSET 0x58

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_16_C0_REG_OFFSET 0x5c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_17_C0_REG_OFFSET 0x60

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_18_C0_REG_OFFSET 0x64

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_19_C0_REG_OFFSET 0x68

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_20_C0_REG_OFFSET 0x6c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_21_C0_REG_OFFSET 0x70

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_22_C0_REG_OFFSET 0x74

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_23_C0_REG_OFFSET 0x78

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_24_C0_REG_OFFSET 0x7c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_25_C0_REG_OFFSET 0x80

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_26_C0_REG_OFFSET 0x84

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_27_C0_REG_OFFSET 0x88

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_28_C0_REG_OFFSET 0x8c

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_29_C0_REG_OFFSET 0x90

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_30_C0_REG_OFFSET 0x94

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_31_C0_REG_OFFSET 0x98

// memory region dedicated to the parameters of the commands and their
// returns
#define SCMI_MESSAGE_PAYLOAD_32_C0_REG_OFFSET 0x9c

// Rapresents the interrupt to be raised towards the platform
#define SCMI_DOORBELL_C0_REG_OFFSET 0xa0

// Rapresent the interrupt the platform should raise when it finishes to
// execute the received command
#define SCMI_COMPLETION_INTERRUPT_C0_REG_OFFSET 0xa4

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _SCMI_REG_DEFS_
// End generated register defines for scmi
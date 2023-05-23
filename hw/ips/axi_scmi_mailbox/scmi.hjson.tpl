// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
<% import math %>\
# SCMI register template
# - src: Number of mailbox channels. Following is the memory layout of one channel.
{
  name: "scmi",
  clock_primary: "clk_i",
  bus_interfaces: [
        { protocol: "reg_iface", direction: "device"}
    ],
  regwidth: "32",
  registers: [
% for i in range(src):  
    { name: "Reserved_1_c${i}",
      desc: "Reserved, must be 0",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:0" }
      ],
    },
    { name: "Channel_Status_c${i}",
      desc: "Indicates which entity has access to the Shared Memory",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:2" },
        { bits: "1",
          name: "channel_error",
          desc: "Must be 0 in absence of errors"
        },
        { bits: "0",
          name: "channel_free",
          desc: "If 1 the agent own the channel, if 0 the platform own the channel"
        }
      ],
    },
    { name: "Reserved_2_c${i}",
      desc: "Reserved, implementation defined (32 bits over 64)",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:0" }
      ],
    },
    { name: "Reserved_3_c${i}",
      desc: "Reserved, implementation defined (32 bits over 64)",
      swaccess: "none",
      hwaccess: "none",
      fields: [
        { bits: "31:0" }
      ],
    },
    { name: "Channel_Flags_c${i}",
      desc: "Defines wheter interrupts or polling is used for communication",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:1" },
        { bits: "0",
          name: "intr_enable",
          desc: "If 1 interruts are used, if 0 polling is used"
        }
      ],
    },
    { name: "Length_c${i}",
      desc: "Lenght of payload + header",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:0" }
      ],
    },
    { name: "Message_Header_c${i}",
      desc: "Defines which commanad the message contains",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:28" },
        { bits: "27:18",
          name: "Token",
          desc: "must be same for the msg responses associated to a msg whith the same header"
        },
        { bits: "17:10",
          name: "Protocol_Id",
          desc: "Identifies to which protocol the command belongs to"
        },
        { bits: "9:8",
          name: "Message_Type",
          desc: "can be 0,1,2,3 depending on the kind of msg to be sent"
        },
        { bits: "7:0",
          name: "Message_Id",
          desc: "unique identifier for each command availabe in the protocol pointed by protocol_id"
        }
      ],
    },
    { name: "Message_Payload_1_c${i}",
      desc: "memory region dedicated to the parameters of the commands and their returns",
      swaccess: "rw",
      hwaccess: "none",
      fields: [
        { bits: "31:0" }
      ],
    },
    { name: "Doorbell_c${i}",
      desc: "Rapresents the interrupt to be raised towards the platform",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "31:1",
          name: "Preserve_Mask",
          desc: "These bits must be constant to 0, not used with just one platform and one agent"
        },
        { bits: "0",
          name: "intr",
          desc: "Interrupt bit"
        }
      ],
    },
    { name:  "Completion_Interrupt_c${i}",
      desc: "Rapresent the interrupt the platform should raise when it finishes to execute the received command",
      swaccess: "rw",
      hwaccess: "hro",
      fields: [
        { bits: "31:1",
          name: "Preserve_Mask",
          desc: "These bits must be constant to 0, not used with just one platform and one agent"
        },
        { bits: "0",
          name: "intr",
          desc: "Interrupt bit"
        }
      ],
    },
% endfor    
  ],
}

#!/usr/bin/env python3

from string import Template
import argparse
import os.path
import sys


parser = argparse.ArgumentParser(description='Generate example of pad frame module instance')
parser.add_argument('filename', metavar='filename', type=str,
                    help='filename of input pads list')

args = parser.parse_args()
file = args.filename

# check that file exists
if not os.path.isfile(file):
    print("File {} does not exist.".format(args.filename))
    sys.exit(1)

filename = os.path.splitext(file)[0]

license = """\
//-----------------------------------------------------------------------------
// Title         : Example module to instantiate pad frame in Control PULP
//-----------------------------------------------------------------------------
// File          : example_pad_frame_inst.sv
//-----------------------------------------------------------------------------
// Description :
// Auto-generated example module that instantiates the pad frame for FPGA
// emulation environment
//-----------------------------------------------------------------------------
// Copyright (C) 2013-2021 ETH Zurich, University of Bologna
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//-----------------------------------------------------------------------------

"""


module = """\
module example_module #(
  // INPUT PARAMETERS
) (
  // INPUTS AND OUTPUTS SIGNALS/PADS
);

  // Inout signals are split into input, output and enables

  // ENABLE SIGNALS TO THE PADS
$logic_pin_oe
  // INPUTS SIGNALS TO THE PADS
$logic_pin_in
  // SIGNALS FROM THE PADS
$logic_pin_out

  // Instantiate pad_frame for chip-like inout signals
  pad_frame_fpga i_pad_frame (
    // OUTPUT ENABLE SIGNALS TO THE PADS
$inst_pin_oe
    // INPUTS SIGNALS TO THE PADS
$inst_pin_in
    // OUTPUT SIGNALS FROM THE PADS
$inst_pin_out
    // EXT CHIP TP                 PADS
$inst_pad
    .pad_cfg_i ( s_pad_cfg )
  );

endmodule
"""

def read_pads():
    pads = {}
    with open(filename + ".txt", 'r') as f:

        # Remove first line
        f.readline()

        line = f.readline().split( )
        pads["arrays"] = {}

        while line[0] != "END":
            pad_name = line[0]
            line.remove(pad_name)
            pads[pad_name] = {}
            for i in range(3):
                pin = line[0]
                direction = pin.split("_")[0]

                # check if it's an array and if so, put it and its dimension in the dictionary
                if "[" in pin:
                    arr_depth = int(pin.split("[")[1][:-1])
                    arr_name  = pin.split("[")[0]
                    pads["arrays"][arr_name] = arr_depth

                pads[pad_name][direction] = pin
                line = f.readline().split( )

    f.close()

    return pads


pads_dict = read_pads()
#print(pads_dict)

logic_pin_oe        = ""
logic_pin_in        = ""
logic_pin_out       = ""

inst_pin_oe         = ""
inst_pin_in         = ""
inst_pin_out        = ""
inst_pad            = ""

pad_inout_i2c       = ""
pad_inout_pmb       = ""
pad_inout_uart      = ""
pad_inout_avs       = ""
pad_inout_qspi      = ""
pad_inout_intr_sckt = ""
pad_inout_gpio      = ""

for pad_name in pads_dict:

    if pad_name == "arrays":
        continue

    # Take the "in_ .." signal as the starting string to work on.
    arr_name = pads_dict[pad_name]["in"].split("[")[0]
    if "[" in pads_dict[pad_name]["in"]:
        arr_idx  = int(pads_dict[pad_name]["in"].split("[")[1][:-1])
        if arr_idx == pads_dict["arrays"][arr_name]:
            logic_pin_oe  += "  logic [" + str(arr_idx) + ":0]      s_oe_" + arr_name[3:-2] + ";\n"
            logic_pin_in  += "  logic [" + str(arr_idx) + ":0]      s_in_" + arr_name[3:-2] + ";\n"
            logic_pin_out += "  logic [" + str(arr_idx) + ":0]      s_out_" + arr_name[3:-2] + ";\n"
            inst_pin_oe   += "    .oe_" + arr_name[3:-2] + "_i ( s_oe_" + arr_name[3:-2] + " ),\n"
            inst_pin_in   += "    .in_" + arr_name[3:-2] + "_o ( s_in_" + arr_name[3:-2] + " ),\n"
            inst_pin_out  += "    .out_" + arr_name[3:-2] + "_i ( s_out_" + arr_name[3:-2] + " ),\n"

    else:
        logic_pin_oe  += "  logic            " + "s_" + pads_dict[pad_name]["oe"][:-2] + ";\n"
        logic_pin_in  += "  logic            " + "s_" + pads_dict[pad_name]["in"][:-2] + ";\n"
        logic_pin_out += "  logic            " + "s_" + pads_dict[pad_name]["out"][:-2] + ";\n"
        inst_pin_oe   += "    .oe_" + arr_name[3:-2] + "_i ( s_" + pads_dict[pad_name]["oe"][:-2] + " ),\n"
        inst_pin_in   += "    .in_" + arr_name[3:-2] + "_o ( s_" + pads_dict[pad_name]["in"][:-2] + " ),\n"
        inst_pin_out  += "    .out_" + arr_name[3:-2] + "_i ( s_" + pads_dict[pad_name]["out"][:-2] + " ),\n"

    inst_pad += "    ." + pad_name + " ( " + pad_name + " ),\n"

    to_write = "false"

    if ("pms0_pms1" in pad_name) or ("i2c7" in pad_name):
        pad_inout_intr_sckt += "  inout wire              " + pad_name + ",\n"
    elif ("pmb" in pad_name):
        pad_inout_pmb += "  inout wire              " + pad_name + ",\n"
    elif ("avs" in pad_name):
        pad_inout_avs += "  inout wire              " + pad_name + ",\n"
    elif ("bios" in pad_name):
        pad_inout_qspi += "  inout wire              " + pad_name + ",\n"
    elif ("i2c" in pad_name):
        pad_inout_i2c += "  inout wire              " + pad_name + ",\n"
    elif ("uart" in pad_name):
        pad_inout_uart += "  inout wire              " + pad_name + ",\n"
    else:
        pad_inout_gpio += "  inout wire              " + pad_name + ",\n"

# Remove final comma
pad_inout_uart = pad_inout_uart[:-2]
with open("example_pad_frame_inst.sv", "w") as f:

    l = Template(license)
    f.write(l.substitute())

    s = Template(module)
    f.write(s.substitute(logic_pin_oe        = logic_pin_oe,
                         logic_pin_in        = logic_pin_in,
                         logic_pin_out       = logic_pin_out,
                         inst_pin_oe         = inst_pin_oe,
                         inst_pin_in         = inst_pin_in,
                         inst_pin_out        = inst_pin_out,
                         inst_pad            = inst_pad
                         ))

f.close()

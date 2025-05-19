#!/usr/bin/env python3

from string import Template
import argparse
import os.path
import sys


parser = argparse.ArgumentParser(description='Generate pad frame module form input file')
parser.add_argument('filename', metavar='filename', type=str,
                    help='filename of input pads list')
parser.add_argument('--title', '-t', type=str, required=True)
parser.add_argument('outname', metavar='outname', type=str,
                    help='filename of output SystemVerilog module')

args = parser.parse_args()
file = args.filename

# check that file exists
if not os.path.isfile(file):
    print("File {} does not exist.".format(args.filename))
    sys.exit(1)


license = """\
//-----------------------------------------------------------------------------
// Title         : $title
//-----------------------------------------------------------------------------
// File          : $file_name
//-----------------------------------------------------------------------------
// Description :
// Auto-generated pad frame from gen_pads.py
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
module $module_name import control_pulp_pkg::*; (

  // OUTPUT ENABLE SIGNALS TO THE PADS
$interfaces_oe
  // INPUTS SIGNALS FROM THE PADS
$interfaces_in
  // OUTPUT SIGNALS TO THE PADS
$interfaces_out

  // PMB PADS INOUT WIRES
$pad_inout_pmb
  // I2C PADS INOUT WIRES
$pad_inout_i2c
  // AVS PADS INOUT WIRES
$pad_inout_avs
  // QSPI PADS INOUT WIRES
$pad_inout_qspi
  // INTER SOCKET PADS INOUT WIRES
$pad_inout_intr_sckt
  // GPIO PADS INOUT WIRES
$pad_inout_gpio
  // UART PADS INOUT WIRES
$pad_inout_uart
  input logic [31:0][5:0] pad_cfg_i
);

  // PMB PADS INSTANCES
$pad_inst_pmb
  // I2C PADS INSTANCES
$pad_inst_i2c
  // AVS PADS INSTANCES
$pad_inst_avs
  // QSPI PADS INSTANCES
$pad_inst_qspi
  // INTER SOCKET PADS INSTANCES
$pad_inst_intr_sckt
  // GPIO PADS INSTANCES
$pad_inst_gpio
  // UART PADS INSTANCES (We actually have only one UART, but the interface name is "uart1" in ATOS)
$pad_inst_uart
endmodule
"""

def read_pads():
    pads = {}
    with open(args.filename, 'r') as f:

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

intf_pin_oes     = ""
intf_pin_inputs  = ""
intf_pin_outputs = ""

pad_inst_i2c       = ""
pad_inst_pmb       = ""
pad_inst_uart      = ""
pad_inst_avs       = ""
pad_inst_qspi      = ""
pad_inst_gpio      = ""
pad_inst_intr_sckt = ""

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

    if "[" in pads_dict[pad_name]["in"]:
        arr_name = pads_dict[pad_name]["in"].split("[")[0]
        arr_idx  = int(pads_dict[pad_name]["in"].split("[")[1][:-1])
        if arr_idx == pads_dict["arrays"][arr_name]:
            pin_oe   = " [" + str(arr_idx) + ":0]       oe_" + arr_name[3:-1] + "i"
            pin_in   = " [" + str(arr_idx) + ":0]      in_" + arr_name[3:-1] + "o"
            pin_out  = " [" + str(arr_idx) + ":0]       out_" + arr_name[3:-1] + "i"
            to_write = "true"
        # Change the suffix of digital signals, since outputs are inputs to the padframe and
        # "viceversa"
        pads_dict[pad_name]["in"]  = "in_" + arr_name[3:-1] + "o[" + str(arr_idx) + "]"
        pads_dict[pad_name]["oe"]  = "oe_" + arr_name[3:-1] + "i[" + str(arr_idx) + "]"
        pads_dict[pad_name]["out"] = "out_" + arr_name[3:-1] + "i[" + str(arr_idx) + "]"

    else:
        arr_name = pads_dict[pad_name]["in"]
        pin_oe   = "             oe_" + arr_name[3:-1] + "i"
        pin_in   = "            in_" + arr_name[3:-1] + "o"
        pin_out  = "             out_" + arr_name[3:-1] + "i"
        to_write = "true"
        # Change the suffix of digital signals, since outputs are inputs to the padframe and
        # "viceversa"
        pads_dict[pad_name]["in"]  = "in_" + arr_name[3:-1] + "o"
        pads_dict[pad_name]["oe"]  = "oe_" + arr_name[3:-1] + "i"
        pads_dict[pad_name]["out"] = "out_" + arr_name[3:-1] + "i"
    if to_write == "true":
        #output enables
        intf_pin_oes     += "  input logic" + pin_oe + ",\n"
        #inputs
        intf_pin_inputs  += "  output logic" + pin_in + ",\n"
        #outputs
        intf_pin_outputs += "  input logic" + pin_out + ",\n"

    to_write = "false"

    # Remove "pad_" from pad name
    inst_name = pad_name[4:]

    if ("pms0_pms1" in pad_name) or ("i2c7" in pad_name):
        pad_inout_intr_sckt += "  inout wire              " + pad_name + ",\n"
        if ("spi" in pad_name):
            pad_inst_intr_sckt += "  pad_functional_pd padinst_spi_" +         \
                inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
                " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
                + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
        else:
            pad_inst_intr_sckt += "  pad_functional_pu padinst_" +         \
                inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
                " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
                + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("i2c" in pad_name):
        pad_inout_i2c += "  inout wire              " + pad_name + ",\n"
        pad_inst_i2c += "  pad_functional_pu padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("pmb" in pad_name):
        pad_inout_pmb += "  inout wire              " + pad_name + ",\n"
        pad_inst_pmb += "  pad_functional_pu padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("avs" in pad_name):
        pad_inout_avs += "  inout wire              " + pad_name + ",\n"
        pad_inst_avs += "  pad_functional_pd padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("bios" in pad_name):
        pad_inout_qspi += "  inout wire              " + pad_name + ",\n"
        pad_inst_qspi += "  pad_functional_pd padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("uart" in pad_name):
        pad_inout_uart += "  inout wire              " + pad_name + ",\n"
        pad_inst_uart += "  pad_functional_pu padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    elif ("pwr_btn" in pad_name):
        pad_inout_gpio += "  inout wire              " + pad_name + ",\n"
        pad_inst_gpio += "  pad_functional_pu padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"
    else:
        pad_inout_gpio += "  inout wire              " + pad_name + ",\n"
        pad_inst_gpio += "  pad_functional_pd padinst_" +         \
            inst_name + "( .OEN(~" + pads_dict[pad_name]["oe"] +             \
            " ), .I(" + pads_dict[pad_name]["out"] +" ), .O(" + pads_dict[pad_name]["in"] \
            + " ), .PAD(" + pad_name +" ), .PEN(1'b0 ));\n"


with open(args.outname, "w") as f:

    l = Template(license)
    f.write(l.substitute(title=args.title, file_name=args.outname))

    s = Template(module)
    sv_module = os.path.splitext(args.outname)[0]
    f.write(s.substitute(module_name         = sv_module,
                         interfaces_oe       = intf_pin_oes,
                         interfaces_in       = intf_pin_inputs,
                         interfaces_out      = intf_pin_outputs,
                         pad_inst_i2c        = pad_inst_i2c,
                         pad_inst_pmb        = pad_inst_pmb,
                         pad_inst_uart       = pad_inst_uart,
                         pad_inst_avs        = pad_inst_avs,
                         pad_inst_intr_sckt  = pad_inst_intr_sckt,
                         pad_inst_qspi       = pad_inst_qspi,
                         pad_inst_gpio       = pad_inst_gpio,
                         pad_inout_i2c       = pad_inout_i2c,
                         pad_inout_pmb       = pad_inout_pmb,
                         pad_inout_avs       = pad_inout_avs,
                         pad_inout_qspi      = pad_inout_qspi,
                         pad_inout_intr_sckt = pad_inout_intr_sckt,
                         pad_inout_uart      = pad_inout_uart,
                         pad_inout_gpio      = pad_inout_gpio,
                         ))

f.close()

#!/usr/bin/env python3

from string import Template
import argparse
import os.path
import sys


parser = argparse.ArgumentParser(description='Generate pad constraints and vivado commands form input file')
parser.add_argument('filename', metavar='filename', type=str,
                    help='filename of input pads constraints list')

args = parser.parse_args()
file = args.filename

# check that file exists
if not os.path.isfile(file):
    print("File {} does not exist.".format(args.filename))
    sys.exit(1)


constr_file = """\
## FPGA pads constraints

### PMB
$pad_const_pmb
### I2C
$pad_const_i2c
### AVS
$pad_const_avs
### QSPI
$pad_const_qspi
### INTER SOCKET
$pad_const_intr_sckt
### UART
$pad_const_uart
### GPIO
$pad_const_gpio

### JTAG
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports jtag_tms_i_0]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports jtag_tdi_i_0]
set_property -dict {PACKAGE_PIN A22 IOSTANDARD LVCMOS33} [get_ports jtag_tdo_o_0]
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports jtag_tck_i_0]
set_property -dict {PACKAGE_PIN B21 IOSTANDARD LVCMOS33} [get_ports jtag_trst_i_0]
"""

vivado_cmd_file = """\
## Vivado commands to make pins external

$vivado_cmds
"""

def read_constr():
    pads_constr = {}
    with open(args.filename, 'r') as f:

        # Remove first line
        f.readline()

        line = f.readline().split( )

        while line[0] != "END":
            pad_name = line[0]
            line.remove(pad_name)
            pads_constr[pad_name] = {"FMC": line[1], "FPGA": line[2]}

            # Skip lines that contain only the pins names
            f.readline()
            f.readline()

            line = f.readline().split( )

    f.close()

    return pads_constr


pads_constr_dict = read_constr()
#print(pads_constr_dict)

pad_const_i2c       = ""
pad_const_pmb       = ""
pad_const_uart      = ""
pad_const_avs       = ""
pad_const_qspi      = ""
pad_const_gpio      = ""
pad_const_intr_sckt = ""
vivado_cmds         = "# make pad pins external\nmake_bd_pins_external \\\n"

for pad_name in pads_constr_dict:

    FPGA_const = pads_constr_dict[pad_name]["FPGA"]
    FMC_const = pads_constr_dict[pad_name]["FMC"]

    if ("pms0_pms1" in pad_name) or ("i2c7" in pad_name):
        pad_const_intr_sckt += "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    elif ("i2c" in pad_name):
        pad_const_i2c += "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    elif ("pmb" in pad_name):
        pad_const_pmb +=  "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    elif ("avs" in pad_name):
        pad_const_avs +=  "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    elif ("bios" in pad_name):
        pad_const_qspi +=  "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    elif ("uart" in pad_name):
        pad_const_uart +=  "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"
    else:
        pad_const_gpio += "# PULP " + pad_name + " - FPGA " + FPGA_const + " - FMC  " + \
            FMC_const + "\nset_property -dict {PACKAGE_PIN " + FPGA_const + \
            " IOSTANDARD LVCMOS18} [get_ports " + pad_name + "_0]\n"

    vivado_cmds += "  [get_bd_pins i_pms_top_fpga/" + pad_name  + "] \\\n"

# JTAG
vivado_cmds += "  [get_bd_pins i_pms_top_fpga/jtag_tms_i] \\\n"
vivado_cmds += "  [get_bd_pins i_pms_top_fpga/jtag_tdi_i] \\\n"
vivado_cmds += "  [get_bd_pins i_pms_top_fpga/jtag_tdo_o] \\\n"
vivado_cmds += "  [get_bd_pins i_pms_top_fpga/jtag_tck_i] \\\n"
vivado_cmds += "  [get_bd_pins i_pms_top_fpga/jtag_trst_i] \\\n"

# remove the trailing backslash
vivado_cmds = vivado_cmds[:-3]

with open("zcu102_peripherals.xdc", "w") as f:

    s = Template(constr_file)
    f.write(s.substitute(pad_const_i2c       = pad_const_i2c,
                         pad_const_pmb       = pad_const_pmb,
                         pad_const_uart      = pad_const_uart,
                         pad_const_avs       = pad_const_avs,
                         pad_const_intr_sckt = pad_const_intr_sckt,
                         pad_const_qspi      = pad_const_qspi,
                         pad_const_gpio      = pad_const_gpio
                         ))

f.close()

with open("zcu102_pins_bd.tcl", "w") as f:

    s = Template(vivado_cmd_file)
    f.write(s.substitute(vivado_cmds = vivado_cmds
                         ))

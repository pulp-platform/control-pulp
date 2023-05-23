#!/usr/bin/python3
#
# Copyright 2022 ETH Zurich and University of Bologna
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""
   Preprocess SystemVerilog filelists/commandlists

   Most commonly used to turn relative paths into absolute paths

   bugs: balasr@iis.ee.ethz.ch
"""

import argparse
import os
import sys
import re

parser = argparse.ArgumentParser(prog='proc_flist.py',
                                 description="""Preprocess
                                 filelists/commandlist""")


parser.add_argument('file_list', metavar='FILE', type=str,
                    help="""Read filelist or commandlist from FILE""")
parser.add_argument('-r', '--root', type=str, help="""Root for absolute paths.
Default is set to current working directory""", default=os.getcwd())
parser.add_argument('-a', '--absolute', action='store_true',
                    help="""Make all paths absolute""")
parser.add_argument('-s', '--script-as-root', action='store_true',
                    help="""Use this script's location as root""")
parser.add_argument('--no-normalize', action='store_true',
                    help="""Disable path normalization""")
parser.add_argument('-e', '--exclude', type=str, action='append',
                    help="""Remove files (indicated with python regex)""")
parser.add_argument('-o', '--output', type=str,
                    help="""Write to OUTPUT file""")


args = parser.parse_args()


def normalize(path):
    if not (args.no_normalize):
        return os.path.normpath(path)
    else:
        return path


with open(args.file_list) as fin:
    # write to file if requested
    if args.output:
        fout = open(args.output, 'w')
    else:
        fout = sys.stdout
    # absolute path to this script
    root = args.root
    if (args.script_as_root):
        root = os.path.dirname(os.path.realpath(sys.argv[0]))

    for line in fin:
        # leave out line if it matches given regex/files
        match = False
        if args.exclude:
            for regex in args.exclude:
                match = match or re.search(regex, line)

        if match:
            continue

        if args.absolute:
            # already an absolute path
            if line.startswith('/'):
                fout.write(line)
            # include statement
            elif line.startswith('+incdir+'):
                path = line[len('+incdir+'):]
                if path.startswith('/'):
                    fout.write(line)
                else:
                    fout.write('+incdir+' + normalize(root + '/' + path))
            # macros
            elif line.startswith('+define+'):
                pass
            # relative path
            else:
                fout.write(normalize(root + '/' + line))
        else:
            fout.write(line)

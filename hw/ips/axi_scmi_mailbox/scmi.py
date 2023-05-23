#!/usr/bin/python3
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
import sys
import argparse
from io import StringIO

from mako.template import Template


def main():
    parser = argparse.ArgumentParser(prog="scmi")
    parser.add_argument('input',
                        nargs='?',
                        metavar='file',
                        type=argparse.FileType('r'),
                        default=sys.stdin,
                        help='input template file')
    parser.add_argument('--sources',
                        '-s',
                        type=int,
                        default=256,
                        help='Number of mailbox channels')

    args = parser.parse_args()

    out = StringIO()

    tpl = Template(args.input.read())
    out.write(tpl.render(src=args.sources))

    print(out.getvalue())
    out.close()


if __name__ == "__main__":
    main()

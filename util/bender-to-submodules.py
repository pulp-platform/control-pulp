#!/usr/bin/python3

# Copyright 2023 ETH Zurich and University of Bologna
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

# Author: Robert Balas (balasr@iis.ee.ethz.ch)

import argparse
import yaml
import sys
import subprocess

parser = argparse.ArgumentParser(prog='rewrite-bender-remotes',
                                 description="""Rewrite git remotes set by
                                 bender during checkout to be the true git
                                 remotes (i.e. where the repos where clones
                                 from)""")

parser.version = '1.0.0'
parser.add_argument('bender_yml', type=str,
                    help="""Location of Bender.yml file""")
# TODO: argument to rewrite https to git remotes
parser.add_argument('bender_lock', type=str,
                    help="""Location of Bender.lock file""")

parser.add_argument('-n', '--no-url-conv', action='store_true',
                    help='Do not convert all git remote addresses to https')

args = parser.parse_args()


def convert_to_https(url):
    if url.startswith('https://'):
        return url
    url = url.replace(':', '/')
    url = url.replace('git@', 'https://')

    return url


# figure out checkout_dir location
with open(args.bender_yml, 'r') as bender_stream:
    try:
        bender = yaml.safe_load(bender_stream)
    except yaml.YAMLError as ex:
        print(ex)

with open(args.bender_lock, 'r') as bender_lock_stream:
    try:
        bender_lock = yaml.safe_load(bender_lock_stream)
    except yaml.YAMLError as ex:
        print(ex)

try:
    checkout_dir = bender['workspace']['checkout_dir']
except Exception:
    print('Error: checkout_dir not found in Bender.yml', file=sys.stderr)
    exit(1)

for package, value in bender_lock['packages'].items():
    # check if 'deps'/'package' exists
    print('Update remote of', package, end='')
    # pick only git repos
    if 'Path' in value['source'].keys():
        print('... skipping because non-git')
        continue
    print('')
    url = value['source']['Git']

    if not(args.no_url_conv):
        url = convert_to_https(url)

    cmd = 'git submodule add ' + url + ' ' + checkout_dir + '/' + package
    print(cmd)
    subprocess.run(cmd, shell=True, check=True)

# git submodule add https://www.github.com/pulp-platform/apb deps/apb

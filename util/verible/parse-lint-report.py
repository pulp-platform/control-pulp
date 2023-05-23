#!/usr/bin/env python3
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
r"""Parses lint report and dump filtered messages in hjson format.
"""
import argparse
import logging as log
import re
import sys
from pathlib import Path
import os
from os import listdir
from os.path import isfile, join

import hjson


def extract_messages(full_file, patterns, results):
    """
    This extracts messages from the sting buffer full_file.
    The argument patterns needs to be a list of tuples with
    (<error_severity>, <pattern_to_match_for>).
    """
    for severity, pattern in patterns:
        results[severity] += re.findall(pattern, full_file, flags=re.MULTILINE)

    return results


def get_results(resdir):
    """
    Parse report and corresponding logfiles and extract error, warning
    and info messages for each IP present in the result folder
    """
    results = {
        "tool": "veriblelint",
        "fusesoc-error": [],
        "errors": [],
        "warnings": [],
        "lint_errors": [],
        "lint_warnings": [],
        "lint_infos": []
    }
    try:
        # check the report file for lint INFO, WARNING and ERRORs
        with Path(resdir).open() as f:
            full_file = f.read()
    except IOError as err:
        results["errors"] += ["IOError: %s" % err]

    err_warn_patterns = [
        # If lint warnings have been found, the lint tool will exit
        # with a nonzero status code and fusesoc will always spit out
        # an error like
        #
        #    ERROR: Failed to run ip:core:name:0.1 : Lint failed
        #
        # If we found any other warnings or errors, there's no point in
        # listing this too. BUT we want to make sure we *do* see this
        # error if there are no other errors or warnings, since that
        # shows something has come unstuck. (Probably the lint tool
        # spat out a warning that we don't understand)
        ("fusesoc-error", r"^ERROR: Failed to run .*: Lint failed.*"),
        ("errors", r"^(?!ERROR: Failed to run .* Lint failed)ERROR: .*"),
        ("errors", r"^.*Error: .*"),
        ("errors", r"^E .*"),
        ("errors", r"^F .*"),
        ("errors", r".*: syntax error, rejected.*"),
        # TODO(https://github.com/olofk/edalize/issues/90):
        # this is a workaround until we actually have native Edalize
        # support for JasperGold and "formal" targets
        ("warnings",
         r"^(?!WARNING: Unknown item formal in section Target)WARNING: .*"),
        ("warnings", r"^.*Warning: .* "),
        ("warnings", r"^W .*"),
        ("lint_warnings", r"^.*\[Style:.*")
    ]
    extract_messages(full_file, err_warn_patterns, results)

    # If there are no errors or warnings, add the "fusesoc-error" field to
    # "errors" (which will be reported as tooling errors). Remove the
    # "fusesoc-error" field either way.
    if not (results['errors'] or results['warnings']):
        results['errors'] = results['fusesoc-error']
    del results['fusesoc-error']

    return results


def main():

    parser = argparse.ArgumentParser(
        description="""This script parses verible lint log files from
        a lint run, filters the messages and creates an aggregated result
        .hjson file with the following fields:
           {"tool": "veriblelint",
            "errors" : [],
            "warnings" : [],
            "lint_errors" : [],
            "lint_warnings" : [],
            "lint_infos" : []}
        The fields 'errors' and 'warnings' contain file IO messages or
        messages output by the tool itself, whereas the fields prefixed with
        'lint_' contain lint-related messages.
        The script returns nonzero status if any warnings or errors are present.
        """)
    parser.add_argument('--repdir',
                        type=str,
                        default="./",
                        help="""The script searches the '-lint.log'
                        files in this directory.
                        Defaults to './'""")

    args = parser.parse_args()

    # Get list of reports
    lint_logs = [f for f in listdir(args.repdir) if isfile(join(args.repdir, f))]

    for lint_log in lint_logs:

        lint_log_path = os.path.join(args.repdir, lint_log)
        results = get_results(lint_log_path)

        lint_hjson_path = os.path.splitext(os.path.join(args.repdir, lint_log))[0] + ".hjson"

        with Path(lint_hjson_path).open("w") as results_file:
            hjson.dump(results,
                       results_file,
                       ensure_ascii=False,
                       for_json=True,
                       use_decimal=True)

        # return nonzero status if any warnings or errors are present
        # lint infos do not count as failures
        n_errors = len(results["errors"]) + len(results["lint_errors"])
        n_warnings = len(results["warnings"]) + len(results["lint_warnings"])
        if n_errors > 0 or n_warnings > 0:
            log.info("Found %d lint errors and %d lint warnings", n_errors,
                     n_warnings)

        log.info("Lint logfile parsed succesfully")


if __name__ == "__main__":
    main()

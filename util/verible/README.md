# Verible support for ControlPULP

[Verible](https://github.com/google/verible) offers several tools to
monitor syntax/linting/formatting of projects written in Verilog.  It
comes with several tools. Pre-built binaries can be found under
`util/verible/bin`.

## Getting started

We actually support three `verible` tools: `verible-verilog-syntax`,
`verible-verilog-lint` and `verible-verilog-format`.  For each of
them, you can display the `help` options by typing:

```
<rootdir_path>/util/verible/bin/<verible_verilog_tool_bin>
--helpfull
```

Where `<rootdir_path>` is the top-level directory of the git
repository.


### Verible Syntax

From the root of the git repository, type:

```
make verible-syntax TARGET=<relative-path-to-target-from-root>
REPORT=0
```

Where `TARGET` is the relative path of the target file/directory with
respect to the top-level root repository (e.g., `TARGET=./rtl/pulp` in
`control_pulp`).  `REPORT=0` shows the verible-tool output on the
shell terminal and it is enabled by default. `REPORT=1` redirects the
output to a `.log` file under `utile/verible/rpt` for each source file
hit by the tool.


### Verible Linter

For linting, we support [lowRISC Verilog Coding
Style](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md). Hence,
we adopt the same [rules
configuration](https://github.com/lowRISC/ibex/blob/71a8763553a25b90394de92f3f97e56b1009030b/vendor/lowrisc_ip/lint/tools/veriblelint/rules.vbl).

From the root of the git repository, type:

```
make verible-lint TARGET=<relative-path-to-target-from-root> REPORT=0
```

When `REPORT=1`, the Linter produces logs in `hjson` format for
analyzing which rule has been violated. As for verible-syntax, you can
find them under `util/verible/rpt`.


### Verible Formatter

From the root of the git repository, type:

```
make verible-format TARGET=<relative-path-to-target-from-root>
```

`verible-verilog-format` uses the `--inplace` option to directly
replace the target file with its formatted version.

#### Incremental formatting (Git)

`verible-verilog-format` can hit changed and not yet committed lines
for each modified file in a `git` repository.  From the root of the
git repository, type:

```
make verible-update
```

The command will format the changes automatically.

#### Interactive Incremental formatting (Git)

If you prefer to perform interactive incremental formatting, you can
call the verible script by yourself:

```
make verible-update-interactive
```

and follow the prompts.

### All at once

For calling all the three tools on a certain target directory at once,
type:

```
make verible-all TARGET=<relative-path-to-target-from-root>
```

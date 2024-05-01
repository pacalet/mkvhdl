# Makefile for VHDL compilation and simulation

```
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable  domain             description (current value)
    SIM   {ghdl,vsim,xsim}   simulation toolchain (ghdl)
    GUI   {yes,no}           use Graphical User Interface (no)
    DIR   -                  temporary compilation and simulation directory (/tmp/pacalet/mkvhdl/ghdl)
    MODE  {work,dirname}     default target library for compilations (work)
    SKIP  -                  NAMEs to ignore for compilation ()
    V     {0,1}              verbosity level (0)

Goals:
    help           print this short help message (default goal)
    long-help      print the long help message
    lib            print the list of libraries and their associated directory
    NAME           compile VHDL source file NAME.vhd
    list           print list of all existing NAMEs not in SKIP
    all            compile all VHDL source files not in SKIP
    NAME.sim       simulate entity NAME
    clean          delete temporary compilation and simulation directory
```

This Makefile uses several conventions that must absolutely be complied with.
If for any reason you cannot comply with these conventions, do not use this Makefile.
The conventions are the following.

## The `TOP` directory

The directory containing this Makefile is the `TOP` directory.
All make commands must be launched from `TOP`.

## VHDL source files

VHDL source files must be stored under `TOP/vhdl` and named `NAME.vhd` where `NAME` is any combination of alphanumeric characters, plus underscore (no spaces, for instance).

## Target libraries

Each VHDL source file has a default target library in which it is compiled.
If `MODE=work` this default target library is `work`.
If `MODE=dirname` it is the library with the same name as the directory of the source file.
The target library is automatically created if it does not exist yet.

## Uniqueness of VHDL source file names

VHDL source file names must be unique.
It is not possible to have a `TOP/vhdl/bar/foo.vhd` and a `TOP/vhdl/qux/foo.vhd`.

## Simulation environments

The `NAME.sim` simulation goals assume that the entity to simulate is `NAME` and that it is defined in file `NAME.vhd`.
If you want to use this Makefile to launch simulations, name the VHDL source files of your simulation environments according their entity names.
Example: if the entity of a simulation environment is `foo_sim`, name its VHDL source file `foo_sim.vhd` and launch the simulation with:

```
make foo_sim.sim [VAR=VALUE...]
```

## Dependencies

Inter-file dependencies must be declared in text files with the `.mk` extension and stored under `TOP/vhdl` or its subdirectories.
The dependency syntax is that of make rules without recipes and using only the basename of the VHDL source files without the `.vhd` extension.
If `TOP/vhdl/foo/bar.mk` exists and contains:

```
bar: qux corge grault
foo garply: corge fred
```

it means that `bar.vhd` cannot be compiled before `qux.vhd`, `corge.vhd` and `grault.vhd` have been compiled.
Similarly, `foo.vhd` and `garply.vhd` cannot be compiled before `corge.vhd` and `fred.vhd`.
The subdirectory in which a `.mk` file is stored does not matter.
Note that the letter case matters: if a VHDL source file is named `BaR.vhd`, dependency rules must use `BaR`, not `bar` or `Bar`.

## Custom target libraries

In the same `.mk` files a target VHDL library other than the default can be specified on a per-source file basis using `NAME-lib` variables.
If there is a `foo/bar.vhd` VHDL source file and one of these `.mk` files contains:

```
bar-lib := barlib
```

it means that `foo/bar.vhd` must be compiled in VHDL library `barlib` instead of the default `work` (if `MODE=work`) or `foo` (if `MODE=dirname`).

## The `local.mk` configuration file

If `TOP` contains a local.mk file, it is included before anything else.
It can be used to define make variables with custom values.
If `TOP/local.mk` exists and contains:

```
DIR  := /home/joe/project
MODE := work
SIM  := vsim
GUI  := yes
SKIP := bogus gusbo
V    := 1
```

the temporary compilation and simulation directory is `/home/joe/project`, the default target library of compilations is `work`, the simulation toolchain is Modelsim, all simulations are run with the Graphical User Interface, the `bogus.vhd` and `gusbo.vhd` source files are ignored and the verbose mode is enabled.
Variable assignments on the command line overwrite assignments in the `local.mk` file.
If you know how to use GNU make you can add other make constructs to the `local.mk` (or to other `.mk` files).

<!-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0: -->

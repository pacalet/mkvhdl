# Makefile for VHDL compilation and simulation

## Quick start

Drop this Makefile in the root directory of your VHDL project and always use
the `.vhd` extension for your source files. From the root directory of your
VHDL project type `make` to print the short help or `make long-help` for the
complete help.

```
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable         valid values    description (current value)
    DIR          -               temporary build directory (/tmp/build/ghdl)
    GHDLAFLAGS   -               GHDL analysis options (--std=08)
    GHDLRFLAGS   -               GHDL simulation options (--std=08)
    GHDLRUNOPTS  -               GHDL RUNOPTS options ()
    GUI          yes|no          use Graphical User Interface (no)
    MODE         work|dirname    default target library (work)
    SIM          ghdl|vsim|xsim  simulation toolchain (ghdl)
    SKIP         -               UNITs to ignore for compilation ()
    V            0|1             verbosity level (0)
    VCOMFLAGS    -               Modelsim analysis options (-2008)
    VSIMFLAGS    -               Modelsim simulation options ()
    XVHDLFLAGS   -               Vivado analysis options (-2008)
    XELABFLAGS   -               Vivado elaboration options ()
    XSIMFLAGS    -               Vivado simulation options ()

Goals:
    help                    this help (default goal)
    long-help               print long help
    libs                    print library names
    UNIT                    compile UNIT.vhd
    units                   print existing UNITs not in SKIP
    all                     compile all source files not in SKIP
    UNIT.sim                simulate UNIT
    clean                   delete temporary build directory
```

## Documentation

This Makefile is for GNU make only and relies on conventions; if your make is
not GNU make or your project is not compatible with the conventions, please do
not use this Makefile.

The `vhdl` sub-directory contains some VHDL source files for testing.

1. The directory containing this Makefile is the `TOP` directory. All make
   commands must be launched from `TOP`:

        cd TOP; make ...

   or:

        make -C TOP ...

2. Source files are considered as indivisible units. They must be stored in the
   `TOP` directory or its sub-directories and named `UNIT.vhd` where `UNIT` is
   any combination of alphanumeric characters, plus underscores (no spaces or tabs,
   for instance). The "name" of a unit is the basename of its source file
   without the `.vhd` extension. Example: the name of unit
   `TOP/tests/cooley.vhd` is `cooley`.

3. Each unit has a default target library: `work` if `MODE=work`, or the name
   of the directory of the unit if `MODE=dirname`. Target libraries are
   automatically created if they don't exist.

4. Unit names must be unique. It is not possible to have units
   `TOP/common/version.vhd` and `TOP/tests/version.vhd`, even if `MODE=dirname`
   and their target libraries are different.

5. If there is a file named `config` in `TOP`, it is included before anything else.
   It can be used to set configuration variables to other values than the default.
   Example of `TOP/config` file:

        DIR  := /tmp/build/vsim
        GUI  := yes
        MODE := work
        SIM  := vsim
        SKIP := bogus in_progress
        V    := 1

   Variable assignments on the command line overwrite assignments in
   `TOP/config`. Example to temporarily disable the GUI for a specific
   simulation:

        make cooley_sim.sim GUI=no

6. Simulations can be launched with `make UNIT.sim` to simulate entity `UNIT`
   defined in file `UNIT.vhd`. Example: if unit `TOP/tests/cooley_sim.vhd`
   defines entity `cooley_sim` a simulation can be launched with:

        make cooley_sim.sim [VAR=VALUE...]

   Note: the simulations are launched from the `DIR` temporary build directory.
   It can matter if, for instance, a simulation reads or writes data files.

   Note: GHDL has no GUI; instead, with GHDL and `GUI=yes`, a `DIR/UNIT.ghw`
   waveform file is generated for post-simulation visualization with, e.g.,
   GTKWave.

7. Inter-unit dependencies must be declared in text files with the `.mk`
   extension stored in `TOP` or its sub-directories. The dependency syntax is:

        UNIT [UNIT...]: UNIT [UNIT...]

   where the left-hand side units depend on the right-hand side units. Example:
   if `cooley_sim.vhd` depends on `rnd_pkg.vhd` and `cooley.vhd` (that is, if
   `rnd_pkg.vhd` and `cooley.vhd` must be compiled before `cooley_sim.vhd`), the
   following can be added to a `.mk` file somewhere under `TOP`:

        cooley_sim: rnd_pkg cooley

   The sub-directory in which a `.mk` file is stored does not matter but the
   letter case matters in dependency rules: if a unit is `cooley.vhd`, its name
   is `cooley` and the dependency rules must use `cooley`, not `Cooley` or
   `COOLEY`.

   `.mk` files can also specify per-unit target libraries other than the
   defaults using `UNIT-lib` variables. Example: if `MODE=dirname` and
   `TOP/common/rnd_pkg.vhd` must be compiled in library `tests` instead of the
   default `common`, the following can be added to a `.mk` file somewhere under
   `TOP`:

        rnd_pkg-lib := tests

Other GNU make statements can be added to `.mk` files. Example if the GHDL
simulation of `cooley_sim` depends on data file `cooley.txt` generated by shell
script `TOP/tests/cooley.sh`, and generic parameter `n` must be set to
`100000`, the following can be added to, e.g., `TOP/tests/cooley.mk`:

    cooley_sim.sim: GHDLRUNOPTS += -gn=100000
    cooley_sim.sim: $(DIR)/cooley.txt
    $(DIR)/cooley.txt: $(TOP)/tests/cooley.sh
            $< > $@

# Makefile for VHDL compilation and simulation

## Quick start

Drop this Makefile in the root directory of your VHDL project and always use the `.vhd` extension for your source files.
From the root directory of your VHDL project just type `make` to print the short help.

```
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable    valid values    description (current value)
    DIR     -               temporary build directory (/tmp/build/ghdl)
    GUI     yes|no          use Graphical User Interface (no)
    MODE    work|dirname    default target library (work)
    SIM     ghdl|vsim|xsim  simulation toolchain (ghdl)
    SKIP    -               UNITs to ignore for compilation ()
    V       0|1             verbosity level (0)

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

This Makefile is for GNU make only and uses conventions; if your project is not
compatible with the conventions, please do not use this Makefile.

1. The directory containing this Makefile is the `TOP` directory. All make
   commands must be launched from `TOP`:

        cd TOP; make ...

   or:

        make -C TOP ...

2. Source files are considered as indivisible units. They must be stored in the
   `TOP` directory or its subdirectories and named `UNIT.vhd` where `UNIT` is
   any combination of alphanumeric characters, plus underscores (no spaces or tabs,
   for instance). The "name" of a unit is the basename of its source file
   without the `.vhd` extension. Example: the name of unit
   `TOP/core/version.vhd` is `version`.

3. Each unit has a default target library: `work` if `MODE=work`, or the name
   of the directory of the unit if `MODE=dirname`. Target libraries are
   automatically created if they don't exist.

4. Unit names must be unique. It is not possible to have units
   `TOP/core/version.vhd` and `TOP/interconnect/version.vhd`, even if
   `MODE=dirname` and their target libraries are different.

5. `make UNIT.sim` simulates entity `UNIT` defined in file `UNIT.vhd`. If you
   want to use this Makefile to launch simulations, name the source file of
   your simulation environment according its entity name. Example: if the
   entity of a simulation environment is `arbiter_bench`, name its source file
   `arbiter_bench.vhd` and launch the simulation with:

        make arbiter_bench.sim [VAR=VALUE...]

   Note: the simulations are launched from the `DIR` temporary build directory.
   It can matter if, for instance, a simulation reads or writes data files.
   With GHDL and `GUI=yes` the waveforms file is created in `DIR`.

6. Inter-unit dependencies must be declared in text files with the `.mk`
   extension and stored in `TOP` or its subdirectories. The dependency syntax is:

        UNIT [UNIT...]: UNIT [UNIT...]

   where the left-hand side units depend on the right-hand side units. Example: if
   `mmu.vhd` and `cpu.vhd` depend on `icache.vhd` and `dcache.vhd` (that is, if
   `icache.vhd` and `dcache.vhd` must be compiled before `mmu.vhd` and
   `cpu.vhd`), add the following to a `.mk` file somewhere under `TOP`:

        mmu cpu: icache dcache

   The subdirectory in which a `.mk` file is stored does not matter.

   Note: the letter case matters in dependency rules: if a unit is `CPU.vhd`,
   its name is `CPU` and the dependency rules must use `CPU`, not `cpu` or
   `Cpu`.

7. A target library other than the default can be specified on a per-unit basis
   using `UNIT-lib` variables. Example: if `MODE=dirname` and
   `TOP/core/utils.vhd` must be compiled in library `common` instead of the
   default `core`, add the following to a `.mk` file somewhere under `TOP`:

        utils-lib := common

8. If there is a file named `config` in `TOP`, it is included before anything else.
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

        make arbiter_bench.sim GUI=no

   If you know how to use GNU make you can add other make constructs to
   `TOP/config` (or to `.mk` files). Example if the simulation of
   `arbiter_bench` depends on data file `arbiter_bench.txt` generated by the
   `TOP/arbiter/bench.sh` script, you can add the following to `TOP/config` or
   to `TOP/arbiter/arbiter.mk`:

        arbiter_bench.sim: $(DIR)/arbiter_bench.txt
        $(DIR)/arbiter_bench.txt: $(TOP)/arbiter/bench.sh
                $< > $@

# Makefile for VHDL compilation and simulation

## Quick start

Copy this Makefile in the root directory of your VHDL project, put your VHDL source files under a subdirectory named `vhdl` and always use the `.vhd` extension for your source files.
From the root directory of your VHDL project just type `make` to print the short help.

```
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable    valid values    description (current value)
    DIR     -               temporary build directory (/tmp/joe/mkvhdl/ghdl)
    GUI     yes|no          use Graphical User Interface (no)
    MODE    work|dirname    default target library (work)
    SIM     ghdl|vsim|xsim  simulation toolchain (ghdl)
    SKIP    -               NAMEs to ignore for compilation ()
    V       0|1             verbosity level (0)
    VHDL    -               absolute path of source files root directory (/home/joe/mkvhdl/vhdl)

Goals:
    help                    this help (default goal)
    long-help               print long help
    lib                     print library names / directories
    NAME                    compile NAME.vhd
    list                    print existing NAMEs not in SKIP
    all                     compile all source files not in SKIP
    NAME.sim                simulate NAME
    clean                   delete temporary build directory
```

This Makefile uses conventions; if your project is not compatible with the
conventions, please do not use this Makefile.

1. The directory containing this Makefile is the `TOP` directory. All make
   commands must be launched from `TOP`:

    ```
    cd TOP; make ...
    ```

   or:

    ```
    make -C TOP ...
    ```

2. The directory containing the source files is the `VHDL` directory. All source
   files must be stored in the VHDL directory or its subdirectories and named
   `NAME.vhd` where `NAME` is any combination of alphanumeric characters, plus
   underscores (no spaces or tabs, for instance).

3. Each source file has a default target library: `work` if `MODE=work`, or the
   name of the directory of the source file if `MODE=dirname`. Target libraries are
   automatically created if they don't exist.

4. Source file names must be unique. It is not possible to have a
   `VHDL/core/version.vhd` and a `VHDL/interconnect/version.vhd`.

5. The `NAME.sim` simulation goal simulates entity `NAME` defined in file `NAME.vhd`.
   If you want to use this Makefile to launch simulations, name the source file of
   your simulation environment according its entity name. Example: if the entity
   of a simulation environment is `arbiter_bench`, name its source file
   `arbiter_bench.vhd` and launch the simulation with:

    ```
    make arbiter_bench.sim [VAR=VALUE...]
    ```

   Note that the simulations are launched from the `DIR` temporary build directory.
   If can matter if, for instance, a simulation environment reads or writes data
   files.

6. Inter-file dependencies must be declared in text files with the `.mk`
   extension and stored in `VHDL` or its subdirectories. The dependency syntax is:

    ```
    NAME1 NAME2...: DEPNAME1 DEPNAME2...
    ```

   Example: if `icache.vhd` and `dcache.vhd` must be compiled before `mmu.vhd` and
   `cpu.vhd`, add the following to a `.mk` file somewhere under `VHDL`:

    ```
    mmu cpu: icache dcache
    ```

   The subdirectory in which a `.mk` file is stored does not matter. Note that the
   letter case matters in dependency rules: if a source file is named `CPU.vhd`,
   dependency rules must use `CPU`, not `cpu` or `Cpu`.

7. A target library other than the default can be specified on a per-source
   file basis using `NAME-lib` variables. Example: if `MODE=dirname` and
   `VHDL/core/utils.vhd` must be compiled in library `common` instead of the default
   `core`, add the following to a `.mk` file somewhere under `VHDL`:

    ```
    utils-lib := common
    ```

8. If there is a `local.mk` file in `TOP`, it is included before anything else. It
   can be used to set configuration variables to other values than the default.
   Example:

    ```
    DIR  := /tmp/build          # temporary build directory
    GUI  := yes                 # simulate with Graphical User Interface
    MODE := work                # default target library
    SIM  := vsim                # Modelsim toolchain
    SKIP := bogus in_progress   # ignore bogus.vhd and in_progress.vhd
    V    := 1                   # verbose mode enabled
    VHDL := /home/joe/project   # absolute path of root directory of source files
    ```

   Variable assignments on the command line overwrite assignments in the `local.mk`
   file. Example to temporarily disable the GUI for a specific simulation:

    ```
    make arbiter_bench.sim GUI=no
    ```

   If you know how to use GNU make you can add other make constructs to
   `TOP/local.mk` (or to other `.mk` files). Example if the simulation of
   `arbiter_bench` depends on data file `arbiter_bench.txt` generated by the
   `VHDL/arbiter/bench.sh` script, you can add the following to `TOP/local.mk` or to
   `VHDL/arbiter/arbiter.mk`:

    ```
    arbiter_bench.sim: arbiter_bench.txt
    arbiter_bench.txt: /home/joe/myProject/vhdl/arbiter/bench.sh
            $< > $@
    ```

<!-- vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0: -->

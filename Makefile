# Copyright © Telecom Paris
# Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
#
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

# default goal
.DEFAULT_GOAL := help

# phony targets
.PHONY: help long-help clean

# Compilation is not parallel-safe because most tools use per-library shared
# files that they update after each compilation.
.NOTPARALLEL:

# multiple goals not tested
ifneq ($(words $(MAKECMDGOALS)),1)
ifneq ($(words $(MAKECMDGOALS)),0)
$(error "multiple goals not supported yet")
endif
endif

# absolute real path of TOP directory
TOP := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# project name
PROJECT := $(notdir $(TOP))
# name of configuration file
CONFIG := config

# include configuration file
ifneq ($(wildcard $(TOP)/$(CONFIG)),)
include $(TOP)/$(CONFIG)
endif

# compute configuration variables
# simulator (ghdl, vsim or xsim)
SIM ?= ghdl
# GUI mode
GUI ?= no
ifneq ($(GUI),yes)
ifneq ($(GUI),no)
$(error "$(GUI): invalid GUI value")
endif
endif
ifeq ($(SIM),ghdl)
COM = ghdl -a --std=08 -frelaxed --work=$(LIBNAME) $(GHDLAFLAGS) $<
ELAB := true
ifeq ($(GUI),yes)
RUN = ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(UNIT) --wave=$(UNIT).ghw $(GHDLRFLAGS); \
      printf 'GHW file: $(DIR)/$(UNIT).ghw\nUse, e.g., GTKWave to display the GHW file\n'
else
RUN = ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(UNIT) $(GHDLRFLAGS)
endif
else ifeq ($(SIM),vsim)
COM = vcom -nologo -quiet -2008 +acc -work $(LIBNAME) $<
ELAB := true
ifeq ($(GUI),yes)
RUN = vsim -voptargs="+acc" $(VSIMFLAGS) $(LIBNAME).$(UNIT)
else
RUN = vsim -voptargs="+acc" -c -do 'run -all; quit' $(VSIMFLAGS) $(LIBNAME).$(UNIT)
endif
else ifeq ($(SIM),xsim)
COM = xvhdl -2008 --work $(LIBNAME) $< $(if $(VERBOSE),,> /dev/null)
ELAB = xelab -debug all $(XELABFLAGS) $(LIBNAME).$(UNIT)
ifeq ($(GUI),yes)
RUN = xsim -gui $(LIBNAME).$(UNIT)
else
RUN = xsim -runall $(LIBNAME).$(UNIT)
endif
else
$(error "$(SIM): invalid SIM value")
endif
# temporary build directory
DIR ?= /tmp/$(USER)/$(PROJECT)/$(SIM)
# tags subdirectory of DIR
TAGS := .tags
# compilation mode:
# - "work":    the default target library is work,
# - "dirname": the default target library is the one with same name as the
#   directory of the source file
MODE ?= work
ifneq ($(MODE),work)
ifneq ($(MODE),dirname)
$(error invalid MODE value: $(MODE))
endif
endif
# verbosity level: 0: quiet, 1: verbose
V ?= 0
ifeq ($(V),0)
.SILENT:
VERBOSE :=
else ifeq ($(V),1)
VERBOSE := yes
else
$(error invalid V value: $(V))
endif

# help messages and goals
define HELP_message
Usage:
    make [GOAL] [VARIABLE=VALUE ...]

Examples:
    make foo_sim DIR=/tmp/mysim SIM=vsim V=1
    make foo_sim.sim DIR=/tmp/ghdl_sim SIM=ghdl GUI=yes

Variable    valid values    description (current value)
    DIR     -               temporary build directory ($(DIR))
    GUI     yes|no          use Graphical User Interface ($(GUI))
    MODE    work|dirname    default target library ($(MODE))
    SIM     ghdl|vsim|xsim  simulation toolchain ($(SIM))
    SKIP    -               UNITs to ignore for compilation ($(SKIP))
    V       0|1             verbosity level ($(V))

Goals:
    help                    this help (default goal)
    long-help               print long help
    libs                    print library names
    UNIT                    compile UNIT.vhd
    units                   print existing UNITs not in SKIP
    all                     compile all source files not in SKIP
    UNIT.sim                simulate UNIT
    clean                   delete temporary build directory
endef
export HELP_message

help::
	@printf '%s\n' "$$HELP_message"

define LONG_HELP_message
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

        arbiter_bench.sim: $$(DIR)/arbiter_bench.txt
        $$(DIR)/arbiter_bench.txt: $$(TOP)/arbiter/bench.sh
                $$< > $$@
endef
export LONG_HELP_message

long-help:: help
	@printf '\n%s\n' "$$LONG_HELP_message"

clean:
	@printf '[RM]    %s\n' "$(DIR)"
	rm -rf $(DIR)

define INTRO_message
# Makefile for VHDL compilation and simulation

## Quick start

Drop this Makefile in the root directory of your VHDL project and always use the `.vhd` extension for your source files.
From the root directory of your VHDL project just type `make` to print the short help.
endef
export INTRO_message

README.md: $(TOP)/Makefile $(wildcard $(TOP)/$(CONFIG))
	printf '%s\n' "$$INTRO_message" > $@
	printf '\n```\n' >> $@
	printf '%s\n' "$$HELP_message" >> $@
	printf '```\n\n## Documentation\n\n' >> $@
	printf '%s\n' "$$LONG_HELP_message" >> $@

# if not clean, help or long-help, and first make invocation
ifneq ($(filter-out clean help long-help,$(MAKECMDGOALS)),)
ifneq ($(PASS),run)

# double-colon rule in case we want to add something elsewhere (e.g. in
# design-specific files)
# last resort default rule to invoke again with same goal and same Makefile but
# in $(DIR)
%::
	mkdir -p $(DIR)/$(TAGS)
	$(MAKE) --no-print-directory -C $(DIR) -f $(TOP)/Makefile $@ PASS=run

# second make invocation (in $(DIR))
else

# search tag files in $(TAGS)
VPATH := $(TAGS)
# all source and dependency files
SRCMKS := $(shell find -L $(TOP) -type f,l \( -name '*.vhd' -o -name '*.mk' \))
# all source files
SRCS := $(patsubst $(TOP)/%,%,$(filter %.vhd,$(SRCMKS)))
# skip units listed in SKIP
SRCS := $(filter-out $(addprefix %/,$(addsuffix .vhd,$(SKIP))),$(SRCS))
# unit names (source file base names without .vhd extension)
UNITS := $(patsubst %.vhd,%,$(notdir $(SRCS)))
sorted_units := $(sort $(UNITS))
duplicates := $(sort $(strip $(foreach u,$(sorted_units),$(word 2,$(filter $u,$(UNITS))))))
ifneq ($(duplicates),)
$(error duplicated unit names: $(duplicates))
endif
UNITS := $(sorted_units)
# simulation goals are UNIT.sim
SIMULATIONS := $(addsuffix .sim,$(UNITS))
# all dependency files under $(TOP)
MKS := $(filter %.mk,$(SRCMKS))

.PHONY: units libs all $(addprefix .sim,$(UNITS))

# include dependency files
include $(MKS)

# library list
LIBS :=

# $(1): source file path relative to $(TOP)
# define target-specific variables (LIBNAME, UNIT)
# instantiate compilation and simulation rules
# in $(DIR) empty files with unit names are used to keep track of last
# compilation times
define GEN_rule
$(1)-unit := $$(patsubst %.vhd,%,$$(notdir $(1)))
ifeq ($$(MODE),work)
$$($(1)-unit)-lib ?= work
else
$$($(1)-unit)-lib ?= $$(notdir $$(patsubst %/,%,$$(dir $(1))))
endif
$$($(1)-unit) $$($(1)-unit).sim: LIBNAME = $$($$($(1)-unit)-lib)
$$($(1)-unit) $$($(1)-unit).sim: UNIT    = $$($(1)-unit)

LIBS += $$($$($(1)-unit)-lib)

$$($(1)-unit): $$(TOP)/$(1)
	@printf '[COM]   %-50s -> %s\n' "$$(patsubst $$(TOP)/%,%,$$<)" "$$(LIBNAME)"
	$$(COM)
	touch $(TAGS)/$$@

$$($(1)-unit).sim: $$($(1)-unit)
	@printf '[SIM]   %-50s\n' "$$(LIBNAME).$$(UNIT)"
	$$(ELAB)
	$$(RUN)
endef
$(foreach f,$(SRCS),$(eval $(call GEN_rule,$(f))))

# library list without duplicates
LIBS := $(sort $(LIBS))

# list libraries
libs:
	@printf '%s\n' $(LIBS)

# list units
units:
	@printf '%-36s%-36s\n' $(UNITS)

# compile all units
all: $(UNITS)
endif
endif

# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:

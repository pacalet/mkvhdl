# Copyright © Telecom Paris
# Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
#
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

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
TOP		:= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# project name
PROJECT		:= $(notdir $(TOP))
# name of local makefile for customizations
LOCAL		:= local.mk

# include local declarations if any
ifneq ($(wildcard $(TOP)/$(LOCAL)),)
include $(TOP)/$(LOCAL)
endif

# absolute real path of vhdl directory
VHDL		?= $(TOP)/vhdl
# simulator (ghdl, vsim or xsim)
SIM		?= ghdl
# GUI mode
GUI		?= no
ifneq ($(GUI),yes)
ifneq ($(GUI),no)
$(error "$(GUI): invalid GUI value")
endif
endif
# temporary build directory
DIR		?= /tmp/$(USER)/$(PROJECT)/$(SIM)
# compilation mode:
# - "work":    the default target library is work,
# - "dirname": the default target library is the one with same name as the
#   directory of the source file
MODE		?= work
ifneq ($(MODE),work)
ifneq ($(MODE),dirname)
$(error invalid MODE value: $(MODE))
endif
endif
# verbosity level: 0: quiet, 1: verbose
V		?= 0
ifeq ($(V),0)
.SILENT:
VERBOSE		:=
else ifeq ($(V),1)
VERBOSE		:= yes
else
$(error invalid V value: $(V))
endif

# 'make' is the same as 'make help'
.DEFAULT_GOAL	:= help

.PHONY: clean
clean:
	rm -rf $(DIR)

# if not clean and first make invocation
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(PASS),run)

# double-colon rule in case we want to add something elsewhere (e.g. in
# design-specific files)
# last resort default rule to invoke again with same goal and same Makefile but
# in $(DIR)
%::
	mkdir -p $(DIR)
	$(MAKE) --no-print-directory -C $(DIR) -f $(TOP)/Makefile $@ PASS=run

# second make invocation (in $(DIR))
else

.PHONY: help long-help list lib all

# all design files
SRCMK		:= $(shell find -L $(VHDL) -type f,l \( -name '*.vhd' -o -name '*.mk' \))
# all source files under $(VHDL)
SRC		:= $(patsubst $(VHDL)/%,%,$(filter %.vhd,$(SRCMK)))
# skip design units listed in SKIP
SRC		:= $(filter-out $(addprefix %/,$(addsuffix .vhd,$(SKIP))),$(SRC))
# design unit names (base names of source files without the .vhd extension)
NAME		:= $(patsubst %.vhd,%,$(notdir $(SRC)))
# simulation targets are NAME.sim
SIMULATIONS	:= $(addsuffix .sim,$(NAME))
# all dependency files under $(VHDL)
MK		:= $(filter %.mk,$(SRCMK))

# include dependency files
include $(MK)

# library list
LIB	:=

# target-specific variables, libraries
# $(1): source file path relative to $(VHDL)
define VAR_rule
$(1)-name		:= $$(patsubst %.vhd,%,$$(notdir $(1)))
ifeq ($$(MODE),work)
$$($(1)-name)-lib	?= work
else
$$($(1)-name)-lib	?= $$(notdir $$(patsubst %/,%,$$(dir $(1))))
endif
$$($(1)-name) $$($(1)-name).sim: LIBNAME = $$($$($(1)-name)-lib)
$$($(1)-name) $$($(1)-name).sim: NAME    = $$($(1)-name)

LIB	+= $$($$($(1)-name)-lib)
endef
$(foreach f,$(SRC),$(eval $(call VAR_rule,$(f))))

# library list without duplicates
LIB	:= $(sort $(LIB))

ifeq ($(SIM),ghdl)
COM		= ghdl -a --std=08 -frelaxed --work=$(LIBNAME) $(GHDLAFLAGS) $<
ELAB		:= true
ifeq ($(GUI),yes)
RUN		= ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(NAME) --wave=$(NAME).ghw $(GHDLRFLAGS); \
			printf 'GHW file: $(DIR)/$(NAME).ghw\nUse, e.g., GTKWave to display the GHW file\n'
else
RUN		= ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(NAME) $(GHDLRFLAGS)
endif
else ifeq ($(SIM),vsim)
COM		= vcom -nologo -quiet -2008 +acc -work $(LIBNAME) $<
ELAB		:= true
ifeq ($(GUI),yes)
RUN		= vsim -voptargs="+acc" $(VSIMFLAGS) $(LIBNAME).$(NAME)
else
RUN		= vsim -voptargs="+acc" -c -do 'run -all; quit' $(VSIMFLAGS) $(LIBNAME).$(NAME)
endif
else ifeq ($(SIM),xsim)
COM		= xvhdl -2008 --work $(LIBNAME) $< $(if $(VERBOSE),,> /dev/null)
ELAB		= xelab -debug all $(XELABFLAGS) $(LIBNAME).$(NAME)
ifeq ($(GUI),yes)
RUN		= xsim -gui $(LIBNAME).$(NAME)
else
RUN		= xsim -runall $(LIBNAME).$(NAME)
endif
else
$(error "$(SIM): invalid SIM value")
endif

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
    SKIP    -               NAMEs to ignore for compilation ($(SKIP))
    V       0|1             verbosity level ($(V))
    VHDL    -               absolute path of source files root directory ($(VHDL))

Goals:
    help                    this help (default goal)
    long-help               print long help
    lib                     print library names / directories
    NAME                    compile NAME.vhd
    list                    print existing NAMEs not in SKIP
    all                     compile all source files not in SKIP
    NAME.sim                simulate NAME
    clean                   delete temporary build directory
endef
export HELP_message

define LONG_HELP_message

This Makefile uses conventions; if your project is not compatible with the
conventions, please do not use this Makefile.

1. The directory containing this Makefile is the TOP directory. All make
commands must be launched from TOP:

cd TOP; make ...

or:

make -C TOP ...

2. The directory containing the source files is the VHDL directory. All source
files must be stored in the VHDL directory or its subdirectories and named
NAME.vhd where NAME is any combination of alphanumeric characters, plus
underscores (no spaces or tabs, for instance).

3. Each source file has a default target library: work if MODE=work, or the
name of the directory of the source file if MODE=dirname. Target libraries are
automatically created if they don't exist.

4. Source file names must be unique. It is not possible to have a
VHDL/core/version.vhd and a VHDL/interconnect/version.vhd.

5. The NAME.sim simulation goal simulates entity NAME defined in file NAME.vhd.
If you want to use this Makefile to launch simulations, name the source file of
your simulation environment according its entity name. Example: if the entity
of a simulation environment is arbiter_bench, name its source file
arbiter_bench.vhd and launch the simulation with:

make arbiter_bench.sim [VAR=VALUE...]

Note that the simulations are launched from the DIR temporary build directory.
If can matter if, for instance, a simulation environment reads or writes data
files.

6. Inter-file dependencies must be declared in text files with the .mk
extension and stored in VHDL or its subdirectories. The dependency syntax is:

NAME1 NAME2...: DEPNAME1 DEPNAME2...

Example: if icache.vhd and dcache.vhd must be compiled before mmu.vhd and
cpu.vhd, add the following to a .mk file somewhere under VHDL:

mmu cpu: icache dcache

The subdirectory in which a .mk file is stored does not matter. Note that the
letter case matters in dependency rules: if a source file is named CPU.vhd,
dependency rules must use CPU, not cpu or Cpu.

7. A target library other than the default can be specified on a per-source
file basis using NAME-lib variables. Example: if MODE=dirname and
VHDL/core/utils.vhd must be compiled in library common instead of the default
core, add the following to a .mk file somewhere under VHDL:

utils-lib := common

8. If there is a local.mk file in TOP, it is included before anything else. It
can be used to set configuration variables to other values than the default.
Example:

DIR  := /tmp/build          # temporary build directory
GUI  := yes                 # simulate with Graphical User Interface
MODE := work                # default target library
SIM  := vsim                # Modelsim toolchain
SKIP := bogus in_progress   # ignore bogus.vhd and in_progress.vhd
V    := 1                   # verbose mode enabled
VHDL := /home/joe/project   # absolute path of root directory of source files

Variable assignments on the command line overwrite assignments in the local.mk
file. Example to temporarily disable the GUI for a specific simulation:

make arbiter_bench.sim GUI=no

If you know how to use GNU make you can add other make constructs to
TOP/local.mk (or to other .mk files). Example if the simulation of
arbiter_bench depends on data file arbiter_bench.txt generated by the
VHDL/arbiter/bench.sh script, you can add the following to TOP/local.mk or to
VHDL/arbiter/arbiter.mk:

arbiter_bench.sim: $(DIR)/arbiter_bench.txt
$(DIR)/arbiter_bench.txt: $(VHDL)/arbiter/bench.sh
        $< > $@

endef
export LONG_HELP_message

help::
	@echo "$$HELP_message"

long-help::
	@echo "$$HELP_message"
	@echo "$$LONG_HELP_message"

lib:
	@printf '%-36s%-36s\n' "Library" "Directory" "-------" "---------"; \
	for l in $(LIB); do \
		printf '%-36s%-36s\n' "$$l" "$(DIR)/.$$l.lib"; \
	done

list:
	@printf '%-36s%-36s\n' "Existing NAMEs" "" "--------------" "" $(sort $(NAME))

# compilation, tag touch and simulation
# tags are empty files used to keep track of the last compilation time of the
# source files; they are stored in $(DIR) and their name is the base name of
# the source file without the .vhd extension
# $(1): source file path relative to $(VHDL)
define VHD_rule
$$($(1)-name): $$(VHDL)/$(1)
	@printf '[COM]   %-50s -> %s\n' "$$(patsubst $$(TOP)/%,%,$$<)" "$$(LIBNAME)"
	$$(COM)
	touch $$@

$$($(1)-name).sim: $$($(1)-name)
	@printf '[SIM]   %-50s\n' "$$(LIBNAME).$$(NAME)"
	$$(ELAB)
	$$(RUN)
endef
$(foreach f,$(SRC),$(eval $(call VHD_rule,$(f))))

.PHONY: $(addprefix .sim,$(NAME))

# compile all source files
all: $(NAME)
endif
endif

# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:

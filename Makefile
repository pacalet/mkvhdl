# Copyright © Telecom Paris
# Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
#
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

# Modelsim is not parallel-safe
.NOTPARALLEL:

# multiple goals not tested
ifneq ($(words $(MAKECMDGOALS)),1)
ifneq ($(words $(MAKECMDGOALS)),0)
$(error "multiple goals not supported")
endif
endif

# absolute real path of TOP directory
TOP			:= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# project name
PROJECT		:= $(notdir $(TOP))
# absolute real path of vhdl directory
VHDL		:= $(TOP)/vhdl
# local makefile for customization
LOCAL		:= $(TOP)/local.mk

# include local declarations if any
include $(wildcard $(LOCAL))

# simulator (ghdl, vsim or xsim)
SIM			?= ghdl
# GUI mode
GUI			?= no
# temporary build directory
DIR			?= /tmp/$(USER)/$(SIM)

ifneq ($(GUI),yes)
ifneq ($(GUI),no)
$(error "$(GUI): invalid GUI value")
endif
endif

# compilation mode:
# - "work":    the default target library is work,
# - "dirname": the default target library is the one with same name as the directory of the source file
MODE		?= work

# verbosity level: 0: quiet, 1: verbose
V			?= 0
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
# last resort default rule to invoke again with same goal and same Makefile but in $(DIR)
%::
	mkdir -p $(DIR)
	$(MAKE) --no-print-directory -C $(DIR) -f $(TOP)/Makefile $@ PASS=run

# second make invocation (in $(DIR))
else

.PHONY: help long-help list lib all

# all design files
SRCMK		:= $(shell find -L $(VHDL) -type f,l \( -name '*.vhd' -o -name '*.mk' \))
# all VHDL source files under $(VHDL)
SRC			:= $(patsubst $(VHDL)/%,%,$(filter %.vhd,$(SRCMK)))
# skip design units listed in SKIP
SRC			:= $(filter-out $(addprefix %/,$(addsuffix .vhd,$(SKIP))),$(SRC))
# design unit names (base names of source files without the .vhd extension)
NAME		:= $(patsubst %.vhd,%,$(notdir $(SRC)))
# simulation targets are NAME.sim
SIMULATIONS	:= $(addsuffix .sim,$(NAME))
# all dependency files under $(VHDL)
MK			:= $(filter %.mk,$(SRCMK))

# include dependency files
include $(MK)

# library list
LIB	:=

# target-specific variables, libraries
# $(1): source file path relative to $(VHDL)
define VAR_rule
$(1)-name			:= $$(patsubst %.vhd,%,$$(notdir $(1)))
ifeq ($$(MODE),work)
$$($(1)-name)-lib	?= work
else ifeq ($$(MODE),dirname)
$$($(1)-name)-lib	?= $$(notdir $$(patsubst %/,%,$$(dir $(1))))
else
$$(error invalid MODE value: $$(MODE))
endif
$$($(1)-name) $$($(1)-name).sim: LIBNAME = $$($$($(1)-name)-lib)
$$($(1)-name) $$($(1)-name).sim: NAME    = $$($(1)-name)

LIB	+= $$($$($(1)-name)-lib)
endef
$(foreach f,$(SRC),$(eval $(call VAR_rule,$(f))))

# library list without duplicates
LIB	:= $(sort $(LIB))

ifeq ($(SIM),ghdl)
COM			= ghdl -a --std=08 -frelaxed --work=$(LIBNAME) $(GHDLAFLAGS) $<
ELAB		:= true
ifeq ($(GUI),yes)
RUN			= ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(NAME) --wave=$(NAME).ghw $(GHDLRFLAGS); \
				printf 'GHW file: $(DIR)/$(NAME).ghw\nUse e.g. GTKWave to display the GHW file\n'
else
RUN			= ghdl --elab-run --std=08 -frelaxed --work=$(LIBNAME) $(NAME) $(GHDLRFLAGS)
endif
else ifeq ($(SIM),vsim)
COM			= vcom -nologo -quiet -2008 +acc -work $(LIBNAME) $<
ELAB		:= true
ifeq ($(GUI),yes)
RUN			= vsim -voptargs="+acc" $(VSIMFLAGS) $(LIBNAME).$(NAME)
else
RUN			= vsim -voptargs="+acc" -c -do 'run -all; quit' $(VSIMFLAGS) $(LIBNAME).$(NAME)
endif
else ifeq ($(SIM),xsim)
COM			= xvhdl -2008 --work $(LIBNAME) $< $(if $(VERBOSE),,> /dev/null)
ELAB		= xelab -debug all $(XELABFLAGS) $(LIBNAME).$(NAME)
ifeq ($(GUI),yes)
RUN			= xsim -gui $(LIBNAME).$(NAME)
else
RUN			= xsim -runall $(LIBNAME).$(NAME)
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

Variable  valid values       description (current value)
    SIM   {ghdl,vsim,xsim}   simulation toolchain ($(SIM))
    GUI   {yes,no}           use Graphical User Interface ($(GUI))
    DIR   -                  temporary build directory ($(DIR))
    MODE  {work,dirname}     default target library for compilations ($(MODE))
    SKIP  -                  NAMEs to ignore for compilation ($(SKIP))
    V     {0,1}              verbosity level ($(V))

Goals:
    help           print this short help message (default goal)
    long-help      print the long help message
    lib            print the list of libraries and their associated directory
    NAME           compile VHDL source file NAME.vhd
    list           print list of all existing NAMEs not in SKIP
    all            compile all VHDL source files not in SKIP
    NAME.sim       simulate entity NAME
    clean          delete temporary build directory
endef
export HELP_message

define LONG_HELP_message

This Makefile uses several conventions that must absolutely be complied with.
If for any reason you cannot comply with these conventions, do not use this
Makefile. The conventions are the following:

1. The directory containing this Makefile is the TOP directory. All make
commands must be launched from TOP.

2. VHDL source files must be stored under TOP/vhdl and named NAME.vhd where
NAME is any combination of alphanumeric characters, plus underscore (no
spaces, for instance).

3. Each VHDL source file has a default target library in which it is compiled.
If MODE=work this default target library is work. If MODE=dirname it is the
library with the same name as the directory of the source file. The target
library is automatically created if it does not exist yet.

4. VHDL source file names must be unique. It is not possible to have a
TOP/vhdl/bar/foo.vhd and a TOP/vhdl/qux/foo.vhd.

5. The NAME.sim simulation goals assume that the entity to simulate is NAME
and that it is defined in file NAME.vhd. If you want to use this Makefile to
launch simulations, name the VHDL source files of your simulation environments
according their entity names. Example: if the entity of a simulation
environment is foo_sim, name its VHDL source file foo_sim.vhd and launch the
simulation with:

make foo_sim.sim [VAR=VALUE...]

6. Inter-file dependencies must be declared in text files with the .mk
extension and stored under TOP/vhdl or its subdirectories. The dependency
syntax is that of make rules without recipes and using only the basename of
the VHDL source files without the .vhd extension. If TOP/vhdl/foo/bar.mk
exists and contains:

bar: qux corge grault
foo garply: corge fred

it means that bar.vhd cannot be compiled before qux.vhd, corge.vhd and
grault.vhd have been compiled. Similarly, foo.vhd and garply.vhd cannot be
compiled before corge.vhd and fred.vhd. The subdirectory in which a .mk file
is stored does not matter. Note that the letter case matters: if a VHDL source
file is named BaR.vhd, dependency rules must use BaR, not bar or Bar.

7. In the same .mk files a target VHDL library other than the default can be
specified on a per-source file basis using NAME-lib variables. If there is a
foo/bar.vhd VHDL source file and one of these .mk files contains:

bar-lib := barlib

it means that foo/bar.vhd must be compiled in VHDL library barlib instead of
the default work (if MODE=work) or foo (if MODE=dirname).

8. If TOP contains a local.mk file, it is included before anything else. It
can be used to define make variables with custom values. If TOP/local.mk
exists and contains:

DIR  := /home/joe/project
MODE := work
SIM  := vsim
GUI  := yes
SKIP := bogus gusbo
V    := 1

the temporary build directory is /home/joe/project, the default target library
of compilations is work, the simulation toolchain is Modelsim, all simulations
are run with the Graphical User Interface, the bogus.vhd and gusbo.vhd source
files are ignored and the verbose mode is enabled. Variable assignments on the
command line overwrite assignments in the local.mk file. If you know how to use
GNU make you can add other make constructs to the local.mk (or to other .mk
files).
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
# tags are empty files used to keep track of the last compilation time of
# the VHDL source files; they are stored in $(DIR) and their name is the
# base name of the source file without the .vhd extension
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

# compile all VHDL source files
all: $(NAME)
endif
endif

# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:


# File: Makefile
# Author: Purush
# Date Created: February 24, 2024
# Last Modified: February 24, 2024
# Description: initial version of  cocotb Makefile
# Copyright (c) May 12, 2024 Purush
# License: All rights reserved
# Dependencies: 
# Contact: emailpurush@gmail.com
# Usage Notes: 
               

# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog
PWD = $(shell pwd)

# VERILOG_SOURCES = $(PWD)/rtl/multiplier_top.sv  $(PWD)/rtl/multiplier.sv 
VERILOG_SOURCES := $(wildcard $(PWD)/rtl/*.sv)
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = multiplier_top_wrapper

# MODULE is the basename of the Python test file
MODULE = tb.tb_multiplier_top

# to get trace when using verilator
EXTRA_ARGS += --trace  --trace-structs  -Wno-{WIDTHEXPAND,WIDTHTRUNC} 
# EXTRA_ARGS += --trace-fst --trace-structs 


# verilator build directory
SIM_BUILD = build/sim_build

TRACE_DIR ?= build

TRACE_FILE ?= $(TOPLEVEL)

PLUSARGS ?= --dmpfile $(TRACE_DIR) $(TRACE_FILE)

COCOTB_RESULTS_FILE = build/results.xml

# COCOTB_HDL_TIMEUNIT = 1ns
# COCOTB_HDL_TIMEPRECISION = 1ps


# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

multiplier: cleanall 
	mkdir -p build; \
	make sim;

cleanall: clean
	rm -rf build


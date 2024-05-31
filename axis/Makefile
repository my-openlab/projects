
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

# VERILOG_SOURCES = $(PWD)/rtl/target_top.sv  $(PWD)/rtl/target.sv 
VERILOG_SOURCES := $(shell cat rtl/sources.lst) axis_tb/axis_fifo_wrapper.sv
# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = axis_fifo_wrapper

# MODULE is the basename of the Python test file
MODULE = axis_tb.tb_axis_fifo

COMPILE_ARGS += -GDATA_W=8  -GID_EN=0 -GUSR_EN=0 -GDST_EN=0 -GRAM_PIPELINE=1
# to get trace when using verilator
EXTRA_ARGS += --trace  --trace-structs  -Wno-{WIDTHEXPAND,WIDTHTRUNC,SELRANGE}  +1800-2017ext+sv
# EXTRA_ARGS += --trace-fst --trace-structs 


# verilator build directory
SIM_BUILD = build/verilator_build

TRACE_DIR ?= build

TRACE_FILE ?= $(TOPLEVEL)

PLUSARGS ?= --dmpfile $(TRACE_DIR) $(TRACE_FILE)

COCOTB_RESULTS_FILE = build/results.xml

# COCOTB_HDL_TIMEUNIT = 1ns
# COCOTB_HDL_TIMEPRECISION = 1ps


# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim


.PHONY:waves, target, cleanall

waves: target
	@echo
	@echo "### WAVES ###"
	gtkwave $(TRACE_DIR)/$(TOPLEVEL).vcd -a wave.gtkw

target: cleanall 
	mkdir -p build; \
	make sim;

cleanall: clean
	rm -rf build


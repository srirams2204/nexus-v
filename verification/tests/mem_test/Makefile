SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Project Root Directory
PROJ_ROOT = $(PWD)/../../..
INCLUDE_DIR = $(PROJ_ROOT)/rtl/core/include

# Verilog Source File Directory
#VERILOG_SOURCES += $(PROJ_ROOT)/rtl/core/sc_stages/fetch_cycle.sv
#VERILOG_SOURCES += $(PROJ_ROOT)/rtl/core/units/pc.sv
VERILOG_SOURCES += $(PROJ_ROOT)/rtl/core/units/data_mem.sv

# Compiler Argument
ifeq ($(SIM), icarus)
	COMPILE_ARGS += -I $(INCLUDE_DIR) -DCOCOTB_SIM
endif

ifeq ($(SIM), vcs)
	COMPILE_ARGS += +define+COCOTB_SIM +define+VCS
	COMPILE_ARGS += +incdir+$(INCLUDE_DIR) 
	COMPILE_ARGS += -full64 -debug_access+all -lca -kdb -sverilog
endif

# Top Level Module name
TOPLEVEL = data_mem

# Python File name
MODULE = test_mem

# Cocotb makefile rule
include $(shell cocotb-config --makefiles)/Makefile.sim
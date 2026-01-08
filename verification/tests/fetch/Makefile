# Makefile for Fetch Stage Verification

# -----------------------------------------------------------------------------
# 1. Simulator Settings
# -----------------------------------------------------------------------------
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# -----------------------------------------------------------------------------
# 2. Path Definitions
# -----------------------------------------------------------------------------
# We use $(PWD) to ensure absolute paths, which avoids confusion in the simulator.
# Current dir: verification/tests/fetch
# Root dir:    verification/tests/fetch/../../..

PROJ_ROOT = $(PWD)/../../..
RTL_CORE  = $(PROJ_ROOT)/rtl/core
FIRMWARE  = $(PROJ_ROOT)/firmware

# -----------------------------------------------------------------------------
# 3. Source Files
# -----------------------------------------------------------------------------
# The Units
VERILOG_SOURCES += $(RTL_CORE)/units/pc.v
VERILOG_SOURCES += $(RTL_CORE)/units/instr_mem.v

# The Stage Wrapper (DUT)
VERILOG_SOURCES += $(RTL_CORE)/stages/fetch_cycle.v

# Include directory for rv_defs.vh
COMPILE_ARGS += -I$(RTL_CORE)/include

# Define the path to hex file
HEX_FILE = $(FIRMWARE)/program.hex

# Override the 'PROGRAM_FILE' parameter in the top-level Verilog module.
# We pass the absolute path so the simulator can find it from anywhere.
# Note: The escaped quotes \" are necessary for string parameters in Icarus.
COMPILE_ARGS += -Pfetch_cycle.PROGRAM_FILE=\"$(HEX_FILE)\"

# -----------------------------------------------------------------------------
# Cocotb Setup
# -----------------------------------------------------------------------------
# The name of your Top Level Verilog Module
TOPLEVEL = fetch_cycle

# The name of your Python Test file (without .py)
MODULE = test_fetch

# NEW: Enable Waveform Dumping
COMPILE_ARGS += -DCOCOTB_SIM

# Include the standard Cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim
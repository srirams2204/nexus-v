# Directories
SRC_DIR := src
TB_DIR := testbench
SIM_DIR := sim
WAVE_DIR := waveform

# Tools
IVERILOG := iverilog
VVP := vvp

# Pass filenames (without .v) from terminal
# Example: make run SRC=my_design TB=tb_my_design
SRC ?= my_design
TB ?= tb_my_design

# File paths (Updated to .v)
SRC_FILE := $(SRC_DIR)/$(SRC).v
TB_FILE := $(TB_DIR)/$(TB).v
VVP_FILE := $(SIM_DIR)/$(SRC).vvp
VCD_FILE := $(WAVE_DIR)/$(SRC).vcd

# --- CRITICAL FIX ---
# We use $(wildcard ...) to correctly find all .v files in the src directory.
# This ensures modules like alu.v, decoder.v, etc. are included.
ALL_SRC_FILES := $(wildcard $(SRC_DIR)/*.v)

# Default target
all: run

# Compile the design
# Depends on the Testbench and ALL source files
$(VVP_FILE): $(TB_FILE) $(ALL_SRC_FILES)
	@mkdir -p $(SIM_DIR) $(WAVE_DIR)
	# Command: iverilog -I src -o output.vvp testbench.v src/*.v
	$(IVERILOG) -I $(SRC_DIR) -o $(VVP_FILE) $(TB_FILE) $(ALL_SRC_FILES)

# Run simulation
run: $(VVP_FILE)
	$(VVP) $(VVP_FILE)

# Open waveform in GTKWave
wave: $(VCD_FILE)
	gtkwave $(VCD_FILE) 

# Clean generated files
clean:
	rm -rf $(SIM_DIR)/* $(WAVE_DIR)/*

.PHONY: all run wave clean
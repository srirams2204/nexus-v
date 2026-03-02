# =============================================================================
# Nexus-V Icarus Verilog Makefile
# =============================================================================

# Root and Build directories
ROOT_DIR      := .
BUILD_DIR     := $(ROOT_DIR)/build
WAVE_DIR      := $(ROOT_DIR)/waveform

# Design Directory
RTL_DIR       := $(ROOT_DIR)/rtl
TB_DIR        := testbench

# Functional Block Subdirectories
COMMON_DIR    := $(RTL_DIR)/common
CORE_DIR      := $(RTL_DIR)/core
BUS_DIR       := $(RTL_DIR)/bus_protocol
PERIPH_DIR    := $(RTL_DIR)/peripherals
SOC_DIR       := $(RTL_DIR)/soc

# -------------------------------------------------
# MANUALLY SET YOUR TESTBENCH HERE
# -------------------------------------------------
TB_SRC        := $(TB_DIR)/mcu_test.v

# Extract testbench name to name the outputs dynamically
TB_NAME       := $(basename $(notdir $(TB_SRC)))
TARGET        := $(BUILD_DIR)/$(TB_NAME).vvp
VCD_OUT       := $(WAVE_DIR)/$(TB_NAME).vcd

# Source files
COMMON_HDR    := $(COMMON_DIR)/rv_defs.vh

CORE_SRCS     := $(wildcard $(CORE_DIR)/*.v)
BUS_SRCS      := $(wildcard $(BUS_DIR)/*.v)
SOC_SRCS      := $(wildcard $(SOC_DIR)/*.v)
PERIPH_SRCS   := $(wildcard $(PERIPH_DIR)/*.v)

ALL_SRCS      := $(COMMON_HDR) \
                 $(CORE_SRCS) \
                 $(BUS_SRCS) \
                 $(SOC_SRCS) \
                 $(PERIPH_SRCS) \
                 $(TB_SRC)

# Tools and Flags
IVERILOG      := iverilog
VVP           := vvp
GTKWAVE       := gtkwave
CFLAGS        := -g2012 -Wall -I$(COMMON_DIR)

# -------------------------------------------------
# Default Target
# -------------------------------------------------
all: run

# -------------------------------------------------
# Create Directories
# -------------------------------------------------
dirs:
	mkdir -p $(BUILD_DIR) $(WAVE_DIR)

# -------------------------------------------------
# Compile 
# -------------------------------------------------
compile: dirs
	@echo "========================================"
	@echo "Compiling $(TB_NAME)..."
	@echo "========================================"
	$(IVERILOG) $(CFLAGS) -o $(TARGET) $(ALL_SRCS)

# -------------------------------------------------
# Run Simulation & Manage Waveform
# -------------------------------------------------
run: compile
	@echo "========================================"
	@echo "Running Simulation for $(TB_NAME)..."
	@echo "========================================"
	$(VVP) $(TARGET)
	@echo "Moving waveform to $(WAVE_DIR)..."
	@mv *.vcd $(VCD_OUT) 2>/dev/null || true
	@echo "Done. Run 'make view' to open GTKWave."

# -------------------------------------------------
# View Waveform
# -------------------------------------------------
view:
	@echo "Opening $(VCD_OUT) in GTKWave..."
	$(GTKWAVE) $(VCD_OUT) &

# -------------------------------------------------
# Clean
# -------------------------------------------------
clean:
	rm -rf $(BUILD_DIR) $(WAVE_DIR)
	@echo "Cleaned build and waveform directories."

.PHONY: all dirs compile run view clean
# =============================================================================
# Nexus-V Icarus Verilog Makefile
# =============================================================================

ROOT_DIR      := .
BUILD_DIR     := build
RTL_DIR       := $(ROOT_DIR)/rtl

COMMON_DIR    := $(RTL_DIR)/common
CORE_DIR      := $(RTL_DIR)/core
BUS_DIR       := $(RTL_DIR)/bus_protocol
PERIPH_DIR    := $(RTL_DIR)/peripherals
SOC_DIR       := $(RTL_DIR)/soc

# 1. Target the definitions header file
COMMON_HDR    := $(COMMON_DIR)/rv_defs.vh

CORE_SRCS     := $(wildcard $(CORE_DIR)/*.v)
BUS_SRCS      := $(wildcard $(BUS_DIR)/*.v)
SOC_SRCS      := $(wildcard $(SOC_DIR)/*.v)
PERIPH_SRCS   := $(wildcard $(PERIPH_DIR)/*.v)

TB_SRC        := testbench/csr_test.v

# 2. Put the header file at the VERY TOP of the compilation list
ALL_SRCS      := $(COMMON_HDR) \
                 $(CORE_SRCS) \
                 $(BUS_SRCS) \
                 $(SOC_SRCS) \
                 $(PERIPH_SRCS) \
                 $(TB_SRC)

IVERILOG      := iverilog
VVP           := vvp

CFLAGS        := -g2012 -Wall -I$(COMMON_DIR)

TARGET        := $(BUILD_DIR)/nexus_v_sim.out

# -------------------------------------------------
# Default Target
# -------------------------------------------------
all: compile run

# -------------------------------------------------
# Create Build Directory
# -------------------------------------------------
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# -------------------------------------------------
# Compile
# -------------------------------------------------
compile: $(BUILD_DIR)
	@echo "Compiling with Icarus Verilog..."
	$(IVERILOG) $(CFLAGS) -o $(TARGET) $(ALL_SRCS)

# -------------------------------------------------
# Run Simulation
# -------------------------------------------------
run:
	@echo "Running Simulation..."
	$(VVP) $(TARGET)

# -------------------------------------------------
# Clean
# -------------------------------------------------
clean:
	rm -rf $(BUILD_DIR)

.PHONY: all compile run clean
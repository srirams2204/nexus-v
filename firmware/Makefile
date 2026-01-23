# ==========================================
# RISC-V Bare Metal Makefile
# ==========================================

# Toolchain Prefix
# Note: If your system uses 'riscv64-unknown-elf-', change this line below.
CROSS_COMPILE ?= riscv32-unknown-elf-

CC      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
HEXDUMP = hexdump

# Compiler Flags (Exactly as requested)
# -march=rv32i      : Target RISC-V 32-bit Integer ISA
# -mabi=ilp32       : Integer Logic pointer 32-bit
# -O0               : No optimization (good for debugging)
# -fno-builtin      : Do not use built-in C functions
# -nostartfiles     : Do not link standard startup code (we use crt0.s)
CFLAGS  = -march=rv32i -mabi=ilp32 -O0 -fno-builtin -nostartfiles

# Linker Script
LDFLAGS = -T link.ld

# Source Files
# You can change 'test.c' to whatever your main C file is called
SRCS    = crt0.s test.c
TARGET  = test

# ==========================================
# Build Rules
# ==========================================

# Default target: build the hex file
all: $(TARGET).hex

# 1. Compile and Link (ELF Generation)
$(TARGET).elf: $(SRCS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS)

# 2. Extract Binary (ELF -> BIN)
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# 3. Generate Hex (BIN -> HEX)
# Uses the exact hexdump format you verified
$(TARGET).hex: $(TARGET).bin
	$(HEXDUMP) -v -e '1/4 "%08x" "\n"' $< > $@

# Clean up build artifacts
clean:
	rm -f *.elf *.bin *.hex

.PHONY: all clean
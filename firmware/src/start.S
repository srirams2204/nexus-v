.section .init, "ax"
.global _start

_start:
    # ----------------------------------------------------------------
    # 1. Setup the Stack Pointer (sp)
    # The linker script calculated _sp as 0x2000.
    # ----------------------------------------------------------------
    la sp, _sp

    # ----------------------------------------------------------------
    # 2. Setup the Global Pointer (gp)
    # This helps GCC optimize memory accesses for global variables.
    # ----------------------------------------------------------------
    .option push
    .option norelax
    la gp, _sp
    .option pop

    # ----------------------------------------------------------------
    # 3. Setup the Trap Vector (mtvec)
    # Tell the hardware CSR exactly where our exception handler lives.
    # ----------------------------------------------------------------
    la t0, _trap_handler
    csrw mtvec, t0

    # ----------------------------------------------------------------
    # 4. Clear the BSS Section
    # C requires uninitialized global variables to default to 0.
    # Hardware RAM powers up with garbage, so we must zero it manually.
    # ----------------------------------------------------------------
    la t0, _sbss
    la t1, _ebss
bss_clear_loop:
    bge t0, t1, bss_clear_done   # If start >= end, we are done
    sw zero, 0(t0)               # Store 0 into RAM
    addi t0, t0, 4               # Move to next 32-bit word
    j bss_clear_loop
bss_clear_done:

    # ----------------------------------------------------------------
    # 5. Enter C Code
    # ----------------------------------------------------------------
    call main

    # ----------------------------------------------------------------
    # 6. Safe Halt (If main() ever returns)
    # ----------------------------------------------------------------
halt:
    j halt


# --------------------------------------------------------------------
# Base Exception Handler
# --------------------------------------------------------------------
.section .trap, "ax"
.global _trap_handler

_trap_handler:
    # Save context (registers) here if handling real hardware interrupts
    
    # Check if it was an ECALL (mcause == 11)
    csrr t0, mcause
    li t1, 11
    bne t0, t1, trap_exit  # If not ECALL, skip mepc increment

    # Increment mepc by 4 so we return to the instruction AFTER the ecall
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0

trap_exit:
    mret
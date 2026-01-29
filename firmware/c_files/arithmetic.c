#include <stdint.h>

#define TIMER_ADDR 0x80000008
#define UART_TX     0x80000100

volatile uint32_t* const TIMER = (uint32_t*) TIMER_ADDR;
volatile uint32_t* const UART  = (uint32_t*) UART_TX;

#define ITERATIONS  1000       // Number of loop cycles
#define BLOCK_SIZE  20         // Instructions per assembly block 
#define CPU_FREQ_MHZ 50        // Clock frequency

void uart_putc(char c) {
    *UART = c;
}

void print_str(char *str) {
    while (*str) uart_putc(*str++);
}

void print_hex(uint32_t val) {
    char hex[] = "0123456789ABCDEF";
    uart_putc('0'); uart_putc('x');
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex[(val >> i) & 0xF]);
    }
    print_str("\n");
}

void main() {
    uint32_t start_time, end_time, total_cycles;
    
    // Header
    print_str("\n=== Nexus-V ALU Benchmark ===\n");
    print_str("Testing R-Type and I-Type Performance...\n");

    // Initialize Registers to avoid 'X' propagation in simulation
    // We do this via inline asm to be safe
    asm volatile (
        "li x10, 50 \n\t"  // Load immediate values
        "li x11, 20 \n\t"
        "li x5,  0xAAAA \n\t"
    );

    // --- START TIMER ---
    start_time = *TIMER;

    // --- THE WORKLOAD ---
    // This loop runs 1000 times.
    // The ASM block contains EXACTLY 20 Instructions.
    // Total Instructions = 1000 * 20 = 20,000 Instructions.
    for (int i = 0; i < ITERATIONS; i++) {
        asm volatile (
            // --- Arithmetic (R-Type) ---
            "add  x12, x10, x11 \n\t"  // 1. Add
            "sub  x13, x10, x11 \n\t"  // 2. Sub
            "slt  x14, x11, x10 \n\t"  // 3. Set Less Than
            "sltu x14, x11, x10 \n\t"  // 4. Set Less Than Unsigned

            // --- Logical (R-Type) ---
            "xor  x5,  x5,  x10 \n\t"  // 5. XOR
            "or   x5,  x5,  x11 \n\t"  // 6. OR
            "and  x5,  x5,  x12 \n\t"  // 7. AND
            
            // --- Shifts (R-Type) ---
            "sll  x6,  x10, x11 \n\t"  // 8. Shift Left Logical
            "srl  x6,  x10, x11 \n\t"  // 9. Shift Right Logical
            "sra  x6,  x10, x11 \n\t"  // 10. Shift Right Arithmetic

            // --- Immediates (I-Type) ---
            "addi x10, x10, 1   \n\t"  // 11. Add Immediate
            "xori x5,  x5,  0xFF\n\t"  // 12. XOR Immediate
            "ori  x5,  x5,  0x0F\n\t"  // 13. OR Immediate
            "andi x5,  x5,  0xF0\n\t"  // 14. AND Immediate
            "slti x14, x10, 100 \n\t"  // 15. SLT Immediate

            // --- Shift Immediates (I-Type) ---
            "slli x6,  x10, 2   \n\t"  // 16. Shift Left Imm
            "srli x6,  x10, 2   \n\t"  // 17. Shift Right Imm
            "srai x6,  x10, 2   \n\t"  // 18. Shift Right Arith Imm
            
            // --- Padding/NOPs ---
            "add  x0,  x0,  x0  \n\t"  // 19. NOP (Pseudo-instruction)
            "add  x0,  x0,  x0  \n\t"  // 20. NOP
        );
    }

    // --- STOP TIMER ---
    end_time = *TIMER;

    // --- REPORTING ---
    total_cycles = end_time - start_time;
    uint32_t total_instructions = ITERATIONS * BLOCK_SIZE;

    print_str("Total Cycles:   ");
    print_hex(total_cycles);
    
    print_str("Inst Count:     ");
    print_hex(total_instructions);

    print_str("\n--- Copy these values for MIPS Calculation ---\n");
    
    // Stop safely
    while(1);
}
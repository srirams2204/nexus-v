// ============================================
// RISC-V RV32I CPU Definitions Header
// ============================================
`ifndef RV_DEFS_VH
`define RV_DEFS_VH

// --------------------------------------------
// Global Parameters
// --------------------------------------------
`define WIDTH 32

// --------------------------------------------
// FSM States (For FPGA BRAM Timing)
// --------------------------------------------
`define STATE_FETCH     2'b00
`define STATE_RF_READ   2'b01
`define STATE_EXECUTE   2'b10
`define STATE_MEM_WAIT  2'b11

// --------------------------------------------
// PC Parameters
// --------------------------------------------
`define PC_RESET 32'h0000_0000

// --------------------------------------------
// Writeback Source Select (result_src)
// --------------------------------------------
`define WB_ALU    1'b0  // Writeback from ALU Result
`define WB_MEM    1'b1  // Writeback from Data Memory

// --------------------------------------------
// Opcode field values (instr[6:0])
// --------------------------------------------
`define OPCODE_R_TYPE   7'b0110011

// I-type
`define OPCODE_I_TYPE   7'b0010011   // Arithmetic Immediate
`define OPCODE_LOAD     7'b0000011   // LB/LH/LW
`define OPCODE_JALR     7'b1100111   // Jump and Link Reg

// S-type
`define OPCODE_STORE    7'b0100011

// B-type
`define OPCODE_BRANCH   7'b1100011

// U-type
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111

// J-type
`define OPCODE_JAL      7'b1101111

// --------------------------------------------
// Sign Extension Operation Select Bits
// --------------------------------------------
`define IMM_NONE 3'd0
`define IMM_I    3'd1
`define IMM_S    3'd2
`define IMM_B    3'd3
`define IMM_U    3'd4
`define IMM_J    3'd5

// --------------------------------------------
// ALU Operation Select Bits
// --------------------------------------------
`define ADD   4'b0000
`define SUB   4'b0001
`define XOR   4'b0010
`define OR    4'b0011
`define AND   4'b0100
`define SLL   4'b0101
`define SRL   4'b0110
`define SRA   4'b0111
`define SLT   4'b1000
`define SLTU  4'b1001
`define COPY_B 4'b1011 // Optional: Useful for LUI (Pass Immediate)

`endif
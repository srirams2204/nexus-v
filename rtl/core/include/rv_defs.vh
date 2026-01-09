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
// Program Counter Parameters
// --------------------------------------------
`define PC_RST 32'd0

// --------------------------------------------
// ALU Operation Select Bits
// --------------------------------------------
`define ADD   4'b0000  // 0
`define SUB   4'b0001  // 1
`define XOR   4'b0010  // 2
`define OR    4'b0011  // 3
`define AND   4'b0100  // 4
`define SLL   4'b0101  // 5
`define SRL   4'b0110  // 6
`define SRA   4'b0111  // 7
`define SLT   4'b1000  // 8
`define SLTU  4'b1001  // 9

`endif
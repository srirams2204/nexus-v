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

// PC Source Select (pc_src)
`define PC_JUMP   1'b1  // RS1 + Imm (JALR)


`endif
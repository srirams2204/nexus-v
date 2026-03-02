`ifndef RV_DEFS_VH
`define RV_DEFS_VH

`define XLEN 32

// OPCODES
`define OPCODE_R_TYPE   7'b0110011
`define OPCODE_I_TYPE   7'b0010011   // Arithmetic Immediate
`define OPCODE_LOAD     7'b0000011   // LB/LH/LW
`define OPCODE_JALR     7'b1100111   // Jump and Link Reg
`define OPCODE_STORE    7'b0100011
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_JAL      7'b1101111
// SYSTEM Instruction
`define OPCODE_SYS      7'b1110011

// Sign/Zero Extension Select Signals
`define IMM_NONE 3'd0
`define IMM_I    3'd1
`define IMM_S    3'd2
`define IMM_B    3'd3
`define IMM_U    3'd4
`define IMM_J    3'd5
`define IMM_CSR  3'd6

// ALU Select Signals
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

`endif
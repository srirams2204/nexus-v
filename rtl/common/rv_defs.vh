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
`define S_FETCH       4'd1
`define S_FETCH_WAIT  4'd2
`define S_DECODE      4'd3
`define S_EXECUTE     4'd4
`define S_WB          4'd5
`define S_MEM_READ    4'd6
`define S_MEM_WAIT    4'd7
`define S_MEM_WRITE   4'd8
`define S_BRANCH      4'd9
`define S_JALR        4'd10
`define S_TRAP        4'd11

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

// SYSTEM Instruction
`define OPCODE_SYS      7'b1110011

// --------------------------------------------
// Sign Extension Operation Select Bits
// --------------------------------------------
`define IMM_NONE 3'd0
`define IMM_I    3'd1
`define IMM_S    3'd2
`define IMM_B    3'd3
`define IMM_U    3'd4
`define IMM_J    3'd5
`define IMM_CSR  3'd6

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

// --------------------------------------------
// SYSTEM/CSR Instruction Funct3 codes
// --------------------------------------------
`define FUNCT3_SYS_PRIV  3'b000  // MRET, ECALL, EBREAK
`define FUNCT3_CSRRW     3'b001  // Atomic Read/Write CSR
`define FUNCT3_CSRRS     3'b010  // Atomic Read/Set CSR
`define FUNCT3_CSRRC     3'b011  // Atomic Read/Clear CSR
`define FUNCT3_CSRRWI    3'b101  // Atomic Read/Write CSR Imm
`define FUNCT3_CSRRSI    3'b110  // Atomic Read/Set CSR Imm
`define FUNCT3_CSRRCI    3'b111  // Atomic Read/Clear CSR Imm

// --------------------------------------------
// CSR Addresses (Commonly Used)
// --------------------------------------------
`define CSR_MSTATUS      12'h300
`define CSR_MIE          12'h304
`define CSR_MTVEC        12'h305
`define CSR_MEPC         12'h341
`define CSR_MCAUSE       12'h342
`define CSR_MIP          12'h344

`endif

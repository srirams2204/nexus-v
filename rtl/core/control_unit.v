`timescale 1ns/1ps
`include "rv_defs.vh"
module control_unit (
    // PC and Fetch Control
    output reg pc_write,
    output reg fbuf_en,
    output reg [1:0]  pc_src_sel,
    
    // Decode and Imm Gen
    output reg reg_write,
    output reg rf_latch_en,
    output reg [2:0]  imm_sel,
    
    // ALU Control
    output reg [1:0]  alu_a_sel,          
    output reg [1:0]  alu_b_sel,          
    output reg [3:0]  alu_sel, 
    output reg aluout_en,
    
    // Mem and Write Back
    output reg mem_read,
    output reg mem_write,
    output reg [1:0]  wb_sel,
    
    // CSR and Trap interface
    output reg csr_we,
    output reg [1:0]  csr_op,
    output reg trap_enter,
    output reg mret_exec,
    output reg [31:0] trap_cause,
    input  [31:0] interrupt_cause,
    
    // Inputs from Datapath/Peripherals
    input [31:0] instr_in,
    input zero,
    input lt_signed,
    input lt_unsigned,
    input bus_ready,
    input interrupt_pending,
    
    // Global Signals
    input clk,
    input rst
);

localparam S_FETCH      = 4'd1;
localparam S_FETCH_WAIT = 4'd2;
localparam S_DECODE     = 4'd3;
localparam S_EXECUTE    = 4'd4;
localparam S_WB         = 4'd5;
localparam S_MEM_READ   = 4'd6;
localparam S_MEM_WAIT   = 4'd7;
localparam S_MEM_WRITE  = 4'd8;
localparam S_BRANCH     = 4'd9;
localparam S_JALR       = 4'd10;
localparam S_TRAP       = 4'd11; 
localparam S_CSR        = 4'd12;

// State registers
reg [3:0] state, next_state;
reg [31:0] trap_cause_reg;
reg [31:0] next_trap_cause;
reg next_trap_type;

// instr decode wire
wire [6:0] opcode = instr_in[6:0];
wire [2:0] funct3 = instr_in[14:12];
wire [6:0] funct7 = instr_in[31:25];

wire is_rtype  = (opcode == 7'b0110011);
wire is_itype  = (opcode == 7'b0010011);
wire is_load   = (opcode == 7'b0000011);
wire is_store  = (opcode == 7'b0100011);
wire is_branch = (opcode == 7'b1100011);
wire is_jal    = (opcode == 7'b1101111);
wire is_jalr   = (opcode == 7'b1100111);
wire is_lui    = (opcode == 7'b0110111);
wire is_auipc  = (opcode == 7'b0010111);
wire is_system = (opcode == 7'b1110011);

wire [11:0] imm12 = instr_in[31:20];
wire system_instr = (opcode == `OPCODE_SYS);
wire privileged_instr = system_instr && (funct3 == 3'b000);

wire ecall_true = privileged_instr && (imm12 == 12'h000);  // ecall identification
wire ebreak_true = privileged_instr && (imm12 == 12'h001); // ebreak identification
wire mret_true  = privileged_instr && (imm12 == 12'h302);  // mret identification

always @(posedge clk) begin
    if (rst) begin
        state          <= S_FETCH;
        trap_cause_reg <= 32'b0;
    end else begin
        state <= next_state;
        // Latch the cause ONLY when transitioning into S_TRAP
        if (next_state == S_TRAP && state != S_TRAP) begin
            trap_cause_reg <= next_trap_cause;
        end
    end
end

always @(*) begin
    next_state = state;
    pc_write = 1'b0;
    fbuf_en = 1'b0;
    pc_src_sel = 2'b00; // default ALU in

    reg_write = 1'b0;
    rf_latch_en = 1'b0;

    case(opcode)
        `OPCODE_STORE: imm_sel = `IMM_S;
        `OPCODE_BRANCH: imm_sel = `IMM_B;
        `OPCODE_JAL: imm_sel = `IMM_J;
        `OPCODE_LUI, `OPCODE_AUIPC: imm_sel = `IMM_U;
        `OPCODE_LOAD, `OPCODE_JALR: imm_sel = `IMM_I; 
        `OPCODE_I_TYPE: imm_sel = `IMM_I;
        `OPCODE_SYS: begin
            if (funct3[2]) imm_sel = `IMM_CSR;
            else imm_sel = `IMM_NONE;
        end
        default: imm_sel = `IMM_NONE;
    endcase

    alu_a_sel = 2'b00; // Default to RS1
    alu_b_sel = 2'b00; // Default to RS2
    alu_sel = `ADD; // Default to ADD
    aluout_en = 1'b0;

    mem_read = 1'b0;
    mem_write = 1'b0;
    wb_sel = 2'b00;

    csr_we = 1'b0;
    csr_op = 2'b00;
    trap_enter = 1'b0;
    mret_exec = 1'b0;

    next_trap_cause = 32'd2; // Default to Illegal Instruction
    trap_cause = trap_cause_reg;

    case (state)
        S_FETCH: begin
            if (interrupt_pending) begin
                next_trap_cause = interrupt_cause;
                next_state = S_TRAP;
            end else begin
                // Prepare PC + 4 using the ALU
                alu_a_sel  = 2'b11; // Select FetchPC
                alu_b_sel  = 2'b10; // Select constant 4
                alu_sel    = `ADD; // ADD
                pc_src_sel = 2'b00; // Next PC comes from ALU result
                /*
                if (bus_ready) begin
                    pc_write = 1'b1;
                    fbuf_en = 1'b1;
                    next_state = S_DECODE;
                end else begin
                    next_state = S_FETCH_WAIT;
                end
                */
                next_state = S_FETCH_WAIT;
            end
        end

        S_FETCH_WAIT: begin
            alu_a_sel = 2'b11; // Select FetchPC
            alu_b_sel = 2'b10; // Select constant 4
            alu_sel = `ADD; // ADD
            pc_src_sel = 2'b00; // Next PC comes from ALU result
            if (bus_ready) begin
                pc_write = 1'b1;
                fbuf_en = 1'b1;
                next_state = S_DECODE;
            end else begin
                next_state = S_FETCH_WAIT;
            end
        end

        S_DECODE: begin
            rf_latch_en = 1'b1;
            next_state = S_EXECUTE;
        end

        S_EXECUTE: begin
            case (opcode)
                `OPCODE_R_TYPE, `OPCODE_I_TYPE: begin
                    alu_a_sel = 2'b00; // RD1
                    alu_b_sel = (opcode == `OPCODE_R_TYPE) ? 2'b00 : 2'b01; // in0: RD2 | in1: Imm
                    case(funct3)
                        3'b000: alu_sel = (opcode == `OPCODE_R_TYPE && funct7[5]) ? `SUB : `ADD;
                        3'b001: alu_sel = `SLL;
                        3'b010: alu_sel = `SLT;
                        3'b011: alu_sel = `SLTU;
                        3'b100: alu_sel = `XOR;
                        3'b101: alu_sel = (funct7[5]) ? `SRA : `SRL; 
                        3'b110: alu_sel = `OR;
                        3'b111: alu_sel = `AND;
                    endcase
                    aluout_en = 1'b1;
                    next_state = S_WB;
                end 

                `OPCODE_BRANCH: begin
                    alu_a_sel = 2'b00; // RD1
                    alu_b_sel = 2'b00; // RD2
                    alu_sel   = `SUB;  // Compare via subtraction
                    
                    // Branch Decision Logic
                    case(funct3)
                        3'b000: next_state = (zero)        ? S_BRANCH : S_FETCH; // BEQ
                        3'b001: next_state = (!zero)       ? S_BRANCH : S_FETCH; // BNE
                        3'b100: next_state = (lt_signed)   ? S_BRANCH : S_FETCH; // BLT
                        3'b101: next_state = (!lt_signed)  ? S_BRANCH : S_FETCH; // BGE
                        3'b110: next_state = (lt_unsigned) ? S_BRANCH : S_FETCH; // BLTU
                        3'b111: next_state = (!lt_unsigned)? S_BRANCH : S_FETCH; // BGEU
                        default: next_state = S_FETCH;
                    endcase
                end

                `OPCODE_JAL: begin
                    alu_a_sel = 2'b01; // buffered_pc (Address of the JAL)
                    alu_b_sel = 2'b10; // Constant 4
                    alu_sel = `ADD;
                    aluout_en = 1'b1;  
                    next_state = S_WB;
                end

                `OPCODE_JALR: begin
                    alu_a_sel = 2'b01; // buffered_pc
                    alu_b_sel = 2'b10; // Constant 4
                    alu_sel = `ADD;
                    aluout_en = 1'b1;
                    next_state = S_WB;  
                end

                `OPCODE_LUI: begin
                    alu_a_sel  = 2'b10; // 0 
                    alu_b_sel  = 2'b01; // Select Imm
                    alu_sel    = `ADD;  // 0 + Imm
                    aluout_en  = 1'b1;
                    next_state = S_WB;
                end

                `OPCODE_AUIPC: begin
                    alu_a_sel  = 2'b01; // buffered_pc 
                    alu_b_sel  = 2'b01; // Select Imm
                    alu_sel    = `ADD;  // PC + Imm
                    aluout_en  = 1'b1;
                    next_state = S_WB;
                end

                `OPCODE_LOAD, `OPCODE_STORE: begin
                    alu_a_sel  = 2'b00; // RD1 
                    alu_b_sel  = 2'b01; // Immediate 
                    alu_sel    = `ADD;
                    aluout_en  = 1'b1;  
                    next_state = (opcode == `OPCODE_LOAD) ? S_MEM_READ : S_MEM_WRITE;
                end

                `OPCODE_SYS: begin
                    if (mret_true) begin
                        mret_exec  = 1'b1;
                        pc_src_sel = 2'b11; // Select MEPC to return from trap
                        pc_write   = 1'b1;
                        next_state = S_FETCH;
                    end else if (ecall_true) begin
                        next_trap_cause = 32'd11; // RISC-V spec: Environment call from M-mode
                        next_state = S_TRAP;
                    end else if (ebreak_true) begin
                        next_trap_cause = 32'd3;  // RISC-V spec: Breakpoint
                        next_state = S_TRAP;
                    end else if (funct3 != 3'b000) begin
                        next_state = S_CSR;  // Valid CSR read/write instruction
                    end else begin
                        next_trap_cause = 32'd2;  // Illegal instruction
                        next_state = S_TRAP;
                    end
                end

                default: begin
                    next_trap_cause = 32'd2;
                    next_state = S_TRAP;
                end
            endcase
        end

        S_BRANCH: begin
            alu_a_sel = 2'b01; // buffered_pc 
            alu_b_sel = 2'b01; // imm_out 
            alu_sel = `ADD;
            pc_src_sel = 2'b00; // Result from ALU
            pc_write = 1'b1;  // jump
            next_state = S_FETCH;
        end

        S_JALR: begin
            alu_a_sel = 2'b00; // RD1
            alu_b_sel= 2'b01; // Imm
            alu_sel = `ADD;
            pc_src_sel = 2'b01; // Special path: ALU Result & ~1 (LSB mask)
            pc_write = 1'b1;
            next_state = S_FETCH;
        end

        S_TRAP: begin
            trap_enter = 1'b1;
            pc_src_sel = 2'b10; // MTVEC from CSR
            pc_write = 1'b1;
            next_state = S_FETCH;
        end

        S_CSR: begin
            reg_write = 1'b1;    
            wb_sel = 2'b10;   // Select csr_rdata_wire for Write-Back
            case(funct3[1:0])
                2'b01: csr_op = 2'b00; // CSRRW (Write)
                2'b10: csr_op = 2'b01; // CSRRS (Set)
                2'b11: csr_op = 2'b10; // CSRRC (Clear)
                default: csr_op = 2'b00;
            endcase
            if (funct3[1:0] == 2'b01) begin
                csr_we = 1'b1;  
            end else begin
                csr_we = (instr_in[19:15] != 5'd0); 
            end
            
            next_state = S_FETCH;
        end

        S_MEM_READ: begin
            mem_read   = 1'b1;
            next_state = S_MEM_WAIT;
        end

        S_MEM_WAIT: begin
            mem_read = 1'b1;
            if (bus_ready) begin
                next_state = S_WB; 
            end else begin
                next_state = S_MEM_WAIT;
            end
        end

        S_MEM_WRITE: begin
            mem_write = 1'b1;
            if (bus_ready) begin
                next_state = S_FETCH; 
            end else begin
                next_state = S_MEM_WRITE;
            end
        end

        S_WB: begin
            reg_write = 1'b1;  
            wb_sel = (opcode == `OPCODE_LOAD) ? 2'b01 : 2'b00; 
            if (opcode == `OPCODE_JAL) begin       
                next_state = S_BRANCH;
            end else if (opcode == `OPCODE_JALR) begin  
                next_state = S_JALR;
            end else begin                            
                next_state = S_FETCH;
            end 
        end
        default: next_state = S_FETCH;
    endcase
end

endmodule
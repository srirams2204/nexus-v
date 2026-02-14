`timescale 1ns/1ps
`include "rv_defs.vh"

module decoder (
    // ---------------- Outputs ----------------
    output reg        pc_write,
    output reg        pc_sel,
    output reg        ir_en,
    output reg        reg_write,
    output reg        rf_latch_en,
    output reg [3:0]  alu_sel,
    output reg [1:0]  alu_a_sel,
    output reg [1:0]  alu_b_sel,
    output reg        aluout_en,
    output reg [2:0]  imm_sel,
    output reg        mem_read_en,
    output reg        mem_write_en,
    output reg [1:0]  wb_sel,

    // ---------------- Inputs -----------------
    input  [31:0] instr_in,
    input         zero,
    input         lt_signed,
    input         lt_unsigned,
    input         mem_ready,  // MEM access based on apb 
    input         clk,
    input         rst
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

wire [6:0] op = instr_in[6:0];
wire [2:0] funct3 = instr_in[14:12];
wire [6:0] funct7 = instr_in[31:25];

reg [3:0] state, next_state;

always @(posedge clk) begin
    if (rst) 
        state <= S_FETCH;
    else 
        state <= next_state;
end

always @(*) begin
    next_state   = S_FETCH;
    pc_write     = 1'b0; 
    pc_sel       = 1'b0;     
    ir_en        = 1'b0;
    reg_write    = 1'b0; 
    rf_latch_en  = 1'b0;
    
    alu_sel      = `ADD;     
    alu_a_sel    = 2'b00;     
    alu_b_sel    = 2'b00;
    aluout_en    = 1'b0;     

    mem_read_en  = 1'b0; 
    mem_write_en = 1'b0;
    wb_sel       = 2'b0;

    // Immediate Selection 
    case(op)
        `OPCODE_STORE:                imm_sel = `IMM_S;
        `OPCODE_BRANCH:               imm_sel = `IMM_B;
        `OPCODE_JAL:                  imm_sel = `IMM_J;
        `OPCODE_LUI, `OPCODE_AUIPC:   imm_sel = `IMM_U;
        `OPCODE_LOAD, `OPCODE_JALR:   imm_sel = `IMM_I; 
        `OPCODE_I_TYPE:               imm_sel = `IMM_I;
        default:                      imm_sel = `IMM_NONE;
    endcase

    case (state)
        S_FETCH: begin
            next_state = S_FETCH_WAIT;
        end

        S_FETCH_WAIT: begin
            ir_en = 1'b1;        
            alu_a_sel = 2'b11;    // PC
            alu_b_sel = 2'b10;    // 4
            alu_sel   = `ADD;
            pc_write = 1'b1;      // Update PC
            next_state = S_DECODE;
        end

        S_DECODE: begin
            rf_latch_en = 1'b1;   
            next_state = S_EXECUTE; 
        end

        S_EXECUTE: begin
            case(op)
                `OPCODE_R_TYPE, `OPCODE_I_TYPE: begin
                    alu_a_sel = 2'b01; 
                    if (op == `OPCODE_R_TYPE) alu_b_sel = 2'b00; 
                    else                      alu_b_sel = 2'b01;
                    case(funct3)
                        3'b000: alu_sel = (op == `OPCODE_R_TYPE && funct7[5]) ? `SUB : `ADD;
                        3'b001: alu_sel = `SLL;
                        3'b010: alu_sel = `SLT;
                        3'b011: alu_sel = `SLTU;
                        3'b100: alu_sel = `XOR;
                        3'b101: alu_sel = (funct7[5]) ? `SRA : `SRL; 
                        3'b110: alu_sel = `OR;
                        3'b111: alu_sel = `AND;
                        default: alu_sel = `ADD;
                    endcase
                    aluout_en = 1'b1;
                    next_state = S_WB;
                end

                `OPCODE_LOAD, `OPCODE_STORE: begin
                    alu_a_sel = 2'b01; 
                    alu_b_sel = 2'b01; 
                    alu_sel = `ADD;
                    aluout_en = 1'b1;
                    if (op == `OPCODE_LOAD) next_state = S_MEM_READ;
                    else                    next_state = S_MEM_WRITE;
                end

                `OPCODE_BRANCH: begin
                    alu_a_sel = 2'b01; 
                    alu_b_sel = 2'b00; 
                    alu_sel   = `SUB;  
                    case(funct3)
                        3'b000: next_state = (zero) ? S_BRANCH : S_FETCH;        // BEQ
                        3'b001: next_state = (!zero) ? S_BRANCH : S_FETCH;       // BNE
                        3'b100: next_state = (lt_signed) ? S_BRANCH : S_FETCH;   // BLT
                        3'b101: next_state = (!lt_signed) ? S_BRANCH : S_FETCH;  // BGE
                        3'b110: next_state = (lt_unsigned) ? S_BRANCH : S_FETCH; // BLTU
                        3'b111: next_state = (!lt_unsigned) ? S_BRANCH : S_FETCH;// BGEU
                        default: next_state = S_FETCH;
                    endcase
                end

                // --- JAL (SPLIT CYCLE) ---
                `OPCODE_JAL: begin
                    // Cycle 1: Save Return Address (PC+4)
                    reg_write = 1'b1;
                    wb_sel    = 2'b10; 
                    // Cycle 2: Perform Jump (Use S_BRANCH state)
                    next_state = S_BRANCH;
                end

                // --- JALR (SPLIT CYCLE) ---
                `OPCODE_JALR: begin
                    // Cycle 1: Save Return Address (PC+4)
                    reg_write = 1'b1;
                    wb_sel    = 2'b10;
                    // Cycle 2: Perform Jump (New S_JALR state)
                    next_state = S_JALR;
                end

                `OPCODE_LUI: begin
                    alu_a_sel = 2'b10; // 0
                    alu_b_sel = 2'b01; // Imm
                    alu_sel   = `ADD;
                    aluout_en = 1'b1;
                    next_state = S_WB;
                end

                `OPCODE_AUIPC: begin
                    alu_a_sel = 2'b00; // OldPC
                    alu_b_sel = 2'b01; // Imm
                    alu_sel   = `ADD;
                    aluout_en = 1'b1;
                    next_state = S_WB;
                end
                default: next_state = S_FETCH;
            endcase
        end

        // --- BRANCH / JAL TARGET CALCULATION ---
        S_BRANCH: begin
            alu_a_sel = 2'b00; // Old PC
            alu_b_sel = 2'b01; // Imm
            alu_sel   = `ADD;
            
            pc_write  = 1'b1;  // Update PC
            ir_en     = 1'b1;  // <--- NEW: Force Fetch Stage to accept the PC write
            
            next_state = S_FETCH;
        end

        // --- JALR TARGET CALCULATION ---
        S_JALR: begin
            alu_a_sel = 2'b01; // RS1
            alu_b_sel = 2'b01; // Imm
            alu_sel   = `ADD;
            
            pc_write  = 1'b1;  // Update PC
            pc_sel    = 1'b1;  // Mask LSB
            ir_en     = 1'b1;  // <--- NEW: Force Fetch Stage to accept the PC write
            
            next_state = S_FETCH;
        end

        // ... Memory States ...
        S_MEM_READ: begin
            mem_read_en = 1'b1;
            next_state = S_MEM_WAIT;
        end
        S_MEM_WAIT: begin
            mem_read_en = 1'b1;
            if (mem_ready) begin
                next_state = S_WB;
            end else begin
                next_state = S_MEM_WAIT;
            end
        end
        S_MEM_WRITE: begin
            mem_write_en = 1'b1;
            if (mem_ready) begin
                next_state = S_FETCH;
            end else begin
                next_state = S_MEM_WRITE;
            end
        end
        
        S_WB: begin
            reg_write = 1'b1;
            if (op == `OPCODE_LOAD) 
                wb_sel = 2'b01; 
            else 
                wb_sel = 2'b00; 
            next_state = S_FETCH;
        end

        default: next_state = S_FETCH;
    endcase
end

endmodule
module imm_gen (
    output reg [31:0] imm_out,
    input [31:0] instr_in,
    input [2:0] imm_sel 
);

// imm_sel encoding:
// 000 = NONE   
// 001 = I-type
// 010 = S-type
// 011 = B-type
// 100 = U-type
// 101 = J-type

always @(*)begin
    case(imm_sel)
        `IMM_I: begin //I-type
            imm_out = {{20{instr_in[31]}}, instr_in[31:20]};
        end

        `IMM_S: begin //S-type
            imm_out = {{20{instr_in[31]}}, instr_in[31:25], instr_in[11:7]};
        end

        `IMM_B: begin //B-type
            imm_out = {{20{instr_in[31]}}, instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
        end

        `IMM_U: begin //U-type
            imm_out = {instr_in[31:12], 12'b0};
        end

        `IMM_J: begin //J-type
            imm_out = {{12{instr_in[31]}}, instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0};
        end

        `IMM_CSR: begin
            imm_out =  {27'b0, instr_in[19:15]};
        end

        default: begin
            imm_out = 32'b0;
        end

    endcase
end
    
endmodule
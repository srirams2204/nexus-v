module branch_unit (
    output pc_src,
    input zero,
    input lt_signed,
    input lt_unsigned,

    input [2:0] funct3,
    input is_branch,
    input is_jump
);

reg branch_taken;

always @(*) begin
    case (funct3) 
        3'b000:  branch_taken = zero;          // BEQ
        3'b001:  branch_taken = !zero;         // BNE
        3'b100:  branch_taken = lt_signed;     // BLT
        3'b101:  branch_taken = !lt_signed;    // BGE
        3'b110:  branch_taken = lt_unsigned;   // BLTU
        3'b111:  branch_taken = !lt_unsigned;  // BGEU
        default: branch_taken = 1'b0;
    endcase
end

assign pc_src = is_jump | (is_branch & branch_taken);
    
endmodule
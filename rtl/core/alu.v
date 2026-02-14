`timescale 1ns/1ps
`include "rv_defs.vh"

module alu (
    output reg [31:0] alu_out,
    input [31:0] A, B,
    input [3:0] sel,

    output zero,
    output lt_signed,
    output lt_unsigned
);

wire [4:0] shamt = B[4:0];

assign lt_signed   = ($signed(A) < $signed(B));
assign lt_unsigned = (A < B);

wire is_sub = (sel == `SUB);
wire [31:0] sum = A + (is_sub ? (~B + 32'd1) : B);

always @(*) begin
    case (sel)
        `ADD, `SUB: alu_out = sum;
        `XOR:  alu_out = A ^ B;
        `OR:   alu_out = A | B;
        `AND:  alu_out = A & B;
        `SLL:  alu_out = A << shamt;
        `SRL:  alu_out = A >> shamt;
        `SRA:  alu_out = $signed(A) >>> shamt;
        `SLT:  alu_out = {31'b0, lt_signed};
        `SLTU: alu_out = {31'b0, lt_unsigned};
        default: alu_out = 32'b0;
    endcase
end

assign zero = (alu_out == 32'b0);

endmodule
`timescale 1ns/1ps
module fetch_buffer (
    output reg [31:0] pc,
    output reg [31:0] instr,
    input [31:0] pc_in,
    input [31:0] instr_in,
    input fbuf_en,
    input clk, rst
);

always @(posedge clk) begin
    if (rst) begin
        pc <= 32'd0;
        instr <= 32'd0;
    end else if (fbuf_en) begin
        pc <= pc_in;
        instr <= instr_in;
    end
end
    
endmodule
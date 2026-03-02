`timescale 1ns/1ps
module pc (
    output reg [31:0] pc_out,
    input [31:0] pc_val,
    input pc_write,
    input clk, rst
);

always @(posedge clk) begin
    if(rst) begin
        pc_out <= 32'd0;
    end else if (pc_write) begin
        pc_out <= pc_val;
    end
end
    
endmodule
`include "../include/rv_defs.vh"

module pc #(
    parameter WIDTH = `WIDTH
)(
    output reg [WIDTH-1:0] pc_out,
    output wire [WIDTH-1:0] pcPlus4,

    input pc_src,
    input pc_halt,
    input [WIDTH-1:0] jump_val,

    input clk,
    input rst
);

wire [WIDTH-1:0] pc_plus4;
assign pc_plus4 = pc_out + 4;

assign pcPlus4 = pc_plus4;

always @(posedge clk) begin
    if (rst) begin
        pc_out <= `PC_RST;
    end else if (!pc_halt) begin 
        if (pc_src) begin
            pc_out <= {jump_val[31:1], 1'b0};
        end else begin
            pc_out <= pc_plus4;
        end
    end
end

endmodule

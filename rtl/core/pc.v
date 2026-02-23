module pc(
    output reg [31:0] pc_out,
    input [31:0] pc_val,
    input pc_write,
    input clk,
    input rst 
);

always @(posedge clk) begin
    if (rst) begin
        pc_out <= `PC_RESET;
    end else if (pc_write) begin
        pc_out <= pc_val;
    end 
end

endmodule
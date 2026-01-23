module fetch_buffer(
    output reg [31:0] old_pc,
    output reg [31:0] instr_out,
    input [31:0] pc_in,
    input [31:0] instr_in,
    input ir_en,
    input clk,
    input rst
);

always @(posedge clk) begin
    if (rst) begin
        old_pc <= 0;
        instr_out <= 0;
    end else if (ir_en) begin
        old_pc <= pc_in;
        instr_out <= instr_in;
    end
end

endmodule
`include "../include/rv_defs.vh"
module instr_mem #(
    parameter WIDTH = `WIDTH,
    parameter ROMdepth = 1024,
    parameter file_path = "../../../firmware/program.hex"
) (
    output reg [WIDTH-1:0] instr_out,
    input [WIDTH-1:0] instr_addr,
    input clk
);
    
(* ram_style = "block" *) reg [31:0] rom [0:ROMdepth-1];

initial begin
    $readmemh(file_path, rom);
end

always @(negedge clk) begin
    instr_out <= rom[instr_addr[31:2]];
end

endmodule
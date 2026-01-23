module instr_mem (
    output reg [31:0] instr,
    output reg [31:0] addr_out,
    input [31:0] addr,
    input clk
);

(* ram_style = "block" *) reg [31:0] mem [0:1023]; // change it to 1023

always @(posedge clk) begin
    instr <= mem[addr[11:2]];
    addr_out <= addr;
end

initial begin
    $readmemh("program.hex", mem);
end

endmodule
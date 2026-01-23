module fetch_stage(
    output [31:0] instr_out,
    output [31:0] pc_current,
    input  [31:0] pc_nxt,
    input         pc_write,
    input         clk,
    input         rst
);

wire [31:0] pc_out_wire;
wire [31:0] instr_rom_wire;

pc PC(
    .pc_out (pc_out_wire),
    .pc_val (pc_nxt),
    .pc_write (pc_write),
    .clk (clk),
    .rst (rst)
);

instr_mem ROM(
    .instr (instr_out),
    .addr_out(pc_current),
    .addr (pc_out_wire),
    .clk (clk)
);

endmodule

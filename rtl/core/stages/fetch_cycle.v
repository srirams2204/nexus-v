`include "../include/rv_defs.vh"
module fetch_cycle #(
    parameter WIDTH = `WIDTH,
    parameter PROGRAM_FILE = "../../../firmware/program.hex"
)(
    output wire [WIDTH-1:0] instr_out,
    output wire [WIDTH-1:0] pc_out,
    output wire [WIDTH-1:0] pcPlus4,

    input wire [WIDTH-1:0] jump_val,
    input wire pc_src,
    input wire pc_halt,

    input clk,
    input rst
);

wire [WIDTH-1:0] pc_val;

pc #(
    .WIDTH(`WIDTH)
) unit_pc (
    .pc_out(pc_val),
    .pcPlus4(pcPlus4),
    .pc_src(pc_src),
    .jump_val(jump_val),
    .pc_halt(pc_halt),
    .clk(clk),
    .rst(rst)
);

instr_mem #(
    .WIDTH(`WIDTH),
    .ROMdepth(1024),
    .file_path(PROGRAM_FILE)
) unit_rom (
    .instr_out(instr_out),
    .instr_addr(pc_val),
    .clk(clk)
);

assign pc_out = pc_val;

// ---------------------------------------------------------
// Waveform Generation (Only for Simulation)
// ---------------------------------------------------------
`ifdef COCOTB_SIM
initial begin
    $dumpfile("fetch_debug.vcd"); // The file name
    $dumpvars(0, fetch_cycle);    // Dump everything inside this module
end
`endif

endmodule
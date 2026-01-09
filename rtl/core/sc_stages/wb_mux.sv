`include "../include/rv_defs.vh"

module wb_mux #(
    parameter WIDTH = `WIDTH
) (
    output wire [WIDTH-1:0] wb_data,    // To Register File
    input  wire [WIDTH-1:0] alu_result, // From ALU
    input  wire [WIDTH-1:0] mem_data,   // From Data Memory
    input  wire             wb_sel      // 0 = ALU, 1 = Memory
);

assign wb_data = (wb_sel) ? mem_data : alu_result;

endmodule
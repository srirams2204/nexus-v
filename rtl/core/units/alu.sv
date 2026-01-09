`include "../include/rv_defs.vh"
module alu #(
    parameter WIDTH = `WIDTH
) (
    output reg [WIDTH-1:0] alu_out,
    input [WIDTH-1:0] A, B,
    input [3:0] sel,

    output zero,
    output lt_signed,
    output lt_unsigned
);

wire [4:0] shamt = B[4:0];

assign lt_signed   = ($signed(A) < $signed(B));
assign lt_unsigned = (A < B);

wire is_sub = (sel == `SUB);
wire [WIDTH-1:0] b_inv = is_sub ? ~B : B;
wire [WIDTH-1:0] sum   = A + b_inv + is_sub;

always @(*) begin
    case (sel)
        `ADD, `SUB: alu_out = sum;
        `XOR:  alu_out = A ^ B;
        `OR:   alu_out = A | B;
        `AND:  alu_out = A & B;
        `SLL:  alu_out = A << shamt;
        `SRL:  alu_out = A >> shamt;
        `SRA:  alu_out = $signed(A) >>> shamt;
        `SLT:  alu_out = {31'b0, lt_signed};
        `SLTU: alu_out = {31'b0, lt_unsigned};
        default: alu_out = 32'b0;
    endcase
end

assign zero = (alu_out == 32'b0);

// ---------------------------------------------------------
// Waveform Generation
// ---------------------------------------------------------
`ifdef COCOTB_SIM
initial begin
    `ifdef VCS 
        $fsdbDumpfile("exec_debug.fsdb"); 
        $fsdbDumpvars(0);
    `else
        $dumpfile("exec_debug.vcd");
        $dumpvars(0);
    `endif
end
`endif

endmodule
`include "../include/rv_defs.vh"
`include "../units/alu.sv"
`include "../units/branch_unit.sv"

module execute_cycle #(
    parameter WIDTH = `WIDTH
)(
    // Decision Outputs
    output wire              pc_src,
    output wire [WIDTH-1:0]  alu_result,
    output wire [WIDTH-1:0]  jump_target_addr, // RENAMED: clearer for Top module

    // Data Inputs
    input  wire [WIDTH-1:0]  pc_val,
    input  wire [WIDTH-1:0]  imm_val,
    input  wire [WIDTH-1:0]  rs1_data,
    input  wire [WIDTH-1:0]  rs2_data,

    // Control Inputs
    input  wire [3:0]        alu_ctrl,
    input  wire              alu_src_a,
    input  wire              alu_src_b,
    input  wire              is_branch,
    input  wire              is_jump,
    input  wire              is_jalr,      
    input  wire [2:0]        funct3
);

wire [WIDTH-1:0] a_input;
wire [WIDTH-1:0] b_input;

assign a_input = (alu_src_a == 1'b0) ? rs1_data : pc_val;
assign b_input = (alu_src_b == 1'b0) ? rs2_data : imm_val;

wire zero, lt_signed, lt_unsigned;

alu #(
    .WIDTH(WIDTH)
) ALU(
    .alu_out     (alu_result),
    .A           (a_input),
    .B           (b_input),
    .sel         (alu_ctrl),
    .zero        (zero),
    .lt_signed   (lt_signed),
    .lt_unsigned (lt_unsigned)
);

branch_unit BRANCH(
    .pc_src      (pc_src), 
    .zero        (zero),
    .lt_signed   (lt_signed),
    .lt_unsigned (lt_unsigned),
    .funct3      (funct3),
    .is_branch   (is_branch),
    .is_jump     (is_jump)
);

assign jump_target_addr = (is_jalr) ? alu_result : (pc_val + imm_val);

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
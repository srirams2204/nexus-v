`timescale 1ns/1ps
`include "rv_defs.vh"

module nexusV_core(
    // apb signals
    output [31:0] paddr,
    output [31:0] pdata,
    output pwrite,
    output psel,
    output penable,
    input [31:0] prdata,
    input clk,
    input rst_n
);

// Active high system reset
wire rst = ~rst_n;

// Fetch cycle wire
wire [31:0] rom_out_wire;
wire [31:0] current_pc_wire;
wire [31:0] pc_nxt_wire;
wire [31:0] instr_out_wire;
wire [31:0] old_pc_wire;
wire pc_sel; // mux for pc_nxt port for JALR bit maksing

// Register File wires
wire [4:0] rs1_wire, rs2_wire, rd_wire;
wire [31:0] rs1_data_wire, rs2_data_wire, rd_data_wire;

assign rs1_wire = instr_out_wire[19:15];
assign rs2_wire = instr_out_wire[24:20];
assign rd_wire  = instr_out_wire[11:7];

// immediate generator wire
wire [31:0] imm_out_wire;

// ALU wire
wire [31:0] alu_a_in, alu_b_in;
wire zero, lt_signed, lt_unsigned;
wire [31:0] alu_out_wire;

// Data_Mem wire
wire [31:0] mem_read_data; 

// Top Module Control Signals 
wire pc_write;
wire ir_en;
wire reg_write;
wire [1:0] alu_a_sel, alu_b_sel;
wire [3:0] alu_sel;
wire [2:0] imm_sel;
wire [1:0] wb_sel;
wire mem_read_en, mem_write_en;
wire rf_latch_en;
reg [31:0] ALUOut;
wire aluout_en;
reg [31:0] RS1, RS2;

// Addr seperation from internal mem and apb access
wire is_mem = ~ALUOut[31];
wire core_mem_write = mem_write_en & is_mem;
wire core_mem_read  = mem_read_en & is_mem;
wire core_apb_write = mem_write_en & ~is_mem;

// APB Specific Signals
wire apb_ready = 1'b1;  // change later when adding apb_master module
wire mem_ready = (is_mem) ? 1'b1 : apb_ready;

fetch_stage FETCH(
    .instr_out(rom_out_wire),
    .pc_current(current_pc_wire),
    .pc_nxt(pc_nxt_wire),
    .pc_write(pc_write),
    .clk(clk),
    .rst(rst)
);

fetch_buffer PFB(
    .old_pc(old_pc_wire),
    .instr_out(instr_out_wire),
    .pc_in(current_pc_wire),
    .instr_in(rom_out_wire),
    .ir_en(ir_en),
    .clk(clk),
    .rst(rst)
);

decoder DECODER(
    //outputs
    .pc_write(pc_write),
    .pc_sel(pc_sel),
    .ir_en(ir_en),
    .reg_write(reg_write),
    .rf_latch_en(rf_latch_en),
    .alu_sel(alu_sel),
    .alu_a_sel(alu_a_sel),
    .alu_b_sel(alu_b_sel),
    .aluout_en(aluout_en),
    .imm_sel(imm_sel),
    .mem_read_en(mem_read_en),
    .mem_write_en(mem_write_en),
    .wb_sel(wb_sel),
    //inputs
    .instr_in(instr_out_wire),
    .zero(zero),
    .lt_signed(lt_signed),
    .lt_unsigned(lt_unsigned),
    .mem_ready(mem_ready),
    //global signal
    .clk(clk),
    .rst(rst)
);

register_file RF(
    .rs1_data(rs1_data_wire),
    .rs2_data(rs2_data_wire),
    .rd_data(rd_data_wire),
    .rs1(rs1_wire),
    .rs2(rs2_wire),
    .rd(rd_wire),
    .reg_write(reg_write),
    .clk(clk)
);

always @(posedge clk) begin
    if (rst) begin
        RS1 <= 0;
        RS2 <= 0;
    end else if (rf_latch_en) begin
        RS1 <= rs1_data_wire;
        RS2 <= rs2_data_wire;
    end
end

imm_gen SignExt(
    .imm_out(imm_out_wire),
    .instr_in(instr_out_wire),
    .imm_sel(imm_sel)
);

mux41_32 muxA(
    .mux_out(alu_a_in),
    .in0(old_pc_wire),
    .in1(RS1),
    .in2(32'd0),
    .in3(current_pc_wire),
    .select(alu_a_sel)
);

mux41_32 muxB(
    .mux_out(alu_b_in),
    .in0(RS2),
    .in1(imm_out_wire),
    .in2(32'd4),
    .in3(32'd0),
    .select(alu_b_sel)
);

alu ALU(
    .alu_out(alu_out_wire),
    .A(alu_a_in),
    .B(alu_b_in),
    .sel(alu_sel),
    .zero(zero),
    .lt_signed(lt_signed),
    .lt_unsigned(lt_unsigned)
);

always @(posedge clk) begin
    if (rst)
        ALUOut <= 32'b0;
    else if (aluout_en)
        ALUOut <= alu_out_wire;
end

data_mem DM(
    .read_data(mem_read_data),
    .misaligned(),
    .read_en(core_mem_read),
    .write_en(core_mem_write),
    .address(ALUOut),
    .write_data(RS2),
    .funct3(instr_out_wire[14:12]),
    .clk(clk)
);

wire [31:0] apb_read_data = 32'b0;
wire [31:0] final_load_data = (is_mem) ? mem_read_data : apb_read_data;

/*
assign rd_data_wire = (wb_sel == 2'b01) ? mem_read_data :
                      (wb_sel == 2'b10) ? current_pc_wire : 
                       ALUOut;
*/

assign rd_data_wire = (wb_sel == 2'b01) ? final_load_data : // <--- CHANGED
                      (wb_sel == 2'b10) ? current_pc_wire : 
                       ALUOut;

assign pc_nxt_wire =
    (pc_sel) ? (alu_out_wire & 32'hFFFFFFFE) : alu_out_wire;


endmodule
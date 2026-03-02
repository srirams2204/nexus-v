`timescale 1ns/1ps
module nexusV_core(
    output [31:0] bus_addr,  // Target Address
    output [31:0] bus_wdata, // Write Data
    output bus_write,        // 1 = Write, 0 = Read
    output bus_valid,        // Request/Enable Signal
    input [31:0] bus_rdata,  // Read Data from Bus
    input bus_ready,         // Ready signal from Bus
    // CSR interrupt signals
    input mtip,
    input msip,
    input meip,
    // Global signals 
    input clk,
    input rst_n
);

wire rst = ~rst_n;

// 4KB Split Logic
// IMEM: 0x0000_0000 - 0x0000_0FFF (4KB)
// DMEM: 0x0000_1000 - 0x0000_1FFF (4KB)
// APB:  0x4000_0000 - 0x4000_FFFF (Peripherals)
wire is_imem_addr = (ALUOut[31:12] == 20'h00000); // Region 0
wire is_dmem_addr = (ALUOut[31:12] == 20'h00001); // Region 1
wire is_apb_addr  = (ALUOut[31:16] == 16'h4000); // Peripheral Region

/*
// 64KB Split Logic (Benchmark Mode)
// IMEM: 0x0000_0000 - 0x0000_FFFF (64KB)
// DMEM: 0x0001_0000 - 0x0001_FFFF (64KB)
// APB:  0x4000_0000 - 0x4000_FFFF (Peripherals)
wire is_imem_addr = (ALUOut[31:16] == 16'h0000); // Region 0
wire is_dmem_addr = (ALUOut[31:16] == 16'h0001); // Region 1 (starts at 0x10000)
wire is_apb_addr  = (ALUOut[31:16] == 16'h4000); // Peripheral Region
*/

// For Interrupt handeling
wire timer_irq = mtip;
wire software_irq = msip;
wire external_irq = meip;

wire [31:0] fetch_instr;   // Output from ROM
wire [31:0] fetch_pc;      // Output from PC (current)

wire [31:0] buffered_pc;
wire [31:0] buffered_instr;

reg [31:0] pc_nxt;
reg pc_write, fbuf_en;
wire [1:0] pc_src_sel;

// PC stall
wire cpu_stall = bus_valid && !bus_ready;
wire final_pc_write = pc_write && !cpu_stall;
wire final_fbuf_en = fbuf_en && !cpu_stall;

wire [4:0] rs1_wire = buffered_instr[19:15];
wire [4:0] rs2_wire = buffered_instr[24:20];
wire [4:0] rd_wire = buffered_instr[11:7];
wire [2:0] funct3_wire = buffered_instr[14:12];

wire rf_latch_en;

wire [31:0] rs1_data_wire, rs2_data_wire, rd_data_wire;
reg [31:0] RD1, RD2;
wire reg_write;
wire final_reg_write = reg_write && !cpu_stall;

wire [31:0] imm_out_wire;
wire [2:0] imm_sel;

wire [1:0] alu_a_sel, alu_b_sel;
wire [3:0] alu_sel;
wire [31:0] alu_a_in, alu_b_in;
wire [31:0] alu_out_wire;
wire zero, lt_signed, lt_unsigned;

wire aluout_en;
reg [31:0] ALUOut;

wire [31:0] mem_read_data;
wire mem_write_en, mem_read_en;
wire dmem_re = mem_read_en  & is_dmem_addr; // gated dmem read control
wire dmem_we = mem_write_en & is_dmem_addr; // gated dmem write control
wire data_misaligned;       

// csr wires
wire csr_we;
wire [1:0] csr_op;
wire trap_enter;
wire mret_exec;
wire interrupt_pending;
wire [31:0] mtvec_out, mepc_out;
wire [31:0] trap_cause;
wire [31:0] csr_rdata_wire;
wire [31:0] interrupt_cause_wire; // Connects CSR output to CU input

wire [1:0] wb_sel;

wire core_bus_req = (mem_read_en | mem_write_en) & is_apb_addr;
assign bus_addr   = ALUOut;
assign bus_wdata  = RD2;
assign bus_write  = mem_write_en & is_apb_addr;
assign bus_valid  = core_bus_req;

mux41_32 mux_pc(
    .mux_out(pc_nxt),
    .in0(alu_out_wire),
    .in1(alu_out_wire & 32'hFFFFFFFE),
    .in2(mtvec_out),
    .in3(mepc_out),
    .select(pc_src_sel)  // control signal
);

fetch_state dut_fetch (
    .instr_out(fetch_instr),
    .pc_current(fetch_pc),
    .pc_nxt(pc_nxt),
    .pc_write(final_pc_write), // control signal
    .clk(clk),
    .rst(rst)
);

fetch_buffer dut_buffer (
    .pc(buffered_pc),
    .instr(buffered_instr),
    .pc_in(fetch_pc),
    .instr_in(fetch_instr),
    .fbuf_en(final_fbuf_en),  // control signal
    .clk(clk),
    .rst(rst)
);

control_unit CU(
    // pc and fetch control
    .pc_write(pc_write),
    .fbuf_en(fbuf_en),
    .pc_src_sel(pc_src_sel),
    // decode and imm gen
    .reg_write(reg_write),
    .rf_latch_en(rf_latch_en),
    .imm_sel(imm_sel),
    // alu control
    .alu_a_sel(alu_a_sel),          
    .alu_b_sel(alu_b_sel),          
    .alu_sel(alu_sel), 
    .aluout_en(aluout_en),
    // mem and write back
    .mem_read(mem_read_en),
    .mem_write(mem_write_en),
    .wb_sel(wb_sel),
    // csr and trap
    .csr_we(csr_we),
    .csr_op(csr_op),
    .trap_enter(trap_enter),
    .mret_exec(mret_exec),
    .trap_cause(trap_cause),
    .interrupt_cause(interrupt_cause_wire),
    // inputs
    .instr_in(buffered_instr),
    .zero(zero),
    .lt_signed(lt_signed),
    .lt_unsigned(lt_unsigned),
    .bus_ready(bus_ready),
    .interrupt_pending(interrupt_pending),
    // global signsl
    .clk(clk),
    .rst(rst)
);

wire [31:0] csr_wdata_mux = (funct3_wire[2]) ? 
                            imm_out_wire : // Zero-extended zimm
                            rs1_data_wire; // From Register File

csr CSR (
    // to datapth 
    .csr_rdata(csr_rdata_wire),
    .csr_wdata(csr_wdata_mux),
    .csr_addr(buffered_instr[31:20]),
    .mtvec_out(mtvec_out),
    .mepc_out(mepc_out),
    .trap_pc(buffered_pc),
    .trap_cause(trap_cause),
    // control signals
    .csr_valid(csr_we),
    .csr_op(csr_op),
    .trap_enter(trap_enter),
    .mret_exec(mret_exec),
    .interrupt_pending(interrupt_pending),
    .interrupt_cause(interrupt_cause_wire),
    .timer_irq(timer_irq),
    .sw_irq(software_irq), 
    .ext_irq(external_irq), 
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
    .reg_write(final_reg_write), // control signal
    .clk(clk)
);

always @(posedge clk) begin
    if (rst) begin
        RD1 <= 0;
        RD2 <= 0;
    end else if (rf_latch_en && !cpu_stall) begin // control signal
        RD1 <= rs1_data_wire;
        RD2 <= rs2_data_wire;
    end
end

imm_gen SignExt(
    .imm_out(imm_out_wire),
    .instr_in(buffered_instr),
    .imm_sel(imm_sel) // control signal
);

mux41_32 muxA(
    .mux_out(alu_a_in),
    .in0(RD1),
    .in1(buffered_pc),
    .in2(32'd0),
    .in3(fetch_pc),
    .select(alu_a_sel)  // control signal
);

mux41_32 muxB(
    .mux_out(alu_b_in),
    .in0(RD2),
    .in1(imm_out_wire),
    .in2(32'd4),
    .in3(32'd0),
    .select(alu_b_sel)  // control signal
);

alu ALU(
    .alu_out(alu_out_wire),
    .A(alu_a_in),
    .B(alu_b_in),
    .sel(alu_sel), // control signal
    .zero(zero),
    .lt_signed(lt_signed),
    .lt_unsigned(lt_unsigned)
);

always @(posedge clk) begin
    if (rst) begin
        ALUOut <= 32'b0;
    end else if (aluout_en && !cpu_stall) begin // control signal
        ALUOut <= alu_out_wire;
    end
end

data_mem DM(
    .read_data(mem_read_data),
    .misaligned(data_misaligned),
    // control signal
    .read_en(dmem_re), // Gated by is_ram_addr
    .write_en(dmem_we), // Gated by is_ram_addr
    .address(ALUOut),
    .write_data(RD2),
    .funct3(funct3_wire),
    .clk(clk)
);

wire [31:0] muxed_mem_rdata = is_dmem_addr ? mem_read_data : bus_rdata;

mux41_32 WB(
    .mux_out(rd_data_wire),
    .in0(ALUOut),
    .in1(muxed_mem_rdata),
    .in2(csr_rdata_wire),
    .in3(ALUOut),
    .select(wb_sel)  // control signal
);

endmodule
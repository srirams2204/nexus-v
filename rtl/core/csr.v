`timescale 1ns/1ps
module csr(
    // CSR instr interface
    output reg [31:0] csr_rdata,
    input [31:0] csr_wdata,
    input [1:0] csr_op,
    input [11:0] csr_addr,
    input csr_valid,
    // trap entry interface
    input trap_enter,
    input [31:0] trap_pc,
    input [31:0] trap_cause,
    // trap return
    input mret_exec,
    // external trap inputs
    input timer_irq,
    input sw_irq,
    input ext_irq,
    // outputputs to core
    output interrupt_pending,
    output [31:0] mepc_out,
    output [31:0] mtvec_out,
    output [31:0] interrupt_cause,
    // global signals
    input clk, rst
);

// Interrupt Piority level (high -> low)
// 1. external
// 2. Software
// 3. timer

// MEI > MSI > MTI

reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mstatus;
reg [31:0] mie;
reg [31:0] mip;
reg [31:0] mscratch;
localparam misa = 32'h40000100;

// Global interrupt enable
wire global_ie = mstatus[3];

wire ext_qual = global_ie && mie[11] && mip[11];
wire sw_qual  = global_ie && mie[3]  && mip[3];
wire tim_qual = global_ie && mie[7]  && mip[7];

assign interrupt_pending = ext_qual | sw_qual | tim_qual;

assign interrupt_cause = ext_qual ? 32'h8000000B :
                         sw_qual  ? 32'h80000003 :
                         tim_qual ? 32'h80000007 :
                         32'b0;

// CSR read logic
always @(*) begin
    case (csr_addr)
        12'h305: csr_rdata = mtvec;  // MTVEC
        12'h341: csr_rdata = mepc;   // MEPC
        12'h342: csr_rdata = mcause; // MCAUSE
        12'h300: csr_rdata = mstatus;// MSTATUS
        12'h304: csr_rdata = mie;    // MIE
        12'h344: csr_rdata = mip;    // MIP
        12'h340: csr_rdata = mscratch;// MSCRATCH
        12'h301: csr_rdata = misa;    // MISA
        default: csr_rdata = 32'b0;
    endcase
end

// CSR write value computation
wire [31:0] csr_old = csr_rdata;
reg [31:0] csr_new;

always @(*) begin
    case (csr_op)
        2'b00: csr_new = csr_wdata;             // CSRRW
        2'b01: csr_new = csr_old | csr_wdata;   // CSRRS
        2'b10: csr_new = csr_old & ~csr_wdata;  // CSRRC
        default: csr_new = csr_old;
    endcase
end

// Priority level
// 1. Reset
// 2. Update mip
// 3. Trap entry
// 4. mret
// 5. CSR write

wire csr_write_en = (csr_op == 2'b00) ? 1'b1 :
                    (csr_op == 2'b01 && csr_wdata != 0) ? 1'b1 :
                    (csr_op == 2'b10 && csr_wdata != 0) ? 1'b1 :
                    1'b0;

always @(posedge clk) begin
    if (rst) begin
        mip <= 32'b0; // mip update from external irq and hardware driven
        mtvec    <= 32'h00000100;  // trap base addr
        mepc     <= 32'd0;
        mcause   <= 32'd0;
        mstatus  <= 32'd0;
        mie      <= 32'd0;
        mscratch <= 32'd0;
    end else begin
        mip[11] <= ext_irq;  // meip
        mip[3] <= sw_irq;    // msip
        mip[7] <= timer_irq; // mtip
        if (trap_enter) begin
            mepc <= trap_pc;
            mcause <= trap_cause;
            mstatus[7] <= mstatus[3]; // MPIE = MIE
            mstatus[3] <= 1'b0; // Disable Global interrupt
        end else if (mret_exec) begin
            mstatus[3] <= mstatus[7]; // restore mie
            mstatus[7] <= 1'b1; // set mpie to 1
        end else if(csr_valid && csr_write_en) begin
            case (csr_addr)
                12'h305: mtvec <= {csr_new[31:2], 2'b00};
                12'h341: mepc <= csr_new;
                12'h342: mcause <= csr_new;
                12'h300: mstatus <= csr_new & 32'h00001888;
                12'h304: mie <= csr_new;
                12'h340: mscratch <= csr_new;
            endcase
        end
    end
end

assign mepc_out = mepc;
assign mtvec_out = mtvec;

endmodule
module csr_unit(
    // CSR instruction Interface
    output reg [31:0] csr_rdata,
    input [11:0] csr_addr,
    input [31:0] csr_wdata,
    input csr_we,
    input [1:0] csr_op,
    // outputs to core
    output [31:0] mtvec_out, // trap vector base
    output [31:0] mepc_out,  // saved pc back to pc module 
    // trap control from decoder 
    input trap_enter,        // asserted when ecall detected
    input [31:0] trap_pc,    // mepc = pc
    input [31:0] trap_cause, // trap cause code
    input mret_exec,         // return from trap

    output interrupt_pending,
    output reg [31:0] interrupt_cause,
    input timer_irq,
    input software_irq,
    input external_irq,
    // global signals
    input clk,
    input rst
);

reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mstatus;
reg [31:0] mie;
reg [31:0] mip;
reg [31:0] mscratch;

localparam MISA_RV32I = 32'h40000100;

wire [31:0] csr_old = csr_rdata;
reg  [31:0] csr_new_value;

always @(*) begin
    case (csr_addr)
        `CSR_MTVEC:    csr_rdata = mtvec;
        `CSR_MEPC:     csr_rdata = mepc;
        `CSR_MCAUSE:   csr_rdata = mcause;
        `CSR_MSTATUS:  csr_rdata = mstatus;
        `CSR_MIE:      csr_rdata = mie;
        `CSR_MIP:      csr_rdata = mip;
        `CSR_MSCRATCH: csr_rdata = mscratch;
        `CSR_MISA:     csr_rdata = MISA_RV32I;
        default:       csr_rdata = 32'b0;
    endcase
end

always @(*) begin
    case (csr_op)
        2'b00: csr_new_value = csr_wdata;            // CSRRW
        2'b01: csr_new_value = csr_old | csr_wdata;  // CSRRS
        2'b10: csr_new_value = csr_old & ~csr_wdata; // CSRRC
        default: csr_new_value = csr_old;
    endcase
end

wire csr_write_enable = csr_we;

assign interrupt_pending = mstatus[3] && (mie[11] && mip[11] ||
                           mie[3]  && mip[3]  ||
                           mie[7]  && mip[7]);

always @(posedge clk) begin
    if (rst) begin
        mtvec   <= 32'h00000100;
        mepc    <= 32'b0;
        mcause  <= 32'b0;
        mstatus <= 32'b0;
        mie     <= 32'b0;
        mip     <= 32'b0;
        mscratch<= 32'b0;
    end else begin
        mip[7]  <= timer_irq;     // MTIP
        mip[3]  <= software_irq;  // MSIP
        mip[11] <= external_irq;  // MEIP
        if (trap_enter) begin
            mepc   <= trap_pc;
            if (interrupt_cause != 32'b0)
                mcause <= interrupt_cause;
            else
                mcause <= trap_cause;

            mstatus[7] <= mstatus[3];  // MPIE = MIE
            mstatus[3] <= 1'b0;        // Disable interrupts
        end
        // MRET
        else if (mret_exec) begin
            mstatus[3] <= mstatus[7];
            mstatus[7] <= 1'b1;
        end
        // CSR Instruction Write
        else if (csr_write_enable) begin
            case (csr_addr)
                `CSR_MTVEC:    mtvec   <= csr_new_value;
                `CSR_MEPC:     mepc    <= csr_new_value;
                `CSR_MCAUSE:   mcause  <= csr_new_value;
                `CSR_MSTATUS:  mstatus <= csr_new_value;
                `CSR_MIE:      mie     <= csr_new_value;
                //`CSR_MIP:     mip     <= csr_new_value;
                `CSR_MSCRATCH: mscratch <= csr_new_value;

            endcase
        end
    end
end

always @(*) begin
    if (mstatus[3]) begin
        if (mie[11] && mip[11])
            interrupt_cause = 32'h8000000B;  // MEIP
        else if (mie[3] && mip[3])
            interrupt_cause = 32'h80000003;  // MSIP
        else if (mie[7] && mip[7])
            interrupt_cause = 32'h80000007;  // MTIP
        else
            interrupt_cause = 32'b0;
    end else begin
        interrupt_cause = 32'b0;
    end
end

assign mtvec_out = mtvec;
assign mepc_out  = mepc;

endmodule
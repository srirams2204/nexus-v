module csr_unit(
    // outputs to core
    output [31:0] mtvec_out, // trap vector base
    output [31:0] mepc_out,  // saved pc back to pc module 
    // trap control from decoder 
    input trap_enter,        // asserted when ecall detected
    input [31:0] trap_pc,    // mepc = pc
    input [31:0] trap_cause, // trap cause code

    // return from trap
    input mret_exec,

    // global signals
    input clk,
    input rst
);

reg [31:0] mtvec;
reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mstatus;

always @(posedge clk) begin
    if (rst) begin
        mtvec <= 32'h00000100;
        mepc <= 32'b0;
        mcause <= 32'b0;
        mstatus <= 32'b0;
    end else begin
        if (trap_enter) begin
            mepc <= trap_pc;
            mcause <= trap_cause;

            // mcause handeling
            mstatus[7] <= mstatus[3];  // MPIE = MIE
            mstatus[3] <= 1'b0;        // Disable interrupts
        end else if (mret_exec) begin
            mstatus[3] <= mstatus[7];  // Restore MIE
            mstatus[7] <= 1'b1;        // Set MPIE
        end
    end
end

assign mtvec_out = mtvec;
assign mepc_out  = mepc;

endmodule
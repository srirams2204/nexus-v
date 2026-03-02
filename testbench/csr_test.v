`timescale 1ns/1ps

module csr_test;

    // --- CSR Interface Signals ---
    wire [31:0] csr_rdata;
    reg  [31:0] csr_wdata;
    reg  [1:0]  csr_op;
    reg  [11:0] csr_addr;
    reg         csr_valid;

    // --- Trap Interface ---
    reg         trap_enter, trap_is_interrupt, mret_exec;
    reg  [31:0] trap_pc, trap_cause;

    // --- External Interrupts ---
    reg         timer_irq, sw_irq, ext_irq;

    // --- Outputs to Core ---
    wire        interrupt_pending;
    wire [31:0] interrupt_cause;
    wire [31:0] mepc_out, mtvec_out;

    // --- Global Signals ---
    reg clk, rst;

    ////////////////////////////////////////////////////////////
    // Instantiate DUT
    ////////////////////////////////////////////////////////////

    csr dut (
        .csr_rdata(csr_rdata),
        .csr_wdata(csr_wdata),
        .csr_op(csr_op),
        .csr_addr(csr_addr),
        .csr_valid(csr_valid),

        .trap_enter(trap_enter),
        .trap_is_interrupt(trap_is_interrupt),
        .trap_pc(trap_pc),
        .trap_cause(trap_cause),

        .mret_exec(mret_exec),

        .timer_irq(timer_irq),
        .sw_irq(sw_irq),
        .ext_irq(ext_irq),

        .interrupt_pending(interrupt_pending),
        .interrupt_cause(interrupt_cause),
        .mepc_out(mepc_out),
        .mtvec_out(mtvec_out),

        .clk(clk),
        .rst(rst)
    );

    ////////////////////////////////////////////////////////////
    // Clock Generation (100 MHz)
    ////////////////////////////////////////////////////////////

    always #5 clk = ~clk;

    ////////////////////////////////////////////////////////////
    // Test Sequence
    ////////////////////////////////////////////////////////////

    initial begin
        clk = 0;
        rst = 1;

        csr_valid = 0;
        csr_op    = 2'b00;
        csr_addr  = 12'd0;
        csr_wdata = 32'd0;

        trap_enter = 0;
        trap_is_interrupt = 0;
        mret_exec = 0;

        timer_irq = 0;
        sw_irq    = 0;
        ext_irq   = 0;

        trap_pc    = 0;
        trap_cause = 0;

        // Release reset
        #20 rst = 0;

        $display("\n================ CSR TEST START ================\n");

        /////////////////////////////////////////////////////////
        // TEST 1: Write MTVEC using CSRRW
        /////////////////////////////////////////////////////////

        csr_addr  = 12'h305;
        csr_wdata = 32'h0000_2000;
        csr_op    = 2'b00;  // CSRRW
        csr_valid = 1;

        #10;  // wait for posedge
        csr_valid = 0;

        #10;
        csr_addr = 12'h305;
        #1  $display("[TEST 1] MTVEC = %h (Expected: 00002000)", csr_rdata);

        /////////////////////////////////////////////////////////
        // TEST 2: Enable Global Interrupt (MSTATUS.MIE)
        /////////////////////////////////////////////////////////

        csr_addr  = 12'h300;
        csr_wdata = 32'h0000_0008; // bit 3
        csr_op    = 2'b01;         // CSRRS
        csr_valid = 1;

        #10;
        csr_valid = 0;

        #10;
        csr_addr = 12'h300;
        #1  $display("[TEST 2] MSTATUS = %h (Expected: 00000008)", csr_rdata);

        /////////////////////////////////////////////////////////
        // TEST 3: Enable External Interrupt in MIE
        /////////////////////////////////////////////////////////

        csr_addr  = 12'h304;
        csr_wdata = 32'h0000_0800; // bit 11
        csr_op    = 2'b01;
        csr_valid = 1;

        #10;
        csr_valid = 0;

        #10;
        csr_addr = 12'h304;
        #1  $display("[TEST 3] MIE = %h (Expected: 00000800)", csr_rdata);

        /////////////////////////////////////////////////////////
        // TEST 4: Assert External Interrupt
        /////////////////////////////////////////////////////////

        ext_irq = 1;

        #10;  // allow mip to latch

        #1  $display("[TEST 4] interrupt_pending = %b (Expected: 1)", interrupt_pending);
        $display("          interrupt_cause   = %h (Expected: 8000000B)", interrupt_cause);

        /////////////////////////////////////////////////////////
        // TEST 5: Take Interrupt Trap
        /////////////////////////////////////////////////////////

        trap_enter = 1;
        trap_is_interrupt = 1;
        trap_pc = 32'h0000_ABCD;

        #10;
        trap_enter = 0;

        #1 $display("[TEST 5] MEPC   = %h (Expected: 0000ABCD)", mepc_out);
        $display("          MCAUSE = %h (Expected: 8000000B)", dut.mcause);
        $display("          MSTATUS= %h (Expected: 00000080)",dut.mstatus);

        /////////////////////////////////////////////////////////
        // TEST 6: Execute MRET
        /////////////////////////////////////////////////////////

        mret_exec = 1;
        #10;
        mret_exec = 0;

        #1 $display("[TEST 6] MSTATUS after MRET = %h (Expected: 00000088)", dut.mstatus);

        /////////////////////////////////////////////////////////
        // TEST 7: CSR Immediate (CSRRSI on MIE)
        /////////////////////////////////////////////////////////

        csr_addr  = 12'h304;
        csr_wdata = 32'h0000_0080;  // set bit 7
        csr_op    = 2'b01;
        csr_valid = 1;

        #10;
        csr_valid = 0;

        #10;
        csr_addr = 12'h304;
        #1  $display("[TEST 7] MIE after CSRRSI = %h (Expected: 00000880)", csr_rdata);

        #50;

        $display("\n================ CSR TEST END ==================\n");
        $finish;
    end

    ////////////////////////////////////////////////////////////
    // Waveform Dump
    ////////////////////////////////////////////////////////////

    initial begin
        $dumpfile("csr_test.vcd");
        $dumpvars(0, csr_test);
    end

endmodule
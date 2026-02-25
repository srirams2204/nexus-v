`timescale 1ns/1ps

module csr_test;

    reg clk;
    reg rst_n;

    wire [31:0] bus_addr;
    wire [31:0] bus_wdata;
    wire        bus_write;
    wire        bus_valid;
    wire [31:0] bus_rdata = 32'd0;
    wire        bus_ready = 1'b1;

    wire mtip = 1'b0;
    wire msip = 1'b0;
    wire meip = 1'b0;

    // Instantiate the Core
    nexusV_core DUT (
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_write(bus_write),
        .bus_valid(bus_valid),
        .bus_rdata(bus_rdata),
        .bus_ready(bus_ready),
        .mtip(mtip),
        .msip(msip),
        .meip(meip),
        .clk(clk),
        .rst_n(rst_n)
    );

    // ---------------- Clock Generation ----------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz Clock
    end

    // ---------------- Reset Sequence ----------------
    initial begin
        rst_n = 0;
        #30;
        rst_n = 1;
    end

    // ---------------- Clean Execution Trace ----------------
    // Logs the PC only when a new instruction is latched from the fetch buffer
    always @(posedge clk) begin
        if (rst_n && DUT.ir_en) begin
            $display("[%0t] Executing PC: %08x", $time, DUT.current_pc_wire);
        end
    end

    // ---------------- Trap & Exception Logging ----------------
    always @(posedge clk) begin
        if (rst_n) begin
            if (DUT.trap_enter_wire) begin
                $display("\n>>> [TRAP EXCEPTION] Time: %0t", $time);
                $display("    Faulting PC (mepc) : %08x", DUT.CSR.mepc);
                $display("    Cause Code (mcause): %08x\n", DUT.CSR.mcause);
            end

            if (DUT.mret_exec_wire) begin
                $display("\n>>> [TRAP RETURN] Time: %0t", $time);
                $display("    Returning to PC    : %08x\n", DUT.CSR.mepc);
            end
        end
    end

    // ---------------- Auto-Halt Detection ----------------
    // Detects if the CPU jumps to the exact same PC it is currently at (e.g., j .)
    reg [31:0] last_executed_pc;
    always @(posedge clk) begin
        if (rst_n && DUT.ir_en) begin
            if (DUT.current_pc_wire == last_executed_pc) begin
                $display("\n[HALT DETECTED] Infinite loop at PC: %08x", DUT.current_pc_wire);
                dump_architectural_state();
            end
            last_executed_pc <= DUT.current_pc_wire;
        end
    end

    // Failsafe Timeout
    initial begin
        #100000; // Adjust this if your program takes longer to run
        $display("\n[TIMEOUT] Simulation exceeded maximum time limit.");
        dump_architectural_state();
    end

    // ---------------- Universal State Dump Task ----------------
    task dump_architectural_state;
        integer i;
        begin
            $display("\n======================================================================");
            $display("                       FINAL REGISTER FILE DUMP");
            $display("======================================================================");
            // Print registers in a 4-column grid
            for (i = 0; i < 32; i = i + 4) begin
                $display(" x%02d: %08x | x%02d: %08x | x%02d: %08x | x%02d: %08x",
                         i,   DUT.RF.register[i],
                         i+1, DUT.RF.register[i+1],
                         i+2, DUT.RF.register[i+2],
                         i+3, DUT.RF.register[i+3]);
            end

            $display("\n======================================================================");
            $display("                          FINAL CSR DUMP");
            $display("======================================================================");
            $display(" mstatus  : %08x       misa     : %08x", DUT.CSR.mstatus, 32'h40000100);
            $display(" mie      : %08x       mip      : %08x", DUT.CSR.mie, DUT.CSR.mip);
            $display(" mtvec    : %08x       mscratch : %08x", DUT.CSR.mtvec, DUT.CSR.mscratch);
            $display(" mepc     : %08x       mcause   : %08x", DUT.CSR.mepc, DUT.CSR.mcause);
            $display("======================================================================\n");
            
            $finish;
        end
    endtask

endmodule
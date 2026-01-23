`timescale 1ns/1ps
`include "rv_defs.vh"

module tb_nexusV;

    // ============================================================
    // 1. Inputs to Core
    // ============================================================
    reg clk;
    reg rst_n;

    // ============================================================
    // 2. Instantiate the Core
    // ============================================================
    nexusV_core uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ============================================================
    // 3. Clock Generation (10ns Period -> 100MHz)
    // ============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // 4. Test Sequence
    // ============================================================
    integer i;
    integer file;

    initial begin
        // --------------------------------------------------------
        // B. Waveform Setup
        // --------------------------------------------------------
        $dumpfile("waveform/nexusV_tb.vcd");
        $dumpvars(0, tb_nexusV);

        // --------------------------------------------------------
        // C. Run Simulation
        // --------------------------------------------------------
        rst_n = 0;
        #20;        
        rst_n = 1;  
        $display("[%0t] Reset released. Processor running...", $time);

        // Wait for program to complete (approx 500-1000ns)
        #2000;

        // --------------------------------------------------------
        // D. Dump Register File
        // --------------------------------------------------------
        $display("\n==================================================");
        $display("           FINAL REGISTER FILE CONTENTS           ");
        $display("==================================================");

        // Loop through all 32 registers and print them
        for (i = 0; i < 32; i = i + 1) begin
            // NOTE: Ensure 'regs' matches the array name in register_file.v
            $display("x%02d = 0x%h", i, uut.RF.register[i]);
        end

        $display("==================================================\n");
        $finish;
    end

endmodule
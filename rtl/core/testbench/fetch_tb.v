`timescale 1ns/1ps
`include "rv_defs.vh"

module fetch_tb;

    // ----------------------------------
    // 1. Signals
    // ----------------------------------
    reg clk;
    reg rst_n; // Active Low Reset

    // ----------------------------------
    // 2. Instantiate DUT (Device Under Test)
    // ----------------------------------
    nexusV_core uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // ----------------------------------
    // 3. Clock Generation (10ns Period -> 100MHz)
    // ----------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ----------------------------------
    // 4. Test Sequence
    // ----------------------------------
    initial begin
        $dumpfile("waveform/fetch_tb.vcd");
        $dumpvars(0, fetch_tb);

        rst_n = 0;      
        $display("--------------------------------------------------");
        $display("           NexusV Fetch Logic Test                ");
        $display("--------------------------------------------------");

        #20;
        rst_n = 1;       
        $display("Time=%0t | Reset Released", $time);

        repeat (100) begin
            @(negedge clk);
            $display("Time=%0t | State=%d | Executing[Addr=%h Instr=%h] | Next_Fetch[Addr=%h]", 
                     $time, 
                     uut.DECODER.state,       // Current FSM State
                     uut.old_pc_wire,         // PC of the instruction in IR
                     uut.instr_out_wire,      // The Instruction in IR
                     uut.current_pc_wire      // The PC Counter (pointing ahead)
            );
        end

        #20;
        $display("--------------------------------------------------");
        $display("           Test Complete                          ");
        $display("--------------------------------------------------");
        $finish;
    end

endmodule
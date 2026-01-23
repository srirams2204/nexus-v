`timescale 1ns/1ps

module debug_tb;

    reg clk;
    reg rst_n;
    wire [31:0] pc_spy;
    wire [31:0] instr_spy;

    nexusV_core uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    assign pc_spy    = uut.current_pc_wire;
    assign instr_spy = uut.rom_out_wire;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer cycles;

    initial begin
        rst_n = 0;
        cycles = 0;
        #20;
        rst_n = 1;
        $display("[INFO] Fast Debug Simulation Started...");
    end

    always @(posedge clk) begin
        cycles = cycles + 1;
        
        // Print status every 1 million cycles
        if (cycles % 1000000 == 0) begin
            $display("Time: %0t ns | Cycle: %0d | PC: 0x%h | Instr: 0x%h", 
                     $time, cycles, pc_spy, instr_spy);
        end
        
        // Check for finish loop (Jumping to self at 0x8 or similar small address)
        if (pc_spy < 32'h20 && instr_spy == 32'h0000006f) begin
             $display("\n[SUCCESS] CPU Finished at PC 0x%h!", pc_spy);
             $display("Final x10 (Result): 0x%h", uut.RF.register[10]);
             $finish;
        end
    end

endmodule
`timescale 1ns/1ps

module benchmark_tb;

    // ============================================================
    // 1. CONFIGURATION
    // ============================================================
    parameter CLK_PERIOD_NS = 10;      // 10ns = 100 MHz
    parameter FREQ_MHZ      = 100.0;   
    
    reg clk;
    reg rst_n;
    wire [31:0] pc_spy;
    wire [31:0] result_reg;

    // Instantiate Core
    nexusV_core uut (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Spy Signals
    assign pc_spy     = uut.current_pc_wire;
    assign result_reg = uut.RF.register[10]; // x10 (a0)

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD_NS/2) clk = ~clk;
    end

    // ============================================================
    // 2. METRICS TRACKING
    // ============================================================
    real    start_time;
    real    total_cycles;
    integer instr_count;     // Total instructions executed
    reg [31:0] prev_pc;      // To detect PC changes
    integer heartbeat;

    initial begin
        // Initialize
        rst_n = 0;
        heartbeat = 0;
        instr_count = 0;
        prev_pc = 32'h0;

        // Reset Pulse
        #20;
        rst_n = 1;
        
        start_time = $time;
        $display("\n[INFO] Simulation Started...");
        $display("[INFO] Tracking Performance Metrics (CPI, MIPS)...");
    end

    // ============================================================
    // 3. INSTRUCTION COUNTER & STOP LOGIC
    // ============================================================
    always @(posedge clk) begin
        if (rst_n) begin
            
            // A. Count Instructions
            // We assume every time the PC changes to a NEW value, 
            // 1 instruction has been retired.
            if (pc_spy != prev_pc && pc_spy != 32'h8) begin
                instr_count = instr_count + 1;
                prev_pc = pc_spy;
            end

            // B. Heartbeat (Show progress)
            heartbeat = heartbeat + 1;
            if (heartbeat >= 10000) begin
                $display("Time: %0t | PC: 0x%h | Instr Count: %0d", $time, pc_spy, instr_count);
                heartbeat = 0;
            end

            // C. SUCCESS CONDITION
            // Stop if PC is at 0x8 AND we have a result in x10
            if (pc_spy == 32'h8 && result_reg != 32'b0) begin
                 // Compensate for the Fetch pre-increment
                 total_cycles = ($time - start_time) / CLK_PERIOD_NS;
                 
                 $display("\n[SUCCESS] CPU Finished execution!");
                 print_metrics();
                 $finish;
            end
        end
    end

    // Timeout Safety
    initial begin
        #2000000000; // 2 seconds
        $display("\n[ERROR] Simulation Timed Out!");
        $display("Last PC: 0x%h", pc_spy);
        $finish;
    end

    // ============================================================
    // 4. METRICS CALCULATION & REPORTING
    // ============================================================
    task print_metrics;
        real cpi;
        real mips;
        real exec_time_us;
        begin
            // 1. Calculate CPI (Cycles Per Instruction)
            // Avoid divide by zero
            if (instr_count > 0)
                cpi = total_cycles / instr_count;
            else
                cpi = 0;

            // 2. Calculate MIPS (Million Instructions Per Second)
            // Formula: Freq(MHz) / CPI
            if (cpi > 0)
                mips = FREQ_MHZ / cpi;
            else
                mips = 0;

            // 3. Execution Time in Microseconds
            exec_time_us = total_cycles * (CLK_PERIOD_NS / 1000.0);

            // --------------------------------------------------------
            // PRINT TABLE
            // --------------------------------------------------------
            $display("\n============================================================");
            $display("               NEXUS-V PERFORMANCE REPORT                   ");
            $display("============================================================");
            $display(" BENCHMARK STATUS  :  PASS");
            $display(" RETURN VALUE (x10):  0x%h (Decimal: %0d)", result_reg, result_reg);
            $display(" ------------------------------------------------------------");
            $display(" TIMING DETAILS:");
            $display("   Frequency       :  %0.1f MHz", FREQ_MHZ);
            $display("   Total Cycles    :  %0.0f", total_cycles);
            $display("   Exec Time       :  %0.3f us", exec_time_us);
            $display(" ------------------------------------------------------------");
            $display(" INSTRUCTION STATS:");
            $display("   Instr Executed  :  %0d", instr_count);
            $display(" ------------------------------------------------------------");
            $display(" PERFORMANCE METRICS:");
            $display("   CPI (Cycles/Instr):  %0.3f", cpi);
            $display("   MIPS Score        :  %0.3f", mips);
            $display("============================================================\n");
        end
    endtask

endmodule
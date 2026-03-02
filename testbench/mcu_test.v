`timescale 1ns / 1ps

module mcu_test;
    reg clk;
    reg rst_n;

    // Instantiate the Top-Level MCU
    nexusV_mcu dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // 100 MHz Clock Generation
    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        // Waveform setup for GTKWave
        $dumpfile("mcu_test.vcd");
        $dumpvars(0, mcu_test);

        // Initialization
        rst_n = 0;

        $display("\n[SYSTEM] Nexus-V MCU Simulation Initialized.");
        $display("[SYSTEM] Holding Reset for 50ns...");
        
        #50 rst_n = 1; // Release Reset
        $display("[SYSTEM] Reset Released at %0t.", $time);

        // Run for enough time to see the timer increment
        // 5000ns = 500 clock cycles
        #5000; 

        $display("\n[SYSTEM] Simulation Timeout Reached.");
        print_mcu_state();
        $finish;
    end

    // --- Monitor Execution & CLINT ---
    initial begin
        $display("\nTime\t\tPC\t\tmtime\t\t\tmtimecmp\t\tMTIP");
        $display("-----------------------------------------------------------------------------------");
        forever begin
            @(posedge clk);
            // Print every 50 clock cycles to avoid spamming the console
            if (rst_n && ($time % 500 == 0)) begin
                $display("%0t\t%h\t0x%016x\t0x%016x\t%b", 
                         $time, 
                         dut.u_core.fetch_pc,     // Peek into the Core
                         dut.u_clint.mtime,       // Peek into the CLINT
                         dut.u_clint.mtimecmp,    // Peek into the CLINT
                         dut.mtip_wire);          // Peek at the interrupt wire
            end
        end
    end

    // --- Final State Dump Task ---
    task print_mcu_state;
        integer i;
        begin
            $display("\n=================== FINAL REGISTER FILE DUMP ===================");
            for (i = 0; i < 32; i = i + 4) begin
                $display(" x%02d: 0x%h | x%02d: 0x%h | x%02d: 0x%h | x%02d: 0x%h", 
                    i,   dut.u_core.RF.register[i], 
                    i+1, dut.u_core.RF.register[i+1], 
                    i+2, dut.u_core.RF.register[i+2], 
                    i+3, dut.u_core.RF.register[i+3]);
            end
            $display("---------------------------------------------------------------");
            $display(" mepc  : 0x%h | mtvec  : 0x%h | mcause : 0x%h",
                     dut.u_core.CSR.mepc, dut.u_core.CSR.mtvec, dut.u_core.CSR.mcause);
            
            $display("---------------------------------------------------------------");
            $display(" mtime : 0x%016x", dut.u_clint.mtime);
            $display(" mtimecmp : 0x%016x", dut.u_clint.mtimecmp);
            $display("===============================================================\n");
        end
    endtask

endmodule
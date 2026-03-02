`timescale 1ns / 1ps

module core_test;
    reg clk;
    reg rst_n;
    reg [31:0] bus_rdata;
    reg bus_ready;
    reg mtip, msip, meip;

    wire [31:0] bus_addr, bus_wdata;
    wire bus_write, bus_valid;

    // Instantiate the Nexus-V Core
    nexusV_core dut (
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

    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz Clock

    // Synchronous Peripheral Model
    // This ensures bus_ready is aligned with the clock edge, preventing stalls.
    always @(posedge clk) begin
        if (!rst_n) begin
            bus_ready <= 1'b0;
            bus_rdata <= 32'h0;
        end else begin
            // We stay 'ready' to allow the multi-cycle FSM to flow smoothly
            bus_ready <= 1'b1; 
            
            // Handle Data Reads from APB/External space
            if (bus_valid && !bus_write) begin
                bus_rdata <= 32'hDEADBEEF; 
            end else begin
                bus_rdata <= 32'h0;
            end
        end
    end

    initial begin
        // Waveform setup
        $dumpfile("core_test.vcd");
        $dumpvars(0, core_test);

        // Initialization
        rst_n = 0;
        mtip = 0; msip = 0; meip = 0;

        $display("\n[SYSTEM] Nexus-V Core Simulation Initialized.");
        $display("[SYSTEM] Holding Reset for 50ns...");
        
        #50 rst_n = 1; // Release Reset
        $display("[SYSTEM] Reset Released at %0t.", $time);

        // Run for a total of 3000ns
        // Each multi-cycle instruction takes ~40-50ns
        #2800; 

        $display("\n[SYSTEM] Simulation Timeout Reached.");
        print_regs();
        $finish;
    end

    initial begin
        $display("\nTime\t\tPC\t\tState\tInstruction\tx10(a0)\t\tx11(a1)");
        $display("-----------------------------------------------------------------------");
        forever begin
            @(posedge clk);
            // We print when the FSM is in DECODE (State 3) or EXECUTE (State 4)
            // to show the values as they are being processed.
            if (rst_n && (dut.CU.state == 4'd3)) begin
                $display("%0t\t%h\t%d\t%h\t%h\t%h", 
                         $time, 
                         dut.fetch_pc, 
                         dut.CU.state,
                         dut.buffered_instr,
                         dut.RF.register[10],
                         dut.RF.register[11]);
            end
        end
    end

    task print_regs;
        integer i;
        begin
            $display("\n=================== FINAL REGISTER FILE DUMP ===================");
            for (i = 0; i < 32; i = i + 4) begin
                // Note: Ensure your internal array in register_file.v is named 'register'
                $display(" x%02d: 0x%h | x%02d: 0x%h | x%02d: 0x%h | x%02d: 0x%h", 
                    i,   dut.RF.register[i], 
                    i+1, dut.RF.register[i+1], 
                    i+2, dut.RF.register[i+2], 
                    i+3, dut.RF.register[i+3]);
            end
            $display("---------------------------------------------------------------");
            $display(" mepc : 0x%h | mtvec : 0x%h | mcause: 0x%h",
                     dut.CSR.mepc, dut.CSR.mtvec, dut.CSR.mcause);
            $display("===============================================================\n");
        end
    endtask

endmodule
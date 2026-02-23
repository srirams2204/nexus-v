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

    // ---------------- Clock ----------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;   // 100MHz
    end

    // ---------------- Reset ----------------
    initial begin
        rst_n = 0;
        #30;
        rst_n = 1;
    end

    // ---------------- Monitor ----------------
    initial begin
        $display("-------------------------------------------------------");
        $display(" Time   PC          mepc        mcause   trap mret ");
        $display("-------------------------------------------------------");

        $monitor("%0t   %h   %h   %h   %b    %b",
                 $time,
                 DUT.current_pc_wire,
                 DUT.CSR.mepc,
                 DUT.CSR.mcause,
                 DUT.trap_enter_wire,
                 DUT.mret_exec_wire);
    end

    // ---------------- Trap Logging ----------------
    always @(posedge clk) begin
        if (DUT.trap_enter_wire) begin
            $display(">>> TRAP ENTERED at %0t", $time);
            $display("    mepc   = %h", DUT.CSR.mepc);
            $display("    mcause = %h", DUT.CSR.mcause);
        end

        if (DUT.mret_exec_wire) begin
            $display(">>> MRET EXECUTED at %0t", $time);
            $display("    Returning to %h", DUT.CSR.mepc);
        end
    end

    // ---------------- End Simulation ----------------
    initial begin
        #2000;

        $display("\n---- Final Register Values ----");
        $display("x1 = %0d", DUT.RF.register[1]);
        $display("x2 = %0d", DUT.RF.register[2]);
        $display("--------------------------------");

        $finish;
    end

endmodule
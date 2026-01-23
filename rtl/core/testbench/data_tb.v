`timescale 1ns/1ps

module data_tb;

    reg         clk;
    reg         read_en, write_en;
    reg [31:0]  address, write_data;
    reg [2:0]   funct3;

    wire [31:0] read_data;
    wire        misaligned;

    integer errors;

    data_mem dut (
        .read_data (read_data),
        .misaligned(misaligned),
        .read_en   (read_en),
        .write_en  (write_en),
        .address   (address),
        .write_data(write_data),
        .funct3    (funct3),
        .clk       (clk)
    );

    always #5 clk = ~clk;

    task check;
        input [31:0] exp;
        input [127:0] name;
        begin
            if (read_data !== exp) begin
                $display("❌ FAIL: %s | exp=0x%08h act=0x%08h", name, exp, read_data);
                errors = errors + 1;
            end else begin
                $display("✅ PASS: %s | value=0x%08h", name, read_data);
            end
        end
    endtask

    initial begin
        $dumpfile("waveform/data_mem.vcd");
        $dumpvars(0, data_tb);

        clk = 0;
        errors = 0;
        read_en = 0;
        write_en = 0;
        address = 0;
        write_data = 0;
        funct3 = 0;

        $display("\n===============================");
        $display(" DATA MEMORY VERIFICATION START ");
        $display("===============================\n");

        // -----------------------------
        // SW + LW
        // -----------------------------
        @(posedge clk);
        @(posedge clk);
        address = 32'h0000_0004;
        write_data = 32'hDEADBEEF;
        funct3 = 3'b010;
        write_en = 1;

        @(posedge clk);
        @(posedge clk);
        write_en = 0;
        read_en  = 1;

        @(posedge clk);
        @(posedge clk);
        check(32'hDEADBEEF, "SW/LW");

        // -----------------------------
        // SB / LB / LBU
        // -----------------------------
        @(posedge clk);
        @(posedge clk);
        address = 32'h0000_0001;
        write_data = 32'h000000AA;
        funct3 = 3'b000;
        write_en = 1;

        @(posedge clk);
        @(posedge clk);
        write_en = 0;
        read_en  = 1;

        @(posedge clk);
        @(posedge clk);
        check(32'hFFFFFFAA, "SB/LB");

        funct3 = 3'b100;
        @(posedge clk);
        @(posedge clk);
        check(32'h000000AA, "SB/LBU");

        // -----------------------------
        // SH / LH / LHU
        // -----------------------------
        @(posedge clk);
        @(posedge clk);
        address = 32'h0000_0002;
        write_data = 32'h00001234;
        funct3 = 3'b001;
        write_en = 1;

        @(posedge clk);
        @(posedge clk);
        write_en = 0;
        read_en  = 1;

        @(posedge clk);
        @(posedge clk);
        check(32'h00001234, "SH/LH");

        funct3 = 3'b101;
        @(posedge clk);
        @(posedge clk);
        check(32'h00001234, "SH/LHU");

        // -----------------------------
        // Misaligned access
        // -----------------------------
        @(posedge clk);
        @(posedge clk);
        address = 32'h0000_0001;
        funct3  = 3'b010;
        read_en = 1;

        @(posedge clk);
        if (misaligned)
            $display("✅ PASS: Misaligned detected");
        else begin
            $display("❌ FAIL: Misaligned not detected");
            errors = errors + 1;
        end

        // -----------------------------
        // Summary
        // -----------------------------
        $display("\n===============================");
        if (errors == 0)
            $display(" 🎉 ALL DATA MEMORY TESTS PASSED ");
        else
            $display(" ❌ DATA MEMORY TESTS FAILED: %0d errors", errors);
        $display("===============================\n");

        $finish;
    end

endmodule

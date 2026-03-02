`timescale 1ns/1ps

module fetch_test;
    wire [31:0] fetch_instr;   // Output from ROM
    wire [31:0] fetch_pc;      // Output from PC (current)
    
    wire [31:0] buffered_pc;
    wire [31:0] buffered_instr;

    reg [31:0] pc_nxt;
    reg pc_write, fbuf_en, clk, rst;

    fetch_state dut_fetch (
        .instr_out(fetch_instr),
        .pc_current(fetch_pc),
        .pc_nxt(pc_nxt),
        .pc_write(pc_write),
        .clk(clk),
        .rst(rst)
    );

    fetch_buffer dut_buffer (
        .pc(buffered_pc),
        .instr(buffered_instr),
        .pc_in(fetch_pc),
        .instr_in(fetch_instr),
        .fbuf_en(fbuf_en),
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        pc_write = 0; fbuf_en = 0;
        pc_nxt = 32'h0;

        #15 rst = 0;
        
        #10 pc_write = 1; fbuf_en = 1;
            pc_nxt = 32'h00000004;
        
        #10 pc_write = 1; fbuf_en = 0;
            pc_nxt = 32'h00000008; 
            

        #10 fbuf_en = 1;
            pc_nxt = 32'h0000000C;

        
        #10 pc_nxt = 32'h00000020; // Jumping to address 0x20

        #40;
        $display("Simulation Finished");
        $finish;
    end

    initial begin
        $dumpfile("fetch_test.vcd");
        $dumpvars(0, fetch_test);
    end
endmodule
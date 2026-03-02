`timescale 1ns/1ps
module apb_master (
    // Interface to nexusV_core
    input  wire [31:0] cpu_addr,   // From bus_addr
    input  wire [31:0] cpu_wdata,  // From bus_wdata
    input  wire cpu_write,         // From bus_write
    input  wire cpu_valid,         // From bus_valid
    output reg [31:0] cpu_rdata,   // To bus_rdata
    output reg cpu_ready,          // To bus_ready

    // APB Master Interface 
    output reg [31:0] paddr,   // APB Address
    output reg [31:0] pwdata,  // APB Write Data
    output reg pwrite,         // 1=Write, 0=Read
    output reg psel,           // Peripheral Select
    output reg penable,        // Peripheral Enable
    input [31:0] prdata,       // Data from Peripheral
    input pready,              // Ready from Peripheral

    // global signals
    input  wire        pclk,
    input  wire        presetn   
);

localparam IDLE = 2'd0;
localparam SETUP = 2'd1;
localparam ACCESS = 2'd2;

reg [1:0] state, next_state;

always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end 

always @(*) begin
    next_state = state;
    psel = 1'b0;
    penable = 1'b0;
    cpu_ready = 1'b0;
    case (state)
        IDLE: begin
            if (cpu_valid) begin
                next_state = SETUP;
            end
        end
        SETUP: begin
            psel = 1'b1;
            penable = 1'b0;
            next_state = ACCESS;
        end
        ACCESS: begin
            psel = 1'b1;
            penable = 1'b1;
            if (pready) begin
                cpu_ready = 1'b1;
                next_state = IDLE;
            end else begin
                next_state = ACCESS;
            end
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        paddr     <= 32'h0;
        pwdata    <= 32'h0;
        pwrite    <= 1'b0;
        cpu_rdata <= 32'h0;
    end else begin
        if (state == IDLE && cpu_valid) begin
            paddr  <= cpu_addr;
            pwdata <= cpu_wdata;
            pwrite <= cpu_write;
        end
        if (state == ACCESS && pready && !pwrite) begin
            cpu_rdata <= prdata;
        end
    end
end

endmodule
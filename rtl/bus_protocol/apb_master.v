`timescale 1ns/1ps

module apb_master(
    // APB MASTER OUTPUT
    output reg [31:0] PADDR,  // APB Address
    output reg [31:0] PWDATA, // APB Write Data
    output reg PWRITE,        // APB Direction (1=Write)
    output reg PSEL,          // APB Select (Peripheral Wakeup)
    output reg PENABLE,       // APB Enable (Strobe)

    input [31:0] PRDATA,      // Data from Slave
    input PREADY,             // Slave Ready (APB Wait State)

    // APB MASTER Connection with CPU Core
    input [31:0] bus_addr,    // Target Address (ALUOut)
    input [31:0] bus_wdata,   // Write Data (RS2)
    input bus_write,          // 1 = Write, 0 = Read
    input bus_valid,          // Request Trigger
 
    output reg bus_ready,     // Stall Control (1=Done, 0=Wait)
    output reg [31:0] bus_rdata,  // Data returned to CPU

    // Global Signals
    input clk,
    input rst_n
);

localparam IDLE   = 2'b00;
localparam SETUP  = 2'b01;
localparam ACCESS = 2'b10;

reg [1:0] state, next_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE; 
    else        state <= next_state;
end

always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            if (bus_valid) next_state = SETUP;
            else           next_state = IDLE;
        end 

        SETUP: begin
            next_state = ACCESS;
        end

        ACCESS: begin
            if (PREADY) begin
                // MUST go to IDLE to unfreeze the CPU stall
                next_state = IDLE; 
            end else begin
                next_state = ACCESS;
            end
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        PADDR   <= 32'b0;
        PWDATA  <= 32'b0;
        PWRITE  <= 1'b0;
        PSEL    <= 1'b0;
        PENABLE <= 1'b0;
    end else begin
        case (next_state)
            IDLE: begin
                PSEL    <= 1'b0;
                PENABLE <= 1'b0;
            end

            SETUP: begin
                PADDR   <= bus_addr;
                PWDATA  <= bus_wdata;
                PWRITE  <= bus_write;
                PSEL    <= 1'b1;     // Select goes High NOW
                PENABLE <= 1'b0;
            end

            ACCESS: begin
                PENABLE <= 1'b1;     // Enable goes High NOW
            end
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bus_ready <= 1'b1;
        bus_rdata <= 32'b0;
    end else begin
        case (state)
            IDLE: begin
                if (bus_valid) bus_ready <= 1'b0; // Freeze CPU immediately
            end

            SETUP: begin
                bus_ready <= 1'b0; // Keep Frozen
            end

            ACCESS: begin
                if (PREADY) begin
                    bus_ready <= 1'b1;   // Unfreeze CPU
                    if (!PWRITE) begin
                        bus_rdata <= PRDATA; // Capture Data
                    end
                end
            end
        endcase
    end
end

endmodule
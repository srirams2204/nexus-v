`timescale 1ns/1ps
module clint_apb (
    // Core Interface 
    output mtip,       // Machine Timer Interrupt Pending
    output msip,        // Machine Software Interrupt Pending
    // APB Slave Interface 
    output reg [31:0] prdata,   // Read data bus
    output pready,              // Slave ready signal
    input [31:0] paddr,         // APB Address bus (from Master)
    input psel,                 // Peripheral Select (from Decoder)
    input penable,              // Enable signal (from Master)
    input pwrite,               // Write control (1=Write, 0=Read)
    input [31:0] pwdata,        // Write data bus
    // global signal
    input pclk,                
    input presetn              
);

// addr mapping
/*
0x000: mtime [31:0]
0x004: mtime [63:32]
0x008: mtimecmp [31:0]
0x00c: mtimecmp [63:32]
0x010: msip
*/

reg [63:0] mtime, mtimecmp;
reg msip_reg;

// no wait state needed
assign pready = 1'b1;

assign mtip = (mtime >= mtimecmp);
assign msip = msip_reg;

always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
        mtime <= 64'b0;
        mtimecmp <= 64'hFFFF_FFFF_FFFF_FFFF;
        msip_reg <= 1'b0;
    end else begin
        mtime <= mtime +1'b1;
        if (psel && pwrite && penable) begin
            case (paddr[11:0]) 
                12'h000: mtime[31:0] <= pwdata;
                12'h004: mtime[63:32] <= pwdata;
                12'h008: mtimecmp[31:0] <= pwdata;
                12'h00C: mtimecmp[63:32] <= pwdata;
                12'h010: msip_reg <= pwdata[0];
            endcase
        end
    end
end

always @(*) begin
    prdata = 32'h0; // Default to 0 to prevent latches
    // Only output data during a valid APB read phase
    if (psel && !pwrite) begin
        case (paddr[11:0])
            12'h000: prdata = mtime[31:0];
            12'h004: prdata = mtime[63:32];
            12'h008: prdata = mtimecmp[31:0];
            12'h00C: prdata = mtimecmp[63:32];
            12'h010: prdata = {31'b0, msip_reg};
            default: prdata = 32'h0;
        endcase
    end
end

endmodule
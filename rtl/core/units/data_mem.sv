`include "../include/rv_defs.vh"

module data_mem #(
    parameter WIDTH = 32,
    parameter memDepth = 1024
) (
    output reg [WIDTH-1:0] data_out,
    input wire [WIDTH-1:0] mem_addr,
    input wire [WIDTH-1:0] mem_data,
    input wire             wr_en,
    input wire [2:0]       funct3,
    input wire             clk,
    input wire             rst
);

    // Force Block RAM inference
    (* ram_style = "block" *) reg [31:0] mem [0:memDepth-1];

    wire [9:0] word_addr = mem_addr[11:2];
    wire [1:0] byte_offset = mem_addr[1:0];

    // --- 1. Combinational Write Control Logic ---
    reg [3:0]  write_mask;
    reg [31:0] wdata_aligned;

    always @(*) begin
        write_mask = 4'b0000;
        wdata_aligned = mem_data; // Default

        if (wr_en) begin
            case (funct3)
                3'b000: begin // SB (Store Byte)
                    // Replicate byte to all positions so alignment doesn't matter
                    wdata_aligned = {4{mem_data[7:0]}}; 
                    case (byte_offset)
                        2'b00: write_mask = 4'b0001;
                        2'b01: write_mask = 4'b0010;
                        2'b10: write_mask = 4'b0100;
                        2'b11: write_mask = 4'b1000;
                    endcase
                end
                3'b001: begin // SH (Store Half)
                    // Replicate halfword to top and bottom
                    wdata_aligned = {2{mem_data[15:0]}};
                    if (byte_offset[1] == 0) write_mask = 4'b0011;
                    else                     write_mask = 4'b1100;
                end
                3'b010: begin // SW (Store Word)
                    wdata_aligned = mem_data;
                    write_mask = 4'b1111;
                end
                default: write_mask = 4'b0000;
            endcase
        end
    end

    // --- 2. Sequential Memory Access (Infers Byte-Enabled BRAM) ---
    reg [31:0] raw_word;
    
    // Initialize memory to zero for simulation/synthesis
    integer i;
    initial begin
        for (i=0; i<memDepth; i=i+1) mem[i] = 32'h0;
    end

    always @(negedge clk) begin
        // Read Port
        raw_word <= mem[word_addr];

        // Write Port: Standard "Byte Enable" pattern for Yosys
        if (write_mask[0]) mem[word_addr][7:0]   <= wdata_aligned[7:0];
        if (write_mask[1]) mem[word_addr][15:8]  <= wdata_aligned[15:8];
        if (write_mask[2]) mem[word_addr][23:16] <= wdata_aligned[23:16];
        if (write_mask[3]) mem[word_addr][31:24] <= wdata_aligned[31:24];
    end

    // --- 3. Output Logic (Sign Extension) ---
    always @(*) begin
        case (funct3)
            3'b000: begin // LB
                case (byte_offset)
                    2'b00: data_out = {{24{raw_word[7]}},  raw_word[7:0]};
                    2'b01: data_out = {{24{raw_word[15]}}, raw_word[15:8]};
                    2'b10: data_out = {{24{raw_word[23]}}, raw_word[23:16]};
                    2'b11: data_out = {{24{raw_word[31]}}, raw_word[31:24]};
                endcase
            end
            3'b001: begin // LH
                if (byte_offset[1] == 1'b0) data_out = {{16{raw_word[15]}}, raw_word[15:0]};
                else                        data_out = {{16{raw_word[31]}}, raw_word[31:16]};
            end
            3'b010: data_out = raw_word; // LW
            3'b100: begin // LBU
                case (byte_offset)
                    2'b00: data_out = {24'b0, raw_word[7:0]};
                    2'b01: data_out = {24'b0, raw_word[15:8]};
                    2'b10: data_out = {24'b0, raw_word[23:16]};
                    2'b11: data_out = {24'b0, raw_word[31:24]};
                endcase
            end
            3'b101: begin // LHU
                if (byte_offset[1] == 1'b0) data_out = {16'b0, raw_word[15:0]};
                else                        data_out = {16'b0, raw_word[31:16]};
            end
            default: data_out = raw_word;
        endcase
    end

endmodule
`include "../include/rv_defs.vh"

module data_mem #(
    parameter WIDTH = `WIDTH,
    parameter memDepth = 1024
) (
    output reg [WIDTH-1:0] data_out,
    input [WIDTH-1:0] mem_addr,
    input [WIDTH-1:0] mem_data,
    input wr_en, // 0 - Load (read), 1 - Store (write)
    input [2:0] funct3,

    input clk,
    input rst
);

(* ram_style = "block" *) reg [31:0] mem [0:memDepth-1];

wire [9:0] word_addr   = mem_addr[11:2];
wire [1:0] byte_offset = mem_addr[1:0];

reg [WIDTH-1:0] raw_word;

// Store Operation
always @(negedge clk) begin
    raw_word <= mem[word_addr];
    if (wr_en) begin
        case(funct3) 
            // Store Byte
            3'b000: begin
                case(byte_offset)
                    2'b00: mem[word_addr][7:0]   <= mem_data[7:0];
                    2'b01: mem[word_addr][15:8]  <= mem_data[15:8];
                    2'b10: mem[word_addr][23:16] <= mem_data[23:16];
                    2'b11: mem[word_addr][31:17] <= mem_data[31:17];
                endcase
            end
            // Store Half
            3'b001: begin
                if (byte_offset[1] == 1'b0)
                    mem[word_addr][15:0]  <= mem_data[15:0];
                else
                    mem[word_addr][31:16] <= mem_data[15:0];
            end
            3'b010: begin
                mem[word_addr] <= mem_data;
            end
        endcase
    end
end

// Load Operations
always @(*) begin
    case (funct3)
        3'b000: begin // LB (Load Byte - Signed)
            case (byte_offset)
                2'b00: data_out = {{24{raw_word[7]}},  raw_word[7:0]};
                2'b01: data_out = {{24{raw_word[15]}}, raw_word[15:8]};
                2'b10: data_out = {{24{raw_word[23]}}, raw_word[23:16]};
                2'b11: data_out = {{24{raw_word[31]}}, raw_word[31:24]};
            endcase
        end

        3'b001: begin // LH (Load Halfword - Signed)
            if (byte_offset[1] == 1'b0)
                data_out = {{16{raw_word[15]}}, raw_word[15:0]};
            else
                data_out = {{16{raw_word[31]}}, raw_word[31:16]};
        end

        3'b010: begin // LW (Load Word)
            data_out = raw_word;
        end

        3'b100: begin // LBU (Load Byte - Unsigned)
            case (byte_offset)
                2'b00: data_out = {24'b0, raw_word[7:0]};
                2'b01: data_out = {24'b0, raw_word[15:8]};
                2'b10: data_out = {24'b0, raw_word[23:16]};
                2'b11: data_out = {24'b0, raw_word[31:24]};
            endcase
        end

        3'b101: begin // LHU (Load Halfword - Unsigned)
            if (byte_offset[1] == 1'b0)
                data_out = {16'b0, raw_word[15:0]};
            else
                data_out = {16'b0, raw_word[31:16]};
        end

        default: data_out = raw_word;
    endcase
end

endmodule
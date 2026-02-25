module data_mem (
    output reg [31:0] read_data,
    output reg        misaligned,

    input             read_en,
    input             write_en,
    input  [31:0]     address,
    input  [31:0]     write_data,
    input  [2:0]      funct3,
    input             clk
);

// Parameters for RISC-V Funct3 
localparam F3_LB  = 3'b000;
localparam F3_LH  = 3'b001;
localparam F3_LW  = 3'b010;
localparam F3_LBU = 3'b100;
localparam F3_LHU = 3'b101;
localparam F3_SB  = 3'b000;
localparam F3_SH  = 3'b001;
localparam F3_SW  = 3'b010;

// Memory Array 
(* ram_style = "block" *) reg [31:0] mem [0:1023];  // change it to 1023 later

integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1)
        mem[i] = 32'b0;
end

// Address Decoding 
wire [9:0] word_addr = address[11:2];
wire [1:0] byte_offset = address[1:0];

// Misalignment Detection
always @(*) begin
    misaligned = 1'b0;
    case (funct3[1:0]) 
        2'b00: misaligned = 1'b0;
        2'b01: misaligned = byte_offset[0];
        2'b10: misaligned = (byte_offset != 2'b00);
        default: misaligned = 1'b0;
    endcase
end

// Write Logic (Byte Enables & Data Alignment)
reg [3:0]  byte_en;
reg [31:0] wdata_aligned;

always @(*) begin
    byte_en = 4'b0000;
    wdata_aligned = 32'b0;

    case (funct3[1:0])
        2'b00: wdata_aligned = {4{write_data[7:0]}};   // SB: Replicate LSB 4 times
        2'b01: wdata_aligned = {2{write_data[15:0]}};  // SH: Replicate Halfword 2 times
        default: wdata_aligned = write_data;           // SW: Pass through 32 bits
    endcase

    if (write_en && !misaligned) begin
        case (funct3)
            F3_SB: byte_en[byte_offset] = 1'b1;
            F3_SH: begin
                byte_en[byte_offset] = 1'b1;
                byte_en[byte_offset + 1] = 1'b1; 
            end
            F3_SW: byte_en = 4'b1111;
            default: byte_en = 4'b0000;
        endcase
    end
end

// --- BRAM Core (Pure Read/Write) ---
reg [31:0] raw_read_word;

always @(posedge clk) begin
    // Byte-Write Port
    if (byte_en[0]) mem[word_addr][7:0]   <= wdata_aligned[7:0];
    if (byte_en[1]) mem[word_addr][15:8]  <= wdata_aligned[15:8];
    if (byte_en[2]) mem[word_addr][23:16] <= wdata_aligned[23:16];
    if (byte_en[3]) mem[word_addr][31:24] <= wdata_aligned[31:24];

    // Read Port
    if (read_en) begin
        raw_read_word <= mem[word_addr];
    end
end

// --- Output Formatting (Combinational) ---
reg [1:0]  read_offset_reg;
reg [2:0]  read_funct3_reg;

always @(posedge clk) begin
    if (read_en) begin
        read_offset_reg <= byte_offset;
        read_funct3_reg <= funct3;
    end
end

always @(*) begin
    case (read_funct3_reg) 
        F3_LB: begin
            case (read_offset_reg)
                2'b00: read_data = {{24{raw_read_word[7]}},  raw_read_word[7:0]};
                2'b01: read_data = {{24{raw_read_word[15]}}, raw_read_word[15:8]};
                2'b10: read_data = {{24{raw_read_word[23]}}, raw_read_word[23:16]};
                2'b11: read_data = {{24{raw_read_word[31]}}, raw_read_word[31:24]};
            endcase
        end
        F3_LH: begin
            case (read_offset_reg[1])
                1'b0: read_data = {{16{raw_read_word[15]}}, raw_read_word[15:0]};
                1'b1: read_data = {{16{raw_read_word[31]}}, raw_read_word[31:16]};
            endcase
        end
        F3_LW: read_data = raw_read_word;
        F3_LBU: begin
            case (read_offset_reg)
                2'b00: read_data = {24'b0, raw_read_word[7:0]};
                2'b01: read_data = {24'b0, raw_read_word[15:8]};
                2'b10: read_data = {24'b0, raw_read_word[23:16]};
                2'b11: read_data = {24'b0, raw_read_word[31:24]};
            endcase
        end
        F3_LHU: begin
            case (read_offset_reg[1])
                1'b0: read_data = {16'b0, raw_read_word[15:0]};
                1'b1: read_data = {16'b0, raw_read_word[31:16]};
            endcase
        end
        default: read_data = 32'b0;
    endcase
end

endmodule
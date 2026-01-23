module mux41_32 (
    output reg [31:0] mux_out,
    input  [31:0] in0,
    input  [31:0] in1,
    input  [31:0] in2,
    input  [31:0] in3,
    input  [1:0]  select
);

always @(*) begin
    case (select)
        2'b00: mux_out = in0;
        2'b01: mux_out = in1;
        2'b10: mux_out = in2;
        2'b11: mux_out = in3;
        default: mux_out = 32'b0;
    endcase
end

endmodule
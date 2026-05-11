`timescale 1ns / 1ps

module alu(
    input  wire [3:0]  alu_op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] f,
    output wire        zf,
    output wire        cf,
    output wire        of,
    output wire        sf
);

    reg c;
    reg o;
    reg [32:0] add_result;

    always @(*) begin
        f = 32'h00000000;
        c = 1'b0;
        o = 1'b0;
        add_result = 33'h000000000;

        case (alu_op)
            4'b0000: begin
                add_result = {1'b0, a} + {1'b0, b};
                f = add_result[31:0];
                c = add_result[32];
                o = (~(a[31] ^ b[31])) & (f[31] ^ a[31]);
            end
            4'b0001: begin
                f = a - b;
                c = (a < b);
                o = (a[31] ^ b[31]) & (f[31] ^ a[31]);
            end
            4'b0010: f = a & b;
            4'b0011: f = a | b;
            4'b0100: f = a ^ b;
            4'b0101: f = a << 1;
            4'b0110: f = a >> 1;
            4'b0111: f = ~a;
            default: f = 32'h00000000;
        endcase
    end

    assign zf = (f == 32'h00000000);
    assign cf = c;
    assign of = o;
    assign sf = f[31];

endmodule

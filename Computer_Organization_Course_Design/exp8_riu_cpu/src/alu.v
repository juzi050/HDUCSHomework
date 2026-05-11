`timescale 1ns / 1ps

module alu(
    input  wire [3:0]  alu_op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] f,
    output wire        zf,
    output reg         cf,
    output reg         of,
    output wire        sf
);

    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_SLL   = 4'b0010;
    localparam ALU_SLT   = 4'b0011;
    localparam ALU_SLTU  = 4'b0100;
    localparam ALU_XOR   = 4'b0101;
    localparam ALU_SRL   = 4'b0110;
    localparam ALU_SRA   = 4'b0111;
    localparam ALU_OR    = 4'b1000;
    localparam ALU_AND   = 4'b1001;
    localparam ALU_PASSB = 4'b1010;

    reg [32:0] add_result;

    always @(*) begin
        f = 32'h0000_0000;
        cf = 1'b0;
        of = 1'b0;
        add_result = 33'h0;

        case (alu_op)
            ALU_ADD: begin
                add_result = {1'b0, a} + {1'b0, b};
                f = add_result[31:0];
                cf = add_result[32];
                of = (~(a[31] ^ b[31])) & (f[31] ^ a[31]);
            end

            ALU_SUB: begin
                f = a - b;
                cf = (a < b);
                of = (a[31] ^ b[31]) & (f[31] ^ a[31]);
            end

            ALU_SLL: begin
                f = a << b[4:0];
            end

            ALU_SLT: begin
                f = ($signed(a) < $signed(b)) ? 32'h0000_0001 : 32'h0000_0000;
            end

            ALU_SLTU: begin
                f = (a < b) ? 32'h0000_0001 : 32'h0000_0000;
            end

            ALU_XOR: begin
                f = a ^ b;
            end

            ALU_SRL: begin
                f = a >> b[4:0];
            end

            ALU_SRA: begin
                f = $signed(a) >>> b[4:0];
            end

            ALU_OR: begin
                f = a | b;
            end

            ALU_AND: begin
                f = a & b;
            end

            ALU_PASSB: begin
                f = b;
            end

            default: begin
                f = 32'h0000_0000;
            end
        endcase
    end

    assign zf = (f == 32'h0000_0000);
    assign sf = f[31];

endmodule

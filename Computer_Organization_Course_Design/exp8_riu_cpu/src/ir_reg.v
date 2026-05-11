`timescale 1ns / 1ps

module ir_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        IR_Write,
    input  wire [31:0] instruction_in,
    output reg  [31:0] IR
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IR <= 32'h0000_0000;
        end else if (IR_Write) begin
            IR <= instruction_in;
        end
    end

endmodule

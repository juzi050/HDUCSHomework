`timescale 1ns / 1ps

module abf_latch(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ab_write,
    input  wire        f_write,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] f_in,
    output reg  [31:0] a,
    output reg  [31:0] b,
    output reg  [31:0] f
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a <= 32'h0000_0000;
            b <= 32'h0000_0000;
            f <= 32'h0000_0000;
        end else begin
            if (ab_write) begin
                a <= a_in;
                b <= b_in;
            end

            if (f_write) begin
                f <= f_in;
            end
        end
    end

endmodule

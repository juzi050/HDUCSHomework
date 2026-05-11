`timescale 1ns / 1ps

module IM_B(
    input  wire        clka,
    input  wire [5:0]  addra,
    output reg  [31:0] douta
);

    reg [31:0] memory [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end

        memory[0] = 32'h1234_50b7;
        memory[1] = 32'h0001_0117;
        memory[2] = 32'hfff0_0193;
        memory[3] = 32'h0100_a203;
        memory[4] = 32'h0041_82b3;
        memory[5] = 32'h0050_aa23;
        memory[6] = 32'h0002_8463;
        memory[7] = 32'h0060_0313;
        memory[8] = 32'hff1f_f3ef;
        douta = 32'h1234_50b7;
    end

    always @(posedge clka) begin
        douta <= memory[addra];
    end

endmodule

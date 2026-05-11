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

        memory[0]  = 32'h8760_0093;
        memory[1]  = 32'h0040_0113;
        memory[2]  = 32'h0020_81b3;
        memory[3]  = 32'h4020_8233;
        memory[4]  = 32'h0020_92b3;
        memory[5]  = 32'h0020_d333;
        memory[6]  = 32'h4020_d3b3;
        memory[7]  = 32'h0020_a433;
        memory[8]  = 32'h0020_b4b3;
        memory[9]  = 32'h0062_f533;
        memory[10] = 32'h0062_e5b3;
        memory[11] = 32'h0062_c633;
        memory[12] = 32'h8000_06b7;
        memory[13] = 32'hfff6_8713;
        memory[14] = 32'h1237_0793;
        memory[15] = 32'h0037_9813;
        memory[16] = 32'h0037_d893;
        memory[17] = 32'h4037_d913;
        memory[18] = 32'hfff9_2993;
        memory[19] = 32'hfff9_3a13;
        memory[20] = 32'h0019_2a93;
        memory[21] = 32'h0019_3b13;
        memory[22] = 32'h0ff6_7b93;
        memory[23] = 32'h0ff6_6b93;
        memory[24] = 32'h0001_0c37;
        memory[25] = 32'hfffc_0c13;
        memory[26] = 32'hfffc_4c93;
        douta = 32'h8760_0093;
    end

    always @(posedge clka) begin
        douta <= memory[addra];
    end

endmodule

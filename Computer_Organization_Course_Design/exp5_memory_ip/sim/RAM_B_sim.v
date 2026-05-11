`timescale 1ns / 1ps

module RAM_B(
    input  wire        clka,
    input  wire        wea,
    input  wire [5:0]  addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta
);

    reg [31:0] memory [0:63];
    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end

        memory[0] = 32'h0000_0820;
        memory[1] = 32'h0063_2020;
        memory[2] = 32'h0001_0FFF;
        memory[3] = 32'h2000_6789;
        memory[4] = 32'hFFFF_0000;
        memory[5] = 32'h0000_FFFF;
        memory[6] = 32'h8888_8888;
        memory[7] = 32'h9999_9999;
        memory[8] = 32'hAAAA_AAAA;
        memory[9] = 32'hBBBB_BBBB;
        douta = 32'h0000_0000;
    end

    always @(posedge clka) begin
        if (wea) begin
            memory[addra] <= dina;
        end else begin
            douta <= memory[addra];
        end
    end

endmodule

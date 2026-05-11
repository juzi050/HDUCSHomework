`timescale 1ns / 1ps

module pc_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        PC_Write,
    output reg  [31:0] PC
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h0000_0000;
        end else if (PC_Write) begin
            PC <= PC + 32'd4;
        end
    end

endmodule

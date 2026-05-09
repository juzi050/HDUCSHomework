`timescale 1ns / 1ps

module Third_experiment_second (
    input  wire [2:0]  AB_SW,
    output reg  [31:0] A,
    output reg  [31:0] B
);
    always @(*) begin
        case (AB_SW)
            3'b000: begin
                A = 32'h0000000F;
                B = 32'h000000F0;
            end
            3'b001: begin
                A = 32'h12345678;
                B = 32'h87654321;
            end
            3'b010: begin
                A = 32'h00000001;
                B = 32'hFFFFFFFF;
            end
            3'b011: begin
                A = 32'h7FFFFFFF;
                B = 32'h00000001;
            end
            3'b100: begin
                A = 32'h80000000;
                B = 32'h00000001;
            end
            3'b101: begin
                A = 32'hFFFFFFFF;
                B = 32'h00000001;
            end
            3'b110: begin
                A = 32'h00000004;
                B = 32'h00000003;
            end
            3'b111: begin
                A = 32'h00000008;
                B = 32'h00000001;
            end
            default: begin
                A = 32'b0;
                B = 32'b0;
            end
        endcase
    end
endmodule

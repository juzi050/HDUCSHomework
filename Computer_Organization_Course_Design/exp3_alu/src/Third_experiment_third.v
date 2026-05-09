`timescale 1ns / 1ps

module Third_experiment_third (
    input  wire [31:0] F,
    input  wire        ZF,
    input  wire        OF,
    input  wire [2:0]  F_LED_SW,
    output reg  [7:0]  LED
);
    always @(*) begin
        case (F_LED_SW)
            3'b000: LED = F[7:0];
            3'b001: LED = F[15:8];
            3'b010: LED = F[23:16];
            3'b011: LED = F[31:24];
            3'b100: LED = {6'b0, OF, ZF};
            default: LED = 8'b0;
        endcase
    end
endmodule

`timescale 1ns / 1ps

module Third_experiment_third (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [31:0] F,
    input  wire        ZF,
    input  wire        OF,
    input  wire [1:0]  display_mode,
    output reg  [35:0] LD
);
    localparam MODE_A = 2'b00;
    localparam MODE_B = 2'b01;
    localparam MODE_F = 2'b10;

    always @(*) begin
        LD = 36'b0;

        case (display_mode)
            MODE_A: LD[31:0] = A;
            MODE_B: LD[31:0] = B;
            default: LD[31:0] = F;
        endcase

        LD[32] = ZF;
        LD[33] = OF;
        LD[35:34] = (display_mode == MODE_A || display_mode == MODE_B) ? display_mode : MODE_F;
    end
endmodule

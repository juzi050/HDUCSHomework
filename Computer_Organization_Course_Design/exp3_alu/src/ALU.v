`timescale 1ns / 1ps

module ALU (
    input  wire       CLK100MHZ,
    input  wire [8:0] SW,
    output wire [9:0] LD,
    output wire [7:0] AN,
    output wire [7:0] SEG
);
    wire [2:0]  ALU_OP;
    wire [2:0]  AB_SW;
    wire [2:0]  F_LED_SW;
    wire [31:0] A;
    wire [31:0] B;
    wire [31:0] F;
    wire        ZF;
    wire        OF;
    wire [7:0]  display_led;

    assign ALU_OP = SW[2:0];
    assign AB_SW = SW[5:3];
    assign F_LED_SW = SW[8:6];

    Third_experiment_second data_input (
        .AB_SW(AB_SW),
        .A(A),
        .B(B)
    );

    Third_experiment_first alu_core (
        .A(A),
        .B(B),
        .ALU_OP(ALU_OP),
        .F(F),
        .ZF(ZF),
        .OF(OF)
    );

    Third_experiment_third display_output (
        .F(F),
        .ZF(ZF),
        .OF(OF),
        .F_LED_SW(F_LED_SW),
        .LED(display_led)
    );

    Third_experiment_fourth seven_segment_display (
        .clk(CLK100MHZ),
        .F(F),
        .AN(AN),
        .SEG(SEG)
    );

    assign LD[7:0] = display_led;
    assign LD[8] = ZF;
    assign LD[9] = OF;
endmodule

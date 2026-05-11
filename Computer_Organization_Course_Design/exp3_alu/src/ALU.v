`timescale 1ns / 1ps

module ALU (
    input  wire       CLK100MHZ,
    input  wire [35:0] SW,
    input  wire [3:0]  BT,
    output wire [35:0] LD,
    output wire [7:0] AN,
    output wire [7:0] SEG
);
    wire [2:0]  ALU_OP;
    wire [31:0] A;
    wire [31:0] B;
    wire [31:0] F;
    wire        ZF;
    wire        OF;
    wire [1:0]  display_mode;

    assign ALU_OP = SW[34:32];

    Third_experiment_second data_input (
        .clk(CLK100MHZ),
        .data_in(SW[31:0]),
        .BT(BT),
        .A(A),
        .B(B),
        .display_mode(display_mode)
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
        .A(A),
        .B(B),
        .F(F),
        .ZF(ZF),
        .OF(OF),
        .display_mode(display_mode),
        .LD(LD)
    );

    Third_experiment_fourth seven_segment_display (
        .clk(CLK100MHZ),
        .F(F),
        .AN(AN),
        .SEG(SEG)
    );
endmodule

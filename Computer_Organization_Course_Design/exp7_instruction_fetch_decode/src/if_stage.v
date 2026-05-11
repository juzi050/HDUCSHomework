`timescale 1ns / 1ps

module if_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        PC_Write,
    input  wire        IR_Write,
    output wire [31:0] PC,
    output wire [31:0] IR,
    output wire [31:0] im_instruction
);

    pc_reg u_pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .PC_Write(PC_Write),
        .PC(PC)
    );

    instruction_memory u_instruction_memory (
        .clk(clk),
        .addr(PC[7:2]),
        .instruction(im_instruction)
    );

    ir_reg u_ir_reg (
        .clk(clk),
        .rst_n(rst_n),
        .IR_Write(IR_Write),
        .instruction_in(im_instruction),
        .IR(IR)
    );

endmodule

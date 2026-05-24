`timescale 1ns / 1ps

//==============================================================================
// if_stage - 取指阶段模块 (Instruction Fetch Stage)
//==============================================================================
// 功能描述:
//   - 集成 PC寄存器、指令存储器和指令寄存器，完成取指操作。
//   - 数据流: PC -> IM(指令存储器) -> IR(指令寄存器)。
//   - PC_Write 控制PC递增。
//   - IR_Write 控制指令锁存。
//   - im_instruction: 直接从IM读出的指令 (用于预取显示)。
//
// 子模块:
//   - pc_reg:             程序计数器
//   - instruction_memory: 指令存储器 (BRAM IP)
//   - ir_reg:             指令寄存器
//==============================================================================

module if_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        PC_Write,
    input  wire        IR_Write,
    output wire [31:0] PC,             // 当前PC值
    output wire [31:0] IR,             // 当前指令 (IR输出)
    output wire [31:0] im_instruction  // IM直接输出的指令 (用于预取显示)
);

    // 程序计数器
    pc_reg u_pc_reg (
        .clk(clk),
        .rst_n(rst_n),
        .PC_Write(PC_Write),
        .PC(PC)
    );

    // 指令存储器: 使用PC[7:2]作为字地址 (忽略低2位, 按4字节对齐)
    instruction_memory u_instruction_memory (
        .clk(clk),
        .addr(PC[7:2]),
        .instruction(im_instruction)
    );

    // 指令寄存器: 锁存当前指令
    ir_reg u_ir_reg (
        .clk(clk),
        .rst_n(rst_n),
        .IR_Write(IR_Write),
        .instruction_in(im_instruction),
        .IR(IR)
    );

endmodule

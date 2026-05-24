`timescale 1ns / 1ps

//==============================================================================
// ir_reg - 指令寄存器 (Instruction Register)
//==============================================================================
// 功能描述:
//   - 32位指令寄存器，存储从指令存储器取出的当前指令。
//   - IR_Write=1 时在时钟上升沿锁存新指令。
//   - rst_n=0 时异步复位为 0x00000000 (NOP)。
//==============================================================================

module ir_reg(
    input  wire        clk,
    input  wire        rst_n,           // 异步复位 (低有效)
    input  wire        IR_Write,        // IR写使能 (1=锁存新指令)
    input  wire [31:0] instruction_in,  // 来自指令存储器的指令
    output reg  [31:0] IR               // 当前指令输出
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            IR <= 32'h0000_0000;        // 复位: IR置NOP
        end else if (IR_Write) begin
            IR <= instruction_in;       // 锁存新指令
        end
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// abf_latch - ALU操作数/结果锁存器 (A/B/F Latch)
//==============================================================================
// 功能描述:
//   - 锁存ALU的操作数A、B和运算结果F，用于流水线各级间数据传递。
//   - ab_write=1: 在时钟上升沿锁存新的A和B值。
//   - f_write=1:  在时钟上升沿锁存新的F值 (ALU结果)。
//   - rst_n=0: 异步复位全部清零。
//==============================================================================

module abf_latch(
    input  wire        clk,
    input  wire        rst_n,      // 异步复位 (低有效)
    input  wire        ab_write,   // A/B写使能
    input  wire        f_write,    // F(结果)写使能
    input  wire [31:0] a_in,       // 操作数A输入
    input  wire [31:0] b_in,       // 操作数B输入
    input  wire [31:0] f_in,       // ALU结果输入
    output reg  [31:0] a,          // 锁存的A
    output reg  [31:0] b,          // 锁存的B
    output reg  [31:0] f           // 锁存的F (写回数据)
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a <= 32'h0000_0000;
            b <= 32'h0000_0000;
            f <= 32'h0000_0000;
        end else begin
            // S2阶段: 锁存操作数A和B
            if (ab_write) begin
                a <= a_in;
                b <= b_in;
            end

            // S3/S5/S6阶段: 锁存ALU运算结果
            if (f_write) begin
                f <= f_in;
            end
        end
    end

endmodule

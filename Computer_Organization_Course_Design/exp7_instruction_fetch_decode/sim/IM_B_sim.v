`timescale 1ns / 1ps

//==============================================================================
// IM_B - 指令存储器行为级仿真模型 (Instruction Memory Behavioral Model)
//==============================================================================
// 功能描述:
//   - 64x32位指令存储器的纯Verilog行为模型，用于仿真替代BRAM IP核。
//   - 初始化预设9条RISC-V指令 (地址0-8)。
//   - 上升沿读出。
//
// 预设指令 (addr: instruction):
//   0: 32'h1234_50b7  (lui  x1, 0x12345)
//   1: 32'h0001_0117  (auipc x2, 0x10)
//   2: 32'hfff0_0193  (addi x3, x0, -1)
//   3: 32'h0100_a203  (lw   x4, 16(x1))
//   4: 32'h0041_82b3  (add  x5, x3, x4)
//   5: 32'h0050_aa23  (sw   x5, 20(x1))
//   6: 32'h0002_8463  (beq  x5, x0, +8)
//   7: 32'h0060_0313  (addi x6, x0, 6)
//   8: 32'hff1f_f3ef  (jal  x7, -16)
//==============================================================================

module IM_B(
    input  wire        clka,
    input  wire [5:0]  addra,
    output reg  [31:0] douta
);

    reg [31:0] memory [0:63];  // 64x32位指令存储器
    integer i;

    initial begin
        // 全部清零
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end

        // 预设RISC-V测试指令
        memory[0] = 32'h1234_50b7;  // lui  x1, 0x12345
        memory[1] = 32'h0001_0117;  // auipc x2, 0x10
        memory[2] = 32'hfff0_0193;  // addi x3, x0, -1
        memory[3] = 32'h0100_a203;  // lw   x4, 16(x1)
        memory[4] = 32'h0041_82b3;  // add  x5, x3, x4
        memory[5] = 32'h0050_aa23;  // sw   x5, 20(x1)
        memory[6] = 32'h0002_8463;  // beq  x5, x0, +8
        memory[7] = 32'h0060_0313;  // addi x6, x0, 6
        memory[8] = 32'hff1f_f3ef;  // jal  x7, -16
        douta = 32'h1234_50b7;
    end

    // 时钟上升沿读出
    always @(posedge clka) begin
        douta <= memory[addra];
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// ALU - 顶层模块 (Top-Level Module for Experiment 3: ALU)
//==============================================================================
// 功能描述:
//   - 接收开发板上的开关(SW)和按钮(BT)输入，控制32位ALU运算。
//   - 通过SW[34:32]选择ALU操作码(ALU_OP)。
//   - 通过SW[31:0]输入32位数据。
//   - 运算结果通过LD(LED)和七段数码管(AN/SEG)显示。
//
// 子模块:
//   - Third_experiment_second: 数据输入与按钮消抖/控制逻辑
//   - Third_experiment_first:  ALU运算核心
//   - Third_experiment_third:  LED显示输出选择
//   - Third_experiment_fourth: 七段数码管动态扫描显示
//
// 端口:
//   - CLK100MHZ: 100MHz系统时钟
//   - SW[35:0]:  拨码开关输入 (SW[34:32]=ALU_OP, SW[31:0]=data)
//   - BT[3:0]:   按钮输入 (BT[0]=load A, BT[1]=load B, BT[2]=clear, BT[3]=切换显示)
//   - LD[35:0]:   LED输出 (LD[31:0]=结果, LD[32]=ZF, LD[33]=OF, LD[35:34]=显示模式)
//   - AN[7:0]:   数码管位选 (低有效)
//   - SEG[7:0]:  数码管段选 (低有效)
//==============================================================================

module ALU (
    input  wire       CLK100MHZ,
    input  wire [35:0] SW,
    input  wire [3:0]  BT,
    output wire [35:0] LD,
    output wire [7:0] AN,
    output wire [7:0] SEG
);
    // 内部连线
    wire [2:0]  ALU_OP;       // ALU操作码
    wire [31:0] A;            // 操作数A
    wire [31:0] B;            // 操作数B
    wire [31:0] F;            // ALU运算结果
    wire        ZF;           // 零标志 (Zero Flag)
    wire        OF;           // 溢出标志 (Overflow Flag)
    wire [1:0]  display_mode; // 显示模式: 00=A, 01=B, 10=F

    // SW[34:32] 选择 ALU 操作码
    assign ALU_OP = SW[34:32];

    // 数据输入模块: 处理按钮消抖, 捕获A/B输入, 管理显示模式
    Third_experiment_second data_input (
        .clk(CLK100MHZ),
        .data_in(SW[31:0]),
        .BT(BT),
        .A(A),
        .B(B),
        .display_mode(display_mode)
    );

    // ALU 运算核心模块
    Third_experiment_first alu_core (
        .A(A),
        .B(B),
        .ALU_OP(ALU_OP),
        .F(F),
        .ZF(ZF),
        .OF(OF)
    );

    // LED 显示输出模块: 根据 display_mode 选择显示 A/B/F
    Third_experiment_third display_output (
        .A(A),
        .B(B),
        .F(F),
        .ZF(ZF),
        .OF(OF),
        .display_mode(display_mode),
        .LD(LD)
    );

    // 七段数码管动态扫描显示模块: 将32位F值以16进制显示在8个数码管上
    Third_experiment_fourth seven_segment_display (
        .clk(CLK100MHZ),
        .F(F),
        .AN(AN),
        .SEG(SEG)
    );
endmodule

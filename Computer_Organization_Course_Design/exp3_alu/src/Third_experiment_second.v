`timescale 1ns / 1ps

//==============================================================================
// Third_experiment_second - 数据输入与控制模块 (Data Input & Button Control)
//==============================================================================
// 功能描述:
//   - 处理按钮的上升沿检测(消抖)。
//   - BT[0]: 将SW[31:0]数据加载到操作数A。
//   - BT[1]: 将SW[31:0]数据加载到操作数B。
//   - BT[2]: 复位A/B为0，显示模式恢复为显示结果F。
//   - BT[3]: 循环切换显示模式: F -> A -> B -> F。
//   - 显示模式: MODE_A(00)=显示A, MODE_B(01)=显示B, MODE_F(10)=显示F。
//==============================================================================

module Third_experiment_second (
    input  wire        clk,
    input  wire [31:0] data_in,
    input  wire [3:0]  BT,
    output reg  [31:0] A,
    output reg  [31:0] B,
    output reg  [1:0]  display_mode
);
    // 显示模式定义
    localparam MODE_A = 2'b00;
    localparam MODE_B = 2'b01;
    localparam MODE_F = 2'b10;

    // 按钮同步与边沿检测寄存器
    reg [3:0] bt_sync0;    // 一级同步
    reg [3:0] bt_sync1;    // 二级同步
    reg [3:0] bt_last;     // 上一周期的同步值
    wire [3:0] bt_rise;    // 按钮上升沿脉冲 (1表示检测到上升沿)

    // 上升沿检测: 当前为1且上一周期为0
    assign bt_rise = bt_sync1 & ~bt_last;

    initial begin
        A = 32'b0;
        B = 32'b0;
        display_mode = MODE_F;  // 默认显示运算结果F
        bt_sync0 = 4'b0;
        bt_sync1 = 4'b0;
        bt_last = 4'b0;
    end

    always @(posedge clk) begin
        // 两级同步寄存器消除亚稳态
        bt_sync0 <= BT;
        bt_sync1 <= bt_sync0;
        bt_last <= bt_sync1;

        if (bt_rise[2]) begin
            // BT[2]: 复位按钮，清除A/B并恢复显示结果F
            A <= 32'b0;
            B <= 32'b0;
            display_mode <= MODE_F;
        end else begin
            // BT[0]: 加载操作数A
            if (bt_rise[0]) begin
                A <= data_in;
            end

            // BT[1]: 加载操作数B
            if (bt_rise[1]) begin
                B <= data_in;
            end

            // BT[3]: 循环切换显示模式 F->A->B->F
            if (bt_rise[3]) begin
                case (display_mode)
                    MODE_F: display_mode <= MODE_A;
                    MODE_A: display_mode <= MODE_B;
                    default: display_mode <= MODE_F;
                endcase
            end
        end
    end
endmodule

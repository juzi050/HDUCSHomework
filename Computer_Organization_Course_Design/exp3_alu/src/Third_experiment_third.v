`timescale 1ns / 1ps

//==============================================================================
// Third_experiment_third - LED 显示输出模块 (LED Display Output)
//==============================================================================
// 功能描述:
//   - 根据 display_mode 选择 LED 显示内容。
//   - LD[31:0]:  显示 A, B 或 F (由 display_mode 决定)
//   - LD[32]:    零标志 ZF
//   - LD[33]:    溢出标志 OF
//   - LD[35:34]: 显示模式指示 (00=A, 01=B, 10/11=F)
//==============================================================================

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

        // 根据显示模式选择输出32位数据
        case (display_mode)
            MODE_A: LD[31:0] = A;
            MODE_B: LD[31:0] = B;
            default: LD[31:0] = F;  // MODE_F 或其他情况显示结果
        endcase

        // 标志位输出
        LD[32] = ZF;       // 零标志
        LD[33] = OF;       // 溢出标志
        LD[35:34] = (display_mode == MODE_A || display_mode == MODE_B) ? display_mode : MODE_F;
    end
endmodule

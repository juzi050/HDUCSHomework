`timescale 1ns / 1ps

//==============================================================================
// seven_seg_display - 32位数码管动态扫描显示 (32-bit 7-Segment Dynamic Scan Display)
//==============================================================================
// 功能描述:
//   - 将32位value以8位16进制数显示在8个共阳极数码管上。
//   - 动态扫描: 每个数码管依次点亮，利用人眼视觉暂留。
//   - 扫描频率 = 100MHz / 2^17 ≈ 763Hz，每位刷新率 ≈ 95Hz。
//   - an[7:0]: 位选信号 (低有效)
//   - seg[6:0]: 段选信号 (低有效)
//   - dp: 小数点 (常灭)
//==============================================================================

module seven_seg_display(
    input  wire        clk,
    input  wire [31:0] value,
    output reg  [7:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);

    reg [16:0] scan_div = 17'd0;    // 扫描分频计数器
    reg [3:0]  current_hex;         // 当前显示的4位16进制值
    wire [2:0] scan_digit;          // 当前位选择 (0-7)

    // 取计数器高3位作为位选择信号，实现8位轮流扫描
    assign scan_digit = scan_div[16:14];
    assign dp = 1'b1;               // 小数点不亮 (共阳极, 1=灭)

    // 扫描计数器自增
    always @(posedge clk) begin
        scan_div <= scan_div + 17'd1;
    end

    // 根据 scan_digit 选择当前显示的数码管位和对应的4位16进制值
    always @(*) begin
        an = 8'b1111_1111;           // 默认全部熄灭
        current_hex = 4'h0;

        case (scan_digit)
            3'd0: begin an = 8'b1111_1110; current_hex = value[3:0];   end  // 最低半字节
            3'd1: begin an = 8'b1111_1101; current_hex = value[7:4];   end
            3'd2: begin an = 8'b1111_1011; current_hex = value[11:8];  end
            3'd3: begin an = 8'b1111_0111; current_hex = value[15:12]; end
            3'd4: begin an = 8'b1110_1111; current_hex = value[19:16]; end
            3'd5: begin an = 8'b1101_1111; current_hex = value[23:20]; end
            3'd6: begin an = 8'b1011_1111; current_hex = value[27:24]; end
            3'd7: begin an = 8'b0111_1111; current_hex = value[31:28]; end  // 最高半字节
            default: begin an = 8'b1111_1111; current_hex = 4'h0; end
        endcase
    end

    // 16进制值到七段码的译码器
    seven_seg_hex u_seven_seg_hex (
        .hex(current_hex),
        .seg(seg)
    );

endmodule

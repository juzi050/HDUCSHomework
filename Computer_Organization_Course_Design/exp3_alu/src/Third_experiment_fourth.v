`timescale 1ns / 1ps

//==============================================================================
// Third_experiment_fourth - 七段数码管动态扫描显示 (7-Segment Dynamic Scan Display)
//==============================================================================
// 功能描述:
//   - 将32位数据F以16进制形式显示在8个共阳极数码管上。
//   - 使用动态扫描技术，每个数码管依次点亮，利用人眼视觉暂留实现稳定显示。
//   - 扫描频率 = 100MHz / 2^17 ≈ 763Hz, 每位数码管刷新率 ≈ 95Hz。
//   - AN[7:0]: 位选信号 (低有效，每次仅使能一位)
//   - SEG[7:0]: 段选信号 (低有效，共阳极数码管段码)
//==============================================================================

module Third_experiment_fourth (
    input  wire        clk,
    input  wire [31:0] F,
    output reg  [7:0]  AN,
    output reg  [7:0]  SEG
);
    reg [16:0] refresh_count;  // 17位刷新计数器
    reg [3:0]  hex_digit;      // 当前显示的4位16进制值
    wire [2:0] digit_select;   // 位选择 (取计数器高3位)

    // 取计数器高3位作为位选择信号，实现8位数码管的轮流扫描
    assign digit_select = refresh_count[16:14];

    initial begin
        refresh_count = 17'b0;
    end

    // 刷新计数器自增
    always @(posedge clk) begin
        refresh_count <= refresh_count + 1'b1;
    end

    // 根据 digit_select 选择当前显示的数码管位和对应的16进制值
    always @(*) begin
        case (digit_select)
            3'b000: begin AN = 8'b11111110; hex_digit = F[3:0];   end  // 最低位
            3'b001: begin AN = 8'b11111101; hex_digit = F[7:4];   end
            3'b010: begin AN = 8'b11111011; hex_digit = F[11:8];  end
            3'b011: begin AN = 8'b11110111; hex_digit = F[15:12]; end
            3'b100: begin AN = 8'b11101111; hex_digit = F[19:16]; end
            3'b101: begin AN = 8'b11011111; hex_digit = F[23:20]; end
            3'b110: begin AN = 8'b10111111; hex_digit = F[27:24]; end
            3'b111: begin AN = 8'b01111111; hex_digit = F[31:28]; end  // 最高位
            default: begin AN = 8'b11111111; hex_digit = 4'h0; end      // 全部熄灭
        endcase
    end

    // 16进制值到共阳极七段数码管段码的转换
    // 段码映射: SEG[7]=DP(小数点), SEG[6:0]={G,F,E,D,C,B,A}
    always @(*) begin
        case (hex_digit)
            4'h0: SEG = 8'hC0;  // 显示 "0"
            4'h1: SEG = 8'hF9;  // 显示 "1"
            4'h2: SEG = 8'hA4;  // 显示 "2"
            4'h3: SEG = 8'hB0;  // 显示 "3"
            4'h4: SEG = 8'h99;  // 显示 "4"
            4'h5: SEG = 8'h92;  // 显示 "5"
            4'h6: SEG = 8'h82;  // 显示 "6"
            4'h7: SEG = 8'hF8;  // 显示 "7"
            4'h8: SEG = 8'h80;  // 显示 "8"
            4'h9: SEG = 8'h90;  // 显示 "9"
            4'hA: SEG = 8'h88;  // 显示 "A"
            4'hB: SEG = 8'h83;  // 显示 "B"
            4'hC: SEG = 8'hC6;  // 显示 "C"
            4'hD: SEG = 8'hA1;  // 显示 "D"
            4'hE: SEG = 8'h86;  // 显示 "E"
            4'hF: SEG = 8'h8E;  // 显示 "F"
            default: SEG = 8'hFF;  // 全部熄灭
        endcase
    end
endmodule

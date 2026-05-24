`timescale 1ns / 1ps

//==============================================================================
// top - 实验5顶层模块: 内存IP实验 (Experiment 5 Top: Memory IP Experiment)
//==============================================================================
// 功能描述:
//   - 通过开关和按钮控制BRAM内存的读写操作。
//   - SW[7:2]:  内存地址 (Mem_Addr)
//   - SW[1:0]:  字节选择 (MUX)
//   - BT[0]:    写使能 (上升沿触发写入)
//   - LD[7:0]:  选中的字节显示
//   - LD[13:8]: 当前地址显示
//   - LD[15:14]: 当前MUX值显示
//   - 七段数码管显示32位读出数据。
//==============================================================================

module top(
    input  wire        clk100mhz,
    input  wire [35:0] sw,
    input  wire [7:0]  bt,
    output wire [35:0] ld,
    output wire        traffic_we_r,
    output wire        traffic_we_y,
    output wire        traffic_we_g,
    output wire        traffic_sn_r,
    output wire        traffic_sn_y,
    output wire        traffic_sn_g,
    output wire [7:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);

    reg bt0_d = 1'b0;            // BT[0]前一周期值 (边沿检测)
    reg [7:0] selected_byte;     // 当前选中的字节

    wire [31:0] read_word;       // 从内存读出的32位数据
    wire write_pulse;            // BT[0]上升沿脉冲

    // BT[0] 上升沿检测 (用于触发单次写操作)
    assign write_pulse = bt[0] & ~bt0_d;

    always @(posedge clk100mhz) begin
        bt0_d <= bt[0];
    end

    // 内存IP核实例
    memory_ip_core u_memory_ip_core (
        .Mem_Addr(sw[7:2]),
        .MUX(sw[1:0]),
        .Mem_Write(write_pulse),
        .Clk(clk100mhz),
        .M_R_Data(read_word)
    );

    // 根据 MUX 从32位读数据中选择对应字节
    always @(*) begin
        case (sw[1:0])
            2'b00: selected_byte = read_word[7:0];
            2'b01: selected_byte = read_word[15:8];
            2'b10: selected_byte = read_word[23:16];
            2'b11: selected_byte = read_word[31:24];
            default: selected_byte = 8'h00;
        endcase
    end

    // LED 输出: {高20位=0, MUX, 地址, 选中字节}
    assign ld = {20'd0, sw[1:0], sw[7:2], selected_byte};

    // 交通灯输出 (未使用)
    assign traffic_we_r = 1'b0;
    assign traffic_we_y = 1'b0;
    assign traffic_we_g = 1'b0;
    assign traffic_sn_r = 1'b0;
    assign traffic_sn_y = 1'b0;
    assign traffic_sn_g = 1'b0;

    // 七段数码管显示完整32位读出数据
    seven_seg_display u_display (
        .clk(clk100mhz),
        .value(read_word),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

endmodule

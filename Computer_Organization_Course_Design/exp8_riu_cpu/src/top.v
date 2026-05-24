`timescale 1ns / 1ps

//==============================================================================
// top - 实验8顶层模块: RIU多周期CPU (Experiment 8 Top: RIU Multi-cycle CPU)
//==============================================================================
// 功能描述:
//   - 完整的RISC-V RV32I子集多周期CPU系统。
//   - 按钮控制:
//     BT[0]: 单步执行 (上升沿触发)
//     BT[1]: 复位 (低有效)
//   - SW[2:0]: 七段数码管显示选择:
//       000: PC (程序计数器)
//       001: IR (指令寄存器)
//       010: w_data (写回数据)
//       011: st   (CPU状态)
//       100: 标志位 {zf, cf, of, sf}
//       default: w_data
//   - LD[27:0]:  w_data[27:0] (写回数据低28位)
//   - LD[31:28]: 标志位 {zf, cf, of, sf}
//   - LD[34:32]: CPU状态 st[2:0]
//   - LD[35]:    step_en (单步指示)
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

    reg bt0_d = 1'b0;                // BT[0]前一周期 (边沿检测)
    reg [31:0] display_value;        // 七段数码管显示值

    wire rst_n;                      // 复位信号 (低有效)
    wire step_en;                    // 单步使能脉冲
    wire [31:0] pc;                  // 程序计数器
    wire [31:0] ir;                  // 指令寄存器
    wire [31:0] w_data;              // 写回数据
    wire [2:0] st;                   // CPU状态
    wire zf;                         // 零标志
    wire cf;                         // 进位标志
    wire of;                         // 溢出标志
    wire sf;                         // 符号标志

    // BT[1] 为复位 (低有效)
    assign rst_n = ~bt[1];
    // BT[0] 上升沿检测: 单步脉冲
    assign step_en = bt[0] & ~bt0_d;

    // BT[0] 同步寄存器 (用于边沿检测)
    always @(posedge clk100mhz or negedge rst_n) begin
        if (!rst_n) begin
            bt0_d <= 1'b0;
        end else begin
            bt0_d <= bt[0];
        end
    end

    // RIU 多周期CPU核心
    riu_cpu u_riu_cpu (
        .clk(clk100mhz),
        .rst_n(rst_n),
        .step_en(step_en),
        .pc(pc),
        .ir(ir),
        .w_data(w_data),
        .st(st),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    // 根据 SW[2:0] 选择七段数码管显示内容
    always @(*) begin
        case (sw[2:0])
            3'b000: display_value = pc;                          // 程序计数器
            3'b001: display_value = ir;                          // 指令寄存器
            3'b010: display_value = w_data;                      // 写回数据
            3'b011: display_value = {29'd0, st};                 // CPU状态
            3'b100: display_value = {28'd0, zf, cf, of, sf};    // 标志位
            default: display_value = w_data;
        endcase
    end

    // LED 输出分配
    assign ld[27:0] = w_data[27:0];          // 写回数据低28位
    assign ld[31:28] = {zf, cf, of, sf};     // 标志位
    assign ld[34:32] = st;                   // CPU状态
    assign ld[35] = step_en;                 // 单步指示

    // 交通灯输出 (未使用)
    assign traffic_we_r = 1'b0;
    assign traffic_we_y = 1'b0;
    assign traffic_we_g = 1'b0;
    assign traffic_sn_r = 1'b0;
    assign traffic_sn_y = 1'b0;
    assign traffic_sn_g = 1'b0;

    // 七段数码管显示
    seven_seg_display u_display (
        .clk(clk100mhz),
        .value(display_value),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

endmodule

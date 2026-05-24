`timescale 1ns / 1ps

//==============================================================================
// top - 实验4顶层模块: ALU + 寄存器堆 (Experiment 4 Top: ALU + Register File)
//==============================================================================
// 功能描述:
//   - 集成ALU和寄存器堆，支持寄存器读写和ALU运算。
//   - 按钮控制:
//     BT[0]: 选择读地址A (raddr_a = SW[4:0])
//     BT[1]: 选择读地址B (raddr_b = SW[4:0])
//     BT[2]: 选择写地址 (waddr = SW[4:0])
//     BT[3]: 将SW[31:0]外部数据写入寄存器 (write_from_alu=0)
//     BT[4]: 将ALU运算结果写入寄存器 (write_from_alu=1)
//     BT[5]: 循环切换显示: 结果 -> 读数据A -> 读数据B -> 结果
//     BT[7]: 复位
//   - SW[35:32]: ALU操作码
//   - SW[31:0]:  外部写数据
//   - LD[31:0]:  显示当前选中的32位值
//   - LD[35:32]: 标志位 {sf, of, cf, zf}
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

    // 显示模式定义
    localparam DISPLAY_RESULT = 2'd0;  // 显示ALU结果
    localparam DISPLAY_A      = 2'd1;  // 显示读数据A
    localparam DISPLAY_B      = 2'd2;  // 显示读数据B

    reg [7:0] bt_d;             // 按钮上一周期值 (用于边沿检测)
    reg [4:0] raddr_a;          // 读地址A
    reg [4:0] raddr_b;          // 读地址B
    reg [4:0] waddr;            // 写地址
    reg [1:0] display_mode;     // 当前显示模式
    reg       wen_pulse;        // 写使能脉冲
    reg       write_from_alu;   // 写来源选择: 1=ALU结果, 0=外部数据

    wire reset;
    wire [7:0] bt_rise;          // 按钮上升沿
    wire [31:0] rdata_a;         // 寄存器堆读数据A
    wire [31:0] rdata_b;         // 寄存器堆读数据B
    wire [31:0] result;          // ALU运算结果
    wire [31:0] display_value;   // 当前显示的值
    wire zf;                     // 零标志
    wire cf;                     // 进位/借位标志
    wire of;                     // 溢出标志
    wire sf;                     // 符号标志

    // BT[7] 为复位信号
    assign reset = bt[7];
    // 按钮上升沿检测: 当前为1且上一周期为0
    assign bt_rise = bt & ~bt_d;

    // 按钮控制逻辑 (边沿触发)
    always @(posedge clk100mhz or posedge reset) begin
        if (reset) begin
            bt_d <= 8'h00;
            raddr_a <= 5'd0;
            raddr_b <= 5'd0;
            waddr <= 5'd0;
            display_mode <= DISPLAY_RESULT;
            wen_pulse <= 1'b0;
            write_from_alu <= 1'b0;
        end else begin
            bt_d <= bt;                           // 更新按钮历史值
            wen_pulse <= 1'b0;                    // 写脉冲仅维持1周期
            write_from_alu <= 1'b0;

            if (bt_rise[0]) begin
                raddr_a <= sw[4:0];               // 设置读地址A
            end

            if (bt_rise[1]) begin
                raddr_b <= sw[4:0];               // 设置读地址B
            end

            if (bt_rise[2]) begin
                waddr <= sw[4:0];                 // 设置写地址
            end

            if (bt_rise[3]) begin
                wen_pulse <= 1'b1;                // 写入外部数据
                write_from_alu <= 1'b0;
            end else if (bt_rise[4]) begin
                wen_pulse <= 1'b1;                // 写入ALU结果
                write_from_alu <= 1'b1;
            end

            if (bt_rise[5]) begin
                // 循环切换显示模式: RESULT->A->B->RESULT
                display_mode <= (display_mode == DISPLAY_B) ? DISPLAY_RESULT : display_mode + 2'd1;
            end
        end
    end

    // ALU + 寄存器堆 组合模块
    alu_reg u_alu_reg (
        .clk(clk100mhz),
        .rst(reset),
        .wen(wen_pulse),
        .write_from_alu(write_from_alu),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata_ext(sw[31:0]),
        .alu_op(sw[35:32]),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b),
        .result(result),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    // 根据显示模式选择七段数码管显示的32位值
    assign display_value = (display_mode == DISPLAY_A) ? rdata_a :
                           (display_mode == DISPLAY_B) ? rdata_b :
                           result;

    // LED 输出分配
    assign ld[31:0] = display_value;  // 32位数据显示
    assign ld[32] = zf;               // 零标志
    assign ld[33] = cf;               // 进位/借位标志
    assign ld[34] = of;               // 溢出标志
    assign ld[35] = sf;               // 符号标志

    // 交通灯输出 (未使用, 全部置0)
    assign traffic_we_r = 1'b0;
    assign traffic_we_y = 1'b0;
    assign traffic_we_g = 1'b0;
    assign traffic_sn_r = 1'b0;
    assign traffic_sn_y = 1'b0;
    assign traffic_sn_g = 1'b0;

    // 七段数码管显示模块
    seven_seg_display u_display (
        .clk(clk100mhz),
        .value(display_value),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

endmodule

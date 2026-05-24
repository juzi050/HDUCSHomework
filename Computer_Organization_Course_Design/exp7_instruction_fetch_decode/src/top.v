`timescale 1ns / 1ps

//==============================================================================
// top - 实验7顶层模块: 指令取指与译码 (Experiment 7 Top: Instruction Fetch & Decode)
//==============================================================================
// 功能描述:
//   - 实现RISC-V单步取指和译码功能。
//   - 按钮控制:
//     BT[0]: 单步执行 (上升沿触发)
//     BT[1]: 复位 (低有效)
//   - SW[0]:  PC_Write使能
//   - SW[1]:  IR_Write使能
//   - SW[3:2]: 七段数码管显示选择:
//       00: 立即数 (imm32)
//       01: 指令寄存器 (IR)
//       10: 程序计数器 (PC)
//       11: 预取指令 (im_instruction)
//   - LD[35:0]: LED显示译码后的指令字段。
//   - 七段数码管显示当前选中的32位值。
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
    wire step_pulse;                 // 单步脉冲
    wire pc_write_pulse;             // PC写使能脉冲
    wire ir_write_pulse;             // IR写使能脉冲
    wire [31:0] pc;                  // 程序计数器
    wire [31:0] ir;                  // 指令寄存器
    wire [31:0] im_instruction;      // IM直接输出
    wire [31:0] imm32;               // 立即数
    wire [6:0] opcode;               // 操作码
    wire [4:0] rd;                   // 目标寄存器
    wire [2:0] funct3;               // 功能码3
    wire [4:0] rs1;                  // 源寄存器1
    wire [4:0] rs2;                  // 源寄存器2
    wire [6:0] funct7;               // 功能码7

    // BT[1] 为复位 (低有效)
    assign rst_n = ~bt[1];
    // BT[0] 上升沿检测: 单步脉冲
    assign step_pulse = bt[0] & ~bt0_d;
    // SW[0]: PC写使能, SW[1]: IR写使能
    assign pc_write_pulse = step_pulse & sw[0];
    assign ir_write_pulse = step_pulse & sw[1];

    // BT[0] 同步寄存器 (下降沿检测用)
    always @(posedge clk100mhz) begin
        if (!rst_n) begin
            bt0_d <= 1'b0;
        end else begin
            bt0_d <= bt[0];
        end
    end

    // 取指阶段模块
    if_stage u_if_stage (
        .clk(clk100mhz),
        .rst_n(rst_n),
        .PC_Write(pc_write_pulse),
        .IR_Write(ir_write_pulse),
        .PC(pc),
        .IR(ir),
        .im_instruction(im_instruction)
    );

    // 指令译码第一阶段
    id1 u_id1 (
        .instr(ir),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm32(imm32)
    );

    // 根据 SW[3:2] 选择七段数码管显示内容
    always @(*) begin
        case (sw[3:2])
            2'b00: display_value = imm32;           // 立即数
            2'b01: display_value = ir;              // 指令寄存器
            2'b10: display_value = pc;              // 程序计数器
            2'b11: display_value = im_instruction;  // 预取指令
            default: display_value = imm32;
        endcase
    end

    // LED 输出指令字段: {funct7, funct3, opcode, rd, rs2, rs1}
    assign ld = {4'd0, funct7, funct3, opcode, rd, rs2, rs1};

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

`timescale 1ns / 1ps

//==============================================================================
// cu - 控制单元 (Control Unit - Multi-cycle State Machine)
//==============================================================================
// 功能描述:
//   - 多周期状态机，控制CPU指令执行的各个阶段。
//   - 状态定义:
//     S1: 取指阶段 (IF)   - PC+4, 锁存IR
//     S2: 译码/读寄存器   - 锁存操作数A/B, 判断指令类型
//     S3: R-type执行      - ALU运算 (寄存器-寄存器)
//     S4: 写回阶段 (WB)   - 结果写回寄存器堆
//     S5: I-type执行      - ALU运算 (寄存器-立即数)
//     S6: LUI执行         - 立即数直通
//
//   - 状态转移:
//     S1 -> S2 -> S3 -> S4 -> S1  (R-type路径)
//     S1 -> S2 -> S5 -> S4 -> S1  (I-type路径)
//     S1 -> S2 -> S6 -> S4 -> S1  (LUI路径)
//
//   - 控制信号:
//     pc_write:  PC写使能 (S1阶段)
//     ir_write:  IR写使能 (S1阶段)
//     ab_write:  A/B锁存使能 (S2阶段)
//     f_write:   ALU结果锁存使能 (S3/S5/S6阶段)
//     reg_write: 寄存器写使能 (S4阶段)
//     rs2_imm_s: 立即数选择 (S5/S6阶段，选择imm32而非r_data_b)
//==============================================================================

module cu(
    input  wire       clk,
    input  wire       rst_n,      // 异步复位 (低有效)
    input  wire       step_en,    // 单步使能
    input  wire       is_r,       // R-type指令
    input  wire       is_imm,     // I-type指令
    input  wire       is_lui,     // LUI指令
    output reg  [2:0] st,         // 当前状态
    output wire       pc_write,   // PC写使能
    output wire       ir_write,   // IR写使能
    output wire       ab_write,   // A/B锁存使能
    output wire       f_write,    // 结果锁存使能
    output wire       reg_write,  // 寄存器写使能
    output wire       rs2_imm_s   // 立即数/寄存器选择
);

    // 状态编码 (独热码风格, 共6个状态)
    localparam S1 = 3'b001;  // 取指
    localparam S2 = 3'b010;  // 译码/读寄存器
    localparam S3 = 3'b011;  // R-type 执行
    localparam S4 = 3'b100;  // 写回
    localparam S5 = 3'b101;  // I-type 执行
    localparam S6 = 3'b110;  // LUI 执行

    reg [2:0] next_st;

    // 状态寄存器: 单步触发状态转移
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S1;                    // 复位后进入取指状态
        end else if (step_en) begin
            st <= next_st;               // 单步时更新状态
        end
    end

    // 次态逻辑: 根据当前状态和指令类型决定下一状态
    always @(*) begin
        case (st)
            S1: next_st = S2;            // 取指 -> 译码 (无条件)

            S2: begin                    // 译码 -> 根据指令类型分支
                if (is_r) begin
                    next_st = S3;        // R-type -> 执行
                end else if (is_imm) begin
                    next_st = S5;        // I-type -> 立即数执行
                end else if (is_lui) begin
                    next_st = S6;        // LUI -> 直通执行
                end else begin
                    next_st = S1;        // 无效指令 -> 回到取指
                end
            end

            S3: next_st = S4;            // R-type执行 -> 写回
            S5: next_st = S4;            // I-type执行 -> 写回
            S6: next_st = S4;            // LUI执行 -> 写回
            S4: next_st = S1;            // 写回 -> 取下一条指令

            default: next_st = S1;
        endcase
    end

    // 控制信号生成 (组合逻辑, 仅在 step_en 时有效)
    assign pc_write  = step_en && (st == S1);                          // S1: PC递增
    assign ir_write  = step_en && (st == S1);                          // S1: 锁存指令
    assign ab_write  = step_en && (st == S2);                          // S2: 锁存A/B
    assign f_write   = step_en && ((st == S3) || (st == S5) || (st == S6)); // 执行阶段锁存结果
    assign reg_write = step_en && (st == S4);                          // S4: 写回寄存器
    assign rs2_imm_s = (st == S5) || (st == S6);                       // I-type/LUI: 选立即数

endmodule

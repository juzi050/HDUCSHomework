`timescale 1ns / 1ps

//==============================================================================
// riu_cpu - RIU多周期CPU顶层 (RIU Multi-cycle CPU Core)
//==============================================================================
// 功能描述:
//   - 集成完整的RISC-V RV32I子集CPU数据通路。
//   - 支持的指令: R-type (ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND),
//                 I-type (ADDI/SLLI/SLTI/SLTIU/XORI/SRLI/SRAI/ORI/ANDI),
//                 U-type (LUI)
//
// 数据通路 (按流水级):
//   取指:   PC -> IM(指令存储器) -> IR(指令寄存器)
//   译码1: IR -> {opcode, rd, funct3, rs1, rs2, funct7, imm32}
//   译码2: {opcode, funct3, funct7} -> {is_r, is_imm, is_lui, alu_op}
//   控制:  step_en + {is_r, is_imm, is_lui} -> 多周期状态机 -> 控制信号
//   执行:  寄存器堆 -> {r_data_a, r_data_b} -> ABF锁存 -> ALU -> F锁存
//   写回:  F锁存 -> w_data -> 寄存器堆
//
// 子模块:
//   - if_stage:    取指阶段 (PC + IM + IR)
//   - id1:         指令译码阶段1 (字段拆分 + 立即数生成)
//   - id2:         指令译码阶段2 (ALU操作码 + 指令类型)
//   - cu:          控制单元 (多周期状态机)
//   - regs:        寄存器堆 (32x32位)
//   - alu:         算术逻辑单元
//   - abf_latch:   A/B/F 锁存器
//==============================================================================

module riu_cpu(
    input  wire        clk,
    input  wire        rst_n,      // 异步复位 (低有效)
    input  wire        step_en,    // 单步执行使能
    output wire [31:0] pc,         // 程序计数器
    output wire [31:0] ir,         // 指令寄存器
    output wire [31:0] w_data,     // 写回数据
    output wire [2:0]  st,         // 当前状态
    output wire        zf,         // 零标志
    output wire        cf,         // 进位标志
    output wire        of,         // 溢出标志
    output wire        sf          // 符号标志
);

    // IF 阶段信号
    wire [31:0] im_instruction;

    // ID1 阶段信号
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  funct7;
    wire [31:0] imm32;

    // ID2 + CU 信号
    wire        is_r;
    wire        is_imm;
    wire        is_lui;
    wire [3:0]  alu_op;
    wire        pc_write;
    wire        ir_write;
    wire        ab_write;
    wire        f_write;
    wire        reg_write;
    wire        rs2_imm_s;

    // 数据通路信号
    wire [31:0] r_data_a;
    wire [31:0] r_data_b;
    wire [31:0] a_latch;
    wire [31:0] b_latch;
    wire [31:0] f_latch;
    wire [31:0] alu_b;       // ALU的B输入 (立即数 或 寄存器B)
    wire [31:0] alu_f;       // ALU运算结果

    // 取指阶段
    if_stage u_if_stage (
        .clk(clk),
        .rst_n(rst_n),
        .PC_Write(pc_write),
        .IR_Write(ir_write),
        .PC(pc),
        .IR(ir),
        .im_instruction(im_instruction)
    );

    // 译码阶段1: 字段拆分 + 立即数生成
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

    // 译码阶段2: ALU操作码 + 指令类型
    id2 u_id2 (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .is_r(is_r),
        .is_imm(is_imm),
        .is_lui(is_lui),
        .alu_op(alu_op)
    );

    // 控制单元: 多周期状态机
    cu u_cu (
        .clk(clk),
        .rst_n(rst_n),
        .step_en(step_en),
        .is_r(is_r),
        .is_imm(is_imm),
        .is_lui(is_lui),
        .st(st),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .ab_write(ab_write),
        .f_write(f_write),
        .reg_write(reg_write),
        .rs2_imm_s(rs2_imm_s)
    );

    // 寄存器堆: 32x32位
    regs u_regs (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .r_addr_a(rs1),
        .r_addr_b(rs2),
        .w_addr(rd),
        .w_data(w_data),
        .r_data_a(r_data_a),
        .r_data_b(r_data_b)
    );

    // ALU B输入选择: I-type/LUI 用立即数, R-type 用寄存器B
    assign alu_b = rs2_imm_s ? imm32 : b_latch;

    // ALU 运算单元
    alu u_alu (
        .alu_op(alu_op),
        .a(a_latch),          // 锁存的寄存器A值
        .b(alu_b),            // 立即数或锁存的寄存器B值
        .f(alu_f),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    // A/B/F 锁存器
    abf_latch u_abf_latch (
        .clk(clk),
        .rst_n(rst_n),
        .ab_write(ab_write),
        .f_write(f_write),
        .a_in(r_data_a),
        .b_in(r_data_b),
        .f_in(alu_f),
        .a(a_latch),
        .b(b_latch),
        .f(f_latch)
    );

    // 写回数据 = 锁存的ALU结果
    assign w_data = f_latch;

endmodule

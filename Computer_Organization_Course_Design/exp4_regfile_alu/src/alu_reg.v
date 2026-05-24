`timescale 1ns / 1ps

//==============================================================================
// alu_reg - ALU + 寄存器堆组合模块 (ALU with Register File)
//==============================================================================
// 功能描述:
//   - 集成寄存器堆(regfile)和ALU(alu)两个子模块。
//   - 从寄存器堆读取两个操作数送入ALU进行运算。
//   - 支持两种写回方式:
//     1. write_from_alu=1: 将ALU运算结果写回寄存器堆
//     2. write_from_alu=0: 将外部数据(wdata_ext)写回寄存器堆
//   - rdata_a/rdata_b: 寄存器堆读出的操作数
//   - result: ALU运算结果
//==============================================================================

module alu_reg(
    input  wire        clk,
    input  wire        rst,
    input  wire        wen,
    input  wire        write_from_alu,
    input  wire [4:0]  raddr_a,
    input  wire [4:0]  raddr_b,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata_ext,
    input  wire [3:0]  alu_op,
    output wire [31:0] rdata_a,
    output wire [31:0] rdata_b,
    output wire [31:0] result,
    output wire        zf,
    output wire        cf,
    output wire        of,
    output wire        sf
);

    wire [31:0] write_data;

    // 选择写回数据: ALU结果 或 外部输入数据
    assign write_data = write_from_alu ? result : wdata_ext;

    // 寄存器堆子模块: 32个32位通用寄存器, R0硬连线为0
    regfile u_regfile (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata(write_data),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b)
    );

    // ALU 子模块: 执行算术逻辑运算
    alu u_alu (
        .alu_op(alu_op),
        .a(rdata_a),          // 操作数A来自寄存器堆
        .b(rdata_b),          // 操作数B来自寄存器堆
        .f(result),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

endmodule

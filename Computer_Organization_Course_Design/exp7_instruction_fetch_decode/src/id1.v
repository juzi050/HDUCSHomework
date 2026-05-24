`timescale 1ns / 1ps

//==============================================================================
// id1 - 指令译码第一阶段 (Instruction Decode Stage 1)
//==============================================================================
// 功能描述:
//   - 将32位RISC-V指令拆分为各个字段。
//   - 输出: opcode, rd, funct3, rs1, rs2, funct7, imm32。
//
// RISC-V 指令字格式:
//   [31:25] funct7  |  [24:20] rs2  |  [19:15] rs1  |  [14:12] funct3  |  [11:7] rd  |  [6:0] opcode
//==============================================================================

module id1(
    input  wire [31:0] instr,
    output wire [6:0]  opcode,   // 操作码 [6:0]
    output wire [4:0]  rd,       // 目标寄存器 [11:7]
    output wire [2:0]  funct3,   // 功能码3 [14:12]
    output wire [4:0]  rs1,      // 源寄存器1 [19:15]
    output wire [4:0]  rs2,      // 源寄存器2 [24:20]
    output wire [6:0]  funct7,   // 功能码7 [31:25]
    output wire [31:0] imm32     // 32位立即数
);

    // 指令字段提取 (组合逻辑)
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // 立即数生成单元
    immu u_immu (
        .instr(instr),
        .imm32(imm32)
    );

endmodule

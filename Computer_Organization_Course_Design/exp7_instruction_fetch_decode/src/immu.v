`timescale 1ns / 1ps

//==============================================================================
// immu - 立即数生成单元 (Immediate Generation Unit)
//==============================================================================
// 功能描述:
//   - 根据RISC-V指令的opcode，将指令中的立即数字段解码为32位立即数。
//   - 支持的指令类型:
//     I-type (opcode=0010011/0000011/1100111): 12位符号扩展立即数
//     S-type (opcode=0100011):                 12位符号扩展立即数 (store)
//     B-type (opcode=1100011):                 13位符号扩展立即数 (branch, LSB=0)
//     U-type (opcode=0110111/0010111):         20位上移立即数 (lui/auipc)
//     J-type (opcode=1101111):                 21位符号扩展立即数 (jal, LSB=0)
//
//   - R-type 指令不产生立即数 (默认输出0)。
//
// RISC-V 立即数字段编码:
//   I-type:  imm = {21{instr[31]}, instr[30:20]}
//   S-type:  imm = {21{instr[31]}, instr[30:25], instr[11:7]}
//   B-type:  imm = {20{instr[31]}, instr[7], instr[30:25], instr[11:8], 0}
//   U-type:  imm = {instr[31:12], 12'b0}
//   J-type:  imm = {12{instr[31]}, instr[19:12], instr[20], instr[30:21], 0}
//==============================================================================

module immu(
    input  wire [31:0] instr,
    output reg  [31:0] imm32
);

    wire [6:0] opcode;

    assign opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // I-type: ALU立即数, Load, Jalr
            7'b0010011,
            7'b0000011,
            7'b1100111: begin
                imm32 = {{20{instr[31]}}, instr[31:20]};  // 12位符号扩展
            end

            // S-type: Store
            7'b0100011: begin
                imm32 = {{20{instr[31]}}, instr[31:25], instr[11:7]};  // 12位符号扩展
            end

            // B-type: Branch
            7'b1100011: begin
                imm32 = {{19{instr[31]}}, instr[31], instr[7],
                         instr[30:25], instr[11:8], 1'b0};  // 13位, LSB=0
            end

            // U-type: LUI, AUIPC
            7'b0110111,
            7'b0010111: begin
                imm32 = {instr[31:12], 12'b0};  // 高20位, 低12位填0
            end

            // J-type: JAL
            7'b1101111: begin
                imm32 = {{11{instr[31]}}, instr[31], instr[19:12],
                         instr[20], instr[30:21], 1'b0};  // 21位, LSB=0
            end

            default: begin
                imm32 = 32'h0000_0000;  // R-type等不产生立即数
            end
        endcase
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// id2 - 指令译码第二阶段 (Instruction Decode Stage 2)
//==============================================================================
// 功能描述:
//   - 根据opcode/funct3/funct7产生ALU操作码和指令类型标志。
//   - 支持的指令类型:
//     R-type (0110011): ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
//     I-type (0010011): ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI
//     U-type (0110111): LUI
//   - 输出信号:
//     is_r:   R-type指令标志
//     is_imm: I-type指令标志
//     is_lui: LUI指令标志
//     alu_op: 4位ALU操作码
//==============================================================================

module id2(
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        is_r,      // R-type标志
    output reg        is_imm,    // I-type标志
    output reg        is_lui,    // LUI标志
    output reg  [3:0] alu_op     // ALU操作码
);

    // RISC-V 操作码定义
    localparam OPC_R      = 7'b0110011;  // R-type
    localparam OPC_IMM    = 7'b0010011;  // I-type (ALU立即数)
    localparam OPC_LUI    = 7'b0110111;  // LUI

    // ALU 操作码 (与 alu模块一致)
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_PASSB  = 4'b1010;

    always @(*) begin
        // 默认值
        is_r = 1'b0;
        is_imm = 1'b0;
        is_lui = 1'b0;
        alu_op = ALU_ADD;

        case (opcode)
            OPC_R: begin  // R-type 指令译码
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin is_r = 1'b1; alu_op = ALU_ADD; end   // ADD
                    {7'b0100000, 3'b000}: begin is_r = 1'b1; alu_op = ALU_SUB; end   // SUB
                    {7'b0000000, 3'b001}: begin is_r = 1'b1; alu_op = ALU_SLL; end   // SLL
                    {7'b0000000, 3'b010}: begin is_r = 1'b1; alu_op = ALU_SLT; end   // SLT
                    {7'b0000000, 3'b011}: begin is_r = 1'b1; alu_op = ALU_SLTU; end  // SLTU
                    {7'b0000000, 3'b100}: begin is_r = 1'b1; alu_op = ALU_XOR; end   // XOR
                    {7'b0000000, 3'b101}: begin is_r = 1'b1; alu_op = ALU_SRL; end   // SRL
                    {7'b0100000, 3'b101}: begin is_r = 1'b1; alu_op = ALU_SRA; end   // SRA
                    {7'b0000000, 3'b110}: begin is_r = 1'b1; alu_op = ALU_OR; end    // OR
                    {7'b0000000, 3'b111}: begin is_r = 1'b1; alu_op = ALU_AND; end   // AND
                    default: begin is_r = 1'b0; alu_op = ALU_ADD; end                // 无效R-type
                endcase
            end

            OPC_IMM: begin  // I-type (ALU立即数) 指令译码
                case (funct3)
                    3'b000: begin is_imm = 1'b1; alu_op = ALU_ADD; end   // ADDI
                    3'b001: begin                                        // SLLI
                        if (funct7 == 7'b0000000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SLL;
                        end
                    end
                    3'b010: begin is_imm = 1'b1; alu_op = ALU_SLT; end   // SLTI
                    3'b011: begin is_imm = 1'b1; alu_op = ALU_SLTU; end  // SLTIU
                    3'b100: begin is_imm = 1'b1; alu_op = ALU_XOR; end   // XORI
                    3'b101: begin                                        // SRLI / SRAI
                        if (funct7 == 7'b0000000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SRA;
                        end
                    end
                    3'b110: begin is_imm = 1'b1; alu_op = ALU_OR; end    // ORI
                    3'b111: begin is_imm = 1'b1; alu_op = ALU_AND; end   // ANDI
                    default: begin is_imm = 1'b0; alu_op = ALU_ADD; end
                endcase
            end

            OPC_LUI: begin  // LUI 指令
                is_lui = 1'b1;
                alu_op = ALU_PASSB;  // 直通立即数 (通过B端口)
            end

            default: begin  // 其他指令类型
                is_r = 1'b0;
                is_imm = 1'b0;
                is_lui = 1'b0;
                alu_op = ALU_ADD;
            end
        endcase
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// alu - 32位算术逻辑单元 (32-bit ALU for RIU CPU)
//==============================================================================
// 功能描述:
//   - RISC-V RV32I 子集ALU，支持11种运算操作。
//   - 操作码与运算对应:
//      0000: a + b   (ADD,  加法)
//      0001: a - b   (SUB,  减法, 带借位)
//      0010: a << b  (SLL,  逻辑左移, 移位量=b[4:0])
//      0011: a < b   (SLT,  有符号比较)
//      0100: a < b   (SLTU, 无符号比较)
//      0101: a ^ b   (XOR,  异或)
//      0110: a >> b  (SRL,  逻辑右移)
//      0111: a >>> b (SRA,  算术右移)
//      1000: a | b   (OR,   或)
//      1001: a & b   (AND,  与)
//      1010: f = b   (PASSB, 直通B, 用于LUI)
//   - 标志位: zf(零), cf(进位/借位), of(溢出), sf(符号)
//==============================================================================

module alu(
    input  wire [3:0]  alu_op,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] f,
    output wire        zf,
    output reg         cf,
    output reg         of,
    output wire        sf
);

    // ALU 操作码定义
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_SLL   = 4'b0010;
    localparam ALU_SLT   = 4'b0011;
    localparam ALU_SLTU  = 4'b0100;
    localparam ALU_XOR   = 4'b0101;
    localparam ALU_SRL   = 4'b0110;
    localparam ALU_SRA   = 4'b0111;
    localparam ALU_OR    = 4'b1000;
    localparam ALU_AND   = 4'b1001;
    localparam ALU_PASSB = 4'b1010;  // 直通B (用于LUI)

    reg [32:0] add_result;  // 33位加法结果 (用于进位检测)

    // ALU 核心运算逻辑
    always @(*) begin
        f = 32'h0000_0000;
        cf = 1'b0;
        of = 1'b0;
        add_result = 33'h0;

        case (alu_op)
            ALU_ADD: begin                     // 加法
                add_result = {1'b0, a} + {1'b0, b};
                f = add_result[31:0];
                cf = add_result[32];           // 进位标志
                of = (~(a[31] ^ b[31])) & (f[31] ^ a[31]); // 溢出: 同号加得异号
            end

            ALU_SUB: begin                     // 减法
                f = a - b;
                cf = (a < b);                  // 借位 (无符号比较)
                of = (a[31] ^ b[31]) & (f[31] ^ a[31]);   // 溢出: 异号减得异号
            end

            ALU_SLL: begin
                f = a << b[4:0];               // 逻辑左移 (移位量低5位)
            end

            ALU_SLT: begin
                f = ($signed(a) < $signed(b)) ? 32'h0000_0001 : 32'h0000_0000; // 有符号比较
            end

            ALU_SLTU: begin
                f = (a < b) ? 32'h0000_0001 : 32'h0000_0000; // 无符号比较
            end

            ALU_XOR: begin
                f = a ^ b;                     // 异或
            end

            ALU_SRL: begin
                f = a >> b[4:0];               // 逻辑右移
            end

            ALU_SRA: begin
                f = $signed(a) >>> b[4:0];     // 算术右移 (符号扩展)
            end

            ALU_OR: begin
                f = a | b;                     // 按位或
            end

            ALU_AND: begin
                f = a & b;                     // 按位与
            end

            ALU_PASSB: begin
                f = b;                         // 直通B (用于LUI指令)
            end

            default: begin
                f = 32'h0000_0000;
            end
        endcase
    end

    // 标志位输出
    assign zf = (f == 32'h0000_0000);  // 零标志
    assign sf = f[31];                  // 符号标志 (最高位)

endmodule

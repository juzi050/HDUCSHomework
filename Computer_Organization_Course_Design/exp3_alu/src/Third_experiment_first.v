`timescale 1ns / 1ps

//==============================================================================
// Third_experiment_first - ALU 运算核心 (ALU Core)
//==============================================================================
// 功能描述:
//   - 32位ALU，支持8种运算操作。
//   - 操作码(ALU_OP)与运算对应关系:
//       000: A & B   (按位与)
//       001: A | B   (按位或)
//       010: A ^ B   (按位异或)
//       011: ~(A^B)  (按位同或)
//       100: A + B   (加法，输出结果、零标志、溢出标志)
//       101: A - B   (减法，输出结果、零标志、溢出标志)
//       110: A < B   (有符号比较，真则输出1)
//       111: B << A  (逻辑左移，A[4:0]为移位量)
//   - 零标志ZF: 当结果F为0时置1。
//   - 溢出标志OF: 通过进位位与符号位异或判断溢出。
//==============================================================================

module Third_experiment_first (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [2:0]  ALU_OP,
    output reg  [31:0] F,
    output wire        ZF,
    output reg         OF
);
    reg  [32:0] add_result;  // 33位加法结果 (含进位)
    reg  [31:0] add_b;       // 加法器B输入 (减法时取反)
    reg         add_cin;     // 加法器进位输入 (减法时置1实现补码)
    wire        add_c32;     // 加法器第32位进位输出

    assign add_c32 = add_result[32];
    assign ZF = (F == 32'b0);  // 零标志: 结果为全0

    // 根据操作码准备加法器的B输入和进位
    // 减法(A-B) = A + (~B) + 1，通过取反B并置进位为1实现
    always @(*) begin
        add_b = B;
        add_cin = 1'b0;

        case (ALU_OP)
            3'b101: begin            // 减法: B取反, 进位置1
                add_b = ~B;
                add_cin = 1'b1;
            end
            default: begin           // 加法及其他: B不变, 进位为0
                add_b = B;
                add_cin = 1'b0;
            end
        endcase
    end

    // ALU 核心运算逻辑
    always @(*) begin
        // 预计算加法结果 (用于加法和减法)
        add_result = {1'b0, A} + {1'b0, add_b} + add_cin;
        F = 32'b0;
        OF = 1'b0;

        case (ALU_OP)
            3'b000: F = A & B;       // 按位与
            3'b001: F = A | B;       // 按位或
            3'b010: F = A ^ B;       // 按位异或
            3'b011: F = ~(A ^ B);    // 按位同或
            3'b100: begin            // 加法
                F = add_result[31:0];
                OF = add_c32 ^ F[31] ^ A[31] ^ add_b[31];  // 溢出检测
            end
            3'b101: begin            // 减法
                F = add_result[31:0];
                OF = add_c32 ^ F[31] ^ A[31] ^ add_b[31];  // 溢出检测
            end
            3'b110: F = ($signed(A) < $signed(B)) ? 32'h00000001 : 32'h00000000; // 有符号比较
            3'b111: F = (A >= 32'd32) ? 32'b0 : (B << A[4:0]); // 逻辑左移, 移位量超过31则输出0
            default: F = 32'b0;
        endcase
    end
endmodule

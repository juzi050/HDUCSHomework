`timescale 1ns / 1ps

//==============================================================================
// pc_reg - 程序计数器寄存器 (Program Counter Register)
//==============================================================================
// 功能描述:
//   - 32位程序计数器，存储当前指令地址。
//   - PC_Write=1 时在时钟上升沿递增 PC ← PC + 4。
//   - rst_n=0 时异步复位为 0x00000000。
//   - 默认每条指令4字节，故每次+4。
//==============================================================================

module pc_reg(
    input  wire        clk,
    input  wire        rst_n,      // 异步复位 (低有效)
    input  wire        PC_Write,   // PC写使能 (1=递增)
    output reg  [31:0] PC
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h0000_0000;        // 复位: PC归零
        end else if (PC_Write) begin
            PC <= PC + 32'd4;           // 递增到下一条指令地址
        end
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// regfile - 32x32位寄存器堆 (32x32-bit Register File)
//==============================================================================
// 功能描述:
//   - 32个32位通用寄存器 (regs[0:31])。
//   - R0 (寄存器0) 硬连线为0，写入R0无效，始终读出0。
//   - 异步读: rdata_a/rdata_b 组合逻辑直接输出 (无需等待时钟)。
//   - 同步写: 在时钟上升沿且wen=1时写入。
//   - rst 高电平复位，将所有寄存器清零。
//==============================================================================

module regfile(
    input  wire        clk,
    input  wire        rst,
    input  wire        wen,
    input  wire [4:0]  raddr_a,
    input  wire [4:0]  raddr_b,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata_a,
    output wire [31:0] rdata_b
);

    reg [31:0] regs [0:31];  // 32个32位寄存器
    integer i;

    // 同步复位与写入逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // 复位: 全部寄存器清零
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else if (wen && (waddr != 5'd0)) begin
            // 写使能有效且目标不是R0时写入
            regs[waddr] <= wdata;
        end
    end

    // 异步读取: R0始终输出0，其他寄存器直接读出当前值
    assign rdata_a = (raddr_a == 5'd0) ? 32'h00000000 : regs[raddr_a];
    assign rdata_b = (raddr_b == 5'd0) ? 32'h00000000 : regs[raddr_b];

endmodule

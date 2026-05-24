`timescale 1ns / 1ps

//==============================================================================
// regs - 32x32位寄存器堆 (32x32-bit Register File for CPU)
//==============================================================================
// 功能描述:
//   - 32个32位通用寄存器 (regs[0:31])。
//   - R0 硬连线为0，写入R0无效，始终读出0。
//   - 异步读: r_data_a/r_data_b 组合逻辑直接输出。
//   - 同步写: 在时钟上升沿且 reg_write=1 时写入。
//   - rst_n=0 异步复位清零。
//==============================================================================

module regs(
    input  wire        clk,
    input  wire        rst_n,       // 异步复位 (低有效)
    input  wire        reg_write,   // 寄存器写使能
    input  wire [4:0]  r_addr_a,    // 读地址A
    input  wire [4:0]  r_addr_b,    // 读地址B
    input  wire [4:0]  w_addr,      // 写地址
    input  wire [31:0] w_data,      // 写数据
    output wire [31:0] r_data_a,    // 读数据A
    output wire [31:0] r_data_b     // 读数据B
);

    reg [31:0] regs [0:31];  // 32个32位寄存器
    integer i;

    // 异步复位与同步写入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位: 全部寄存器清零
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h0000_0000;
            end
        end else if (reg_write && (w_addr != 5'd0)) begin
            // 写使能有效且目标不是R0时写入
            regs[w_addr] <= w_data;
        end
    end

    // 异步读取: R0始终输出0，其他寄存器直接读出当前值
    assign r_data_a = (r_addr_a == 5'd0) ? 32'h0000_0000 : regs[r_addr_a];
    assign r_data_b = (r_addr_b == 5'd0) ? 32'h0000_0000 : regs[r_addr_b];

endmodule

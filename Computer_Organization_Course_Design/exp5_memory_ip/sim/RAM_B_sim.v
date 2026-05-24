`timescale 1ns / 1ps

//==============================================================================
// RAM_B - BRAM行为级仿真模型 (BRAM Behavioral Simulation Model)
//==============================================================================
// 功能描述:
//   - 64x32位内存的纯Verilog行为模型，用于仿真替代BRAM IP核。
//   - 初始化预设9条测试数据 (地址0-8)，其余清零。
//   - 上升沿写入/读出。
//==============================================================================

module RAM_B(
    input  wire        clka,
    input  wire        wea,
    input  wire [5:0]  addra,
    input  wire [31:0] dina,
    output reg  [31:0] douta
);

    reg [31:0] memory [0:63];  // 64x32位内存
    integer i;

    initial begin
        // 全部清零
        for (i = 0; i < 64; i = i + 1) begin
            memory[i] = 32'h0000_0000;
        end

        // 预设测试数据
        memory[0] = 32'h0000_0820;
        memory[1] = 32'h0063_2020;
        memory[2] = 32'h0001_0FFF;
        memory[3] = 32'h2000_6789;
        memory[4] = 32'hFFFF_0000;
        memory[5] = 32'h0000_FFFF;
        memory[6] = 32'h8888_8888;
        memory[7] = 32'h9999_9999;
        memory[8] = 32'hAAAA_AAAA;
        memory[9] = 32'hBBBB_BBBB;
        douta = 32'h0000_0000;
    end

    // 时钟上升沿: wea=1时写入，wea=0时读出
    always @(posedge clka) begin
        if (wea) begin
            memory[addra] <= dina;   // 写入
        end else begin
            douta <= memory[addra];  // 读出
        end
    end

endmodule

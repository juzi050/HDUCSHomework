`timescale 1ns / 1ps

//==============================================================================
// instruction_memory - 指令存储器封装 (Instruction Memory Wrapper)
//==============================================================================
// 功能描述:
//   - 封装BRAM IP核 (IM_B) 作为指令存储器。
//   - 输入6位地址，输出32位RISC-V指令。
//   - 容量: 64 x 32位 (256字节)。
//==============================================================================

module instruction_memory(
    input  wire        clk,
    input  wire [5:0]  addr,         // 字地址 (6位, 64个字)
    output wire [31:0] instruction   // 32位指令输出
);

    // BRAM IP核: 64x32位指令存储器
    IM_B u_im_b (
        .clka(clk),
        .addra(addr),
        .douta(instruction)
    );

endmodule

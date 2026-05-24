`timescale 1ns / 1ps

//==============================================================================
// RAM - 内存IP顶层封装 (Memory IP Top-Level Wrapper)
//==============================================================================
// 功能描述:
//   - 封装 memory_ip_core，通过 MUX 选择输出的字节。
//   - 将32位内存读出数据按字节选择输出到8位LED。
//   - MUX[1:0] = 00: 选最低字节 [7:0]
//                01: 选 [15:8]
//                10: 选 [23:16]
//                11: 选最高字节 [31:24]
//
// 子模块:
//   - memory_ip_core: 内存IP核 + 写数据生成 + BRAM IP实例化
//==============================================================================

module RAM(
    input  wire [7:2] Mem_Addr,
    input  wire [1:0] MUX,
    input  wire       Mem_Write,
    input  wire       Clk,
    output reg  [7:0] LED
);

    wire [31:0] M_R_Data;  // 从内存IP核读出的32位数据

    memory_ip_core u_memory_ip_core (
        .Mem_Addr(Mem_Addr),
        .MUX(MUX),
        .Mem_Write(Mem_Write),
        .Clk(Clk),
        .M_R_Data(M_R_Data)
    );

    // 根据MUX选择输出32位数据中的对应字节到LED
    always @(*) begin
        case (MUX)
            2'b00: LED = M_R_Data[7:0];    // 最低字节
            2'b01: LED = M_R_Data[15:8];
            2'b10: LED = M_R_Data[23:16];
            2'b11: LED = M_R_Data[31:24];   // 最高字节
            default: LED = 8'h00;
        endcase
    end

endmodule

//==============================================================================
// memory_ip_core - 内存IP核模块 (Memory IP Core)
//==============================================================================
// 功能描述:
//   - 根据 MUX 选择生成写数据 M_W_Data。
//   - 实例化 BRAM IP (RAM_B) 进行内存读写。
//   - MUX 控制的写数据:
//       00: 0x0000000F
//       01: 0x00000DB0
//       10: 0x003CC381
//       11: 0xFFFFFFFF
//==============================================================================

module memory_ip_core(
    input  wire [5:0]  Mem_Addr,
    input  wire [1:0]  MUX,
    input  wire        Mem_Write,
    input  wire        Clk,
    output wire [31:0] M_R_Data
);

    reg [31:0] M_W_Data;  // 写数据 (根据MUX选择预设值)

    // 根据MUX选择写数据
    always @(*) begin
        case (MUX)
            2'b00: M_W_Data = 32'h0000_000F;
            2'b01: M_W_Data = 32'h0000_0DB0;
            2'b10: M_W_Data = 32'h003C_C381;
            2'b11: M_W_Data = 32'hFFFF_FFFF;
            default: M_W_Data = 32'h0000_0000;
        endcase
    end

    // BRAM IP 核实例: 64x32位双端口RAM
    RAM_B u_ram_b (
        .clka(Clk),
        .wea(Mem_Write),     // 写使能
        .addra(Mem_Addr),    // 读写地址
        .dina(M_W_Data),     // 写数据输入
        .douta(M_R_Data)     // 读数据输出
    );

endmodule

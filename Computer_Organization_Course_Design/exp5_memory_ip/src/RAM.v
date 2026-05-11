`timescale 1ns / 1ps

module RAM(
    input  wire [7:2] Mem_Addr,
    input  wire [1:0] MUX,
    input  wire       Mem_Write,
    input  wire       Clk,
    output reg  [7:0] LED
);

    wire [31:0] M_R_Data;

    memory_ip_core u_memory_ip_core (
        .Mem_Addr(Mem_Addr),
        .MUX(MUX),
        .Mem_Write(Mem_Write),
        .Clk(Clk),
        .M_R_Data(M_R_Data)
    );

    always @(*) begin
        case (MUX)
            2'b00: LED = M_R_Data[7:0];
            2'b01: LED = M_R_Data[15:8];
            2'b10: LED = M_R_Data[23:16];
            2'b11: LED = M_R_Data[31:24];
            default: LED = 8'h00;
        endcase
    end

endmodule

module memory_ip_core(
    input  wire [5:0]  Mem_Addr,
    input  wire [1:0]  MUX,
    input  wire        Mem_Write,
    input  wire        Clk,
    output wire [31:0] M_R_Data
);

    reg [31:0] M_W_Data;

    always @(*) begin
        case (MUX)
            2'b00: M_W_Data = 32'h0000_000F;
            2'b01: M_W_Data = 32'h0000_0DB0;
            2'b10: M_W_Data = 32'h003C_C381;
            2'b11: M_W_Data = 32'hFFFF_FFFF;
            default: M_W_Data = 32'h0000_0000;
        endcase
    end

    RAM_B u_ram_b (
        .clka(Clk),
        .wea(Mem_Write),
        .addra(Mem_Addr),
        .dina(M_W_Data),
        .douta(M_R_Data)
    );

endmodule

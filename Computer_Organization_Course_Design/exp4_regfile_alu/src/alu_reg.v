`timescale 1ns / 1ps

module alu_reg(
    input  wire        clk,
    input  wire        rst,
    input  wire        wen,
    input  wire        write_from_alu,
    input  wire [4:0]  raddr_a,
    input  wire [4:0]  raddr_b,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata_ext,
    input  wire [3:0]  alu_op,
    output wire [31:0] rdata_a,
    output wire [31:0] rdata_b,
    output wire [31:0] result,
    output wire        zf,
    output wire        cf,
    output wire        of,
    output wire        sf
);

    wire [31:0] write_data;

    assign write_data = write_from_alu ? result : wdata_ext;

    regfile u_regfile (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata(write_data),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b)
    );

    alu u_alu (
        .alu_op(alu_op),
        .a(rdata_a),
        .b(rdata_b),
        .f(result),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

endmodule

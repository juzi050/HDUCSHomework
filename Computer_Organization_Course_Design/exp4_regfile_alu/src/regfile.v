`timescale 1ns / 1ps

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

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else if (wen && (waddr != 5'd0)) begin
            regs[waddr] <= wdata;
        end
    end

    assign rdata_a = (raddr_a == 5'd0) ? 32'h00000000 : regs[raddr_a];
    assign rdata_b = (raddr_b == 5'd0) ? 32'h00000000 : regs[raddr_b];

endmodule

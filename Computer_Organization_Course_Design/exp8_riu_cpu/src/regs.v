`timescale 1ns / 1ps

module regs(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_write,
    input  wire [4:0]  r_addr_a,
    input  wire [4:0]  r_addr_b,
    input  wire [4:0]  w_addr,
    input  wire [31:0] w_data,
    output wire [31:0] r_data_a,
    output wire [31:0] r_data_b
);

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h0000_0000;
            end
        end else if (reg_write && (w_addr != 5'd0)) begin
            regs[w_addr] <= w_data;
        end
    end

    assign r_data_a = (r_addr_a == 5'd0) ? 32'h0000_0000 : regs[r_addr_a];
    assign r_data_b = (r_addr_b == 5'd0) ? 32'h0000_0000 : regs[r_addr_b];

endmodule

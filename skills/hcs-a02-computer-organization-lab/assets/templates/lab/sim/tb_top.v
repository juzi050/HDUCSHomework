`timescale 1ns / 1ps

module tb___MODULE_NAME__;

    reg clk100mhz = 1'b0;
    reg [35:0] sw = 36'd0;
    reg [7:0] bt = 8'd0;

    wire [35:0] ld;
    wire traffic_we_r;
    wire traffic_we_y;
    wire traffic_we_g;
    wire traffic_sn_r;
    wire traffic_sn_y;
    wire traffic_sn_g;
    wire [7:0] an;
    wire [6:0] seg;
    wire dp;

    integer failures = 0;

    always #5 clk100mhz = ~clk100mhz;

    __MODULE_NAME__ dut (
        .clk100mhz(clk100mhz),
        .sw(sw),
        .bt(bt),
        .ld(ld),
        .traffic_we_r(traffic_we_r),
        .traffic_we_y(traffic_we_y),
        .traffic_we_g(traffic_we_g),
        .traffic_sn_r(traffic_sn_r),
        .traffic_sn_y(traffic_sn_y),
        .traffic_sn_g(traffic_sn_g),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

    initial begin
        sw = 36'h0ABCDE123;
        bt = 8'b0000_0000;
        #20;

        if (ld !== sw) begin
            $display("FAIL: ld should mirror sw. ld=%h sw=%h", ld, sw);
            failures = failures + 1;
        end

        bt = 8'b1111_1100;
        #20;

        if ({traffic_we_r, traffic_we_y, traffic_we_g, traffic_sn_r, traffic_sn_y, traffic_sn_g} !== 6'b111111) begin
            $display("FAIL: traffic lights should follow bt[7:2].");
            failures = failures + 1;
        end

        sw[3:0] = 4'hA;
        #20;

        if (an !== 8'b1111_1110) begin
            $display("FAIL: initial scan digit should select AN0. an=%b", an);
            failures = failures + 1;
        end

        if (seg !== 7'b0001000) begin
            $display("FAIL: seven-segment decode for A is wrong. seg=%b", seg);
            failures = failures + 1;
        end

        if (dp !== 1'b1) begin
            $display("FAIL: decimal point should be off by default.");
            failures = failures + 1;
        end

        if (failures == 0) begin
            $display("PASS: HCS-A02 template smoke test passed.");
        end else begin
            $display("FAIL: %0d failure(s).", failures);
        end

        $finish;
    end

endmodule

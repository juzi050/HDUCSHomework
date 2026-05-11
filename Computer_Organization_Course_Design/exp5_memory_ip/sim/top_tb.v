`timescale 1ns / 1ps

module top_tb;

    reg clk100mhz;
    reg [35:0] sw;
    reg [7:0] bt;
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

    integer errors;

    top dut (
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

    always #5 clk100mhz = ~clk100mhz;

    task expect_leds;
        input [7:0] expected_byte;
        input [5:0] expected_addr;
        input [1:0] expected_mux;
        input [255:0] name;
        begin
            #1;
            if (ld[7:0] !== expected_byte || ld[13:8] !== expected_addr ||
                ld[15:14] !== expected_mux || ld[35:16] !== 20'd0) begin
                $display("FAIL %-0s ld=%h byte=%h/%h addr=%h/%h mux=%b/%b",
                         name, ld, ld[7:0], expected_byte,
                         ld[13:8], expected_addr, ld[15:14], expected_mux);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s ld=%h", name, ld);
            end
        end
    endtask

    task expect_output;
        input actual;
        input expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL %-0s actual=%b expected=%b", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s value=%b", name, actual);
            end
        end
    endtask

    initial begin
        clk100mhz = 1'b0;
        sw = 36'd0;
        bt = 8'd0;
        errors = 0;

        repeat (2) @(posedge clk100mhz);
        sw[7:2] = 6'd0;
        sw[1:0] = 2'b00;
        @(posedge clk100mhz);
        expect_leds(8'h20, 6'd0, 2'b00, "initial address 0 byte 0");

        sw[1:0] = 2'b01;
        expect_leds(8'h08, 6'd0, 2'b01, "initial address 0 byte 1");

        sw[7:2] = 6'd63;
        sw[1:0] = 2'b00;
        bt[0] = 1'b1;
        @(posedge clk100mhz);
        @(posedge clk100mhz);
        sw[1:0] = 2'b11;
        repeat (3) @(posedge clk100mhz);
        bt[0] = 1'b0;
        sw[1:0] = 2'b00;
        @(posedge clk100mhz);
        #1;

        if (dut.read_word !== 32'h0000_000F) begin
            $display("FAIL long press single write read_word=%h expected=0000000f", dut.read_word);
            errors = errors + 1;
        end else begin
            $display("PASS long press single write read_word=%h", dut.read_word);
        end
        expect_leds(8'h0F, 6'd63, 2'b00, "long press led status");

        force dut.u_display.scan_div = {3'b000, 14'b0};
        #1;
        if (an !== 8'b1111_1110 || seg !== 7'b0001110 || dp !== 1'b1) begin
            $display("FAIL seven segment low digit an=%b seg=%b dp=%b", an, seg, dp);
            errors = errors + 1;
        end else begin
            $display("PASS seven segment low digit");
        end
        release dut.u_display.scan_div;

        expect_output(traffic_we_r, 1'b0, "traffic_we_r off");
        expect_output(traffic_we_y, 1'b0, "traffic_we_y off");
        expect_output(traffic_we_g, 1'b0, "traffic_we_g off");
        expect_output(traffic_sn_r, 1'b0, "traffic_sn_r off");
        expect_output(traffic_sn_y, 1'b0, "traffic_sn_y off");
        expect_output(traffic_sn_g, 1'b0, "traffic_sn_g off");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: top_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: top_tb errors=%0d", errors);
        end
    end

endmodule

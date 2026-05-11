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

    task expect_equal;
        input [31:0] actual;
        input [31:0] expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL %-0s actual=%h expected=%h", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s value=%h", name, actual);
            end
        end
    endtask

    task expect_fields;
        input [31:0] instruction;
        input [255:0] name;
        begin
            #1;
            expect_equal({25'd0, ld[21:15]}, {25'd0, instruction[6:0]}, {name, " opcode led"});
            expect_equal({27'd0, ld[14:10]}, {27'd0, instruction[11:7]}, {name, " rd led"});
            expect_equal({29'd0, ld[24:22]}, {29'd0, instruction[14:12]}, {name, " funct3 led"});
            expect_equal({27'd0, ld[4:0]}, {27'd0, instruction[19:15]}, {name, " rs1 led"});
            expect_equal({27'd0, ld[9:5]}, {27'd0, instruction[24:20]}, {name, " rs2 led"});
            expect_equal({25'd0, ld[31:25]}, {25'd0, instruction[31:25]}, {name, " funct7 led"});
        end
    endtask

    task press_step;
        begin
            @(negedge clk100mhz);
            bt[0] = 1'b1;
            @(negedge clk100mhz);
            bt[0] = 1'b0;
            repeat (2) @(posedge clk100mhz);
            #1;
        end
    endtask

    initial begin
        clk100mhz = 1'b0;
        sw = 36'd0;
        bt = 8'd0;
        errors = 0;

        bt[1] = 1'b1;
        repeat (2) @(posedge clk100mhz);
        bt[1] = 1'b0;
        sw[1:0] = 2'b11;
        repeat (2) @(posedge clk100mhz);
        #1;

        expect_equal(dut.pc, 32'h0000_0000, "reset PC");
        expect_equal(dut.ir, 32'h0000_0000, "reset IR");

        press_step();
        expect_equal(dut.ir, 32'h1234_50b7, "first fetched IR");
        expect_equal(dut.pc, 32'h0000_0004, "first PC");
        expect_fields(32'h1234_50b7, "first instruction");

        sw[3:2] = 2'b00;
        #1;
        expect_equal(dut.display_value, 32'h1234_5000, "display imm32");
        sw[3:2] = 2'b01;
        #1;
        expect_equal(dut.display_value, 32'h1234_50b7, "display IR");
        sw[3:2] = 2'b10;
        #1;
        expect_equal(dut.display_value, 32'h0000_0004, "display PC");
        sw[3:2] = 2'b11;
        #1;
        expect_equal(dut.display_value, 32'h0001_0117, "display prefetched instruction");

        sw[3:2] = 2'b00;
        press_step();
        expect_equal(dut.ir, 32'h0001_0117, "second fetched IR");
        expect_equal(dut.pc, 32'h0000_0008, "second PC");
        expect_fields(32'h0001_0117, "second instruction");

        if (traffic_we_r !== 1'b0 || traffic_we_y !== 1'b0 || traffic_we_g !== 1'b0 ||
            traffic_sn_r !== 1'b0 || traffic_sn_y !== 1'b0 || traffic_sn_g !== 1'b0) begin
            $display("FAIL traffic lights should be off");
            errors = errors + 1;
        end else begin
            $display("PASS traffic lights off");
        end

        if (errors == 0) begin
            $display("ALL TESTS PASSED: top_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: top_tb errors=%0d", errors);
        end
    end

endmodule

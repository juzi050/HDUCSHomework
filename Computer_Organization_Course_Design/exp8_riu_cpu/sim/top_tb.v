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

    task expect_bit;
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
        repeat (2) @(posedge clk100mhz);
        #1;

        expect_equal(dut.u_riu_cpu.pc, 32'h0000_0000, "reset PC");
        expect_equal(dut.u_riu_cpu.ir, 32'h0000_0000, "reset IR");
        expect_equal({29'd0, dut.u_riu_cpu.st}, 32'h0000_0001, "reset ST");

        press_step();
        expect_equal(dut.u_riu_cpu.ir, 32'h8760_0093, "first IR");
        expect_equal(dut.u_riu_cpu.pc, 32'h0000_0004, "first PC");
        expect_equal({29'd0, dut.u_riu_cpu.st}, 32'h0000_0002, "after first step ST");

        press_step();
        expect_equal({29'd0, dut.u_riu_cpu.st}, 32'h0000_0005, "first execute ST");

        press_step();
        expect_equal({29'd0, dut.u_riu_cpu.st}, 32'h0000_0004, "first writeback ST");
        expect_equal(dut.u_riu_cpu.w_data, 32'hffff_f876, "first W_Data");

        press_step();
        expect_equal({29'd0, dut.u_riu_cpu.st}, 32'h0000_0001, "first done ST");
        expect_equal(dut.u_riu_cpu.u_regs.regs[1], 32'hffff_f876, "first register write");

        sw[2:0] = 3'b000;
        #1;
        expect_equal(dut.display_value, 32'h0000_0004, "display PC");
        sw[2:0] = 3'b001;
        #1;
        expect_equal(dut.display_value, 32'h8760_0093, "display IR");
        sw[2:0] = 3'b010;
        #1;
        expect_equal(dut.display_value, 32'hffff_f876, "display W_Data");
        sw[2:0] = 3'b011;
        #1;
        expect_equal(dut.display_value, 32'h0000_0001, "display ST");
        sw[2:0] = 3'b100;
        #1;
        expect_equal(dut.display_value, {28'd0, dut.u_riu_cpu.zf, dut.u_riu_cpu.cf, dut.u_riu_cpu.of, dut.u_riu_cpu.sf}, "display flags");

        expect_equal({4'd0, ld[27:0]}, {4'd0, dut.u_riu_cpu.w_data[27:0]}, "LED W_Data low bits");
        expect_equal({28'd0, ld[31:28]}, {28'd0, dut.u_riu_cpu.zf, dut.u_riu_cpu.cf, dut.u_riu_cpu.of, dut.u_riu_cpu.sf}, "LED flags");
        expect_equal({29'd0, ld[34:32]}, {29'd0, dut.u_riu_cpu.st}, "LED ST");

        expect_bit(traffic_we_r, 1'b0, "traffic_we_r off");
        expect_bit(traffic_we_y, 1'b0, "traffic_we_y off");
        expect_bit(traffic_we_g, 1'b0, "traffic_we_g off");
        expect_bit(traffic_sn_r, 1'b0, "traffic_sn_r off");
        expect_bit(traffic_sn_y, 1'b0, "traffic_sn_y off");
        expect_bit(traffic_sn_g, 1'b0, "traffic_sn_g off");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: top_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: top_tb errors=%0d", errors);
        end
    end

endmodule

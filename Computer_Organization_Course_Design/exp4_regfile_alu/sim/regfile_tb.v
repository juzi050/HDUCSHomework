`timescale 1ns / 1ps

module regfile_tb;

    reg clk;
    reg rst;
    reg wen;
    reg [4:0] raddr_a;
    reg [4:0] raddr_b;
    reg [4:0] waddr;
    reg [31:0] wdata;
    wire [31:0] rdata_a;
    wire [31:0] rdata_b;

    integer errors;
    integer idx;

    regfile dut (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata(wdata),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b)
    );

    always #5 clk = ~clk;

    task expect_value;
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

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        wen = 1'b0;
        raddr_a = 5'd0;
        raddr_b = 5'd0;
        waddr = 5'd0;
        wdata = 32'h00000000;
        errors = 0;

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        #1;

        for (idx = 0; idx < 32; idx = idx + 1) begin
            raddr_a = idx;
            #1;
            expect_value(rdata_a, 32'h00000000, "reset clears register");
        end

        waddr = 5'd5;
        wdata = 32'hDEADBEEF;
        wen = 1'b1;
        @(posedge clk);
        #1;
        wen = 1'b0;
        raddr_a = 5'd5;
        #1;
        expect_value(rdata_a, 32'hDEADBEEF, "write and read R5");

        waddr = 5'd0;
        wdata = 32'hFFFFFFFF;
        wen = 1'b1;
        @(posedge clk);
        #1;
        wen = 1'b0;
        raddr_a = 5'd0;
        #1;
        expect_value(rdata_a, 32'h00000000, "R0 ignores writes");

        raddr_a = 5'd0;
        raddr_b = 5'd5;
        #1;
        expect_value(rdata_a, 32'h00000000, "async read A R0");
        expect_value(rdata_b, 32'hDEADBEEF, "async read B R5");

        raddr_a = 5'd5;
        waddr = 5'd5;
        wdata = 32'h12345678;
        wen = 1'b1;
        #1;
        expect_value(rdata_a, 32'hDEADBEEF, "same-address read before clock");
        @(posedge clk);
        #1;
        wen = 1'b0;
        expect_value(rdata_a, 32'h12345678, "same-address read after write clock");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: regfile_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: regfile_tb errors=%0d", errors);
        end
    end

endmodule

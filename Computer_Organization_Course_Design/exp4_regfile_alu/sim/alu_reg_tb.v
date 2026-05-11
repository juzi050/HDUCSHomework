`timescale 1ns / 1ps

module alu_reg_tb;

    reg clk;
    reg rst;
    reg wen;
    reg write_from_alu;
    reg [4:0] raddr_a;
    reg [4:0] raddr_b;
    reg [4:0] waddr;
    reg [31:0] wdata_ext;
    reg [3:0] alu_op;
    wire [31:0] rdata_a;
    wire [31:0] rdata_b;
    wire [31:0] result;
    wire zf;
    wire cf;
    wire of;
    wire sf;

    integer errors;

    alu_reg dut (
        .clk(clk),
        .rst(rst),
        .wen(wen),
        .write_from_alu(write_from_alu),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata_ext(wdata_ext),
        .alu_op(alu_op),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b),
        .result(result),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
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

    task write_external;
        input [4:0] addr;
        input [31:0] data;
        begin
            waddr = addr;
            wdata_ext = data;
            write_from_alu = 1'b0;
            wen = 1'b1;
            @(posedge clk);
            #1;
            wen = 1'b0;
        end
    endtask

    task write_result;
        input [4:0] addr;
        begin
            waddr = addr;
            write_from_alu = 1'b1;
            wen = 1'b1;
            @(posedge clk);
            #1;
            wen = 1'b0;
            write_from_alu = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        wen = 1'b0;
        write_from_alu = 1'b0;
        raddr_a = 5'd0;
        raddr_b = 5'd0;
        waddr = 5'd0;
        wdata_ext = 32'h00000000;
        alu_op = 4'b0000;
        errors = 0;

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        #1;
        expect_value(result, 32'h00000000, "reset result");

        write_external(5'd1, 32'h0000000A);
        write_external(5'd2, 32'h00000007);

        raddr_a = 5'd1;
        raddr_b = 5'd2;
        alu_op = 4'b0000;
        #1;
        expect_value(rdata_a, 32'h0000000A, "read operand A");
        expect_value(rdata_b, 32'h00000007, "read operand B");
        expect_value(result, 32'h00000011, "add before writeback");

        write_result(5'd3);
        raddr_a = 5'd3;
        raddr_b = 5'd0;
        #1;
        expect_value(rdata_a, 32'h00000011, "read ALU writeback R3");
        expect_value(result, 32'h00000011, "R3 plus R0");

        raddr_a = 5'd1;
        raddr_b = 5'd2;
        alu_op = 4'b0001;
        #1;
        expect_value(result, 32'h00000003, "sub before writeback");
        write_result(5'd4);
        raddr_a = 5'd4;
        raddr_b = 5'd0;
        #1;
        expect_value(rdata_a, 32'h00000003, "read ALU writeback R4");

        write_external(5'd0, 32'hFFFFFFFF);
        raddr_a = 5'd0;
        #1;
        expect_value(rdata_a, 32'h00000000, "R0 still zero through alu_reg");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: alu_reg_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: alu_reg_tb errors=%0d", errors);
        end
    end

endmodule

`timescale 1ns / 1ps

//==============================================================================
// alu_reg_tb - ALU+寄存器堆组合模块测试平台 (ALU+RegFile Testbench)
//==============================================================================
// 测试内容:
//   1. 复位后ALU结果为0。
//   2. 外部数据写入寄存器，验证读出。
//   3. ALU运算结果写回寄存器，验证写入正确。
//   4. R0硬连线验证 (通过组合模块)。
//==============================================================================

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

    // 值验证任务
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

    // 外部数据写入任务
    task write_external;
        input [4:0] addr;
        input [31:0] data;
        begin
            waddr = addr;
            wdata_ext = data;
            write_from_alu = 1'b0;      // 选择外部数据
            wen = 1'b1;
            @(posedge clk);
            #1;
            wen = 1'b0;
        end
    endtask

    // ALU结果写回任务
    task write_result;
        input [4:0] addr;
        begin
            waddr = addr;
            write_from_alu = 1'b1;      // 选择ALU结果
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
        alu_op = 4'b0000;              // 默认加法
        errors = 0;

        // 复位测试
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        #1;
        expect_value(result, 32'h00000000, "reset result");

        // 外部数据写入 R1=10, R2=7
        write_external(5'd1, 32'h0000000A);
        write_external(5'd2, 32'h00000007);

        // ALU 加法测试: R1 + R2 = 17
        raddr_a = 5'd1;
        raddr_b = 5'd2;
        alu_op = 4'b0000;
        #1;
        expect_value(rdata_a, 32'h0000000A, "read operand A");
        expect_value(rdata_b, 32'h00000007, "read operand B");
        expect_value(result, 32'h00000011, "add before writeback");

        // ALU结果写回R3并验证
        write_result(5'd3);
        raddr_a = 5'd3;
        raddr_b = 5'd0;
        #1;
        expect_value(rdata_a, 32'h00000011, "read ALU writeback R3");
        expect_value(result, 32'h00000011, "R3 plus R0");

        // ALU 减法测试: R1 - R2 = 3, 写回R4
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

        // R0硬连线测试: 外部写入R0应无效
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

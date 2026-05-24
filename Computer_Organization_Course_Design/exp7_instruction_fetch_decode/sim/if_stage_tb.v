`timescale 1ns / 1ps

//==============================================================================
// if_stage_tb - 取指阶段测试平台 (Instruction Fetch Stage Testbench)
//==============================================================================
// 测试内容:
//   1. 复位后 PC=0, IR=0。
//   2. 连续9条指令取指，验证PC每次+4，IR锁存正确指令。
//   3. PC_Write=0 时 PC 保持不变。
//   4. IR_Write=0 时 IR 保持不变。
//==============================================================================

module if_stage_tb;

    reg clk;
    reg rst_n;
    reg PC_Write;
    reg IR_Write;
    wire [31:0] PC;
    wire [31:0] IR;
    wire [31:0] im_instruction;

    reg [31:0] expected_instr [0:8];  // 期望的指令序列
    integer i;
    integer errors;

    if_stage dut (
        .clk(clk),
        .rst_n(rst_n),
        .PC_Write(PC_Write),
        .IR_Write(IR_Write),
        .PC(PC),
        .IR(IR),
        .im_instruction(im_instruction)
    );

    always #5 clk = ~clk;  // 100MHz 时钟

    // 值验证任务
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

    // 单步取指任务: 拉高 PC_Write 和 IR_Write 一个周期
    task step_fetch;
        begin
            PC_Write = 1'b1;
            IR_Write = 1'b1;
            @(posedge clk);
            #1;
            PC_Write = 1'b0;
            IR_Write = 1'b0;
        end
    endtask

    initial begin
        // 期望指令序列 (与 IM_B_sim 一致)
        expected_instr[0] = 32'h1234_50b7;
        expected_instr[1] = 32'h0001_0117;
        expected_instr[2] = 32'hfff0_0193;
        expected_instr[3] = 32'h0100_a203;
        expected_instr[4] = 32'h0041_82b3;
        expected_instr[5] = 32'h0050_aa23;
        expected_instr[6] = 32'h0002_8463;
        expected_instr[7] = 32'h0060_0313;
        expected_instr[8] = 32'hff1f_f3ef;

        clk = 1'b0;
        rst_n = 1'b0;      // 初始复位
        PC_Write = 1'b0;
        IR_Write = 1'b0;
        errors = 0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;      // 释放复位
        repeat (2) @(posedge clk);
        #1;

        // 复位验证
        expect_equal(PC, 32'h0000_0000, "reset PC");
        expect_equal(IR, 32'h0000_0000, "reset IR");
        expect_equal(im_instruction, expected_instr[0], "prefetch instruction 0");

        // 连续取指9条指令
        for (i = 0; i < 9; i = i + 1) begin
            step_fetch();
            expect_equal(IR, expected_instr[i], "IR after fetch");
            expect_equal(PC, (i + 1) * 32'd4, "PC increments by 4");
            @(posedge clk);
            #1;
        end

        // PC/IR保持测试: 写使能为0时值不变
        @(posedge clk);
        #1;
        expect_equal(PC, 32'd36, "PC hold when PC_Write=0");
        expect_equal(IR, expected_instr[8], "IR hold when IR_Write=0");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: if_stage_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: if_stage_tb errors=%0d", errors);
        end
    end

endmodule

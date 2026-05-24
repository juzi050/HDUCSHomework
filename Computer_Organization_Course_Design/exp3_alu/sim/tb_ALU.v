`timescale 1ns / 1ps

//==============================================================================
// tb_ALU - ALU 顶层仿真测试平台 (ALU Top-Level Testbench)
//==============================================================================
// 测试内容:
//   1. 按钮操作: 加载A/B, 清除, 显示模式切换。
//   2. 所有8种ALU运算: AND, OR, XOR, XNOR, ADD, SUB, SLT, SLL。
//   3. 标志位: ZF(零标志), OF(溢出标志)。
//   4. 七段数码管段码输出验证。
//==============================================================================

module tb_ALU;
    localparam MODE_A = 2'b00;
    localparam MODE_B = 2'b01;
    localparam MODE_F = 2'b10;

    reg         clk;
    reg  [35:0] SW;
    reg  [3:0]  BT;
    wire [35:0] LD;
    wire [7:0]  AN;
    wire [7:0]  SEG;

    integer errors;  // 错误计数器

    ALU dut (
        .CLK100MHZ(clk),
        .SW(SW),
        .BT(BT),
        .LD(LD),
        .AN(AN),
        .SEG(SEG)
    );

    // 100MHz 时钟生成 (周期 10ns)
    always #5 clk = ~clk;

    // 按钮按下任务: 模拟按下和释放指定按钮
    task press_button;
        input integer button;
        begin
            BT[button] = 1'b1;
            repeat (4) @(posedge clk);  // 保持高电平4个周期
            BT[button] = 1'b0;
            repeat (4) @(posedge clk);  // 等待4个周期稳定
            #1;
        end
    endtask

    // 验证 LED 输出任务: 比较实际值与期望值
    task expect_led;
        input [31:0]  exp_value;
        input [1:0]   exp_mode;
        input         exp_zf;
        input         exp_of;
        input [255:0] name;
        begin
            #1;
            if (LD[31:0] !== exp_value || LD[35:34] !== exp_mode ||
                LD[32] !== exp_zf || LD[33] !== exp_of) begin
                $display("FAIL %-0s LD_VALUE=%h exp=%h MODE=%b exp=%b ZF=%b exp=%b OF=%b exp=%b",
                         name, LD[31:0], exp_value, LD[35:34], exp_mode,
                         LD[32], exp_zf, LD[33], exp_of);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s LD_VALUE=%h MODE=%b ZF=%b OF=%b",
                         name, LD[31:0], LD[35:34], LD[32], LD[33]);
            end
        end
    endtask

    // ALU 运算测试任务: 设置操作数和操作码，验证结果
    task run_alu_case;
        input [31:0]  in_a;
        input [31:0]  in_b;
        input [2:0]   op;
        input [31:0]  exp_f;
        input         exp_zf;
        input         exp_of;
        input [255:0] name;
        begin
            press_button(2);        // 清除之前的输入

            SW[31:0] = in_a;
            press_button(0);        // 加载A

            SW[31:0] = in_b;
            press_button(1);        // 加载B

            SW[34:32] = op;         // 设置ALU操作码
            #1;
            expect_led(exp_f, MODE_F, exp_zf, exp_of, name);
        end
    endtask

    // 七段数码管验证任务: 强制设定位选信号，验证段码输出
    task expect_seven_seg;
        input [2:0]   sel;
        input [7:0]   exp_an;
        input [7:0]   exp_seg;
        input [255:0] name;
        begin
            force dut.seven_segment_display.refresh_count = {sel, 14'b0};
            #1;
            if (AN !== exp_an || SEG !== exp_seg) begin
                $display("FAIL %-0s AN=%b exp=%b SEG=%h exp=%h",
                         name, AN, exp_an, SEG, exp_seg);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s AN=%b SEG=%h", name, AN, SEG);
            end
            release dut.seven_segment_display.refresh_count;
        end
    endtask

    initial begin
        errors = 0;
        clk = 1'b0;
        SW = 36'b0;
        BT = 4'b0;

        repeat (2) @(posedge clk);

        // 测试清除功能
        press_button(2);
        expect_led(32'h00000000, MODE_F, 1'b1, 1'b0, "clear initializes F display");

        // 测试加载A/B并验证XOR结果
        SW[31:0] = 32'h12345678;
        press_button(0);
        SW[31:0] = 32'h87654321;
        press_button(1);
        SW[34:32] = 3'b010;
        expect_led(32'h95511559, MODE_F, 1'b0, 1'b0, "load A/B and display F");

        // 测试显示模式切换 F->A->B->F
        press_button(3);
        expect_led(32'h12345678, MODE_A, 1'b0, 1'b0, "display A");
        press_button(3);
        expect_led(32'h87654321, MODE_B, 1'b0, 1'b0, "display B");
        press_button(3);
        expect_led(32'h95511559, MODE_F, 1'b0, 1'b0, "display F again");

        // 测试清除后恢复显示F
        press_button(2);
        expect_led(32'h00000000, MODE_F, 1'b1, 1'b0, "clear restores F display");

        // 测试所有ALU运算
        run_alu_case(32'hFFFF0000, 32'h0F0F0F0F, 3'b000, 32'h0F0F0000, 1'b0, 1'b0, "and");
        run_alu_case(32'h12345678, 32'h87654321, 3'b001, 32'h97755779, 1'b0, 1'b0, "or");
        run_alu_case(32'h12345678, 32'h87654321, 3'b010, 32'h95511559, 1'b0, 1'b0, "xor");
        run_alu_case(32'h12345678, 32'h87654321, 3'b011, 32'h6AAEEAA6, 1'b0, 1'b0, "xnor");
        run_alu_case(32'h00000001, 32'h00000002, 3'b100, 32'h00000003, 1'b0, 1'b0, "add normal");
        run_alu_case(32'h00000001, 32'hFFFFFFFF, 3'b100, 32'h00000000, 1'b1, 1'b0, "add zero");
        run_alu_case(32'h7FFFFFFF, 32'h00000001, 3'b100, 32'h80000000, 1'b0, 1'b1, "add overflow");
        run_alu_case(32'h00000005, 32'h00000003, 3'b101, 32'h00000002, 1'b0, 1'b0, "sub normal");
        run_alu_case(32'h80000000, 32'h00000001, 3'b101, 32'h7FFFFFFF, 1'b0, 1'b1, "sub overflow");
        run_alu_case(32'hFFFFFFFF, 32'h00000001, 3'b110, 32'h00000001, 1'b0, 1'b0, "slt signed true");
        run_alu_case(32'h00000002, 32'hFFFFFFFF, 3'b110, 32'h00000000, 1'b1, 1'b0, "slt signed false");
        run_alu_case(32'h00000004, 32'h00000001, 3'b111, 32'h00000010, 1'b0, 1'b0, "sll normal");
        run_alu_case(32'h00000020, 32'h00000001, 3'b111, 32'h00000000, 1'b1, 1'b0, "sll large shift");

        // 测试七段数码管段码输出 (设定结果为 0x12345678, 验证每个数码管)
        run_alu_case(32'hFFFFFFFF, 32'h12345678, 3'b000, 32'h12345678, 1'b0, 1'b0, "seven segment source");
        expect_seven_seg(3'b000, 8'b11111110, 8'h80, "seven segment digit 0 8");
        expect_seven_seg(3'b001, 8'b11111101, 8'hF8, "seven segment digit 1 7");
        expect_seven_seg(3'b010, 8'b11111011, 8'h82, "seven segment digit 2 6");
        expect_seven_seg(3'b011, 8'b11110111, 8'h92, "seven segment digit 3 5");
        expect_seven_seg(3'b100, 8'b11101111, 8'h99, "seven segment digit 4 4");
        expect_seven_seg(3'b101, 8'b11011111, 8'hB0, "seven segment digit 5 3");
        expect_seven_seg(3'b110, 8'b10111111, 8'hA4, "seven segment digit 6 2");
        expect_seven_seg(3'b111, 8'b01111111, 8'hF9, "seven segment digit 7 1");

        // 测试结果汇总
        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED errors=%0d", errors);
        end

        $finish;
    end
endmodule

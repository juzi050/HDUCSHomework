`timescale 1ns / 1ps

//==============================================================================
// top_tb - 实验4顶层测试平台 (Experiment 4 Top Testbench)
//==============================================================================
// 测试内容:
//   1. 按钮操作: 设置读/写地址, 外部写入/ALU写回, 显示模式切换, 复位。
//   2. 寄存器堆 + ALU 协同工作验证。
//   3. 溢出标志位验证 (0x7FFFFFFF + 1)。
//   4. 七段数码管显示验证。
//   5. 交通灯输出确认关闭。
//==============================================================================

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

    // 按钮按下任务: 模拟按下和释放
    task press_button;
        input integer button;
        begin
            bt[button] = 1'b1;
            repeat (3) @(posedge clk100mhz);
            bt[button] = 1'b0;
            repeat (3) @(posedge clk100mhz);
            #1;
        end
    endtask

    // 设置读/写地址任务
    task latch_addr;
        input integer button;
        input [4:0] addr;
        begin
            sw[4:0] = addr;
            press_button(button);
        end
    endtask

    // 加载数据到寄存器任务
    task load_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            latch_addr(2, addr);     // 设置写地址
            sw[31:0] = data;
            press_button(3);         // 写入外部数据
        end
    endtask

    // LED 显示验证任务
    task expect_display;
        input [31:0] exp_value;
        input exp_zf;
        input exp_cf;
        input exp_of;
        input exp_sf;
        input [255:0] name;
        begin
            #1;
            if (ld[31:0] !== exp_value || ld[32] !== exp_zf ||
                ld[33] !== exp_cf || ld[34] !== exp_of || ld[35] !== exp_sf) begin
                $display("FAIL %-0s ld=%h/%h zf=%b/%b cf=%b/%b of=%b/%b sf=%b/%b",
                         name, ld[31:0], exp_value, ld[32], exp_zf,
                         ld[33], exp_cf, ld[34], exp_of, ld[35], exp_sf);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s ld=%h flags=%b%b%b%b",
                         name, ld[31:0], ld[35], ld[34], ld[33], ld[32]);
            end
        end
    endtask

    // 单值验证任务
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
        sw = 36'h000000000;
        bt = 8'h00;
        errors = 0;

        repeat (2) @(posedge clk100mhz);
        press_button(7);                      // 复位
        sw[35:32] = 4'b0000;                  // ALU加法
        expect_display(32'h00000000, 1'b1, 1'b0, 1'b0, 1'b0, "reset display result");

        // 加载 R1=3, R2=5
        load_reg(5'd1, 32'h00000003);
        load_reg(5'd2, 32'h00000005);
        // 选择操作数 A=R1, B=R2
        latch_addr(0, 5'd1);
        latch_addr(1, 5'd2);
        sw[35:32] = 4'b0000;
        #1;
        expect_display(32'h00000008, 1'b0, 1'b0, 1'b0, 1'b0, "top add result");

        // ALU结果写回测试: R3 = R1 + R2 = 8
        latch_addr(2, 5'd3);
        press_button(4);                      // ALU结果写回
        latch_addr(0, 5'd3);
        latch_addr(1, 5'd0);
        #1;
        expect_display(32'h00000008, 1'b0, 1'b0, 1'b0, 1'b0, "top writeback result");

        // 七段数码管显示验证: 强制扫描位置
        force dut.u_display.scan_div = {3'b000, 14'b0};
        #1;
        if (an !== 8'b1111_1110 || seg !== 7'b0000000 || dp !== 1'b1) begin
            $display("FAIL seven segment low digit an=%b seg=%b dp=%b", an, seg, dp);
            errors = errors + 1;
        end else begin
            $display("PASS seven segment low digit");
        end
        release dut.u_display.scan_div;

        // 显示模式切换测试: A -> B -> Result
        press_button(5);
        expect_display(32'h00000008, 1'b0, 1'b0, 1'b0, 1'b0, "display A");
        press_button(5);
        expect_display(32'h00000000, 1'b0, 1'b0, 1'b0, 1'b0, "display B");
        press_button(5);
        expect_display(32'h00000008, 1'b0, 1'b0, 1'b0, 1'b0, "display result again");

        // 溢出测试: 0x7FFFFFFF + 1 = 0x80000000
        load_reg(5'd4, 32'h7FFFFFFF);
        load_reg(5'd5, 32'h00000001);
        latch_addr(0, 5'd4);
        latch_addr(1, 5'd5);
        sw[35:32] = 4'b0000;
        #1;
        expect_display(32'h80000000, 1'b0, 1'b0, 1'b1, 1'b1, "top overflow flags");

        // 交通灯输出验证
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

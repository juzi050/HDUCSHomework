`timescale 1ns / 1ps

module tb_ALU;
    reg  [31:0] A;
    reg  [31:0] B;
    reg         clk;
    reg  [2:0]  ALU_OP;
    reg  [2:0]  F_LED_SW;
    reg  [31:0] seg_f;
    wire [31:0] F;
    wire        ZF;
    wire        OF;
    wire [7:0]  LED;
    wire [7:0]  AN;
    wire [7:0]  SEG;

    integer errors;

    Third_experiment_first dut_alu (
        .A(A),
        .B(B),
        .ALU_OP(ALU_OP),
        .F(F),
        .ZF(ZF),
        .OF(OF)
    );

    Third_experiment_third dut_display (
        .F(F),
        .ZF(ZF),
        .OF(OF),
        .F_LED_SW(F_LED_SW),
        .LED(LED)
    );

    Third_experiment_fourth dut_seven_seg (
        .clk(clk),
        .F(seg_f),
        .AN(AN),
        .SEG(SEG)
    );

    always #5 clk = ~clk;

    task expect_alu;
        input [31:0] exp_f;
        input        exp_zf;
        input        exp_of;
        input [255:0] name;
        begin
            #1;
            if (F !== exp_f || ZF !== exp_zf || OF !== exp_of) begin
                $display("FAIL %-0s F=%h exp=%h ZF=%b exp=%b OF=%b exp=%b",
                         name, F, exp_f, ZF, exp_zf, OF, exp_of);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s F=%h ZF=%b OF=%b", name, F, ZF, OF);
            end
        end
    endtask

    task expect_led;
        input [2:0]  sw;
        input [7:0]  exp_led;
        input [255:0] name;
        begin
            F_LED_SW = sw;
            #1;
            if (LED !== exp_led) begin
                $display("FAIL %-0s LED=%h exp=%h", name, LED, exp_led);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s LED=%h", name, LED);
            end
        end
    endtask

    task expect_seven_seg;
        input [2:0]   sel;
        input [7:0]   exp_an;
        input [7:0]   exp_seg;
        input [255:0] name;
        begin
            force dut_seven_seg.refresh_count = {sel, 14'b0};
            #1;
            if (AN !== exp_an || SEG !== exp_seg) begin
                $display("FAIL %-0s AN=%b exp=%b SEG=%h exp=%h",
                         name, AN, exp_an, SEG, exp_seg);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s AN=%b SEG=%h", name, AN, SEG);
            end
            release dut_seven_seg.refresh_count;
        end
    endtask

    initial begin
        errors = 0;
        clk = 1'b0;
        A = 32'b0;
        B = 32'b0;
        seg_f = 32'h1234ABCD;
        ALU_OP = 3'b000;
        F_LED_SW = 3'b000;

        A = 32'hFFFF0000; B = 32'h0F0F0F0F; ALU_OP = 3'b000;
        expect_alu(32'h0F0F0000, 1'b0, 1'b0, "and");

        A = 32'h00000000; B = 32'h00000000; ALU_OP = 3'b001;
        expect_alu(32'h00000000, 1'b1, 1'b0, "or zero");

        A = 32'hAAAA5555; B = 32'hFFFF0000; ALU_OP = 3'b010;
        expect_alu(32'h55555555, 1'b0, 1'b0, "xor");

        A = 32'hAAAA5555; B = 32'hFFFF0000; ALU_OP = 3'b011;
        expect_alu(32'hAAAAAAAA, 1'b0, 1'b0, "xnor");

        A = 32'h00000001; B = 32'h00000002; ALU_OP = 3'b100;
        expect_alu(32'h00000003, 1'b0, 1'b0, "add normal");

        A = 32'h00000001; B = 32'hFFFFFFFF; ALU_OP = 3'b100;
        expect_alu(32'h00000000, 1'b1, 1'b0, "add zero");

        A = 32'h7FFFFFFF; B = 32'h00000001; ALU_OP = 3'b100;
        expect_alu(32'h80000000, 1'b0, 1'b1, "add positive overflow");

        A = 32'h00000005; B = 32'h00000003; ALU_OP = 3'b101;
        expect_alu(32'h00000002, 1'b0, 1'b0, "sub normal");

        A = 32'h80000000; B = 32'h00000001; ALU_OP = 3'b101;
        expect_alu(32'h7FFFFFFF, 1'b0, 1'b1, "sub negative overflow");

        A = 32'hFFFFFFFF; B = 32'h00000001; ALU_OP = 3'b110;
        expect_alu(32'h00000001, 1'b0, 1'b0, "slt signed true");

        A = 32'h00000002; B = 32'hFFFFFFFF; ALU_OP = 3'b110;
        expect_alu(32'h00000000, 1'b1, 1'b0, "slt signed false");

        A = 32'h00000024; B = 32'h00000001; ALU_OP = 3'b111;
        expect_alu(32'h00000010, 1'b0, 1'b0, "sll low five bits");

        A = 32'h12345678; B = 32'h00000000; ALU_OP = 3'b000;
        expect_alu(32'h00000000, 1'b1, 1'b0, "display source zero");
        expect_led(3'b000, 8'h00, "display byte0");

        A = 32'hFFFFFFFF; B = 32'h12345678; ALU_OP = 3'b000;
        expect_alu(32'h12345678, 1'b0, 1'b0, "display source");
        expect_led(3'b000, 8'h78, "display byte0");
        expect_led(3'b001, 8'h56, "display byte1");
        expect_led(3'b010, 8'h34, "display byte2");
        expect_led(3'b011, 8'h12, "display byte3");

        A = 32'h7FFFFFFF; B = 32'h00000001; ALU_OP = 3'b100;
        expect_alu(32'h80000000, 1'b0, 1'b1, "display flags source");
        expect_led(3'b100, 8'h02, "display flags");
        expect_led(3'b101, 8'h00, "display unused 101");
        expect_led(3'b110, 8'h00, "display unused 110");
        expect_led(3'b111, 8'h00, "display unused 111");

        expect_seven_seg(3'b000, 8'b11111110, 8'hA1, "seven segment digit 0 D");
        expect_seven_seg(3'b001, 8'b11111101, 8'hC6, "seven segment digit 1 C");
        expect_seven_seg(3'b010, 8'b11111011, 8'h83, "seven segment digit 2 B");
        expect_seven_seg(3'b011, 8'b11110111, 8'h88, "seven segment digit 3 A");
        expect_seven_seg(3'b100, 8'b11101111, 8'h99, "seven segment digit 4 4");
        expect_seven_seg(3'b101, 8'b11011111, 8'hB0, "seven segment digit 5 3");
        expect_seven_seg(3'b110, 8'b10111111, 8'hA4, "seven segment digit 6 2");
        expect_seven_seg(3'b111, 8'b01111111, 8'hF9, "seven segment digit 7 1");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED errors=%0d", errors);
        end

        $finish;
    end
endmodule

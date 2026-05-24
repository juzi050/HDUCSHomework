`timescale 1ns / 1ps

//==============================================================================
// RAM_tb - RAM模块仿真测试平台 (RAM Testbench)
//==============================================================================
// 测试内容:
//   1. 读取预设初始值 (地址0)。
//   2. 写入并验证各MUX值对应的写数据。
//   3. 验证不同MUX值的LED输出字节选择。
//==============================================================================

module RAM_tb;

    reg [7:2] Mem_Addr;
    reg [1:0] MUX;
    reg Mem_Write;
    reg Clk;
    wire [7:0] LED;

    integer errors;

    RAM dut (
        .Mem_Addr(Mem_Addr),
        .MUX(MUX),
        .Mem_Write(Mem_Write),
        .Clk(Clk),
        .LED(LED)
    );

    // 时钟: 周期10ns
    always #5 Clk = ~Clk;

    // 读取地址任务: 设置地址, 等待读出
    task read_addr;
        input [5:0] addr;
        begin
            Mem_Addr = addr;
            Mem_Write = 1'b0;      // 读模式
            @(posedge Clk);
            #1;
        end
    endtask

    // LED 输出验证任务
    task expect_led;
        input [1:0] mux_value;
        input [7:0] expected;
        input [255:0] name;
        begin
            MUX = mux_value;
            #1;
            if (LED !== expected) begin
                $display("FAIL %-0s LED=%h expected=%h", name, LED, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s LED=%h", name, LED);
            end
        end
    endtask

    // 按MUX写入任务
    task write_word_by_mux;
        input [5:0] addr;
        input [1:0] mux_value;
        begin
            Mem_Addr = addr;
            MUX = mux_value;
            Mem_Write = 1'b1;      // 写模式
            @(posedge Clk);
            #1;
            Mem_Write = 1'b0;
            @(posedge Clk);
            #1;
        end
    endtask

    initial begin
        Clk = 1'b0;
        Mem_Addr = 6'd0;
        MUX = 2'b00;
        Mem_Write = 1'b0;
        errors = 0;

        repeat (2) @(posedge Clk);

        // 验证初始数据: 地址0读出32'h0000_0820
        read_addr(6'd0);
        expect_led(2'b00, 8'h20, "init word byte 0");  // 最低字节
        expect_led(2'b01, 8'h08, "init word byte 1");
        expect_led(2'b10, 8'h00, "init word byte 2");
        expect_led(2'b11, 8'h00, "init word byte 3");

        // MUX=00 写入: 0x0000000F
        write_word_by_mux(6'd63, 2'b00);
        expect_led(2'b00, 8'h0F, "write 0000000F byte 0");
        expect_led(2'b01, 8'h00, "write 0000000F byte 1");

        // MUX=01 写入: 0x00000DB0
        write_word_by_mux(6'd63, 2'b01);
        expect_led(2'b00, 8'hB0, "write 00000DB0 byte 0");
        expect_led(2'b01, 8'h0D, "write 00000DB0 byte 1");

        // MUX=10 写入: 0x003CC381
        write_word_by_mux(6'd63, 2'b10);
        expect_led(2'b00, 8'h81, "write 003CC381 byte 0");
        expect_led(2'b01, 8'hC3, "write 003CC381 byte 1");
        expect_led(2'b10, 8'h3C, "write 003CC381 byte 2");

        // MUX=11 写入: 0xFFFFFFFF
        write_word_by_mux(6'd63, 2'b11);
        expect_led(2'b00, 8'hFF, "write FFFFFFFF byte 0");
        expect_led(2'b01, 8'hFF, "write FFFFFFFF byte 1");
        expect_led(2'b10, 8'hFF, "write FFFFFFFF byte 2");
        expect_led(2'b11, 8'hFF, "write FFFFFFFF byte 3");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: RAM_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: RAM_tb errors=%0d", errors);
        end
    end

endmodule

`timescale 1ns / 1ps

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

    always #5 Clk = ~Clk;

    task read_addr;
        input [5:0] addr;
        begin
            Mem_Addr = addr;
            Mem_Write = 1'b0;
            @(posedge Clk);
            #1;
        end
    endtask

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

    task write_word_by_mux;
        input [5:0] addr;
        input [1:0] mux_value;
        begin
            Mem_Addr = addr;
            MUX = mux_value;
            Mem_Write = 1'b1;
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

        read_addr(6'd0);
        expect_led(2'b00, 8'h20, "init word byte 0");
        expect_led(2'b01, 8'h08, "init word byte 1");
        expect_led(2'b10, 8'h00, "init word byte 2");
        expect_led(2'b11, 8'h00, "init word byte 3");

        write_word_by_mux(6'd63, 2'b00);
        expect_led(2'b00, 8'h0F, "write 0000000F byte 0");
        expect_led(2'b01, 8'h00, "write 0000000F byte 1");

        write_word_by_mux(6'd63, 2'b01);
        expect_led(2'b00, 8'hB0, "write 00000DB0 byte 0");
        expect_led(2'b01, 8'h0D, "write 00000DB0 byte 1");

        write_word_by_mux(6'd63, 2'b10);
        expect_led(2'b00, 8'h81, "write 003CC381 byte 0");
        expect_led(2'b01, 8'hC3, "write 003CC381 byte 1");
        expect_led(2'b10, 8'h3C, "write 003CC381 byte 2");

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

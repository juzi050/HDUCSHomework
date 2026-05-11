`timescale 1ns / 1ps

module alu_tb;

    reg [3:0] alu_op;
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] f;
    wire zf;
    wire cf;
    wire of;
    wire sf;

    integer errors;

    alu dut (
        .alu_op(alu_op),
        .a(a),
        .b(b),
        .f(f),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    task check_case;
        input [3:0] op;
        input [31:0] in_a;
        input [31:0] in_b;
        input [31:0] exp_f;
        input exp_zf;
        input exp_cf;
        input exp_of;
        input exp_sf;
        input [255:0] name;
        begin
            alu_op = op;
            a = in_a;
            b = in_b;
            #1;

            if (f !== exp_f || zf !== exp_zf || cf !== exp_cf ||
                of !== exp_of || sf !== exp_sf) begin
                $display("FAIL %-0s f=%h/%h zf=%b/%b cf=%b/%b of=%b/%b sf=%b/%b",
                         name, f, exp_f, zf, exp_zf, cf, exp_cf, of, exp_of, sf, exp_sf);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s f=%h zf=%b cf=%b of=%b sf=%b",
                         name, f, zf, cf, of, sf);
            end
        end
    endtask

    initial begin
        errors = 0;
        alu_op = 4'd0;
        a = 32'd0;
        b = 32'd0;

        check_case(4'b0000, 32'h00000001, 32'h00000002, 32'h00000003, 1'b0, 1'b0, 1'b0, 1'b0, "add normal");
        check_case(4'b0000, 32'hFFFFFFFF, 32'h00000001, 32'h00000000, 1'b1, 1'b1, 1'b0, 1'b0, "add carry");
        check_case(4'b0000, 32'h7FFFFFFF, 32'h00000001, 32'h80000000, 1'b0, 1'b0, 1'b1, 1'b1, "add overflow");
        check_case(4'b0001, 32'h00000005, 32'h00000003, 32'h00000002, 1'b0, 1'b0, 1'b0, 1'b0, "sub normal");
        check_case(4'b0001, 32'h00000003, 32'h00000005, 32'hFFFFFFFE, 1'b0, 1'b1, 1'b0, 1'b1, "sub borrow");
        check_case(4'b0001, 32'h80000000, 32'h00000001, 32'h7FFFFFFF, 1'b0, 1'b0, 1'b1, 1'b0, "sub overflow");
        check_case(4'b0010, 32'hFFFF0000, 32'h0F0F0F0F, 32'h0F0F0000, 1'b0, 1'b0, 1'b0, 1'b0, "and");
        check_case(4'b0011, 32'h12345678, 32'h87654321, 32'h97755779, 1'b0, 1'b0, 1'b0, 1'b1, "or");
        check_case(4'b0100, 32'h12345678, 32'h87654321, 32'h95511559, 1'b0, 1'b0, 1'b0, 1'b1, "xor");
        check_case(4'b0101, 32'h80000001, 32'h00000000, 32'h00000002, 1'b0, 1'b0, 1'b0, 1'b0, "shift left one");
        check_case(4'b0110, 32'h80000001, 32'h00000000, 32'h40000000, 1'b0, 1'b0, 1'b0, 1'b0, "shift right one");
        check_case(4'b0111, 32'h00000000, 32'hFFFFFFFF, 32'hFFFFFFFF, 1'b0, 1'b0, 1'b0, 1'b1, "not");
        check_case(4'b1000, 32'hAAAAAAAA, 32'h55555555, 32'h00000000, 1'b1, 1'b0, 1'b0, 1'b0, "default op");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: alu_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: alu_tb errors=%0d", errors);
        end
    end

endmodule

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

    task check;
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

            if (f !== exp_f || zf !== exp_zf || cf !== exp_cf || of !== exp_of || sf !== exp_sf) begin
                $display("FAIL %-0s f=%h zf=%b cf=%b of=%b sf=%b expected f=%h zf=%b cf=%b of=%b sf=%b",
                         name, f, zf, cf, of, sf, exp_f, exp_zf, exp_cf, exp_of, exp_sf);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s f=%h", name, f);
            end
        end
    endtask

    initial begin
        errors = 0;
        alu_op = 4'd0;
        a = 32'd0;
        b = 32'd0;

        check(4'b0000, 32'h7fff_ffff, 32'h0000_0001, 32'h8000_0000, 1'b0, 1'b0, 1'b1, 1'b1, "add overflow");
        check(4'b0001, 32'h0000_0000, 32'h0000_0001, 32'hffff_ffff, 1'b0, 1'b1, 1'b0, 1'b1, "sub borrow");
        check(4'b0010, 32'hffff_f876, 32'h0000_0004, 32'hffff_8760, 1'b0, 1'b0, 1'b0, 1'b1, "sll");
        check(4'b0011, 32'hffff_f876, 32'h0000_0004, 32'h0000_0001, 1'b0, 1'b0, 1'b0, 1'b0, "slt");
        check(4'b0100, 32'hffff_f876, 32'h0000_0004, 32'h0000_0000, 1'b1, 1'b0, 1'b0, 1'b0, "sltu");
        check(4'b0101, 32'hffff_8760, 32'h0fff_ff87, 32'hf000_78e7, 1'b0, 1'b0, 1'b0, 1'b1, "xor");
        check(4'b0110, 32'hffff_f876, 32'h0000_0004, 32'h0fff_ff87, 1'b0, 1'b0, 1'b0, 1'b0, "srl");
        check(4'b0111, 32'hffff_f876, 32'h0000_0004, 32'hffff_ff87, 1'b0, 1'b0, 1'b0, 1'b1, "sra");
        check(4'b1000, 32'hffff_8760, 32'h0fff_ff87, 32'hffff_ffe7, 1'b0, 1'b0, 1'b0, 1'b1, "or");
        check(4'b1001, 32'hffff_8760, 32'h0fff_ff87, 32'h0fff_8700, 1'b0, 1'b0, 1'b0, 1'b0, "and");
        check(4'b1010, 32'h1234_5678, 32'h8000_0000, 32'h8000_0000, 1'b0, 1'b0, 1'b0, 1'b1, "pass b");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: alu_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: alu_tb errors=%0d", errors);
        end
    end

endmodule

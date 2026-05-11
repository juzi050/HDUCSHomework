`timescale 1ns / 1ps

module id2_tb;

    reg [31:0] instr;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire is_r;
    wire is_imm;
    wire is_lui;
    wire [3:0] alu_op;

    integer errors;

    assign opcode = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    id2 dut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .is_r(is_r),
        .is_imm(is_imm),
        .is_lui(is_lui),
        .alu_op(alu_op)
    );

    task check;
        input [31:0] in_instr;
        input exp_r;
        input exp_imm;
        input exp_lui;
        input [3:0] exp_alu_op;
        input [255:0] name;
        begin
            instr = in_instr;
            #1;

            if (is_r !== exp_r || is_imm !== exp_imm || is_lui !== exp_lui || alu_op !== exp_alu_op) begin
                $display("FAIL %-0s r=%b imm=%b lui=%b alu=%b expected r=%b imm=%b lui=%b alu=%b",
                         name, is_r, is_imm, is_lui, alu_op, exp_r, exp_imm, exp_lui, exp_alu_op);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s alu=%b", name, alu_op);
            end
        end
    endtask

    initial begin
        errors = 0;
        instr = 32'h0000_0000;

        check(32'h0020_81b3, 1'b1, 1'b0, 1'b0, 4'b0000, "add");
        check(32'h4020_8233, 1'b1, 1'b0, 1'b0, 4'b0001, "sub");
        check(32'h0020_92b3, 1'b1, 1'b0, 1'b0, 4'b0010, "sll");
        check(32'h0020_a433, 1'b1, 1'b0, 1'b0, 4'b0011, "slt");
        check(32'h0020_b4b3, 1'b1, 1'b0, 1'b0, 4'b0100, "sltu");
        check(32'h0062_c633, 1'b1, 1'b0, 1'b0, 4'b0101, "xor");
        check(32'h0020_d333, 1'b1, 1'b0, 1'b0, 4'b0110, "srl");
        check(32'h4020_d3b3, 1'b1, 1'b0, 1'b0, 4'b0111, "sra");
        check(32'h0062_e5b3, 1'b1, 1'b0, 1'b0, 4'b1000, "or");
        check(32'h0062_f533, 1'b1, 1'b0, 1'b0, 4'b1001, "and");

        check(32'h8760_0093, 1'b0, 1'b1, 1'b0, 4'b0000, "addi negative");
        check(32'h0037_9813, 1'b0, 1'b1, 1'b0, 4'b0010, "slli");
        check(32'hfff9_2993, 1'b0, 1'b1, 1'b0, 4'b0011, "slti");
        check(32'hfff9_3a13, 1'b0, 1'b1, 1'b0, 4'b0100, "sltiu");
        check(32'hfffc_4c93, 1'b0, 1'b1, 1'b0, 4'b0101, "xori");
        check(32'h0037_d893, 1'b0, 1'b1, 1'b0, 4'b0110, "srli");
        check(32'h4037_d913, 1'b0, 1'b1, 1'b0, 4'b0111, "srai");
        check(32'h0ff6_6b93, 1'b0, 1'b1, 1'b0, 4'b1000, "ori");
        check(32'h0ff6_7b93, 1'b0, 1'b1, 1'b0, 4'b1001, "andi");
        check(32'h8000_06b7, 1'b0, 1'b0, 1'b1, 4'b1010, "lui");

        check(32'h0000_0000, 1'b0, 1'b0, 1'b0, 4'b0000, "invalid");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: id2_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: id2_tb errors=%0d", errors);
        end
    end

endmodule

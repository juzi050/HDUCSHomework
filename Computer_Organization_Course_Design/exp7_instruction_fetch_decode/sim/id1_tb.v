`timescale 1ns / 1ps

//==============================================================================
// id1_tb - 指令译码测试平台 (Instruction Decode Testbench)
//==============================================================================
// 测试内容: 验证所有RISC-V指令格式的译码字段提取和立即数生成。
//   指令类型: LUI, AUIPC, ADDI, LW, ADD, SW, BEQ, JAL
//==============================================================================

module id1_tb;

    reg [31:0] instr;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;
    wire [31:0] imm32;

    integer errors;

    id1 dut (
        .instr(instr),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm32(imm32)
    );

    // 值比较验证任务
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

    // 完整指令检查任务: 验证所有译码字段和立即数
    task check_instr;
        input [31:0] instruction;
        input [31:0] expected_imm;
        input [255:0] name;
        begin
            instr = instruction;
            #1;
            expect_equal({25'd0, opcode}, {25'd0, instruction[6:0]}, {name, " opcode"});
            expect_equal({27'd0, rd}, {27'd0, instruction[11:7]}, {name, " rd"});
            expect_equal({29'd0, funct3}, {29'd0, instruction[14:12]}, {name, " funct3"});
            expect_equal({27'd0, rs1}, {27'd0, instruction[19:15]}, {name, " rs1"});
            expect_equal({27'd0, rs2}, {27'd0, instruction[24:20]}, {name, " rs2"});
            expect_equal({25'd0, funct7}, {25'd0, instruction[31:25]}, {name, " funct7"});
            expect_equal(imm32, expected_imm, {name, " imm32"});
        end
    endtask

    initial begin
        instr = 32'h0000_0000;
        errors = 0;

        // 测试各种指令格式的译码
        check_instr(32'h1234_50b7, 32'h1234_5000, "lui");     // U-type
        check_instr(32'h0001_0117, 32'h0001_0000, "auipc");   // U-type
        check_instr(32'hfff0_0193, 32'hffff_ffff, "addi -1"); // I-type (负立即数)
        check_instr(32'h0100_a203, 32'h0000_0010, "lw 16");   // I-type (load)
        check_instr(32'h0041_82b3, 32'h0000_0000, "add");     // R-type (无立即数)
        check_instr(32'h0050_aa23, 32'h0000_0014, "sw 20");   // S-type
        check_instr(32'h0002_8463, 32'h0000_0008, "beq 8");   // B-type
        check_instr(32'h0060_0313, 32'h0000_0006, "addi 6");  // I-type
        check_instr(32'hff1f_f3ef, 32'hffff_fff0, "jal -16"); // J-type (负跳转)

        if (errors == 0) begin
            $display("ALL TESTS PASSED: id1_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: id1_tb errors=%0d", errors);
        end
    end

endmodule

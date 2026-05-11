`timescale 1ns / 1ps

module riu_cpu_tb;

    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
    localparam S6 = 3'b110;

    reg clk;
    reg rst_n;
    reg step_en;
    wire [31:0] pc;
    wire [31:0] ir;
    wire [31:0] w_data;
    wire [2:0] st;
    wire zf;
    wire cf;
    wire of;
    wire sf;

    reg [31:0] instr_mem [0:26];
    reg [31:0] expected_wdata [0:26];
    reg [2:0] expected_exec_st [0:26];
    reg [4:0] expected_rd [0:26];
    integer errors;
    integer i;

    riu_cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .step_en(step_en),
        .pc(pc),
        .ir(ir),
        .w_data(w_data),
        .st(st),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    always #5 clk = ~clk;

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

    task expect_state;
        input [2:0] actual;
        input [2:0] expected;
        input [255:0] name;
        begin
            if (actual !== expected) begin
                $display("FAIL %-0s actual=%b expected=%b", name, actual, expected);
                errors = errors + 1;
            end else begin
                $display("PASS %-0s state=%b", name, actual);
            end
        end
    endtask

    task run_instruction;
        input integer idx;
        begin
            expect_state(st, S1, "start S1");

            @(posedge clk);
            #1;
            expect_state(st, S2, "after fetch S2");
            expect_equal(ir, instr_mem[idx], "fetched IR");
            expect_equal(pc, 32'd4 * (idx + 1), "PC after fetch");

            @(posedge clk);
            #1;
            expect_state(st, expected_exec_st[idx], "execute state");

            @(posedge clk);
            #1;
            expect_state(st, S4, "writeback state");
            expect_equal(w_data, expected_wdata[idx], "W_Data");

            @(posedge clk);
            #1;
            expect_state(st, S1, "back to S1");
            expect_equal(dut.u_regs.regs[expected_rd[idx]], expected_wdata[idx], "register writeback");
        end
    endtask

    initial begin
        instr_mem[0]  = 32'h8760_0093; expected_wdata[0]  = 32'hffff_f876; expected_exec_st[0]  = S5; expected_rd[0]  = 5'd1;
        instr_mem[1]  = 32'h0040_0113; expected_wdata[1]  = 32'h0000_0004; expected_exec_st[1]  = S5; expected_rd[1]  = 5'd2;
        instr_mem[2]  = 32'h0020_81b3; expected_wdata[2]  = 32'hffff_f87a; expected_exec_st[2]  = S3; expected_rd[2]  = 5'd3;
        instr_mem[3]  = 32'h4020_8233; expected_wdata[3]  = 32'hffff_f872; expected_exec_st[3]  = S3; expected_rd[3]  = 5'd4;
        instr_mem[4]  = 32'h0020_92b3; expected_wdata[4]  = 32'hffff_8760; expected_exec_st[4]  = S3; expected_rd[4]  = 5'd5;
        instr_mem[5]  = 32'h0020_d333; expected_wdata[5]  = 32'h0fff_ff87; expected_exec_st[5]  = S3; expected_rd[5]  = 5'd6;
        instr_mem[6]  = 32'h4020_d3b3; expected_wdata[6]  = 32'hffff_ff87; expected_exec_st[6]  = S3; expected_rd[6]  = 5'd7;
        instr_mem[7]  = 32'h0020_a433; expected_wdata[7]  = 32'h0000_0001; expected_exec_st[7]  = S3; expected_rd[7]  = 5'd8;
        instr_mem[8]  = 32'h0020_b4b3; expected_wdata[8]  = 32'h0000_0000; expected_exec_st[8]  = S3; expected_rd[8]  = 5'd9;
        instr_mem[9]  = 32'h0062_f533; expected_wdata[9]  = 32'h0fff_8700; expected_exec_st[9]  = S3; expected_rd[9]  = 5'd10;
        instr_mem[10] = 32'h0062_e5b3; expected_wdata[10] = 32'hffff_ffe7; expected_exec_st[10] = S3; expected_rd[10] = 5'd11;
        instr_mem[11] = 32'h0062_c633; expected_wdata[11] = 32'hf000_78e7; expected_exec_st[11] = S3; expected_rd[11] = 5'd12;
        instr_mem[12] = 32'h8000_06b7; expected_wdata[12] = 32'h8000_0000; expected_exec_st[12] = S6; expected_rd[12] = 5'd13;
        instr_mem[13] = 32'hfff6_8713; expected_wdata[13] = 32'h7fff_ffff; expected_exec_st[13] = S5; expected_rd[13] = 5'd14;
        instr_mem[14] = 32'h1237_0793; expected_wdata[14] = 32'h8000_0122; expected_exec_st[14] = S5; expected_rd[14] = 5'd15;
        instr_mem[15] = 32'h0037_9813; expected_wdata[15] = 32'h0000_0910; expected_exec_st[15] = S5; expected_rd[15] = 5'd16;
        instr_mem[16] = 32'h0037_d893; expected_wdata[16] = 32'h1000_0024; expected_exec_st[16] = S5; expected_rd[16] = 5'd17;
        instr_mem[17] = 32'h4037_d913; expected_wdata[17] = 32'hf000_0024; expected_exec_st[17] = S5; expected_rd[17] = 5'd18;
        instr_mem[18] = 32'hfff9_2993; expected_wdata[18] = 32'h0000_0001; expected_exec_st[18] = S5; expected_rd[18] = 5'd19;
        instr_mem[19] = 32'hfff9_3a13; expected_wdata[19] = 32'h0000_0001; expected_exec_st[19] = S5; expected_rd[19] = 5'd20;
        instr_mem[20] = 32'h0019_2a93; expected_wdata[20] = 32'h0000_0001; expected_exec_st[20] = S5; expected_rd[20] = 5'd21;
        instr_mem[21] = 32'h0019_3b13; expected_wdata[21] = 32'h0000_0000; expected_exec_st[21] = S5; expected_rd[21] = 5'd22;
        instr_mem[22] = 32'h0ff6_7b93; expected_wdata[22] = 32'h0000_00e7; expected_exec_st[22] = S5; expected_rd[22] = 5'd23;
        instr_mem[23] = 32'h0ff6_6b93; expected_wdata[23] = 32'hf000_78ff; expected_exec_st[23] = S5; expected_rd[23] = 5'd23;
        instr_mem[24] = 32'h0001_0c37; expected_wdata[24] = 32'h0001_0000; expected_exec_st[24] = S6; expected_rd[24] = 5'd24;
        instr_mem[25] = 32'hfffc_0c13; expected_wdata[25] = 32'h0000_ffff; expected_exec_st[25] = S5; expected_rd[25] = 5'd24;
        instr_mem[26] = 32'hfffc_4c93; expected_wdata[26] = 32'hffff_0000; expected_exec_st[26] = S5; expected_rd[26] = 5'd25;
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        step_en = 1'b0;
        errors = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        #1;
        expect_state(st, S1, "reset state");
        expect_equal(pc, 32'h0000_0000, "reset PC");
        expect_equal(ir, 32'h0000_0000, "reset IR");
        step_en = 1'b1;

        for (i = 0; i < 27; i = i + 1) begin
            $display("---- instruction %0d ----", i + 1);
            run_instruction(i);
        end

        expect_equal(dut.u_regs.regs[1],  32'hffff_f876, "final x1");
        expect_equal(dut.u_regs.regs[2],  32'h0000_0004, "final x2");
        expect_equal(dut.u_regs.regs[3],  32'hffff_f87a, "final x3");
        expect_equal(dut.u_regs.regs[4],  32'hffff_f872, "final x4");
        expect_equal(dut.u_regs.regs[5],  32'hffff_8760, "final x5");
        expect_equal(dut.u_regs.regs[6],  32'h0fff_ff87, "final x6");
        expect_equal(dut.u_regs.regs[7],  32'hffff_ff87, "final x7");
        expect_equal(dut.u_regs.regs[8],  32'h0000_0001, "final x8");
        expect_equal(dut.u_regs.regs[9],  32'h0000_0000, "final x9");
        expect_equal(dut.u_regs.regs[10], 32'h0fff_8700, "final x10");
        expect_equal(dut.u_regs.regs[11], 32'hffff_ffe7, "final x11");
        expect_equal(dut.u_regs.regs[12], 32'hf000_78e7, "final x12");
        expect_equal(dut.u_regs.regs[13], 32'h8000_0000, "final x13");
        expect_equal(dut.u_regs.regs[14], 32'h7fff_ffff, "final x14");
        expect_equal(dut.u_regs.regs[15], 32'h8000_0122, "final x15");
        expect_equal(dut.u_regs.regs[16], 32'h0000_0910, "final x16");
        expect_equal(dut.u_regs.regs[17], 32'h1000_0024, "final x17");
        expect_equal(dut.u_regs.regs[18], 32'hf000_0024, "final x18");
        expect_equal(dut.u_regs.regs[19], 32'h0000_0001, "final x19");
        expect_equal(dut.u_regs.regs[20], 32'h0000_0001, "final x20");
        expect_equal(dut.u_regs.regs[21], 32'h0000_0001, "final x21");
        expect_equal(dut.u_regs.regs[22], 32'h0000_0000, "final x22");
        expect_equal(dut.u_regs.regs[23], 32'hf000_78ff, "final x23");
        expect_equal(dut.u_regs.regs[24], 32'h0000_ffff, "final x24");
        expect_equal(dut.u_regs.regs[25], 32'hffff_0000, "final x25");

        if (errors == 0) begin
            $display("ALL TESTS PASSED: riu_cpu_tb");
            $finish;
        end else begin
            $fatal(1, "TESTS FAILED: riu_cpu_tb errors=%0d", errors);
        end
    end

endmodule

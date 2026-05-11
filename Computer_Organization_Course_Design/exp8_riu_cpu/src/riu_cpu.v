`timescale 1ns / 1ps

module riu_cpu(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        step_en,
    output wire [31:0] pc,
    output wire [31:0] ir,
    output wire [31:0] w_data,
    output wire [2:0]  st,
    output wire        zf,
    output wire        cf,
    output wire        of,
    output wire        sf
);

    wire [31:0] im_instruction;
    wire [6:0]  opcode;
    wire [4:0]  rd;
    wire [2:0]  funct3;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [6:0]  funct7;
    wire [31:0] imm32;

    wire        is_r;
    wire        is_imm;
    wire        is_lui;
    wire [3:0]  alu_op;
    wire        pc_write;
    wire        ir_write;
    wire        ab_write;
    wire        f_write;
    wire        reg_write;
    wire        rs2_imm_s;

    wire [31:0] r_data_a;
    wire [31:0] r_data_b;
    wire [31:0] a_latch;
    wire [31:0] b_latch;
    wire [31:0] f_latch;
    wire [31:0] alu_b;
    wire [31:0] alu_f;

    if_stage u_if_stage (
        .clk(clk),
        .rst_n(rst_n),
        .PC_Write(pc_write),
        .IR_Write(ir_write),
        .PC(pc),
        .IR(ir),
        .im_instruction(im_instruction)
    );

    id1 u_id1 (
        .instr(ir),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7),
        .imm32(imm32)
    );

    id2 u_id2 (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .is_r(is_r),
        .is_imm(is_imm),
        .is_lui(is_lui),
        .alu_op(alu_op)
    );

    cu u_cu (
        .clk(clk),
        .rst_n(rst_n),
        .step_en(step_en),
        .is_r(is_r),
        .is_imm(is_imm),
        .is_lui(is_lui),
        .st(st),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .ab_write(ab_write),
        .f_write(f_write),
        .reg_write(reg_write),
        .rs2_imm_s(rs2_imm_s)
    );

    regs u_regs (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .r_addr_a(rs1),
        .r_addr_b(rs2),
        .w_addr(rd),
        .w_data(w_data),
        .r_data_a(r_data_a),
        .r_data_b(r_data_b)
    );

    assign alu_b = rs2_imm_s ? imm32 : b_latch;

    alu u_alu (
        .alu_op(alu_op),
        .a(a_latch),
        .b(alu_b),
        .f(alu_f),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    abf_latch u_abf_latch (
        .clk(clk),
        .rst_n(rst_n),
        .ab_write(ab_write),
        .f_write(f_write),
        .a_in(r_data_a),
        .b_in(r_data_b),
        .f_in(alu_f),
        .a(a_latch),
        .b(b_latch),
        .f(f_latch)
    );

    assign w_data = f_latch;

endmodule

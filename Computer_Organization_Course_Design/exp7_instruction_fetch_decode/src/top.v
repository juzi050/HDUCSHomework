`timescale 1ns / 1ps

module top(
    input  wire        clk100mhz,
    input  wire [35:0] sw,
    input  wire [7:0]  bt,
    output wire [35:0] ld,
    output wire        traffic_we_r,
    output wire        traffic_we_y,
    output wire        traffic_we_g,
    output wire        traffic_sn_r,
    output wire        traffic_sn_y,
    output wire        traffic_sn_g,
    output wire [7:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);

    reg bt0_d = 1'b0;
    reg [31:0] display_value;

    wire rst_n;
    wire step_pulse;
    wire pc_write_pulse;
    wire ir_write_pulse;
    wire [31:0] pc;
    wire [31:0] ir;
    wire [31:0] im_instruction;
    wire [31:0] imm32;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign rst_n = ~bt[1];
    assign step_pulse = bt[0] & ~bt0_d;
    assign pc_write_pulse = step_pulse & sw[0];
    assign ir_write_pulse = step_pulse & sw[1];

    always @(posedge clk100mhz) begin
        if (!rst_n) begin
            bt0_d <= 1'b0;
        end else begin
            bt0_d <= bt[0];
        end
    end

    if_stage u_if_stage (
        .clk(clk100mhz),
        .rst_n(rst_n),
        .PC_Write(pc_write_pulse),
        .IR_Write(ir_write_pulse),
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

    always @(*) begin
        case (sw[3:2])
            2'b00: display_value = imm32;
            2'b01: display_value = ir;
            2'b10: display_value = pc;
            2'b11: display_value = im_instruction;
            default: display_value = imm32;
        endcase
    end

    assign ld = {4'd0, funct7, funct3, opcode, rd, rs2, rs1};

    assign traffic_we_r = 1'b0;
    assign traffic_we_y = 1'b0;
    assign traffic_we_g = 1'b0;
    assign traffic_sn_r = 1'b0;
    assign traffic_sn_y = 1'b0;
    assign traffic_sn_g = 1'b0;

    seven_seg_display u_display (
        .clk(clk100mhz),
        .value(display_value),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

endmodule

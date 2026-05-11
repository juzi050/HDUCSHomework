`timescale 1ns / 1ps

module cu(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       step_en,
    input  wire       is_r,
    input  wire       is_imm,
    input  wire       is_lui,
    output reg  [2:0] st,
    output wire       pc_write,
    output wire       ir_write,
    output wire       ab_write,
    output wire       f_write,
    output wire       reg_write,
    output wire       rs2_imm_s
);

    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;
    localparam S6 = 3'b110;

    reg [2:0] next_st;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st <= S1;
        end else if (step_en) begin
            st <= next_st;
        end
    end

    always @(*) begin
        case (st)
            S1: next_st = S2;
            S2: begin
                if (is_r) begin
                    next_st = S3;
                end else if (is_imm) begin
                    next_st = S5;
                end else if (is_lui) begin
                    next_st = S6;
                end else begin
                    next_st = S1;
                end
            end
            S3: next_st = S4;
            S5: next_st = S4;
            S6: next_st = S4;
            S4: next_st = S1;
            default: next_st = S1;
        endcase
    end

    assign pc_write  = step_en && (st == S1);
    assign ir_write  = step_en && (st == S1);
    assign ab_write  = step_en && (st == S2);
    assign f_write   = step_en && ((st == S3) || (st == S5) || (st == S6));
    assign reg_write = step_en && (st == S4);
    assign rs2_imm_s = (st == S5) || (st == S6);

endmodule

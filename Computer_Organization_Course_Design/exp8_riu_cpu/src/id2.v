`timescale 1ns / 1ps

module id2(
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        is_r,
    output reg        is_imm,
    output reg        is_lui,
    output reg  [3:0] alu_op
);

    localparam OPC_R      = 7'b0110011;
    localparam OPC_IMM    = 7'b0010011;
    localparam OPC_LUI    = 7'b0110111;

    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_PASSB  = 4'b1010;

    always @(*) begin
        is_r = 1'b0;
        is_imm = 1'b0;
        is_lui = 1'b0;
        alu_op = ALU_ADD;

        case (opcode)
            OPC_R: begin
                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: begin is_r = 1'b1; alu_op = ALU_ADD; end
                    {7'b0100000, 3'b000}: begin is_r = 1'b1; alu_op = ALU_SUB; end
                    {7'b0000000, 3'b001}: begin is_r = 1'b1; alu_op = ALU_SLL; end
                    {7'b0000000, 3'b010}: begin is_r = 1'b1; alu_op = ALU_SLT; end
                    {7'b0000000, 3'b011}: begin is_r = 1'b1; alu_op = ALU_SLTU; end
                    {7'b0000000, 3'b100}: begin is_r = 1'b1; alu_op = ALU_XOR; end
                    {7'b0000000, 3'b101}: begin is_r = 1'b1; alu_op = ALU_SRL; end
                    {7'b0100000, 3'b101}: begin is_r = 1'b1; alu_op = ALU_SRA; end
                    {7'b0000000, 3'b110}: begin is_r = 1'b1; alu_op = ALU_OR; end
                    {7'b0000000, 3'b111}: begin is_r = 1'b1; alu_op = ALU_AND; end
                    default: begin is_r = 1'b0; alu_op = ALU_ADD; end
                endcase
            end

            OPC_IMM: begin
                case (funct3)
                    3'b000: begin is_imm = 1'b1; alu_op = ALU_ADD; end
                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SLL;
                        end
                    end
                    3'b010: begin is_imm = 1'b1; alu_op = ALU_SLT; end
                    3'b011: begin is_imm = 1'b1; alu_op = ALU_SLTU; end
                    3'b100: begin is_imm = 1'b1; alu_op = ALU_XOR; end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SRL;
                        end else if (funct7 == 7'b0100000) begin
                            is_imm = 1'b1;
                            alu_op = ALU_SRA;
                        end
                    end
                    3'b110: begin is_imm = 1'b1; alu_op = ALU_OR; end
                    3'b111: begin is_imm = 1'b1; alu_op = ALU_AND; end
                    default: begin is_imm = 1'b0; alu_op = ALU_ADD; end
                endcase
            end

            OPC_LUI: begin
                is_lui = 1'b1;
                alu_op = ALU_PASSB;
            end

            default: begin
                is_r = 1'b0;
                is_imm = 1'b0;
                is_lui = 1'b0;
                alu_op = ALU_ADD;
            end
        endcase
    end

endmodule

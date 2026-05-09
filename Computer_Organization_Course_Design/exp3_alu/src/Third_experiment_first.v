`timescale 1ns / 1ps

module Third_experiment_first (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [2:0]  ALU_OP,
    output reg  [31:0] F,
    output wire        ZF,
    output reg         OF
);
    reg  [32:0] add_result;
    reg  [31:0] add_b;
    reg         add_cin;
    wire        add_c32;

    assign add_c32 = add_result[32];
    assign ZF = (F == 32'b0);

    always @(*) begin
        add_b = B;
        add_cin = 1'b0;

        case (ALU_OP)
            3'b101: begin
                add_b = ~B;
                add_cin = 1'b1;
            end
            default: begin
                add_b = B;
                add_cin = 1'b0;
            end
        endcase
    end

    always @(*) begin
        add_result = {1'b0, A} + {1'b0, add_b} + add_cin;
        F = 32'b0;
        OF = 1'b0;

        case (ALU_OP)
            3'b000: F = A & B;
            3'b001: F = A | B;
            3'b010: F = A ^ B;
            3'b011: F = ~(A ^ B);
            3'b100: begin
                F = add_result[31:0];
                OF = add_c32 ^ F[31] ^ A[31] ^ add_b[31];
            end
            3'b101: begin
                F = add_result[31:0];
                OF = add_c32 ^ F[31] ^ A[31] ^ add_b[31];
            end
            3'b110: F = ($signed(A) < $signed(B)) ? 32'h00000001 : 32'h00000000;
            3'b111: F = B << A[4:0];
            default: F = 32'b0;
        endcase
    end
endmodule

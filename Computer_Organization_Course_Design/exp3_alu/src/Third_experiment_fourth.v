`timescale 1ns / 1ps

module Third_experiment_fourth (
    input  wire        clk,
    input  wire [31:0] F,
    output reg  [7:0]  AN,
    output reg  [7:0]  SEG
);
    reg [16:0] refresh_count;
    reg [3:0]  hex_digit;
    wire [2:0] digit_select;

    assign digit_select = refresh_count[16:14];

    initial begin
        refresh_count = 17'b0;
    end

    always @(posedge clk) begin
        refresh_count <= refresh_count + 1'b1;
    end

    always @(*) begin
        case (digit_select)
            3'b000: begin AN = 8'b11111110; hex_digit = F[3:0]; end
            3'b001: begin AN = 8'b11111101; hex_digit = F[7:4]; end
            3'b010: begin AN = 8'b11111011; hex_digit = F[11:8]; end
            3'b011: begin AN = 8'b11110111; hex_digit = F[15:12]; end
            3'b100: begin AN = 8'b11101111; hex_digit = F[19:16]; end
            3'b101: begin AN = 8'b11011111; hex_digit = F[23:20]; end
            3'b110: begin AN = 8'b10111111; hex_digit = F[27:24]; end
            3'b111: begin AN = 8'b01111111; hex_digit = F[31:28]; end
            default: begin AN = 8'b11111111; hex_digit = 4'h0; end
        endcase
    end

    always @(*) begin
        case (hex_digit)
            4'h0: SEG = 8'hC0;
            4'h1: SEG = 8'hF9;
            4'h2: SEG = 8'hA4;
            4'h3: SEG = 8'hB0;
            4'h4: SEG = 8'h99;
            4'h5: SEG = 8'h92;
            4'h6: SEG = 8'h82;
            4'h7: SEG = 8'hF8;
            4'h8: SEG = 8'h80;
            4'h9: SEG = 8'h90;
            4'hA: SEG = 8'h88;
            4'hB: SEG = 8'h83;
            4'hC: SEG = 8'hC6;
            4'hD: SEG = 8'hA1;
            4'hE: SEG = 8'h86;
            4'hF: SEG = 8'h8E;
            default: SEG = 8'hFF;
        endcase
    end
endmodule

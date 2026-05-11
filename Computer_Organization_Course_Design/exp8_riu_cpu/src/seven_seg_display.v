`timescale 1ns / 1ps

module seven_seg_display(
    input  wire        clk,
    input  wire [31:0] value,
    output reg  [7:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);

    reg [16:0] scan_div = 17'd0;
    reg [3:0] current_hex;
    wire [2:0] scan_digit;

    assign scan_digit = scan_div[16:14];
    assign dp = 1'b1;

    always @(posedge clk) begin
        scan_div <= scan_div + 17'd1;
    end

    always @(*) begin
        an = 8'b1111_1111;
        current_hex = 4'h0;

        case (scan_digit)
            3'd0: begin an = 8'b1111_1110; current_hex = value[3:0]; end
            3'd1: begin an = 8'b1111_1101; current_hex = value[7:4]; end
            3'd2: begin an = 8'b1111_1011; current_hex = value[11:8]; end
            3'd3: begin an = 8'b1111_0111; current_hex = value[15:12]; end
            3'd4: begin an = 8'b1110_1111; current_hex = value[19:16]; end
            3'd5: begin an = 8'b1101_1111; current_hex = value[23:20]; end
            3'd6: begin an = 8'b1011_1111; current_hex = value[27:24]; end
            3'd7: begin an = 8'b0111_1111; current_hex = value[31:28]; end
            default: begin an = 8'b1111_1111; current_hex = 4'h0; end
        endcase
    end

    seven_seg_hex u_seven_seg_hex (
        .hex(current_hex),
        .seg(seg)
    );

endmodule

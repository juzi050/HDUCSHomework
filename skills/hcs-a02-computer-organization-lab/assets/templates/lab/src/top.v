`timescale 1ns / 1ps

module __MODULE_NAME__(
    input wire clk100mhz,
    input wire [35:0] sw,
    input wire [7:0] bt,
    output wire [35:0] ld,
    output wire traffic_we_r,
    output wire traffic_we_y,
    output wire traffic_we_g,
    output wire traffic_sn_r,
    output wire traffic_sn_y,
    output wire traffic_sn_g,
    output reg [7:0] an,
    output wire [6:0] seg,
    output wire dp
);

    reg [16:0] scan_div = 17'd0;
    reg [3:0] current_hex = 4'h0;

    wire [2:0] scan_digit = scan_div[16:14];

    assign ld = sw;

    assign traffic_we_r = bt[7];
    assign traffic_we_y = bt[6];
    assign traffic_we_g = bt[5];
    assign traffic_sn_r = bt[4];
    assign traffic_sn_y = bt[3];
    assign traffic_sn_g = bt[2];

    assign dp = 1'b1;

    always @(posedge clk100mhz) begin
        scan_div <= scan_div + 17'd1;
    end

    always @(*) begin
        an = 8'b1111_1111;
        current_hex = 4'h0;

        case (scan_digit)
            3'd0: begin an = 8'b1111_1110; current_hex = sw[3:0]; end
            3'd1: begin an = 8'b1111_1101; current_hex = sw[7:4]; end
            3'd2: begin an = 8'b1111_1011; current_hex = sw[11:8]; end
            3'd3: begin an = 8'b1111_0111; current_hex = sw[15:12]; end
            3'd4: begin an = 8'b1110_1111; current_hex = sw[19:16]; end
            3'd5: begin an = 8'b1101_1111; current_hex = sw[23:20]; end
            3'd6: begin an = 8'b1011_1111; current_hex = sw[27:24]; end
            3'd7: begin an = 8'b0111_1111; current_hex = sw[31:28]; end
            default: begin an = 8'b1111_1111; current_hex = 4'h0; end
        endcase
    end

    seven_seg_hex u_seven_seg_hex (
        .hex(current_hex),
        .seg(seg)
    );

endmodule

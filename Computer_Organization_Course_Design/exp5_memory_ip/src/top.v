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
    reg [7:0] selected_byte;

    wire [31:0] read_word;
    wire write_pulse;

    assign write_pulse = bt[0] & ~bt0_d;

    always @(posedge clk100mhz) begin
        bt0_d <= bt[0];
    end

    memory_ip_core u_memory_ip_core (
        .Mem_Addr(sw[7:2]),
        .MUX(sw[1:0]),
        .Mem_Write(write_pulse),
        .Clk(clk100mhz),
        .M_R_Data(read_word)
    );

    always @(*) begin
        case (sw[1:0])
            2'b00: selected_byte = read_word[7:0];
            2'b01: selected_byte = read_word[15:8];
            2'b10: selected_byte = read_word[23:16];
            2'b11: selected_byte = read_word[31:24];
            default: selected_byte = 8'h00;
        endcase
    end

    assign ld = {20'd0, sw[1:0], sw[7:2], selected_byte};

    assign traffic_we_r = 1'b0;
    assign traffic_we_y = 1'b0;
    assign traffic_we_g = 1'b0;
    assign traffic_sn_r = 1'b0;
    assign traffic_sn_y = 1'b0;
    assign traffic_sn_g = 1'b0;

    seven_seg_display u_display (
        .clk(clk100mhz),
        .value(read_word),
        .an(an),
        .seg(seg),
        .dp(dp)
    );

endmodule

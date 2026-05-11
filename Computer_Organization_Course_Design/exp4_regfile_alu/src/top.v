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

    localparam DISPLAY_RESULT = 2'd0;
    localparam DISPLAY_A      = 2'd1;
    localparam DISPLAY_B      = 2'd2;

    reg [7:0] bt_d;
    reg [4:0] raddr_a;
    reg [4:0] raddr_b;
    reg [4:0] waddr;
    reg [1:0] display_mode;
    reg       wen_pulse;
    reg       write_from_alu;

    wire reset;
    wire [7:0] bt_rise;
    wire [31:0] rdata_a;
    wire [31:0] rdata_b;
    wire [31:0] result;
    wire [31:0] display_value;
    wire zf;
    wire cf;
    wire of;
    wire sf;

    assign reset = bt[7];
    assign bt_rise = bt & ~bt_d;

    always @(posedge clk100mhz or posedge reset) begin
        if (reset) begin
            bt_d <= 8'h00;
            raddr_a <= 5'd0;
            raddr_b <= 5'd0;
            waddr <= 5'd0;
            display_mode <= DISPLAY_RESULT;
            wen_pulse <= 1'b0;
            write_from_alu <= 1'b0;
        end else begin
            bt_d <= bt;
            wen_pulse <= 1'b0;
            write_from_alu <= 1'b0;

            if (bt_rise[0]) begin
                raddr_a <= sw[4:0];
            end

            if (bt_rise[1]) begin
                raddr_b <= sw[4:0];
            end

            if (bt_rise[2]) begin
                waddr <= sw[4:0];
            end

            if (bt_rise[3]) begin
                wen_pulse <= 1'b1;
                write_from_alu <= 1'b0;
            end else if (bt_rise[4]) begin
                wen_pulse <= 1'b1;
                write_from_alu <= 1'b1;
            end

            if (bt_rise[5]) begin
                display_mode <= (display_mode == DISPLAY_B) ? DISPLAY_RESULT : display_mode + 2'd1;
            end
        end
    end

    alu_reg u_alu_reg (
        .clk(clk100mhz),
        .rst(reset),
        .wen(wen_pulse),
        .write_from_alu(write_from_alu),
        .raddr_a(raddr_a),
        .raddr_b(raddr_b),
        .waddr(waddr),
        .wdata_ext(sw[31:0]),
        .alu_op(sw[35:32]),
        .rdata_a(rdata_a),
        .rdata_b(rdata_b),
        .result(result),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    assign display_value = (display_mode == DISPLAY_A) ? rdata_a :
                           (display_mode == DISPLAY_B) ? rdata_b :
                           result;

    assign ld[31:0] = display_value;
    assign ld[32] = zf;
    assign ld[33] = cf;
    assign ld[34] = of;
    assign ld[35] = sf;

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

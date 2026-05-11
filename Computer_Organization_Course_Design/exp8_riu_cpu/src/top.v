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
    wire step_en;
    wire [31:0] pc;
    wire [31:0] ir;
    wire [31:0] w_data;
    wire [2:0] st;
    wire zf;
    wire cf;
    wire of;
    wire sf;

    assign rst_n = ~bt[1];
    assign step_en = bt[0] & ~bt0_d;

    always @(posedge clk100mhz or negedge rst_n) begin
        if (!rst_n) begin
            bt0_d <= 1'b0;
        end else begin
            bt0_d <= bt[0];
        end
    end

    riu_cpu u_riu_cpu (
        .clk(clk100mhz),
        .rst_n(rst_n),
        .step_en(step_en),
        .pc(pc),
        .ir(ir),
        .w_data(w_data),
        .st(st),
        .zf(zf),
        .cf(cf),
        .of(of),
        .sf(sf)
    );

    always @(*) begin
        case (sw[2:0])
            3'b000: display_value = pc;
            3'b001: display_value = ir;
            3'b010: display_value = w_data;
            3'b011: display_value = {29'd0, st};
            3'b100: display_value = {28'd0, zf, cf, of, sf};
            default: display_value = w_data;
        endcase
    end

    assign ld[27:0] = w_data[27:0];
    assign ld[31:28] = {zf, cf, of, sf};
    assign ld[34:32] = st;
    assign ld[35] = step_en;

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

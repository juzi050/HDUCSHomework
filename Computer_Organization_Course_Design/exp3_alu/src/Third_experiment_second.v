`timescale 1ns / 1ps

module Third_experiment_second (
    input  wire        clk,
    input  wire [31:0] data_in,
    input  wire [3:0]  BT,
    output reg  [31:0] A,
    output reg  [31:0] B,
    output reg  [1:0]  display_mode
);
    localparam MODE_A = 2'b00;
    localparam MODE_B = 2'b01;
    localparam MODE_F = 2'b10;

    reg [3:0] bt_sync0;
    reg [3:0] bt_sync1;
    reg [3:0] bt_last;
    wire [3:0] bt_rise;

    assign bt_rise = bt_sync1 & ~bt_last;

    initial begin
        A = 32'b0;
        B = 32'b0;
        display_mode = MODE_F;
        bt_sync0 = 4'b0;
        bt_sync1 = 4'b0;
        bt_last = 4'b0;
    end

    always @(posedge clk) begin
        bt_sync0 <= BT;
        bt_sync1 <= bt_sync0;
        bt_last <= bt_sync1;

        if (bt_rise[2]) begin
            A <= 32'b0;
            B <= 32'b0;
            display_mode <= MODE_F;
        end else begin
            if (bt_rise[0]) begin
                A <= data_in;
            end

            if (bt_rise[1]) begin
                B <= data_in;
            end

            if (bt_rise[3]) begin
                case (display_mode)
                    MODE_F: display_mode <= MODE_A;
                    MODE_A: display_mode <= MODE_B;
                    default: display_mode <= MODE_F;
                endcase
            end
        end
    end
endmodule

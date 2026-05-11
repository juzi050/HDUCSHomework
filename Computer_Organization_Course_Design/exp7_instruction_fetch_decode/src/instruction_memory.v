`timescale 1ns / 1ps

module instruction_memory(
    input  wire        clk,
    input  wire [5:0]  addr,
    output wire [31:0] instruction
);

    IM_B u_im_b (
        .clka(clk),
        .addra(addr),
        .douta(instruction)
    );

endmodule

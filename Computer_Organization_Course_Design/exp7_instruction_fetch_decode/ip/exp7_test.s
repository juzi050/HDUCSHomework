    .option norvc
    .section .text
    .globl main

main:
    lui   x1, 0x12345
    auipc x2, 0x00010
    addi  x3, x0, -1
    lw    x4, 16(x1)
r_type:
    add   x5, x3, x4
    sw    x5, 20(x1)
    beq   x5, x0, branch_target
    addi  x6, x0, 6
branch_target:
    jal   x7, r_type

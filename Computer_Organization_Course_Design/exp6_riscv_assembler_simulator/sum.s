    .section .text
    .globl sum
    .globl main

sum:
    addi t0, zero, 0
    addi t1, zero, 0
sum_loop:
    blt  a0, t0, sum_done
    add  t1, t1, t0
    addi t0, t0, 1
    jal  zero, sum_loop
sum_done:
    add  a0, t1, zero
    jalr zero, 0(ra)

main:
    addi sp, sp, -16
    sw   ra, 12(sp)
    addi t0, zero, 100
    add  a0, t0, zero
    jal  ra, sum
    addi a0, zero, 0
    lw   ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)

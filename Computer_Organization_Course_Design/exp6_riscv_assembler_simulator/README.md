# 实验 6 RISC-V 汇编器与模拟器实验

本 README 记录实验 6 的环境搭建、源程序、汇编/反汇编命令和结果分析。实验目录为：

```text
D:\HDUCSHomework\Computer_Organization_Course_Design\exp6_riscv_assembler_simulator
```

本次按实操便利性选择 Ubuntu 22.04，而不是题面中的 Ubuntu 18.04。原因是 2026 年新装环境下 Ubuntu 22.04 的软件源和 RISC-V 工具链更容易稳定获取，实验目标仍然是 RV32I 汇编、机器码和模拟运行。

## 1. 环境搭建与 hello.c 验证

本机 VMware 程序位置：

```text
D:\VM\vmware.exe
```

新建虚拟机建议配置：

| 项目 | 配置 |
| --- | --- |
| 虚拟机目录 | `D:\虚拟机\Ubuntu_RISCV_22_04` |
| 系统镜像 | Ubuntu 22.04.5 LTS |
| 用户名 | `riscv` |
| 密码 | `Riscv@2026` |
| CPU/内存 | 2 核 / 4 GB 或以上 |
| 磁盘 | 40 GB 或以上 |

Ubuntu ISO 下载页：

```text
https://releases.ubuntu.com/releases/22.04.5/
```

进入 Ubuntu 后安装基础工具：

```bash
sudo apt update
sudo apt install -y qemu-user wget tar xz-utils ca-certificates build-essential
```

从 riscv-collab 下载 `riscv32-glibc-ubuntu-22.04-gcc.tar.xz`：

```text
https://github.com/riscv-collab/riscv-gnu-toolchain/releases
```

假设压缩包位于 `~/Downloads`，安装到 `/opt/riscv32`：

```bash
sudo mkdir -p /opt/riscv32
sudo tar -xf ~/Downloads/riscv32-glibc-ubuntu-22.04-gcc.tar.xz -C /opt/riscv32 --strip-components=1
```

配置课程同名命令 `gccrv32` 和 `runrv32`：

```bash
cat >> ~/.bashrc <<'EOF'
export RISCV32=/opt/riscv32
export PATH=$RISCV32/bin:$PATH

gccrv32() {
    riscv32-unknown-linux-gnu-gcc -static "$@"
}

runrv32() {
    qemu-riscv32 "$@"
}
EOF
source ~/.bashrc
```

验证工具链：

```bash
riscv32-unknown-linux-gnu-gcc --version
qemu-riscv32 --version
```

`hello.c`：

```c
#include <stdio.h>

int main(void) {
    printf("hello world\n");
    return 0;
}
```

编译并运行：

```bash
gccrv32 hello.c -o hello
runrv32 ./hello
```

预期输出：

```text
hello world
```

这说明 RISC-V 32 位交叉编译器、链接器和 QEMU 模拟器均可正常工作。

## 2. acc.s 汇编、反汇编与功能分析

`acc.s`：

```asm
main:
    add  t0,x0,  x0
    add  t1,x0,  x0
    addi t2,x0,  10
L1: lw   t3,0x40(t1)
    add  t0,t0,t3
    addi t1,t1,4
    addi t2,t2,-1
    beq  t2,x0,  L2
    j    L1
L2: sw   t0,  0x80(x0)
```

汇编与反汇编命令：

```bash
mkdir -p build dump
riscv32-unknown-linux-gnu-as -march=rv32i -mabi=ilp32 acc.s -o build/acc.o
riscv32-unknown-linux-gnu-ld -m elf32lriscv -Ttext=0x0 build/acc.o -o build/acc.elf
riscv32-unknown-linux-gnu-objdump -d -M no-aliases,numeric build/acc.elf > dump/acc.dump
```

核心反汇编结果：

```text
00000000 <main>:
   0: 000002b3    add  x5,x0,x0
   4: 00000333    add  x6,x0,x0
   8: 00a00393    addi x7,x0,10

0000000c <L1>:
   c: 04032e03    lw   x28,64(x6)
  10: 01c282b3    add  x5,x5,x28
  14: 00430313    addi x6,x6,4
  18: fff38393    addi x7,x7,-1
  1c: 00038463    beq  x7,x0,24 <L2>
  20: fedff06f    jal  x0,c <L1>

00000024 <L2>:
  24: 08502023    sw   x5,128(x0)
```

程序功能：

- `t0` 初始化为 0，用作累加和。
- `t1` 初始化为 0，用作数组偏移量。
- `t2` 初始化为 10，用作循环计数器。
- 每次循环从 `0x40 + t1` 读取一个 32 位字，加到 `t0`。
- 每次循环后 `t1 += 4`，`t2 -= 1`。
- 循环 10 次后，将累加和写入内存地址 `0x80`。

因此，该程序的功能是累加主存地址 `0x40` 到 `0x64` 之间连续 10 个 32 位数据，并把结果保存到 `0x80`。

`j L1` 的机器码实现：

- `j L1` 是 RISC-V 伪指令。
- 机器码层面由 `jal x0, L1` 实现。
- 指令地址为 `0x20`，目标地址为 `0x0c`。
- 偏移量为 `0x0c - 0x20 = -0x14`，即 `-20`。
- 机器码为 `fedff06f`。
- 执行效果为：`pc <- 0x0c`。由于目的寄存器是 `x0`，返回地址写入会被丢弃。

## 3. move.s 汇编、反汇编与子程序调用分析

`move.s`：

```asm
BankMove:
    add  t0,  a0, zero
    add  t1,  a1, zero
    add  t2,  a2, zero
L1: lw   t3,  0(t0)
    sw   t3,  0(t1)
    addi t0,  t0,  4
    addi t1,  t1,  4
    addi t2,  t2,  -1
    bne  t2,  zero,L1
    jr   ra

main:
    addi a0,  zero,0x30
    addi a1,  zero,0x60
    addi a2,  zero,10
    jal  BankMove
```

汇编与反汇编命令：

```bash
riscv32-unknown-linux-gnu-as -march=rv32i -mabi=ilp32 move.s -o build/move.o
riscv32-unknown-linux-gnu-ld -m elf32lriscv -Ttext=0x0 build/move.o -o build/move.elf
riscv32-unknown-linux-gnu-objdump -d -M no-aliases,numeric build/move.elf > dump/move.dump
```

核心反汇编结果：

```text
00000000 <BankMove>:
   0: 000502b3    add  x5,x10,x0
   4: 00058333    add  x6,x11,x0
   8: 000603b3    add  x7,x12,x0

0000000c <L1>:
   c: 0002ae03    lw   x28,0(x5)
  10: 01c32023    sw   x28,0(x6)
  14: 00428293    addi x5,x5,4
  18: 00430313    addi x6,x6,4
  1c: fff38393    addi x7,x7,-1
  20: fe0396e3    bne  x7,x0,c <L1>
  24: 00008067    jalr x0,0(x1)

00000028 <main>:
  28: 03000513    addi x10,x0,48
  2c: 06000593    addi x11,x0,96
  30: 00a00613    addi x12,x0,10
  34: fcdff0ef    jal  x1,0 <BankMove>
```

程序功能：

- `BankMove(a0, a1, a2)` 是数据块复制子程序。
- `a0` 保存源数据区首地址，`a1` 保存目标数据区首地址，`a2` 保存复制的数据个数。
- 子程序把 `a0/a1/a2` 分别复制到 `t0/t1/t2`。
- 每次循环从 `0(t0)` 取一个 32 位字，写入 `0(t1)`，然后两个地址指针都加 4，计数器减 1。
- `main` 设置 `a0=0x30`、`a1=0x60`、`a2=10`，因此实际效果是从内存地址 `0x30` 开始复制 10 个 32 位数据到内存地址 `0x60` 开始的区域。

`jal BankMove` 分析：

- 源汇编 `jal BankMove` 等价于 `jal ra, BankMove`。
- 反汇编机器指令为 `fcdff0ef`，即 `jal x1,0 <BankMove>`。
- 指令地址为 `0x34`，目标地址为 `0x00`。
- J 型立即数最低位隐含为 0，编码后的有符号偏移量为 `-0x34`，即 `-52`。
- 执行结果：
  - `ra = x1 = pc + 4 = 0x38`
  - `pc = 0x34 - 0x34 = 0x00`
- 跳转目标地址 `0x00` 对应指令是 `BankMove` 的第一条指令：`add t0, a0, zero`。

`jr ra` 分析：

- `jr ra` 是伪指令。
- 机器码层面为 `jalr x0, 0(ra)`，反汇编为 `00008067`。
- 执行到 `jr ra` 时，`ra` 中保存的是前面 `jal BankMove` 写入的 `0x38`。
- 执行结果：
  - `pc = (ra + 0) & ~1 = 0x38`
  - 由于目的寄存器为 `x0`，`pc + 4` 不会被保存。
- 也就是说，子程序返回到调用指令 `jal BankMove` 的下一条地址 `0x38`。本题给出的源程序在 `jal` 后没有继续写指令，因此可以理解为主程序调用完成后结束。

## 4. 手写 sum.s 并汇编、反汇编

对应 C 程序：

```c
int sum(int n)
{
    int i,s=0;
    for(i=0;i<=n;i++)
        s += i;
    return(s);
}

int main()
{
    int x=100;    int y;
    y = sum(x);
    return 0;
}
```

手写 `sum.s`：

```asm
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
```

设计说明：

- 按 RISC-V ABI，`a0` 作为 `sum` 的入口参数 `n`，同时也作为返回值寄存器。
- `t0` 表示循环变量 `i`，`t1` 表示累加变量 `s`。
- 循环条件 `i <= n` 用 `blt a0, t0, sum_done` 表示：当 `n < i` 时退出循环。
- `main` 调用 `sum` 前保存 `ra`，调用后恢复 `ra`，并按 C 程序要求返回 0。

汇编与反汇编命令：

```bash
riscv32-unknown-linux-gnu-as -march=rv32i -mabi=ilp32 sum.s -o build/sum.o
riscv32-unknown-linux-gnu-ld -m elf32lriscv -Ttext=0x0 build/sum.o -o build/sum.elf
riscv32-unknown-linux-gnu-objdump -d -M no-aliases,numeric build/sum.elf > dump/sum.dump
```

核心反汇编结果：

```text
00000000 <sum>:
   0: 00000293    addi x5,x0,0
   4: 00000313    addi x6,x0,0

00000008 <sum_loop>:
   8: 00554863    blt  x10,x5,18 <sum_done>
   c: 00530333    add  x6,x6,x5
  10: 00128293    addi x5,x5,1
  14: ff5ff06f    jal  x0,8 <sum_loop>

00000018 <sum_done>:
  18: 00030533    add  x10,x6,x0
  1c: 00008067    jalr x0,0(x1)

00000020 <main>:
  20: ff010113    addi x2,x2,-16
  24: 00112623    sw   x1,12(x2)
  28: 06400293    addi x5,x0,100
  2c: 00028533    add  x10,x5,x0
  30: fd1ff0ef    jal  x1,0 <sum>
  34: 00000513    addi x10,x0,0
  38: 00c12083    lw   x1,12(x2)
  3c: 01010113    addi x2,x2,16
  40: 00008067    jalr x0,0(x1)
```

如果希望把手写 `sum.s` 链接成 Linux 可执行文件，也可以使用 GCC 驱动链接 C 运行时：

```bash
gccrv32 sum.s -o build/sum_manual
runrv32 ./build/sum_manual
echo $?
```

该程序没有输出，返回值应为 0。

## 5. sum.c 编译反汇编与手写汇编对比

`sum.c`：

```c
int sum(int n)
{
    int i, s = 0;
    for (i = 0; i <= n; i++)
        s += i;
    return s;
}

int main(void)
{
    int x = 100;
    int y;
    y = sum(x);
    return 0;
}
```

编译、生成汇编和反汇编：

```bash
gccrv32 -O0 -march=rv32i -mabi=ilp32 -S sum.c -o dump/sum_c_gcc.s
gccrv32 -O0 -march=rv32i -mabi=ilp32 -c sum.c -o build/sum_c.o
riscv32-unknown-linux-gnu-objdump -d -M no-aliases,numeric build/sum_c.o > dump/sum_c.dump
```

对比结论：

| 对比项 | 手写 `sum.s` | GCC `-O0` 生成代码 |
| --- | --- | --- |
| 局部变量 | 主要放在 `t0/t1` 寄存器 | 通常放入栈帧中的内存槽 |
| 栈帧 | `sum` 不建栈帧，`main` 只保存 `ra` | `sum` 和 `main` 往往都会建立栈帧 |
| 循环实现 | 指令少，逻辑直接 | 指令更多，便于调试和保持 C 语义映射 |
| 可读性 | 更接近算法本身 | 更接近编译器通用模板 |
| 性能 | 对本例更简洁 | `-O0` 不追求优化，性能不是重点 |

差异原因：

- 手写汇编只服务于当前程序，知道 `sum` 内部不需要调用其他函数，所以可以不保存 `ra`，也不建立完整栈帧。
- GCC `-O0` 的目标是保留清晰的调试关系，因此会保留局部变量的内存位置，生成较多 `lw/sw/addi`。
- 如果使用 `-O2`，GCC 可能会明显减少栈访问，甚至对循环做更激进的优化；本实验固定用 `-O0`，更方便和 C 源代码逐行对照。

## 6. 思考与探索

1. 伪指令不是新硬件指令。`j label` 最终变成 `jal x0,label`，`jr ra` 最终变成 `jalr x0,0(ra)`。反汇编时加 `-M no-aliases` 可以更清楚地看到真实指令。
2. RISC-V 的分支和跳转立即数不是连续存放在机器码中的。例如 J 型立即数按 `imm[20|10:1|11|19:12]` 分散编码，最低位因为指令对齐而隐含为 0。
3. 子程序调用的关键是 `ra`。`jal` 把返回地址写入 `ra`，子程序末尾的 `jalr x0,0(ra)` 再跳回该地址。
4. 手写汇编适合教学分析机器码和数据通路；编译器生成代码更强调通用 ABI、调试信息和一致的代码生成规则。

## 7. 实验结论

- 已掌握 RV32I 常见 R 型、I 型、S 型、B 型、J 型指令的基本编码和反汇编观察方法。
- `acc.s` 验证了循环、访存、条件分支和无条件跳转的组合。
- `move.s` 验证了参数传递、子程序调用和返回机制。
- `sum.s` 展示了如何把 C 语言循环和函数调用手动翻译为 RV32I 汇编。
- 直接编译 `sum.c` 的结果通常比手写汇编更冗长，核心原因是 `-O0` 下编译器优先保证调试友好和通用 ABI 形式。

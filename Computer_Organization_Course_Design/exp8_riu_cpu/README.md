# 实验 8 RIU 多周期 CPU

本工程面向 HCS-A02 教学 FPGA 开发板，实现仅包含 R 型运算指令、I 型运算指令和 `lui` 的多周期 RIU_CPU。工程独立放在 `exp8_riu_cpu`，复用实验 7 的 IF、ID1、ROM 包装、数码管显示和 HCS-A02 约束。

## 文件说明

- `ip/RIU_test.s`：实验 8 测试汇编程序。
- `ip/RIU_test.coe`：64x32 位指令 ROM 初始化文件，前 27 个单元为测试程序。
- `src/id2.v`：二级译码模块，输出 R/I/U 类型和 ALU 操作码。
- `src/cu.v`：多周期控制单元，使用三段式 FSM。
- `src/alu.v`：支持目标指令集所需的 10 类 ALU 运算。
- `src/regs.v`：32x32 位寄存器堆，x0 恒为 0。
- `src/abf_latch.v`：A、B、F 暂存器。
- `src/riu_cpu.v`：RIU_CPU 整机数据通路。
- `src/top.v`：HCS-A02 板级测试顶层。
- `sim/*_tb.v`：自检仿真。
- `scripts/create_project.tcl`、`scripts/run_all.tcl`：Vivado 工程创建、仿真、实现和 bitstream 生成脚本。
- `RIU_CPU_report.md`：实验报告。

## 状态流程

每条有效 RIU 指令使用 4 个单步时钟完成：

```text
S1: 取指，PC 加 4，IR 锁存指令
S2: 译码并读取寄存器，A/B 暂存
S3: R 型执行
S5: I 型执行
S6: lui 执行
S4: 写回 rd
```

状态编码：

| 状态   | 编码    | 说明       |
| ---- | ----- | -------- |
| `S1` | `001` | 取指       |
| `S2` | `010` | 读寄存器/译码  |
| `S3` | `011` | R 型执行    |
| `S4` | `100` | 写回       |
| `S5` | `101` | I 型执行    |
| `S6` | `110` | `lui` 执行 |

## 板级操作

输入：

| 设备        | 功能            |
| --------- | ------------- |
| `BT0`     | 单步执行一个 CPU 状态 |
| `BT1`     | 复位，按下有效       |
| `SW[2:0]` | 数码管显示选择       |

数码管显示选择：

| `SW[2:0]` | 显示内容            |
| --------- | --------------- |
| `000`     | `PC`            |
| `001`     | `IR`            |
| `010`     | `W_Data`        |
| `011`     | `ST`            |
| `100`     | `{ZF,CF,OF,SF}` |

LED 显示：

| LED         | 内容              |
| ----------- | --------------- |
| `LD[27:0]`  | `W_Data[27:0]`  |
| `LD[31:28]` | `{ZF,CF,OF,SF}` |
| `LD[34:32]` | `ST`            |
| `LD[35]`    | `BT0` 单步脉冲      |

## 运行命令

在 PowerShell 中进入本目录后执行：

```powershell
& "E:\Vivado\2025.1\Vivado\bin\vivado.bat" -mode batch -source .\scripts\run_all.tcl
```

脚本会先运行 `alu_tb`、`id2_tb`、`riu_cpu_tb`、`top_tb`，全部通过后再综合、实现并生成 bitstream：

```text
build\RIU_CPU.bit
```

# 实验 3 多功能 ALU Vivado 工程

本工程面向 HCS-A02 教学 FPGA 开发板，实现一个 32 位、8 功能 ALU，并支持 LED 和 8 位数码管显示结果。

## 文件说明

- `src/ALU.v`：顶层模块。
- `src/Third_experiment_first.v`：ALU 核心模块，实现 8 种运算和 `ZF/OF` 标志。
- `src/Third_experiment_second.v`：根据 `AB_SW` 输出 8 组预设 `A/B` 测试数据。
- `src/Third_experiment_third.v`：根据 `F_LED_SW` 选择 LED 显示内容。
- `src/Third_experiment_fourth.v`：8 位数码管动态扫描模块，将 32 位结果 `F` 显示为 8 个十六进制数。
- `sim/tb_ALU.v`：仿真测试文件。
- `constrs/HCS_A02.xdc`：HCS-A02 开关、LED、时钟和数码管管脚约束。
- `scripts/create_project.tcl`：创建 Vivado 工程。
- `scripts/run_all.tcl`：运行仿真、综合、实现并生成 bitstream。

## 板卡开关与显示

- `SW[2:0]`：ALU 运算选择 `ALU_OP`。
- `SW[5:3]`：预设数据选择 `AB_SW`。
- `SW[8:6]`：LED 显示内容选择 `F_LED_SW`。
- `LD[7:0]`：显示所选结果字节或标志位。
- `LD[8]`：零标志 `ZF`，结果为 0 时亮。
- `LD[9]`：溢出标志 `OF`，有符号加减溢出时亮。
- `AN[7:0]`、`SEG[7:0]`：8 位数码管，持续显示 ALU 结果 `F` 的 8 位十六进制值。

`SEG[0]~SEG[6]` 对应 `CA~CG`，`SEG[7]` 对应 `DP`。HCS-A02 的数码管为共阳极，位选和段选均为低电平有效。

## 数码管显示规则

数码管从左到右显示 `F[31:28]` 到 `F[3:0]`，即完整 32 位结果的十六进制形式。例如结果为 `32'h80000000` 时，数码管显示 `80000000`。

## 运行命令

在 PowerShell 中进入本目录后执行：

```powershell
& "E:\Vivado\2025.1\Vivado\bin\vivado.bat" -mode batch -source .\scripts\run_all.tcl
```

生成的 Vivado 图形工程默认位于 `vivado_project`。如果该目录被已打开的 Vivado 占用，脚本会自动改用 `vivado_project_batch` 作为临时工程目录。

综合实现后的文件位于 `build`，下载到板子的 bit 文件为：

```text
build\ALU.bit
```

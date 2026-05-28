# 实验 5 存储器设计实验：Vivado IP 核 RAM

本工程面向 HCS-A02 教学 FPGA 开发板，使用 Vivado Block Memory Generator IP 核实现一个 `64x32` 单端口同步 RAM。实验给出的物理存储器为 `256x8`，按字节编址、按字访问，因此上板时只使用地址高 6 位，低 2 位固定理解为 `00`。

## 文件说明

- `src/RAM.v`：题面接口 `RAM` 模块，以及共用的 `memory_ip_core` IP 包装模块。
- `src/top.v`：HCS-A02 板卡顶层，连接开关、按键、LED 和 8 位数码管。
- `src/seven_seg_hex.v`、`src/seven_seg_display.v`：数码管十六进制显示。
- `ip/Test_Mem.coe`：Block Memory Generator 初始化文件。
- `sim/RAM_B_sim.v`：仿真用 `RAM_B` 行为模型，不参与综合。
- `sim/RAM_tb.v`、`sim/top_tb.v`：自检仿真。
- `constrs/HCS_A02.xdc`：HCS-A02 完整引脚约束。
- `scripts/create_project.tcl`：创建 Vivado 工程并生成 `RAM_B` IP。
- `scripts/run_all.tcl`：运行仿真、综合、实现并生成 bitstream。

## IP 核配置

脚本会自动创建名为 `RAM_B` 的 `blk_mem_gen` IP，核心配置为：

- Memory Type：Single Port RAM
- Width：`32`
- Depth：`64`
- Enable：Always Enabled
- Operating Mode：Read First
- 初始化文件：`ip/Test_Mem.coe`

初始化内容：

```text
00000820, 00632020, 00010fff, 20006789, ffff0000,
0000ffff, 88888888, 99999999, aaaaaaaa, bbbbbbbb
```

## 板卡操作

- `sw[7:2]`：RAM 地址高 6 位，对应逻辑字地址 `0` 到 `63`。
- `sw[1:0]`：`MUX`，选择读出字节，也选择写入的固定 32 位数据。
- `bt[0]`：写入按钮，上升沿产生一个时钟周期的写脉冲。
- `ld[7:0]`：显示当前 `MUX` 选中的 8 位字节。
- `ld[13:8]`：显示当前地址 `sw[7:2]`。
- `ld[15:14]`：显示当前 `MUX`。
- `ld[35:16]`：关闭。
- 数码管：显示当前 RAM 读出的完整 32 位字。

`MUX` 与写入数据、读出字节的关系：

| `MUX` | 写入数据            | LED 显示字节           |
| ----- | --------------- | ------------------ |
| `00`  | `32'h0000_000F` | `read_word[7:0]`   |
| `01`  | `32'h0000_0DB0` | `read_word[15:8]`  |
| `10`  | `32'h003C_C381` | `read_word[23:16]` |
| `11`  | `32'hFFFF_FFFF` | `read_word[31:24]` |

同步 RAM 的读数据在时钟上升沿更新。切换地址后，等待一个时钟周期，LED 和数码管会显示该地址读出的数据。

## 运行命令

在 PowerShell 中进入本目录后执行：

```powershell
& "E:\Vivado\2025.1\Vivado\bin\vivado.bat" -mode batch -source .\scripts\run_all.tcl
```

如果 Vivado 安装路径不同，请替换为本机实际路径。脚本完成后，下载到板子的 bit 文件为：

```text
build\Memory_IP_Experiment.bit
```

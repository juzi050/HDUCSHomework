# 实验 7 指令取指与译码实验

本工程面向 HCS-A02 教学 FPGA 开发板，实现 64x32 位指令 ROM、PC/IR 取指模块、指令初级译码器 ID1 和立即数拼接扩展器 ImmU。实验只验证取指和译码，不执行跳转或分支目标更新，因此 PC 固定按 `+4` 顺序前进。

## 文件说明

- `ip/exp7_test.s`：覆盖 R/I/S/B/U/J 六类 RV32I 指令格式的测试汇编程序。
- `ip/exp7_test.coe`：64x32 位 ROM 初始化文件，前 9 个单元为测试指令，其余填 0。
- `src/pc_reg.v`、`src/ir_reg.v`：PC 和 IR 寄存器，低有效复位清零，写使能有效时更新。
- `src/instruction_memory.v`：Vivado `IM_B` ROM IP 包装模块。
- `src/if_stage.v`：取指模块，使用 `PC[7:2]` 作为 ROM 字地址。
- `src/id1.v`、`src/immu.v`：字段解析和立即数生成模块。
- `src/top.v`：HCS-A02 板级测试顶层。
- `sim/IM_B_sim.v`：仿真用 ROM 行为模型，内容与 COE 一致。
- `sim/if_stage_tb.v`、`sim/id1_tb.v`、`sim/top_tb.v`：自检仿真。
- `scripts/create_project.tcl`、`scripts/run_all.tcl`：Vivado 工程创建、仿真、综合实现和 bitstream 生成脚本。
- `constrs/HCS_A02.xdc`：HCS-A02 管脚约束。

## 测试程序与 COE 内容

| PC | COE 指令代码 | 汇编指令 | 指令格式 | imm32 |
| --- | --- | --- | --- | --- |
| `0x00` | `123450b7` | `lui x1,0x12345` | U | `12345000` |
| `0x04` | `00010117` | `auipc x2,0x00010` | U | `00010000` |
| `0x08` | `fff00193` | `addi x3,x0,-1` | I | `ffffffff` |
| `0x0c` | `0100a203` | `lw x4,16(x1)` | I | `00000010` |
| `0x10` | `004182b3` | `add x5,x3,x4` | R | `00000000` |
| `0x14` | `0050aa23` | `sw x5,20(x1)` | S | `00000014` |
| `0x18` | `00028463` | `beq x5,x0,+8` | B | `00000008` |
| `0x1c` | `00600313` | `addi x6,x0,6` | I | `00000006` |
| `0x20` | `ff1ff3ef` | `jal x7,-16` | J | `fffffff0` |

## 模块结构与连接

取指链路为：

```text
PC_Write/IR_Write -> pc_reg -> PC[7:2] -> IM_B ROM -> ir_reg -> IR
```

译码链路为：

```text
IR -> id1 -> opcode/rd/funct3/rs1/rs2/funct7
IR -> immu -> imm32
```

`IM_B` 是同步 ROM。板级顶层使用 100MHz 时钟持续驱动 ROM，按键 `BT0` 只产生 PC/IR 写入脉冲；复位释放后 ROM 会预取 0 号单元，因此第一次单步即可将第一条指令锁存到 IR。

## 板级验证方案

输入：

| 设备 | 功能 |
| --- | --- |
| `SW0` | `PC_Write`，置 1 后单步时 PC 加 4 |
| `SW1` | `IR_Write`，置 1 后单步时 IR 锁存当前 ROM 输出 |
| `SW3:SW2` | 数码管显示选择：`00=imm32`，`01=IR`，`10=PC`，`11=ROM 预取值` |
| `BT0` | 单步取指按钮 |
| `BT1` | 复位按钮，按下清零 PC 和 IR |

输出：

| 设备 | 显示内容 |
| --- | --- |
| 8 个数码管 | 按 `SW3:SW2` 显示 `imm32/IR/PC/ROM预取值` |
| `LD4:LD0` | `rs1[4:0]` |
| `LD9:LD5` | `rs2[4:0]` |
| `LD14:LD10` | `rd[4:0]` |
| `LD21:LD15` | `opcode[6:0]` |
| `LD24:LD22` | `funct3[2:0]` |
| `LD31:LD25` | `funct7[6:0]` |

操作过程：

1. 按住 `BT1` 复位，再松开，PC 和 IR 清零。
2. 打开 `SW0` 和 `SW1`。
3. 将 `SW3:SW2` 置 `00`，数码管显示当前 IR 译码得到的 `imm32`。
4. 每按一次 `BT0`，取出一条指令；用 `SW3:SW2=01/10` 分别观察 IR 和 PC。
5. 将 LED 字段与上表的机器码字段对照，记录“解析字段是否正确”。

板级记录表：

| PC | IR | COE 文件中指令代码 | 汇编指令 | imm32 | 解析字段是否正确 |
| --- | --- | --- | --- | --- | --- |
| `0x00` | `123450b7` | `123450b7` | `lui x1,0x12345` | `12345000` | 是 |
| `0x04` | `00010117` | `00010117` | `auipc x2,0x00010` | `00010000` | 是 |
| `0x08` | `fff00193` | `fff00193` | `addi x3,x0,-1` | `ffffffff` | 是 |
| `0x0c` | `0100a203` | `0100a203` | `lw x4,16(x1)` | `00000010` | 是 |
| `0x10` | `004182b3` | `004182b3` | `add x5,x3,x4` | `00000000` | 是 |
| `0x14` | `0050aa23` | `0050aa23` | `sw x5,20(x1)` | `00000014` | 是 |
| `0x18` | `00028463` | `00028463` | `beq x5,x0,+8` | `00000008` | 是 |
| `0x1c` | `00600313` | `00600313` | `addi x6,x0,6` | `00000006` | 是 |
| `0x20` | `ff1ff3ef` | `ff1ff3ef` | `jal x7,-16` | `fffffff0` | 是 |

## 仿真验证结论

`if_stage_tb` 验证：

- 复位后 PC 和 IR 均为 0。
- ROM 预取 0 号单元，第一次单步取出 `123450b7`。
- `PC_Write=1` 且单步脉冲有效时，PC 每次增加 4。
- `IR_Write=1` 且单步脉冲有效时，IR 顺序锁存 COE 中的机器码。
- 写使能无效时 PC 和 IR 保持不变。

`id1_tb` 验证：

- `opcode/rd/funct3/rs1/rs2/funct7` 均按固定 bit 位解析。
- I/S/B/U/J 型立即数拼接与符号扩展正确。
- R 型指令 `add` 的 `imm32` 输出 0。

`top_tb` 验证：

- `BT1` 可清零 PC/IR。
- `BT0` 上升沿只产生一个单步写入脉冲。
- LED 字段映射与 ID1 输出一致。
- `SW3:SW2` 可选择数码管显示 `imm32/IR/PC/ROM预取值`。

## 思考与探索

1. PC 是字节地址，ROM 是 32 位字寻址，因此取指地址使用 `PC[7:2]`。PC 从 `0x00` 开始，每次 `+4`，对应 ROM 单元编号依次为 0、1、2。
2. B 型和 J 型立即数在机器码中分散存放，最低位隐含为 0。ImmU 必须先按格式重排，再做符号扩展。
3. `addi -1` 和 `jal -16` 能验证符号扩展；如果只测试正数立即数，无法证明高位扩展逻辑正确。
4. 本实验是 IF 与 ID1 验证，不包含执行阶段或 PC 选择器，所以即使译码到 `beq/jal`，PC 仍按顺序 `+4`。
5. 同步 ROM 的输出随时钟更新。顶层用 100MHz 时钟持续驱动 ROM、单步脉冲只控制 PC/IR 写入，这样板级按键操作时可以稳定观察每条指令。

## 运行命令

在 PowerShell 中进入本目录后执行：

```powershell
& "E:\Vivado\2025.1\Vivado\bin\vivado.bat" -mode batch -source .\scripts\run_all.tcl
```

生成的 bit 文件位置：

```text
build\Instruction_Fetch_Decode.bit
```

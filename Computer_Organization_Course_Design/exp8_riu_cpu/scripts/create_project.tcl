#==============================================================================
# create_project.tcl - Vivado 项目创建脚本 (Experiment 8: RIU CPU)
#==============================================================================
# 功能:
#   - 创建 Vivado 项目，添加完整 RIU CPU 源文件、仿真文件和约束文件。
#   - 创建 BRAM IP 核 (IM_B: 64x32位, 单端口ROM, 用作指令存储器)。
#   - 从 .coe 文件加载 RISC-V 测试程序。
#   - 目标器件: xc7a100tcsg324-1 (HCS-A02 开发板)。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "RIU_CPU"
set part_name "xc7a100tcsg324-1"

# 设计源文件: 完整的 RIU 多周期 CPU 数据通路
set src_files [list \
    [file join $root_dir "src" "pc_reg.v"] \
    [file join $root_dir "src" "ir_reg.v"] \
    [file join $root_dir "src" "instruction_memory.v"] \
    [file join $root_dir "src" "if_stage.v"] \
    [file join $root_dir "src" "immu.v"] \
    [file join $root_dir "src" "id1.v"] \
    [file join $root_dir "src" "id2.v"] \
    [file join $root_dir "src" "cu.v"] \
    [file join $root_dir "src" "regs.v"] \
    [file join $root_dir "src" "alu.v"] \
    [file join $root_dir "src" "abf_latch.v"] \
    [file join $root_dir "src" "riu_cpu.v"] \
    [file join $root_dir "src" "seven_seg_hex.v"] \
    [file join $root_dir "src" "seven_seg_display.v"] \
    [file join $root_dir "src" "top.v"] \
]

# 仿真模型文件 (IM_B 行为级模型，代替 ROM IP)
set sim_model_files [list \
    [file join $root_dir "sim" "IM_B_sim.v"] \
]

# 仿真测试平台文件
set sim_files [list \
    [file join $root_dir "sim" "alu_tb.v"] \
    [file join $root_dir "sim" "id2_tb.v"] \
    [file join $root_dir "sim" "riu_cpu_tb.v"] \
    [file join $root_dir "sim" "top_tb.v"] \
]

set constr_file [file join $root_dir "constrs" "HCS_A02.xdc"]
set coe_file [file join $root_dir "ip" "RIU_test.coe"]

# 如果旧项目目录存在，尝试删除 (被占用则使用备用目录)
if {[file exists $project_dir]} {
    if {[catch {file delete -force $project_dir} delete_error]} {
        set project_dir [file join $root_dir "vivado_project_batch"]
        if {[file exists $project_dir]} {
            file delete -force $project_dir
        }
        puts "Primary project directory is busy; using: $project_dir"
    }
}

create_project $project_name $project_dir -part $part_name

# 添加设计源文件、仿真文件、约束文件
add_files -fileset sources_1 $src_files
add_files -fileset sim_1 $sim_files
foreach sim_file $sim_files {
    set_property file_type SystemVerilog [get_files $sim_file]
}
add_files -fileset constrs_1 $constr_file

# 创建 BRAM IP 核: 64x32位单端口ROM (指令存储器), 加载测试程序
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name IM_B
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File $coe_file \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
] [get_ips IM_B]

generate_target all [get_ips IM_B]
export_ip_user_files -of_objects [get_ips IM_B] -no_script -sync -force -quiet

# 设置顶层模块
set_property top top [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

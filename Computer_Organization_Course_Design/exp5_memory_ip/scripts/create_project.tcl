#==============================================================================
# create_project.tcl - Vivado 项目创建脚本 (Experiment 5: Memory IP)
#==============================================================================
# 功能:
#   - 创建 Vivado 项目，添加源文件、仿真文件和约束文件。
#   - 创建 BRAM IP 核 (RAM_B: 64x32位, 单端口RAM)。
#   - 从 .coe 文件初始化内存内容。
#   - 目标器件: xc7a100tcsg324-1 (HCS-A02 开发板)。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "Memory_IP_Experiment"
set part_name "xc7a100tcsg324-1"

# 设计源文件
set src_files [list \
    [file join $root_dir "src" "RAM.v"] \
    [file join $root_dir "src" "seven_seg_hex.v"] \
    [file join $root_dir "src" "seven_seg_display.v"] \
    [file join $root_dir "src" "top.v"] \
]

# 仿真模型文件 (RAM_B 行为级模型，替代IP核)
set sim_model_files [list \
    [file join $root_dir "sim" "RAM_B_sim.v"] \
]

# 仿真测试平台文件
set sim_files [list \
    [file join $root_dir "sim" "RAM_tb.v"] \
    [file join $root_dir "sim" "top_tb.v"] \
]

set constr_file [file join $root_dir "constrs" "HCS_A02.xdc"]
set coe_file [file join $root_dir "ip" "Test_Mem.coe"]

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

# 创建 BRAM IP 核: 64x32位单端口RAM, 带初始化文件
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name RAM_B
set_property -dict [list \
    CONFIG.Memory_Type {Single_Port_RAM} \
    CONFIG.Write_Width_A {32} \
    CONFIG.Read_Width_A {32} \
    CONFIG.Write_Depth_A {64} \
    CONFIG.Operating_Mode_A {READ_FIRST} \
    CONFIG.Enable_A {Always_Enabled} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Coe_File $coe_file \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
] [get_ips RAM_B]

generate_target all [get_ips RAM_B]
export_ip_user_files -of_objects [get_ips RAM_B] -no_script -sync -force -quiet

# 设置顶层模块
set_property top top [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

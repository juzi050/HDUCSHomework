#==============================================================================
# create_project.tcl - Vivado 项目创建脚本 (Experiment 4: Register File + ALU)
#==============================================================================
# 功能:
#   - 创建 Vivado 项目，添加源文件、仿真文件和约束文件。
#   - 设置顶层模块 (top: top, sim: top_tb)。
#   - 目标器件: xc7a100tcsg324-1 (HCS-A02 开发板)。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "RegisterFile_Experiment"
set part_name "xc7a100tcsg324-1"

# 源文件列表: 寄存器堆、ALU、组合模块、七段数码管、顶层
set src_files [list \
    [file join $root_dir "src" "regfile.v"] \
    [file join $root_dir "src" "alu.v"] \
    [file join $root_dir "src" "alu_reg.v"] \
    [file join $root_dir "src" "seven_seg_hex.v"] \
    [file join $root_dir "src" "seven_seg_display.v"] \
    [file join $root_dir "src" "top.v"] \
]

# 仿真文件列表: 各模块独立测试 + 顶层测试
set sim_files [list \
    [file join $root_dir "sim" "regfile_tb.v"] \
    [file join $root_dir "sim" "alu_tb.v"] \
    [file join $root_dir "sim" "alu_reg_tb.v"] \
    [file join $root_dir "sim" "top_tb.v"] \
]

set constr_file [file join $root_dir "constrs" "HCS_A02.xdc"]

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

# 设置顶层模块
set_property top top [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

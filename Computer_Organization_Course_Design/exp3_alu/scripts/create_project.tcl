#==============================================================================
# create_project.tcl - Vivado 项目创建脚本 (Experiment 3: ALU)
#==============================================================================
# 功能:
#   - 创建 Vivado 项目，添加源文件、仿真文件和约束文件。
#   - 设置顶层模块 (top: ALU, sim: tb_ALU)。
#   - 目标器件: xc7a100tcsg324-1 (HCS-A02 开发板)。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "exp3_alu"
set part_name "xc7a100tcsg324-1"

# 如果项目目录已被占用，使用备用目录
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

# 添加设计源文件
add_files -fileset sources_1 [list \
    [file join $root_dir "src" "ALU.v"] \
    [file join $root_dir "src" "Third_experiment_first.v"] \
    [file join $root_dir "src" "Third_experiment_second.v"] \
    [file join $root_dir "src" "Third_experiment_third.v"] \
    [file join $root_dir "src" "Third_experiment_fourth.v"] \
]

# 添加仿真文件和约束文件
add_files -fileset sim_1 [file join $root_dir "sim" "tb_ALU.v"]
add_files -fileset constrs_1 [file join $root_dir "constrs" "HCS_A02.xdc"]

# 设置顶层模块
set_property top ALU [get_filesets sources_1]
set_property top tb_ALU [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

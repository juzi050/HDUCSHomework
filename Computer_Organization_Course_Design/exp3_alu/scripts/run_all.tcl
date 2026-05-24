#==============================================================================
# run_all.tcl - 一键仿真+综合+实现脚本 (Experiment 3: ALU)
#==============================================================================
# 功能:
#   - 调用 create_project.tcl 创建项目。
#   - 运行行为级仿真。
#   - 执行综合、优化、布局布线。
#   - 生成比特流 (.bit) 和设计检查点 (.dcp)。
#   - 输出资源利用率和时序报告。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_dir [file join $root_dir "vivado_project"]
set build_dir [file join $root_dir "build"]

source [file join $script_dir "create_project.tcl"]

# 运行仿真
launch_simulation
run all
close_sim
close_project

# 综合与实现
if {[file exists $build_dir]} {
    file delete -force $build_dir
}
file mkdir $build_dir

read_verilog [list \
    [file join $root_dir "src" "ALU.v"] \
    [file join $root_dir "src" "Third_experiment_first.v"] \
    [file join $root_dir "src" "Third_experiment_second.v"] \
    [file join $root_dir "src" "Third_experiment_third.v"] \
    [file join $root_dir "src" "Third_experiment_fourth.v"] \
]

synth_design -top ALU -part $part_name
read_xdc [file join $root_dir "constrs" "HCS_A02.xdc"]
opt_design
place_design
route_design

# 生成输出文件
write_checkpoint -force [file join $build_dir "ALU_routed.dcp"]
write_bitstream -force [file join $build_dir "ALU.bit"]
report_utilization -file [file join $build_dir "utilization.rpt"]
report_timing_summary -file [file join $build_dir "timing_summary.rpt"]

puts "Bitstream generated: [file join $build_dir ALU.bit]"

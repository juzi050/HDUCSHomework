#==============================================================================
# run_all.tcl - 一键仿真+综合+实现脚本 (Experiment 4: Register File + ALU)
#==============================================================================
# 功能:
#   - 调用 create_project.tcl 创建项目。
#   - 使用 xvlog/xelab/xsim 命令行工具运行4个仿真测试平台。
#   - 执行综合、优化、布局布线。
#   - 生成比特流 (.bit) 和设计检查点 (.dcp)。
#   - 输出资源利用率和时序报告。
#==============================================================================

set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_dir [file join $root_dir "vivado_project"]
set build_dir [file join $root_dir "build"]
set sim_build_dir [file join $root_dir "sim_build"]

source [file join $script_dir "create_project.tcl"]

# 查找 Vivado 命令行工具 (xvlog/xelab/xsim)
proc find_tool {tool_name} {
    set vivado_bin [file normalize [file dirname [info nameofexecutable]]]

    for {set i 0} {$i < 8} {incr i} {
        set tool_path [file join $vivado_bin $tool_name]
        if {[file exists $tool_path]} {
            return $tool_path
        }
        set vivado_bin [file dirname $vivado_bin]
    }

    error "Cannot find $tool_name near Vivado executable"
}

# 运行命令行工具
proc run_cmd {work_dir cmd} {
    set old_dir [pwd]
    cd $work_dir
    puts "CMD: $cmd"

    if {[catch {exec {*}$cmd} result options]} {
        cd $old_dir
        puts $result
        return -options $options $result
    }

    cd $old_dir
    if {[string length $result] > 0} {
        puts $result
    }
}

# 生成 xsim 项目文件 (.prj)
proc write_sim_project {prj_file src_files tb_file glbl_file} {
    set fp [open $prj_file "w"]
    puts $fp "# command-line xsim project"
    foreach src_file $src_files {
        puts $fp "verilog xil_defaultlib \"$src_file\""
    }
    puts $fp "sv xil_defaultlib \"$tb_file\""
    puts $fp "verilog xil_defaultlib \"$glbl_file\""
    puts $fp "nosort"
    close $fp
}

# 运行单个测试平台
proc run_testbench {tb_name src_files root_dir sim_build_dir xvlog xelab xsim glbl_file} {
    puts "Running simulation: $tb_name"

    set tb_dir [file join $sim_build_dir $tb_name]
    file mkdir $tb_dir

    set tb_file [file join $root_dir "sim" "$tb_name.v"]
    set prj_file [file join $tb_dir "$tb_name.prj"]
    set snapshot "${tb_name}_snap"

    write_sim_project $prj_file $src_files $tb_file $glbl_file

    run_cmd $tb_dir [list cmd /c $xvlog --relax --prj $prj_file --log [file join $tb_dir "xvlog.log"]]
    run_cmd $tb_dir [list cmd /c $xelab --relax --mt 2 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot $snapshot "xil_defaultlib.$tb_name" xil_defaultlib.glbl --log [file join $tb_dir "xelab.log"]]
    run_cmd $tb_dir [list cmd /c $xsim $snapshot --R --onerror quit --onfinish quit --log [file join $tb_dir "xsim.log"]]
}

# 查找工具
set xvlog [find_tool "xvlog.bat"]
set xelab [find_tool "xelab.bat"]
set xsim [find_tool "xsim.bat"]
set vivado_root [file normalize [file join [file dirname $xvlog] ".."]]
set glbl_file [file join $vivado_root "data" "verilog" "src" "glbl.v"]

# 运行所有测试平台
if {[file exists $sim_build_dir]} {
    file delete -force $sim_build_dir
}
file mkdir $sim_build_dir

foreach tb_name [list regfile_tb alu_tb alu_reg_tb top_tb] {
    run_testbench $tb_name $src_files $root_dir $sim_build_dir $xvlog $xelab $xsim $glbl_file
}

close_project

# 综合与实现
if {[file exists $build_dir]} {
    file delete -force $build_dir
}
file mkdir $build_dir

read_verilog $src_files
synth_design -top top -part $part_name
read_xdc $constr_file
opt_design
place_design
route_design

# 生成输出文件
write_checkpoint -force [file join $build_dir "RegisterFile_Experiment_routed.dcp"]
write_bitstream -force [file join $build_dir "RegisterFile_Experiment.bit"]
report_utilization -file [file join $build_dir "utilization.rpt"]
report_timing_summary -file [file join $build_dir "timing_summary.rpt"]

puts "Bitstream generated: [file join $build_dir RegisterFile_Experiment.bit]"

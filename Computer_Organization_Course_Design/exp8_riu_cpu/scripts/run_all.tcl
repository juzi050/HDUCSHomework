set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_dir [file join $root_dir "vivado_project"]
set build_dir [file join $root_dir "build"]
set sim_build_dir [file join $root_dir "sim_build"]

source [file join $script_dir "create_project.tcl"]

proc find_tool {tool_base_name} {
    set exe_dir [file normalize [file dirname [info nameofexecutable]]]
    set candidate_dirs [list \
        $exe_dir \
        [file normalize [file join $exe_dir ".."]] \
        [file normalize [file join $exe_dir ".." ".."]] \
        [file normalize [file join $exe_dir ".." ".." "bin"]] \
    ]

    foreach dir $candidate_dirs {
        foreach suffix [list ".bat" "" ".exe"] {
            set tool_path [file join $dir "${tool_base_name}${suffix}"]
            if {[file exists $tool_path]} {
                return $tool_path
            }
        }
    }

    error "Cannot find $tool_base_name near Vivado executable"
}

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

proc write_sim_project {prj_file src_files tb_file} {
    set fp [open $prj_file "w"]
    puts $fp "# command-line xsim project"
    foreach src_file $src_files {
        puts $fp "verilog xil_defaultlib \"$src_file\""
    }
    puts $fp "sv xil_defaultlib \"$tb_file\""
    puts $fp "nosort"
    close $fp
}

proc run_testbench {tb_name src_files root_dir sim_build_dir xvlog xelab xsim} {
    puts "Running simulation: $tb_name"

    set tb_dir [file join $sim_build_dir $tb_name]
    file mkdir $tb_dir

    set tb_file [file join $root_dir "sim" "$tb_name.v"]
    set prj_file [file join $tb_dir "$tb_name.prj"]
    set xsim_log [file join $tb_dir "xsim.log"]
    set snapshot "${tb_name}_snap"

    write_sim_project $prj_file $src_files $tb_file

    run_cmd $tb_dir [list cmd /c $xvlog --relax --prj $prj_file --log [file join $tb_dir "xvlog.log"]]
    run_cmd $tb_dir [list cmd /c $xelab --relax --mt 2 -L xil_defaultlib --snapshot $snapshot "xil_defaultlib.$tb_name" --log [file join $tb_dir "xelab.log"]]
    run_cmd $tb_dir [list cmd /c $xsim $snapshot --R --onerror quit --onfinish quit --log $xsim_log]

    set fp [open $xsim_log "r"]
    set log_data [read $fp]
    close $fp

    if {[string first "TESTS FAILED" $log_data] >= 0 ||
        [string first "ALL TESTS PASSED: $tb_name" $log_data] < 0} {
        error "Simulation failed or did not report success: $tb_name"
    }
}

set xvlog [find_tool "xvlog"]
set xelab [find_tool "xelab"]
set xsim [find_tool "xsim"]

if {[file exists $sim_build_dir]} {
    file delete -force $sim_build_dir
}
file mkdir $sim_build_dir

set behavioral_src_files [concat $sim_model_files $src_files]
foreach tb_name [list alu_tb id2_tb riu_cpu_tb top_tb] {
    run_testbench $tb_name $behavioral_src_files $root_dir $sim_build_dir $xvlog $xelab $xsim
}

if {[file exists $build_dir]} {
    file delete -force $build_dir
}
file mkdir $build_dir

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

open_run impl_1
set impl_dir [file join $project_dir "${project_name}.runs" "impl_1"]
set bit_files [glob -nocomplain [file join $impl_dir "*.bit"]]
if {[llength $bit_files] == 0} {
    error "Bitstream was not generated in $impl_dir"
}

file copy -force [lindex $bit_files 0] [file join $build_dir "RIU_CPU.bit"]
write_checkpoint -force [file join $build_dir "RIU_CPU_routed.dcp"]
report_utilization -file [file join $build_dir "utilization.rpt"]
report_timing_summary -file [file join $build_dir "timing_summary.rpt"]

puts "Bitstream generated: [file join $build_dir RIU_CPU.bit]"

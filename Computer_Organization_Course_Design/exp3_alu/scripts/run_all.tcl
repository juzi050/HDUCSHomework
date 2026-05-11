set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
set project_dir [file join $root_dir "vivado_project"]
set build_dir [file join $root_dir "build"]

source [file join $script_dir "create_project.tcl"]

launch_simulation
run all
close_sim
close_project

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

write_checkpoint -force [file join $build_dir "ALU_routed.dcp"]
write_bitstream -force [file join $build_dir "ALU.bit"]
report_utilization -file [file join $build_dir "utilization.rpt"]
report_timing_summary -file [file join $build_dir "timing_summary.rpt"]

puts "Bitstream generated: [file join $build_dir ALU.bit]"

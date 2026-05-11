set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "RegisterFile_Experiment"
set part_name "xc7a100tcsg324-1"

set src_files [list \
    [file join $root_dir "src" "regfile.v"] \
    [file join $root_dir "src" "alu.v"] \
    [file join $root_dir "src" "alu_reg.v"] \
    [file join $root_dir "src" "seven_seg_hex.v"] \
    [file join $root_dir "src" "seven_seg_display.v"] \
    [file join $root_dir "src" "top.v"] \
]

set sim_files [list \
    [file join $root_dir "sim" "regfile_tb.v"] \
    [file join $root_dir "sim" "alu_tb.v"] \
    [file join $root_dir "sim" "alu_reg_tb.v"] \
    [file join $root_dir "sim" "top_tb.v"] \
]

set constr_file [file join $root_dir "constrs" "HCS_A02.xdc"]

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

add_files -fileset sources_1 $src_files
add_files -fileset sim_1 $sim_files
foreach sim_file $sim_files {
    set_property file_type SystemVerilog [get_files $sim_file]
}
add_files -fileset constrs_1 $constr_file

set_property top top [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

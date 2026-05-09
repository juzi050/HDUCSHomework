set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "exp3_alu"
set part_name "xc7a100tcsg324-1"

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

add_files -fileset sources_1 [list \
    [file join $root_dir "src" "ALU.v"] \
    [file join $root_dir "src" "Third_experiment_first.v"] \
    [file join $root_dir "src" "Third_experiment_second.v"] \
    [file join $root_dir "src" "Third_experiment_third.v"] \
    [file join $root_dir "src" "Third_experiment_fourth.v"] \
]

add_files -fileset sim_1 [file join $root_dir "sim" "tb_ALU.v"]
add_files -fileset constrs_1 [file join $root_dir "constrs" "HCS_A02.xdc"]

set_property top ALU [get_filesets sources_1]
set_property top tb_ALU [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

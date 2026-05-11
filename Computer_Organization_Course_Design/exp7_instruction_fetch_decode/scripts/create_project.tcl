set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir ".."]]
if {![info exists project_dir]} {
    set project_dir [file join $root_dir "vivado_project"]
}
set project_name "Instruction_Fetch_Decode"
set part_name "xc7a100tcsg324-1"

set src_files [list \
    [file join $root_dir "src" "pc_reg.v"] \
    [file join $root_dir "src" "ir_reg.v"] \
    [file join $root_dir "src" "instruction_memory.v"] \
    [file join $root_dir "src" "if_stage.v"] \
    [file join $root_dir "src" "immu.v"] \
    [file join $root_dir "src" "id1.v"] \
    [file join $root_dir "src" "seven_seg_hex.v"] \
    [file join $root_dir "src" "seven_seg_display.v"] \
    [file join $root_dir "src" "top.v"] \
]

set sim_model_files [list \
    [file join $root_dir "sim" "IM_B_sim.v"] \
]

set sim_files [list \
    [file join $root_dir "sim" "if_stage_tb.v"] \
    [file join $root_dir "sim" "id1_tb.v"] \
    [file join $root_dir "sim" "top_tb.v"] \
]

set constr_file [file join $root_dir "constrs" "HCS_A02.xdc"]
set coe_file [file join $root_dir "ip" "exp7_test.coe"]

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

set_property top top [get_filesets sources_1]
set_property top top_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Created project: $project_dir"

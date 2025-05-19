set partNumber $::env(XILINX_PART)

if [info exists ::env(BOARD)] {
    set BOARD $::env(BOARD)
} else {
    error "BOARD is not defined. Please source the sourceme.sh file."
    exit
}
if [info exists ::env(XILINX_BOARD)] {
  set boardName  $::env(XILINX_BOARD)
}

create_project xilinx_tag_cache_32x10 . -part $partNumber
set_property board_part $boardName [current_project]

set ipName xilinx_tag_cache_32x10

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -module_name $ipName

set_property -dict [eval list CONFIG.Memory_Type {Single_Port_RAM} \
                        CONFIG.Use_Byte_Write_Enable {true} \
                        CONFIG.Byte_Size {8} CONFIG.Write_Width_A {16} \
                        CONFIG.Write_Depth_A {32} \
                        CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
                        CONFIG.Use_RSTA_Pin {true}\
                       ] [get_ips $ipName]

generate_target all [get_files ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] ./$ipName.srcs/sources_1/ip/$ipName/$ipName.xci]
launch_run -jobs 8 ${ipName}_synth_1
wait_on_run ${ipName}_synth_1

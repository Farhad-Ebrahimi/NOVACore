# Launch Synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1
# open_run synth_1 -name netlist_1
puts "INFO: Project synthesis finished:${_xil_proj_name_}"

# Launch Implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1 

puts "INFO: Project implementation finished:${_xil_proj_name_}"
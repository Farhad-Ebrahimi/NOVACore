# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir [file dirname [file normalize [info script]]]

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "NOVACore"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "NOVACore.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script. The created project will be"
  puts "functionally equivalent to the original project for which this script was"
  puts "generated. The script contains commands for creating a project, filesets,"
  puts "runs, adding/importing sources and setting properties on various objects.\n"
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--origin_dir <path>\]  Determine source file paths wrt this path. Default"
  puts "                       origin_dir path value is \".\", otherwise, the value"
  puts "                       that was set with the \"-paths_relative_to\" switch"
  puts "                       when this script was generated.\n"
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                       name is the name of the project from where this"
  puts "                       script was generated.\n"
  puts "\[--help\]               Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Create project
create_project ${_xil_proj_name_} $origin_dir/../build/${_xil_proj_name_} -part xczu3eg-sbva484-1-i -force

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set_property -name "board_part" -value "avnet.com:ultra96v2:part0:1.2" -objects [current_project]
set_property -name "simulator_language" -value "Mixed" -objects [current_project]
set_property -name "target_language" -value "VHDL" -objects [current_project]

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]

# Import local files from the original project
set files [list \
 [file normalize "${origin_dir}/../src/aee_rom.vhd"]\
 [file normalize "${origin_dir}/../src/bpu.vhd"]\
 [file normalize "${origin_dir}/../src/Bin2Ter.vhd"]\
 [file normalize "${origin_dir}/../src/mul_stg3.vhd"]\
 [file normalize "${origin_dir}/../src/CSD_Adder.vhd"]\
 [file normalize "${origin_dir}/../src/CSD_Sub.vhd"]\
 [file normalize "${origin_dir}/../src/mul_stg2.vhd"]\
 [file normalize "${origin_dir}/../src/pp_types.vhd"]\
 [file normalize "${origin_dir}/../src/pp_constants.vhd"]\
 [file normalize "${origin_dir}/../src/pp_utilities.vhd"]\
 [file normalize "${origin_dir}/../src/pp_alu_control_unit.vhd"]\
 [file normalize "${origin_dir}/../src/pp_alu_mux.vhd"]\
 [file normalize "${origin_dir}/../src/pp_comparator.vhd"]\
 [file normalize "${origin_dir}/../src/pp_csr.vhd"]\
 [file normalize "${origin_dir}/../src/pp_control_unit.vhd"]\
 [file normalize "${origin_dir}/../src/pp_counter.vhd"]\
 [file normalize "${origin_dir}/../src/pp_csr_unit.vhd"]\
 [file normalize "${origin_dir}/../src/pp_register_file.vhd"]\
 [file normalize "${origin_dir}/../src/pp_fetch.vhd"]\
 [file normalize "${origin_dir}/../src/pp_imm_decoder.vhd"]\
 [file normalize "${origin_dir}/../src/pp_decode.vhd"]\
 [file normalize "${origin_dir}/../src/pp_csr_alu.vhd"]\
 [file normalize "${origin_dir}/../src/pp_execute.vhd"]\
 [file normalize "${origin_dir}/../src/pp_memory.vhd"]\
 [file normalize "${origin_dir}/../src/pp_writeback.vhd"]\
 [file normalize "${origin_dir}/../src/pp_core.vhd"]\
 [file normalize "${origin_dir}/../src/pp_icache.vhd"]\
 [file normalize "${origin_dir}/../src/pp_wb_adapter.vhd"]\
 [file normalize "${origin_dir}/../src/pp_wb_arbiter.vhd"]\
 [file normalize "${origin_dir}/../src/pp_novacore.vhd"]\
 [file normalize "${origin_dir}/../src/bw_alu.vhd"]\
 [file normalize "${origin_dir}/../src/csd_alu.vhd"]\
 [file normalize "${origin_dir}/../src/execution_stg1.vhd"]\
 [file normalize "${origin_dir}/../src/execution_stg2.vhd"]\
 [file normalize "${origin_dir}/../src/execution_stg3.vhd"]\
 [file normalize "${origin_dir}/../example/toplevel.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_fifo.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_gpio.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_intercon.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_memory.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_reset.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_timer.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_uart.vhd"]\
 [file normalize "${origin_dir}/../soc/pp_soc_uart.vhd"]\
 [file normalize "${origin_dir}/../src/nv_memsys/nv_arbiter.vhd"]\
 [file normalize "${origin_dir}/../src/nv_memsys/nv_memsys.vhd"]\
 [file normalize "${origin_dir}/../example/fsbl_rom_wrapper.vhd"]\
 [file normalize "${origin_dir}/../src/SRAM-Sky130nm/sram_wrapper_aee_ram.vhd"]\
 [file normalize "${origin_dir}/../src/SRAM-Sky130nm/sram_wrapper_ssbl_ram.vhd"]\
 [file normalize "${origin_dir}/../src/SRAM-Sky130nm/sram_wrapper_main_memory.vhd"]\
 [file normalize "${origin_dir}/../src/SRAM-Sky130nm/sky130_sram_1kbyte_1rw1r_32x256_8.v"]\
 [file normalize "${origin_dir}/../src/SRAM-Sky130nm/sky130_sram_2kbyte_1rw1r_32x512_8.v"]\
 [file normalize "${origin_dir}/../src/pp_fp_register_file.vhd"]\
 [file normalize "${origin_dir}/../src/pp_fp_comparator.vhd"]\
 [file normalize "${origin_dir}/../src/pp_fpu_add.sv"]\
 [file normalize "${origin_dir}/../src/pp_fpu_mul.sv"]\
 [file normalize "${origin_dir}/../src/pp_fpu_div.sv"]\
 [file normalize "${origin_dir}/../src/pp_fpu_sub.sv"]\
 [file normalize "${origin_dir}/../src/fpu_stage1.vhd"]\
 [file normalize "${origin_dir}/../src/fpu_stage2.vhd"]\
 [file normalize "${origin_dir}/../src/fpu_stage3.vhd"]\


]
add_files -fileset sources_1 $files

# Creat Block Design
source ${origin_dir}/block_design.tcl
# Make wrapper for the block design
set wrapper_path [make_wrapper -fileset sources_1 -files [ get_files -norecurse zynq.bd] -top]
add_files -norecurse -fileset sources_1 $wrapper_path


# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}


# Add/Import constrs file and set constrs file properties

set files [list \
 [file normalize "$origin_dir/../constraints/Ultra96_v2.xdc"]\
]
add_files -fileset constrs_1 $files

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

set_property -name "top" -value "zynq_wrapper" -objects [get_filesets sources_1]
set_property -name "top" -value "zynq_wrapper" -objects [get_filesets sim_1]

set_property -name "top_auto_set" -value "0" -objects [get_filesets sources_1]
set_property -name "top_auto_set" -value "0" -objects [get_filesets sim_1]

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xczu3eg-sbva484-1-i -flow {Vivado Synthesis 2023} -strategy "Flow_AlternateRoutability" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Flow_AlternateRoutability" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2023" [get_runs synth_1]
}
 #set_property -name "part" -value "xczu3eg-sbva484-1-i" -objects [get_runs synth_1]

set_property -name "strategy" -value "Flow_AlternateRoutability" -objects [get_runs synth_1]

set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xczu3eg-sbva484-1-i -flow {Vivado Implementation 2023} -strategy "Performance_ExplorePostRoutePhysOpt" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_ExplorePostRoutePhysOpt" [get_runs impl_1]
  set_property flow "Vivado Implementation 2023" [get_runs impl_1]
}

# set obj [get_runs impl_1]
current_run -implementation [get_runs impl_1]
puts "INFO: Project created:${_xil_proj_name_}"
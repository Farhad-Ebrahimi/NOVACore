yosys -import

source "./utils/utils.tcl"

set vhdl_sources {
	../src/aee_rom.vhd
	../src/bpu.vhd
	../src/Bin2Ter.vhd
	../src/CSD_Adder.vhd
	../src/mul_stg3.vhd
	../src/CSD_Sub.vhd
	../src/mul_stg2.vhd
	../src/pp_types.vhd
	../src/pp_constants.vhd
	../src/pp_utilities.vhd
	../src/pp_alu_control_unit.vhd
	../src/pp_alu_mux.vhd
	../src/pp_comparator.vhd
	../src/pp_csr.vhd
	../src/pp_control_unit.vhd
	../src/pp_counter.vhd
	../src/pp_csr_unit.vhd
	../src/pp_register_file.vhd
	../src/pp_fetch.vhd
	../src/pp_imm_decoder.vhd
	../src/pp_decode.vhd
	../src/pp_csr_alu.vhd
	../src/bw_alu.vhd
	../src/execution_stg1.vhd
	../src/csd_alu.vhd
	../src/execution_stg2.vhd
	../src/execution_stg3.vhd
	../src/pp_execute.vhd
	../src/pp_memory.vhd
	../src/pp_writeback.vhd
	../src/pp_core.vhd
}

set synth_options {
	-gPROCESSOR_ID=x"00000000"
	-gRESET_ADDRESS=x"00000000"
	-gMTIME_DIVIDER=5
	-gTIME_DIVIDER=5
}

#foreach lib ${::liberty_files} {
#	read_liberty -lib $lib
#}

ghdl {*}$synth_options {*}$vhdl_sources -e ${design_name}

hierarchy -check -top ${design_name}
flatten
synth
techmap
dfflibmap -liberty ${pdk_path}/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_typ_1p50V_25C.lib

abc -script ./01-synth/abc_speed.script -liberty [lindex $liberty_files 0]

setundef -zero
hilomap -hicell {*}$tiehi_pin -locell {*}$tielo_pin

insbuf -buf {*}$small_buf_port_pin

write_verilog "${res_dir}/01-synth/${design_name}.v"
write_json "${res_dir}/01-synth/${design_name}.json"

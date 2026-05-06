set current_corner     "typ_1p20V_25C"
set design_name        "$::env(DESIGN)"
set utils_dir          "./utils"
set res_dir            "./build"
set pdk_root           "$::env(PDK_ROOT)"
set pdk                "$::env(PDK)"
set pdk_path           "${pdk_root}/${pdk}"
set min_routing_layer  "Metal2"
set max_routing_layer  "TopMetal1"
set cell_pad_side      0
set fill_cells         "sg13g2_fill_1 sg13g2_fill_2 sg13g2_decap_4 sg13g2_decap_8"
set tielo_pin          "sg13g2_tielo L_LO"
set tiehi_pin          "sg13g2_tiehi L_HI"
set small_buf_port_pin "sg13g2_buf_1 A X"
set tielo_pin_path     "[lindex $tielo_pin 0]/[lindex $tielo_pin 1]"
set tiehi_pin_path     "[lindex $tiehi_pin 0]/[lindex $tiehi_pin 1]"
set power_net          "VDD"
set std_power_pin      {^VDD$}
set ground_net         "VSS"
set std_ground_pin     {^VSS$}

set liberty_files "
	${pdk_path}/libs.ref/sg13g2_stdcell/lib/sg13g2_stdcell_${current_corner}.lib
"

#Techlef, cell lef and macro lef
set lef_files "
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
	${pdk_path}/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
"

set cdl_masters "${pdk_path}/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl"

set is_dev_pdk [string equal "dev" [exec {*}[auto_execok git] -C $::pdk_root branch --show-current]]

set dont_use_cells {sg13g2_lgcp_1 sg13g2_sighold sg13g2_slgcp_1 sg13g2_dfrbp_2}

set horizontal_pin_layer "Metal2"
set vertical_pin_layer "Metal3"
if {$is_dev_pdk == 1} {
	set horizontal_pin_layer "Metal3"
	set vertical_pin_layer "Metal2"
}

proc read_libs {} {
	define_corner ${::current_corner}
	foreach lib ${::liberty_files} {
		read_liberty -corner ${::current_corner} $lib
	}
}

proc read_netlist {last_step} {
	if { [ file exists "${::res_dir}/${last_step}/${::design_name}.pnl.v" ] } {
		read_verilog "${::res_dir}/${last_step}/${::design_name}.pnl.v"
	} elseif { [ file exists "${::res_dir}/${last_step}/${::design_name}.nl.v" ] } {
		read_verilog "${::res_dir}/${last_step}/${::design_name}.nl.v"
	} else {
		read_verilog "${::res_dir}/${last_step}/${::design_name}.v"
	}
	link_design ${::design_name}

	read_sdc "${::utils_dir}/base.sdc"
}

proc read_lefs {} {
	foreach lef ${::lef_files} {
		read_lef $lef
	}
}

proc read_design {last_step} {
	if { [ file exists "${::res_dir}/${last_step}/${::design_name}.odb" ] } {
		read_db "${::res_dir}/${last_step}/${::design_name}.odb"
	} else {
		read_lefs
	}
	read_libs
	read_sdc "${::utils_dir}/base.sdc"
}

proc write_design {this_step} {
	write_db "${::res_dir}/${this_step}/${::design_name}.odb"
	write_verilog "${::res_dir}/${this_step}/${::design_name}.nl.v"
	write_verilog -include_pwr_gnd "${::res_dir}/${this_step}/${::design_name}.pnl.v"
	write_def "${::res_dir}/${this_step}/${::design_name}.def"
	write_sdc "${::res_dir}/${this_step}/${::design_name}.sdc"
	write_cdl -include_fillers -masters ${::cdl_masters} "${::res_dir}/${this_step}/${::design_name}.cdl"
}

proc set_rc {} {
	set_wire_rc -signal -layers {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2}
	set_wire_rc -clock -layers {Metal1 Metal2 Metal3 Metal4 Metal5 TopMetal1 TopMetal2}
}

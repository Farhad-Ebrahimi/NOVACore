set last_step      "02-sta"
set this_step      "03-fp"
set site_name      "CoreSite"
set utilization    70
set sram_power_pin "VDDARRAY!"
set halo_width     10
set macro_width    784.480
set macro_height   64.585
# Using the default from openlane
set bt_margin_mul  4
set lr_margin_mul  12

set manual_placement 0
set die_bound 30

source "./utils/utils.tcl"

read_libs
read_lefs
read_netlist ${last_step}

set ::db [::ord::get_db]
set ::chip [$::db getChip]
set ::tech [$::db getTech]
set ::libs [$::db getLibs]
set llx $die_bound
set lly $die_bound
set urx [expr 2 * $halo_width + $macro_width + $die_bound]
set ury [expr 4 * $halo_width + 3 * $macro_height + $die_bound]
eval "set core_area { $llx $lly $urx $ury }"
eval "set die_area { [expr $llx - $die_bound] [expr $lly - $die_bound] [expr $urx + $die_bound] [expr $ury + $die_bound] }"

foreach lib $::libs {
	set current_sites [$lib getSites]
	foreach site $current_sites {
		set name [$site getName]
		set ::sites($name) $site
	}
}

set core_site $::sites($name)
set core_site_w [expr [$core_site getWidth]  / double([$::tech getDbUnitsPerMicron])]
set core_site_h [expr [$core_site getHeight] / double([$::tech getDbUnitsPerMicron])]

set bt_margin   [expr $core_site_w * $bt_margin_mul]
set lr_margin   [expr $core_site_h * $lr_margin_mul]


if {$manual_placement == 1} {
	initialize_floorplan -site $site_name \
		-die_area $die_area \
		-core_area $core_area
} else {
	initialize_floorplan -site $site_name \
		-utilization $utilization \
		-aspect_ratio 1 \
		-core_space "$bt_margin $bt_margin $lr_margin $lr_margin"
}

insert_tiecells $tielo_pin_path -prefix "TIE_ZERO_"
insert_tiecells $tiehi_pin_path -prefix "TIE_ONE_"

add_global_connection -net $power_net -pin_pattern $std_power_pin -power
add_global_connection -net $ground_net -pin_pattern $std_ground_pin -ground
add_global_connection -net $power_net -pin_pattern $sram_power_pin -power

report_design_area_metrics
report_cell_usage

# Fetches information from the Tech-LEF
make_tracks
remove_buffers
place_pins -hor_layers $horizontal_pin_layer -ver_layers $vertical_pin_layer -random

if {$manual_placement == 1} {
	eval "set macro_location1 { [expr $halo_width + $die_bound] [expr $halo_width + $die_bound] }"
	eval "set macro_location2 { [expr $halo_width + $die_bound] [expr 2 * $halo_width + $macro_height + $die_bound] }"
	eval "set macro_location3 { [expr $halo_width + $die_bound] [expr 3 * $halo_width + 2 * $macro_height + $die_bound]}"

	place_macro -macro_name "banks:1.bank.i_ram" -location $macro_location1
	place_macro -macro_name "banks:2.bank.i_ram" -location $macro_location2
	place_macro -macro_name "banks:3.bank.i_ram" -location $macro_location3 -orientation "R180"
} else {
	rtl_macro_placer -halo_width $halo_width -halo_height $halo_width
}

# IHP PDK seems to include no Encap or Welltie cells, so we only cut rows
cut_rows

##########################################################################################
####                  Power-Distribution-Network Generation                           ####
##########################################################################################

global_connect
report_global_connect

#set_debug_level "PDN" "Straps" 3
#set_debug_level "PDN" "Channel" 3

set pdn_stripe_layer "Metal5"
if { $is_dev_pdk == 1 } {
	set pdn_stripe_layer "TopMetal1"
}

set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}
define_pdn_grid -name {grid} -voltage_domain {CORE} -pins {TopMetal1}
add_pdn_stripe -grid {grid} -layer {Metal1}     -width {0.44}  -offset {0}      -followpins
add_pdn_stripe -grid {grid} -layer $pdn_stripe_layer     -width {2.81}  -pitch {11.24} -offset {2.810} -spacing {2.810}
add_pdn_connect -grid {grid} -layers "Metal1 $pdn_stripe_layer"

pdngen

write_design ${this_step}

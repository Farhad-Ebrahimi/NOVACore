set last_step "05-cts"
set this_step "06-rt"

source "./utils/utils.tcl"
read_design ${last_step}
set_rc

set_global_routing_layer_adjustment ${min_routing_layer}-${max_routing_layer} 0.05
set_routing_layers -signal ${min_routing_layer}-${max_routing_layer}
set_placement_padding -global -right $cell_pad_side -left $cell_pad_side

set_propagated_clock [all_clocks]

global_route -allow_congestion -congestion_iterations 5 -congestion_report $res_dir/${this_step}/congestion.rpt

repair_antennas
detailed_placement
check_placement -verbose -report_file $res_dir/${this_step}/placement.rpt
check_antennas -verbose -report_file $res_dir/${this_step}/grt_antennas.rpt
estimate_parasitics -global_routing

##########################################################################################
####                                 Detailed Routing                                 ####
##########################################################################################

set drt_args "-output_drc $res_dir/${this_step}/route_drc.rpt"
append drt_args " -output_maze $res_dir/${this_step}/maze.log"

detailed_route {*}$drt_args

set repair_antennas_iters 1
if {[repair_antennas]} {
	detailed_route {*}$drt_args
}
while {[check_antennas] && $repair_antennas_iters < 5} {
	repair_antennas
	detailed_route {*}$drt_args
	incr repair_antennas_iters
}

check_antennas -report_file $res_dir/${this_step}/drt_antennas.rpt

if {![design_is_routed]} {
	error "Design no routed"
}

##########################################################################################
####                              Filler Placement                                    ####
##########################################################################################

filler_placement $fill_cells
# Filler_placement also places decap cells
global_connect
check_placement

write_design ${this_step}
write_guides $res_dir/${this_step}/route.guide
write_lef $res_dir/${this_step}/${design_name}.lef
write_abstract_lef $res_dir/${this_step}/${design_name}.abstract.lef
write_timing_model -library_name "${design_name}" -corner $current_corner $res_dir/${this_step}/${design_name}.lib

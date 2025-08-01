set last_step "03-fp"
set this_step "04-plc"
set decap_cell "sg13g2_decap_4"
set halo_width 10

source "./utils/utils.tcl"
read_design ${last_step}

global_placement -skip_io -pad_left 1 -pad_right 1

place_pins -hor_layers $horizontal_pin_layer -ver_layers $vertical_pin_layer -min_distance 6

#proc ::TracePuts args {
#	puts $args
#}
#trace add execution set_wire_rc {enterstep leavestep} ::TracePuts
set_rc

global_placement -skip_io -pad_left 1 -pad_right 1
estimate_parasitics -placement

##########################################################################################
#####                               Resize                                           #####
##########################################################################################
set_dont_use $dont_use_cells

repair_design

set tielo_pin      "sg13g2_tielo/L_LO"
set tiehi_pin      "sg13g2_tiehi/L_HI"

repair_tie_fanout [get_lib_pin $tielo_pin]
repair_tie_fanout [get_lib_pin $tiehi_pin]

##########################################################################################
#####                          Detailed Placement                                    #####
##########################################################################################

set_placement_padding -global -left 1 -right 1
detailed_placement
improve_placement -max_displacement {5 1}
optimize_mirroring
estimate_parasitics -placement

write_design ${this_step}

set last_step "04-plc"
set this_step "05-cts"

set buf_cells { sg13g2_buf_16 sg13g2_buf_8 sg13g2_buf_4 sg13g2_buf_2 sg13g2_buf_1 }

source "./utils/utils.tcl"
read_design ${last_step}
set_rc

repair_clock_inverters

clock_tree_synthesis -buf_list $buf_cells

set_propagated_clock [all_clocks]
estimate_parasitics -placement
repair_clock_nets

detailed_placement
repair_timing -match_cell_footprint

global_connect

report_cts -out_file "$res_dir/${this_step}/cts.rpt"

write_design ${this_step}

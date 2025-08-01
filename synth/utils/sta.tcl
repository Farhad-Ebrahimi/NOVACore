source "./utils/utils.tcl"

set sdf_save_dir "./$res_dir/${this_step}/sdf"
set lib_save_dir "./$res_dir/${this_step}/lib"

define_corner ${current_corner}
foreach lib ${::liberty_files} {
	read_liberty -corner ${current_corner} $lib
}

if { [file exists ./$res_dir/${last_step}/${design_name}.nl.v ] } {
    read_verilog ./$res_dir/${last_step}/${design_name}.nl.v
} else {
    read_verilog ./$res_dir/${last_step}/${design_name}.v
}
link_design ${design_name}

read_sdc "./utils/base.sdc"

puts "\[INFO] Creating report min.rpt"
set chan [open $res_dir/${this_step}/min.rpt w]
puts $chan "\n==========================================================================="
puts $chan "report_checks -path_delay min (Hold)"
puts $chan "============================================================================"
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_checks -sort_by_slack -path_delay min -fields {slew cap input nets fanout} -format full_clock_expanded -group_count 1000 -corner ${current_corner} >> $res_dir/${this_step}/min.rpt


puts "\[INFO] Creating report max.rpt"
set chan [open $res_dir/${this_step}/max.rpt w]
puts $chan "\n==========================================================================="
puts $chan "report_checks -path_delay max (Setup)"
puts $chan "============================================================================"
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_checks -sort_by_slack -path_delay max -fields {slew cap input nets fanout} -format full_clock_expanded -group_count 1000 -corner ${current_corner} >> $res_dir/${this_step}/max.rpt


puts "\[INFO] Creating report checks.rpt"
set chan [open $res_dir/${this_step}/checks.rpt w]
puts $chan "\n==========================================================================="
puts $chan "report_checks -unconstrained"
puts $chan "==========================================================================="
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_checks -unconstrained -fields {slew cap input nets fanout} -format full_clock_expanded -corner ${current_corner} >> $res_dir/${this_step}/checks.rpt


set chan [open $res_dir/${this_step}/checks.rpt a]
puts $chan "\n==========================================================================="
puts $chan "report_checks --slack_max -0.01"
puts $chan "============================================================================"
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_checks -slack_max -0.01 -fields {slew cap input nets fanout} -format full_clock_expanded -corner ${current_corner} >> $res_dir/${this_step}/checks.rpt

set chan [open $res_dir/${this_step}/checks.rpt a]
puts $chan "\n==========================================================================="
puts $chan " report_check_types -max_slew -max_cap -max_fanout -violators"
puts $chan "============================================================================"
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_check_types -max_slew -max_capacitance -max_fanout -violators -corner ${current_corner} >> $res_dir/${this_step}/checks.rpt

set chan [open $res_dir/${this_step}/checks.rpt a]
puts $chan "\n==========================================================================="
puts $chan "report_parasitic_annotation -report_unannotated"
puts $chan "============================================================================"
close $chan
report_parasitic_annotation -report_unannotated >> $res_dir/${this_step}/checks.rpt

set chan [open $res_dir/${this_step}/checks.rpt a]
puts $chan "\n==========================================================================="
puts $chan "max slew violation count [sta::max_slew_violation_count]"
puts $chan "max fanout violation count [sta::max_fanout_violation_count]"
puts $chan "max cap violation count [sta::max_capacitance_violation_count]"
puts $chan "============================================================================"

puts $chan "\n==========================================================================="
puts $chan "check_setup -verbose -unconstrained_endpoints -multiple_clock -no_clock -no_input_delay -loops -generated_clocks"
puts $chan "==========================================================================="
close $chan
check_setup -verbose -unconstrained_endpoints -multiple_clock -no_clock -no_input_delay -loops -generated_clocks >> $res_dir/${this_step}/checks.rpt



puts "\[INFO] Creating report power.rpt"
set chan [open $res_dir/${this_step}/power.rpt w]
puts $chan "\n==========================================================================="
puts $chan " report_power"
puts $chan "============================================================================"
puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_power -corner ${current_corner} >> $res_dir/${this_step}/power.rpt


set chan [open $res_dir/${this_step}/skew.min.rpt w]
puts $chan "\[INFO] Creating report skew.min.rpt"
puts $chan "\n==========================================================================="
puts $chan "Clock Skew (Hold)"
puts $chan "============================================================================"
set skew_corner [worst_clock_skew -hold]

puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_clock_skew -corner ${current_corner} -hold >> $res_dir/${this_step}/skew.min.rpt


puts "\[INFO] Creating report skew.max.rpt"
set chan [open $res_dir/${this_step}/skew.max.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Clock Skew (Setup)"
puts $chan "============================================================================"
set skew_corner [worst_clock_skew -setup]

puts $chan "======================= ${current_corner} Corner ===================================\n"
close $chan
report_clock_skew -corner ${current_corner} -setup >> $res_dir/${this_step}/skew.max.rpt


puts "\[INFO] Creating report ws.min.rpt"
set chan [open $res_dir/${this_step}/ws.min.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Worst Slack (Hold)"
puts $chan "============================================================================"
set ws [worst_slack -corner ${current_corner} -min]
puts $chan "${current_corner}: $ws"
close $chan

puts "\[INFO] Creating report ws.max.rpt"
set chan [open $res_dir/${this_step}/ws.max.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Worst Slack (Setup)"
puts $chan "============================================================================"

set ws [worst_slack -corner ${current_corner} -max]
puts $chan "${current_corner}: $ws"

puts $chan "\[INFO] Creating report tns.min.rpt"
puts $chan "\n==========================================================================="
puts $chan "Total Negative Slack (Hold)"
puts $chan "============================================================================"

set tns [total_negative_slack -corner ${current_corner} -min]
puts $chan "${current_corner}: $tns"
close $chan

puts "\[INFO] Creating report tns.max.rpt"
set chan [open $res_dir/${this_step}/tns.max.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Total Negative Slack (Setup)"
puts $chan "============================================================================"
set tns [total_negative_slack -corner ${current_corner} -max]
puts $chan "${current_corner}: $tns"
close $chan

puts "\[INFO] Creating report wns.min.rpt"
set chan [open $res_dir/${this_step}/ws.min.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Worst Negative Slack (Hold)"
puts $chan "============================================================================"

set ws [worst_slack -corner ${current_corner} -min]
set wns 0
if { $ws < 0 } {
    set wns $ws
}
puts $chan "${current_corner}: $wns"
close $chan

puts "\[INFO] Creating report wns.max.rpt"
set chan [open $res_dir/${this_step}/ws.max.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Worst Negative Slack (Setup)"
puts $chan "============================================================================"

set ws [worst_slack -corner ${current_corner} -max]
set wns 0.0
if { $ws < 0 } {
    set wns $ws
}
puts $chan "${current_corner}: $wns"
close $chan

proc check_if_terminal {pin_object} {
    set net [get_nets -of_object $pin_object]
    if { "$net" == "NULL" } {
        return 1
    }
    return 0
}

proc get_path_kind {start_pin end_pin} {
    set from "reg"
    set to "reg"

    if { [check_if_terminal $start_pin] } {
        set from "in"
    }
    if { [check_if_terminal $end_pin] } {
        set to "out"
    }
    return "$from-$to"
}

puts "\[INFO] Creating report violator_list.rpt"
set chan [open $res_dir/${this_step}/wiolator_list.rpt w]
puts $chan "\n==========================================================================="
puts $chan "Violator List"
puts $chan "============================================================================"

set total_hold_vios 0
set r2r_hold_vios 0
set total_setup_vios 0
set r2r_setup_vios 0

set max_violator_count 999999999
if { [info exists ::env(STA_MAX_VIOLATOR_COUNT)] } {
    set max_violator_count $::env(STA_MAX_VIOLATOR_COUNT)
}

set hold_violating_paths [find_timing_paths -unique_paths_to_endpoint -path_delay min -sort_by_slack -group_count $max_violator_count -slack_max 0]
foreach path $hold_violating_paths {
    set start_pin [get_property $path startpoint]
    set end_pin [get_property $path endpoint]
    set kind "[get_path_kind $start_pin $end_pin]"
    set slack [get_property $path slack]

    if { $slack >= 0 } {
        continue
    }

    incr total_hold_vios
    if { "$kind" == "reg-reg" } {
        incr r2r_hold_vios
    }
    puts $chan "\[hold $kind] [get_property $start_pin full_name] -> [get_property $end_pin full_name] : [get_property $path slack]"
}

set worst_r2r_hold_slack 1e30
set hold_paths [find_timing_paths -unique_paths_to_endpoint -path_delay min -sort_by_slack -group_count $max_violator_count -slack_max $worst_r2r_hold_slack]
foreach path $hold_paths {
    set start_pin [get_property $path startpoint]
    set end_pin [get_property $path endpoint]
    set kind "[get_path_kind $start_pin $end_pin]"
    set slack [get_property $path slack]

    if { "$kind" == "reg-reg" } {
        set slack [get_property $path slack]

        if { $slack < $worst_r2r_hold_slack } {
            set worst_r2r_hold_slack $slack
        }
    }
}

set setup_violating_paths [find_timing_paths -unique_paths_to_endpoint -path_delay max -sort_by_slack -group_count $max_violator_count -slack_max 0]
foreach path $setup_violating_paths {
    set start_pin [get_property $path startpoint]
    set end_pin [get_property $path endpoint]
    set kind "[get_path_kind $start_pin $end_pin]"
    set slack [get_property $path slack]

    if { $slack >= 0 } {
        continue
    }

    incr total_setup_vios
    if { "$kind" == "reg-reg" } {
        incr r2r_setup_vios
    }
    puts $chan "\[setup $kind] [get_property $start_pin full_name] -> [get_property $end_pin full_name] : [get_property $path slack]"
}

set worst_r2r_setup_slack 1e30
set setup_paths [find_timing_paths -unique_paths_to_endpoint -path_delay max -sort_by_slack -group_count $max_violator_count -slack_max $worst_r2r_setup_slack]
foreach path $setup_paths {
    set start_pin [get_property $path startpoint]
    set end_pin [get_property $path endpoint]
    set kind "[get_path_kind $start_pin $end_pin]"
    set slack [get_property $path slack]

    if { "$kind" == "reg-reg" } {
        set slack [get_property $path slack]
        if { $slack < $worst_r2r_setup_slack } {
            set worst_r2r_setup_slack $slack
        }
    }
}

close $chan

puts "\[INFO] Creating report unpropagated.rpt"
set chan [open $res_dir/${this_step}/unpropagated.rpt w]

foreach clock [all_clocks] {
    if { ![get_property $clock is_propagated] } {
        puts $chan "[get_property $clock full_name]"
    }
}

close $chan


puts "\[INFO] Creating report clock.rpt"
set chan [open $res_dir/${this_step}/clock.rpt w]

foreach clock [all_clocks] {
    set source_names ""
    set is_generated "no"
    set is_virtual "no"
    set is_propagated "no"
    foreach source [get_property $clock sources] {
        set source_names "[get_property $source full_name] $source_names"
    }
    if { [get_property $clock is_generated] } {
        set is_generated "yes"
    }
    if { [get_property $clock is_virtual] } {
        set is_virtual "yes"
    }
    if { [get_property $clock is_propagated] } {
        set is_virtual "yes"
    }
    puts $chan "Clock: [get_property $clock name]"
    puts $chan "Sources: $source_names"
    puts $chan "Generated: $is_generated"
    puts $chan "Virtual: $is_virtual"
    puts $chan "Propagated: $is_propagated"
    puts $chan "Period: [get_property $clock period]"
    puts $chan "\n==========================================================================="
    puts $chan "report_clock_properties"
    puts $chan "============================================================================"
    close $chan
    report_clock_properties $clock >> $res_dir/${this_step}/clock.rpt
    set chan [open $res_dir/${this_step}/clock.rpt a]
    puts $chan "\n==========================================================================="
    puts $chan "report_clock_latency"
    puts $chan "============================================================================"
    close $chan
    report_clock_latency -clock $clock >> $res_dir/${this_step}/clock.rpt
    set chan [open $res_dir/${this_step}/clock.rpt a]
    puts $chan "\n==========================================================================="
    puts $chan "report_clock_min_period"
    puts $chan "============================================================================"
    close $chan
    report_clock_min_period -clocks [get_property $clock name] >> $res_dir/${this_step}/clock.rpt
}


proc write_sdfs {} {
    if { [info exists ::sdf_save_dir] } {
        set corners [sta::corners]

        puts "Writing SDF files for all corners…"
        foreach corner $corners {
            set corner_name [$corner name]
            set target ${::sdf_save_dir}/${::design_name}__$corner_name.sdf
            write_sdf -include_typ -divider . -corner $corner_name $target
        }
    }
}

proc write_libs {} {
    if { [info exists ::lib_save_dir] } {
        puts "Removing Clock latencies before writing libs…"
        # This is to avoid OpenSTA writing a context-dependent timing model
        set_clock_latency -source -max 0 [all_clocks]
        set_clock_latency -source -min 0 [all_clocks]
        set corners [sta::corners]
        puts "Writing timing models for all corners…"
        foreach corner $corners {
            set corner_name [$corner name]
            set target ${::lib_save_dir}/${::design_name}__$corner_name.lib
            puts "Writing timing models for the $corner_name corner to $target…"
            write_timing_model -corner $corner_name $target
        }
    }
}


write_sdfs
write_libs
write_verilog "$res_dir/${this_step}/${design_name}.nl.v"
write_verilog -include_pwr_gnd "$res_dir/${this_step}/${design_name}.pnl.v"

set last_step "06-rt"
set this_step "07-misc"

source "./utils/utils.tcl"
read_design ${last_step}
set_rc

extract_parasitics -ext_model_file $::env(RCX_RULES)
write_spef ${::res_dir}/${::this_step}/${design_name}.spef

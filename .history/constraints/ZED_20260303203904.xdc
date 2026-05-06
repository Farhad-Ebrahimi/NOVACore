#### Primary clock: 100 MHz board clock
create_clock -name sys_clk -period 10.000 [get_ports clk]

#### Generated clock: Core clock from Clock Wizard IP
# Frequency set in clk_wiz_0 IP configuration (41 MHz or 58 MHz)
# Vivado will auto-derive period from IP settings
create_generated_clock -name clk_core \
  -source [get_ports clk] \
  [get_pins u_clkgen/clk_out]

# Note: If auto-derivation fails, manually specify:
# For 41 MHz: -divide_by 122 -multiply_by 50
# For 58 MHz: -divide_by 50 -multiply_by 29

# ==============================
# CLOCK INPUT (100 MHz)
# ==============================
set_property PACKAGE_PIN Y9 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# ==============================
# RESET BUTTON (BTNU / BTN0)
# ==============================
set_property PACKAGE_PIN T18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# ==============================
# STALL INPUT (assigned to BTNR pushbutton)
# ==============================
set_property PACKAGE_PIN R16 [get_ports stall]
set_property IOSTANDARD LVCMOS33 [get_ports stall]

# ==============================
# UART TX OUTPUT (FPGA to USB via PMOD)   (not used)
# ==============================
set_property PACKAGE_PIN Y11 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

# ==============================
# Monitor Outputs (for debug/visibility)
# ==============================
set_property PACKAGE_PIN W13 [get_ports monitor_valid]
set_property IOSTANDARD LVCMOS33 [get_ports monitor_valid]

set_property PACKAGE_PIN W15 [get_ports {monitor_pc[0]}]
set_property PACKAGE_PIN V15 [get_ports {monitor_pc[1]}]
set_property PACKAGE_PIN U17 [get_ports {monitor_pc[2]}]
set_property PACKAGE_PIN V14 [get_ports {monitor_pc[3]}]
set_property PACKAGE_PIN V13 [get_ports {monitor_pc[4]}]
set_property PACKAGE_PIN AB17 [get_ports {monitor_pc[5]}]
set_property PACKAGE_PIN AA17 [get_ports {monitor_pc[6]}]
set_property PACKAGE_PIN Y15 [get_ports {monitor_pc[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {monitor_pc[*]}]


set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]


# MARK_DEBUG for Internal Nets Only
# ==============================
set_property MARK_DEBUG true [get_nets debug_add_result]
set_property MARK_DEBUG true [get_nets debug_sub_result]
set_property MARK_DEBUG true [get_nets debug_mul_result]
set_property MARK_DEBUG true [get_nets debug_div_result]
set_property MARK_DEBUG true [get_nets monitor_pc] 

# NEW MARK_DEBUG signals for pipeline state, memory, and writeback:
set_property MARK_DEBUG true [get_nets internal_stall]
set_property MARK_DEBUG true [get_nets pc_out]
set_property MARK_DEBUG true [get_nets imem_address]
set_property MARK_DEBUG true [get_nets imem_instruction]
set_property MARK_DEBUG true [get_nets ifu_valid_out]
set_property MARK_DEBUG true [get_nets decode_valid_out]
set_property MARK_DEBUG true [get_nets ex_valid_out]
set_property MARK_DEBUG true [get_nets mem_valid_out]
set_property MARK_DEBUG true [get_nets wb_valid_out]
set_property MARK_DEBUG true [get_nets {wb_rd_out[*]}] 
set_property MARK_DEBUG true [get_nets {wb_result_out[*]}] # For multi-bit signal
set_property MARK_DEBUG true [get_nets wb_reg_write_en]


set_property MARK_DEBUG true [get_nets {reg_file[0]}]
set_property MARK_DEBUG true [get_nets {reg_file[1]}]
set_property MARK_DEBUG true [get_nets {reg_file[4]}]
set_property MARK_DEBUG true [get_nets {reg_file[5]}]
set_property MARK_DEBUG true [get_nets {reg_file[2]}]
set_property MARK_DEBUG true [get_nets {reg_file[3]}]
set_property MARK_DEBUG true [get_nets {reg_file[8]}]
set_property MARK_DEBUG true [get_nets {reg_file[12]}]
set_property MARK_DEBUG true [get_nets {opcode}]
set_property MARK_DEBUG true [get_nets decode_instruction_out]



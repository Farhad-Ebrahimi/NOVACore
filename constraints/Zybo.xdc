# The Potato Processor - A simple processor for FPGAs
# (c) Kristian Klomsten Skordal 2016 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

# Set operating conditions to improve temperature estimation:
set_operating_conditions -airflow 0
set_operating_conditions -heatsink low

# Clock signal:
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} [get_ports clk]

# Reset button:
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports reset_n]

# GPIOs (Buttons):
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[0]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[1]}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[2]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[3]}]

# GPIO (Switches):
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[4]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[5]}]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[6]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[7]}]

# GPIOs (LEDs):
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[8]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[9]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[10]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[11]}]


# UART1 (pin 5 and 6 on JA, to match the pins on the PMOD-GPS):
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports uart0_txd]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports uart0_rxd]

# UART0:
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports uart1_txd]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports uart1_rxd]




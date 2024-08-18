# Set operating conditions to improve temperature estimation:
set_operating_conditions -airflow 0
set_operating_conditions -heatsink low

# Set the bank voltage for IO Bank 26 to 1.8V
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 26]];

# GPIOs (Buttons):
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[0]}]
set_property -dict {PACKAGE_PIN E6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[1]}]
set_property -dict {PACKAGE_PIN E5 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[2]}]
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[3]}]

# GPIO (Switches):
set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[4]}]
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[5]}]
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[6]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[7]}]

# GPIOs (LEDs):
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[8]}]
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[9]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[10]}]
set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS18} [get_ports {gpio_pins[11]}]

# UART0:
#set_property -dict {PACKAGE_PIN D7 IOSTANDARD LVCMOS18} [get_ports uart0_txd]
#set_property -dict {PACKAGE_PIN F8 IOSTANDARD LVCMOS18} [get_ports uart0_rxd]

# UART1 (pin 5 and 6 on JA, to match the pins on the PMOD-GPS):
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS12} [get_ports {uart1_txd}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS12} [get_ports {uart1_rxd}]

#rst_gpio led # "A9.RADIO_LED0"
set_property -dict {PACKAGE_PIN A9 IOSTANDARD LVCMOS18} [get_ports {led}];  

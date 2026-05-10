# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Fri May 08 15:03:25 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design siso_right_shift

create_clock -name "clk" -period 2.0 -waveform {0.0 1.0} [get_ports clk]
set_clock_transition 0.1 [get_clocks clk]
set_load -pin_load 0.15 [get_ports serial_out]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 0.8 [get_ports reset]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.8 [get_ports serial_in]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.8 [get_ports serial_out]
set_max_fanout 20.000 [current_design]
set_input_transition 0.12 [get_ports clk]
set_input_transition 0.12 [get_ports reset]
set_input_transition 0.12 [get_ports serial_in]
set_wire_load_mode "enclosed"
set_clock_uncertainty -setup 0.01 [get_clocks clk]
set_clock_uncertainty -hold 0.01 [get_clocks clk]

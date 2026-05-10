# SDC Constraints for 4-bit Right Shift Register (SISO)

create_clock -name clk -period 2 -waveform {0 1} [get_ports clk]

set_clock_transition -rise 0.1 [get_clocks clk]
set_clock_transition -fall 0.1 [get_clocks clk]

set_clock_uncertainty 0.01 [get_clocks clk]

set_input_transition 0.12 [all_inputs]

set_input_delay -max 0.8 [get_ports reset] -clock [get_clocks clk]
set_input_delay -max 0.8 [get_ports serial_in] -clock [get_clocks clk]

set_output_delay -max 0.8 [get_ports serial_out] -clock [get_clocks clk]

set_load 0.15 [all_outputs]

set_max_fanout 20 [current_design]

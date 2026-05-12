read_libs slow.lib
read_hdl counter.v
elaborate
read_sdc constraints.sdc
set_db syn_generic_effort medium 
set_db syn_map_effort medium
set_db syn_opt_effort medium
syn_generic
syn_map
syn_opt
report_timing > counter_timing.rep
report_area > counter_area.rep
report_power > counter_power.rep
write_hdl > counter_netlist.v
write_sdc > counter_output_constaints.sdc
report_gates > counter_gates.v
gui_show

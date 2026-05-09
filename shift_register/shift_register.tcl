read_libs /home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib
read_hdl reg.v
elaborate
read_sdc reg.sdc
set_db syn_generic_effort medium 
set_db syn_map_effort medium
set_db syn_opt_effort medium
syn_generic
syn_map
syn_opt
report_timing > reg_timing.rep
report_area > reg_area.rep
report_power > reg_power.rep
write_hdl > reg_netlist.v
write_sdc > reg_output_constaints.sdc
report_gates > reg_gates.v
gui_show

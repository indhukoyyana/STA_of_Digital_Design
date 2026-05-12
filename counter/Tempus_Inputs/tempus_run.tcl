
# STEP 1: Read liberty library

read_libs slow.lib


# STEP 2: Read synthesized gate-level netlist

read_verilog counter_netlist.v


# STEP 3: Set top module

set_top_module counter


# STEP 4: Read SDC constraints

read_sdc counter_constraints.sdc


# STEP 5: Update timing graph

update_timing


# STEP 6: Setup timing report  (max delay)

report_timing \
    -delay_type max \
    -path_type  full_clock \
    -max_paths  20 \
    -nworst     5 \
    > setup_report.rpt


# STEP 7: Hold timing report  (min delay)

report_timing \
    -delay_type min \
    -path_type  full_clock \
    -max_paths  20 \
    -nworst     5 \
    > hold_report.rpt


# STEP 8: Timing summary report  (WNS, TNS, WHS, THS)

report_timing_summary \
    -max_paths 50 \
    > timing_summary.rpt


# STEP 9: Clock report

report_clock \
    -skew \
    -latency \
    -uncertainty \
    > clock_report.rpt


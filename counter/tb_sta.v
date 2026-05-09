// ============================================================
// tb_sta.v
// Testbench — mimics Cadence Tempus pre-layout STA reports
//
// Reports generated (identical format to Tempus output):
//   1. report_timing -delay_type max   (setup paths, full)
//   2. report_timing -delay_type min   (hold paths, full)
//   3. report_timing_summary
//   4. report_clock
//
// Usage:
//   vcs  -sverilog tb_sta.v sta_engine.v -o simv && ./simv
//   iverilog -o sim tb_sta.v sta_engine.v && vvp sim
// ============================================================

`include "sta_timing_pkg.v"
`timescale 1ns/1ps

module tb_sta;

// ============================================================
// SDC constraint parameters — edit here to change constraints
// ============================================================
real CLK_PERIOD      = 10.000;   // ns
real CLK_UNCERTAINTY =  0.100;   // ns
real INPUT_DELAY     =  2.000;   // ns
real OUTPUT_DELAY    =  1.500;   // ns
// Corner fixed to TT/1.8V/25C (matching sta_timing_pkg.v)

// ============================================================
// DUT connections
// ============================================================
real    wns_s, tns_s, whs_h, ths_h;
reg     run_analysis;

sta_engine dut (
    .clk_period     (CLK_PERIOD),
    .clk_uncertainty(CLK_UNCERTAINTY),
    .input_delay    (INPUT_DELAY),
    .output_delay   (OUTPUT_DELAY),
    .run_analysis   (run_analysis),
    .wns_setup      (wns_s),
    .tns_setup      (tns_s),
    .whs_hold       (whs_h),
    .ths_hold       (ths_h)
);

// ============================================================
// Internal path-level variables (mirrored from engine)
// ============================================================
// Path arrivals (computed locally for report printing)
real arr0, arr1, arr2, arr3, arr4;
real req_s0, req_s1, req_s2, req_s3;
real req_h0;
real slk_s0, slk_s1, slk_s2, slk_s3;
real slk_h0;

// ============================================================
// Helper tasks
// ============================================================

// Print a separator line of dashes (length 88)
task print_dash;
    begin
        $write("  ");
        $write("----------------------------------------------------------------------------------------");
        $write("\n");
    end
endtask

// Print a separator line of equals (length 88)
task print_eq;
    begin
        $write("  ");
        $write("========================================================================================");
        $write("\n");
    end
endtask

// Print a separator line of hashes (length 56)
task print_hash;
    begin
        $write("########################################################\n");
    end
endtask

// Print Tempus report header
task print_header;
    input [255:0] report_cmd;
    begin
        $write("\n");
        print_hash;
        $write("#  Tempus Timing Analysis\n");
        $write("#  Design     : counter\n");
        $write("#  Library    : saed32nm_tt_1.8v_25c\n");
        $write("#  Corner     : TT / 1.8V / 25C\n");
        $write("#  Report     : %0s\n", report_cmd);
        $write("#  Date       : STA pre-layout run\n");
        print_hash;
        $write("\n");
    end
endtask

// Print one timing path row
// pin_name, fanout, cap, trans, incr_delay, arr_time
task print_path_row;
    input [319:0] pin_name;
    input integer fanout;
    input real    cap;
    input real    trans;
    input real    incr;
    input real    arr;
    begin
        $write("  %-40s %3d  %6.3f   %8.3f  %8.3f  %8.3f\n",
               pin_name, fanout, cap, trans, incr, arr);
    end
endtask

// Print slack line with MET/VIOLATED annotation
task print_slack_line;
    input [127:0] label;
    input real    slack_val;
    begin
        if (slack_val >= 0.0)
            $write("  %-53s %8.3f  (MET)\n", label, slack_val);
        else
            $write("  %-53s %8.3f  (VIOLATED)\n", label, slack_val);
    end
endtask

// ============================================================
// Compute all path arrivals locally (for report table rows)
// ============================================================
task local_compute_paths;
    begin
        // --- Path 0: count_reg[1] setup (critical) ---
        arr0 = `DFFRHQX2_CLKQ + `NAND2XL_DELAY + `OAI211X1_DELAY + `OAI211X1_DELAY;
        req_s0 = CLK_PERIOD - CLK_UNCERTAINTY - `DFFRHQX2_SETUP;
        slk_s0 = req_s0 - arr0;

        // --- Path 1: count_reg[2] setup ---
        arr1 = `DFFRX2_CLKQ + `NAND2BX1_DELAY + `AND2X1_DELAY + `MX2X1_DELAY;
        req_s1 = CLK_PERIOD - CLK_UNCERTAINTY - `SDFFRHQX2_SETUP;
        slk_s1 = req_s1 - arr1;

        // --- Path 2: count_reg[3] setup ---
        arr2 = `SDFFRHQX2_CLKQ + `CLKINVX1_DELAY + `MX2X1_DELAY;
        req_s2 = CLK_PERIOD - CLK_UNCERTAINTY - `SDFFRHQX2_SETUP;
        slk_s2 = req_s2 - arr2;

        // --- Path 3: count_reg[0] setup ---
        arr3 = `DFFRX2_CLKQ;
        req_s3 = CLK_PERIOD - CLK_UNCERTAINTY - `DFFRX2_SETUP;
        slk_s3 = req_s3 - arr3;

        // --- Path 4: count_reg[0] hold ---
        arr4  = `DFFRX2_CLKQ;
        req_h0 = `DFFRX2_HOLD + CLK_UNCERTAINTY;
        slk_h0 = arr4 - req_h0;
    end
endtask

// ============================================================
// REPORT 1: report_timing -delay_type max (SETUP)
// ============================================================
task report_timing_setup;
    begin
        print_header("report_timing -path_type full -delay_type max -nworst 4");

        // ---- PATH 0: count_reg[1] ----
        $write("  ----------------------------------------------------------------\n");
        $write("  Path Group          : clk\n");
        $write("  Path Type           : max  (setup)\n");
        $write("  Analysis Mode       : single_scenario\n");
        $write("  Startpoint          : count_reg[0]/CK\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        $write("  Endpoint            : count_reg[1]/D\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        if (slk_s0 >= 0.0)
            $write("  Path slack          : %10.3f ns  (MET)\n", slk_s0);
        else
            $write("  Path slack          : %10.3f ns  (VIOLATED)\n", slk_s0);
        $write("  ----------------------------------------------------------------\n");
        $write("\n");
        $write("  Point                                    Fanout  Cap(pF) Trans(ns)  Incr(ns)  Path(ns)\n");
        print_dash;
        $write("  clock clk (rise edge)                                               0.000     0.000\n");
        $write("  clock network delay (ideal)                                         0.000     0.000\n");
        print_path_row("count_reg[0]/CK",          1, 0.004, 0.010, 0.000,               0.000);
        print_path_row("count_reg[0]/Q (DFFRHQX2)",1, 0.003, 0.009, `DFFRHQX2_CLKQ,     `DFFRHQX2_CLKQ);
        print_path_row("g245__6783/Y (NAND2XL)",   1, 0.002, 0.007, `NAND2XL_DELAY,     `DFFRHQX2_CLKQ+`NAND2XL_DELAY);
        print_path_row("g241__4319/Y (OAI211X1)",  1, 0.002, 0.008, `OAI211X1_DELAY,    `DFFRHQX2_CLKQ+`NAND2XL_DELAY+`OAI211X1_DELAY);
        print_path_row("g238__2398/Y (OAI211X1)",  1, 0.003, 0.009, `OAI211X1_DELAY,    arr0);
        print_dash;
        $write("  data arrival time                                                             %8.3f\n", arr0);
        $write("\n");
        $write("  clock clk (rise edge)                                              %8.3f\n", CLK_PERIOD);
        $write("  clock uncertainty                                                  %8.3f\n", -CLK_UNCERTAINTY);
        $write("  library setup time (DFFRHQX2)                                      %8.3f\n", -`DFFRHQX2_SETUP);
        $write("  data required time                                                 %8.3f\n", req_s0);
        print_dash;
        $write("  data required time                                                 %8.3f\n", req_s0);
        $write("  data arrival time                                                  %8.3f\n", -arr0);
        print_eq;
        print_slack_line("  slack", slk_s0);
        $write("\n\n");

        // ---- PATH 1: count_reg[2] ----
        $write("  ----------------------------------------------------------------\n");
        $write("  Path Group          : clk\n");
        $write("  Path Type           : max  (setup)\n");
        $write("  Analysis Mode       : single_scenario\n");
        $write("  Startpoint          : count_reg[0]/CK\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        $write("  Endpoint            : count_reg[2]/D\n");
        $write("                        (rising edge-triggered SDFF clocked by clk)\n");
        if (slk_s1 >= 0.0)
            $write("  Path slack          : %10.3f ns  (MET)\n", slk_s1);
        else
            $write("  Path slack          : %10.3f ns  (VIOLATED)\n", slk_s1);
        $write("  ----------------------------------------------------------------\n");
        $write("\n");
        $write("  Point                                    Fanout  Cap(pF) Trans(ns)  Incr(ns)  Path(ns)\n");
        print_dash;
        $write("  clock clk (rise edge)                                               0.000     0.000\n");
        $write("  clock network delay (ideal)                                         0.000     0.000\n");
        print_path_row("count_reg[0]/CK",           1, 0.004, 0.010, 0.000,              0.000);
        print_path_row("count_reg[0]/Q (DFFRX2)",   1, 0.003, 0.009, `DFFRX2_CLKQ,      `DFFRX2_CLKQ);
        print_path_row("g242__8428/Y (NAND2BX1)",   1, 0.002, 0.007, `NAND2BX1_DELAY,   `DFFRX2_CLKQ+`NAND2BX1_DELAY);
        print_path_row("g240__6260/Y (AND2X1)",     1, 0.002, 0.007, `AND2X1_DELAY,     `DFFRX2_CLKQ+`NAND2BX1_DELAY+`AND2X1_DELAY);
        print_path_row("g239__5107/Y (MX2X1)",      1, 0.003, 0.009, `MX2X1_DELAY,      arr1);
        print_dash;
        $write("  data arrival time                                                             %8.3f\n", arr1);
        $write("\n");
        $write("  clock clk (rise edge)                                              %8.3f\n", CLK_PERIOD);
        $write("  clock uncertainty                                                  %8.3f\n", -CLK_UNCERTAINTY);
        $write("  library setup time (SDFFRHQX2)                                     %8.3f\n", -`SDFFRHQX2_SETUP);
        $write("  data required time                                                 %8.3f\n", req_s1);
        print_dash;
        $write("  data required time                                                 %8.3f\n", req_s1);
        $write("  data arrival time                                                  %8.3f\n", -arr1);
        print_eq;
        print_slack_line("  slack", slk_s1);
        $write("\n\n");

        // ---- PATH 2: count_reg[3] ----
        $write("  ----------------------------------------------------------------\n");
        $write("  Path Group          : clk\n");
        $write("  Path Type           : max  (setup)\n");
        $write("  Analysis Mode       : single_scenario\n");
        $write("  Startpoint          : count_reg[2]/CK\n");
        $write("                        (rising edge-triggered SDFF clocked by clk)\n");
        $write("  Endpoint            : count_reg[3]/D\n");
        $write("                        (rising edge-triggered SDFF clocked by clk)\n");
        if (slk_s2 >= 0.0)
            $write("  Path slack          : %10.3f ns  (MET)\n", slk_s2);
        else
            $write("  Path slack          : %10.3f ns  (VIOLATED)\n", slk_s2);
        $write("  ----------------------------------------------------------------\n");
        $write("\n");
        $write("  Point                                    Fanout  Cap(pF) Trans(ns)  Incr(ns)  Path(ns)\n");
        print_dash;
        $write("  clock clk (rise edge)                                               0.000     0.000\n");
        $write("  clock network delay (ideal)                                         0.000     0.000\n");
        print_path_row("count_reg[2]/CK",           1, 0.004, 0.010, 0.000,             0.000);
        print_path_row("count_reg[2]/Q (SDFFRHQX2)",1, 0.003, 0.009, `SDFFRHQX2_CLKQ,  `SDFFRHQX2_CLKQ);
        print_path_row("g248/Y (CLKINVX1)",         1, 0.002, 0.006, `CLKINVX1_DELAY,  `SDFFRHQX2_CLKQ+`CLKINVX1_DELAY);
        print_path_row("g239__5107/Y (MX2X1)",      1, 0.003, 0.009, `MX2X1_DELAY,     arr2);
        print_dash;
        $write("  data arrival time                                                             %8.3f\n", arr2);
        $write("\n");
        $write("  clock clk (rise edge)                                              %8.3f\n", CLK_PERIOD);
        $write("  clock uncertainty                                                  %8.3f\n", -CLK_UNCERTAINTY);
        $write("  library setup time (SDFFRHQX2)                                     %8.3f\n", -`SDFFRHQX2_SETUP);
        $write("  data required time                                                 %8.3f\n", req_s2);
        print_dash;
        $write("  data required time                                                 %8.3f\n", req_s2);
        $write("  data arrival time                                                  %8.3f\n", -arr2);
        print_eq;
        print_slack_line("  slack", slk_s2);
        $write("\n\n");

        // ---- PATH 3: count_reg[0] ----
        $write("  ----------------------------------------------------------------\n");
        $write("  Path Group          : clk\n");
        $write("  Path Type           : max  (setup)\n");
        $write("  Analysis Mode       : single_scenario\n");
        $write("  Startpoint          : count_reg[0]/CK\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        $write("  Endpoint            : count_reg[0]/D\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        if (slk_s3 >= 0.0)
            $write("  Path slack          : %10.3f ns  (MET)\n", slk_s3);
        else
            $write("  Path slack          : %10.3f ns  (VIOLATED)\n", slk_s3);
        $write("  ----------------------------------------------------------------\n");
        $write("\n");
        $write("  Point                                    Fanout  Cap(pF) Trans(ns)  Incr(ns)  Path(ns)\n");
        print_dash;
        $write("  clock clk (rise edge)                                               0.000     0.000\n");
        $write("  clock network delay (ideal)                                         0.000     0.000\n");
        print_path_row("count_reg[0]/CK",           1, 0.004, 0.010, 0.000,        0.000);
        print_path_row("count_reg[0]/QN (DFFRX2)",  1, 0.003, 0.009, `DFFRX2_CLKQ, arr3);
        print_dash;
        $write("  data arrival time                                                             %8.3f\n", arr3);
        $write("\n");
        $write("  clock clk (rise edge)                                              %8.3f\n", CLK_PERIOD);
        $write("  clock uncertainty                                                  %8.3f\n", -CLK_UNCERTAINTY);
        $write("  library setup time (DFFRX2)                                        %8.3f\n", -`DFFRX2_SETUP);
        $write("  data required time                                                 %8.3f\n", req_s3);
        print_dash;
        $write("  data required time                                                 %8.3f\n", req_s3);
        $write("  data arrival time                                                  %8.3f\n", -arr3);
        print_eq;
        print_slack_line("  slack", slk_s3);
        $write("\n\n");
    end
endtask

// ============================================================
// REPORT 2: report_timing -delay_type min (HOLD)
// ============================================================
task report_timing_hold;
    begin
        print_header("report_timing -path_type full -delay_type min -nworst 4");

        $write("  ----------------------------------------------------------------\n");
        $write("  Path Group          : clk\n");
        $write("  Path Type           : min  (hold)\n");
        $write("  Analysis Mode       : single_scenario\n");
        $write("  Startpoint          : count_reg[0]/CK\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        $write("  Endpoint            : count_reg[0]/D\n");
        $write("                        (rising edge-triggered flip-flop clocked by clk)\n");
        if (slk_h0 >= 0.0)
            $write("  Path slack          : %10.3f ns  (MET)\n", slk_h0);
        else
            $write("  Path slack          : %10.3f ns  (VIOLATED)\n", slk_h0);
        $write("  ----------------------------------------------------------------\n");
        $write("\n");
        $write("  Point                                    Fanout  Cap(pF) Trans(ns)  Incr(ns)  Path(ns)\n");
        print_dash;
        $write("  clock clk (rise edge)                                               0.000     0.000\n");
        $write("  clock network delay (ideal)                                         0.000     0.000\n");
        print_path_row("count_reg[0]/CK",           1, 0.004, 0.010, 0.000,         0.000);
        print_path_row("count_reg[0]/QN (DFFRX2)",  1, 0.003, 0.009, `DFFRX2_CLKQ,  arr4);
        print_dash;
        $write("  data arrival time                                                             %8.3f\n", arr4);
        $write("\n");
        $write("  clock clk (rise edge)                                               0.000\n");
        $write("  clock uncertainty                                                   %8.3f\n",  CLK_UNCERTAINTY);
        $write("  library hold time (DFFRX2)                                         %8.3f\n",  `DFFRX2_HOLD);
        $write("  data required time                                                 %8.3f\n",  req_h0);
        print_dash;
        $write("  data arrival time                                                  %8.3f\n",  arr4);
        $write("  data required time                                                  %8.3f\n", -req_h0);
        print_eq;
        print_slack_line("  slack (min_slack)", slk_h0);
        $write("\n\n");
    end
endtask

// ============================================================
// REPORT 3: report_timing_summary
// ============================================================
task report_timing_summary;
    real _wns, _tns, _whs, _ths;
    integer fail_s, fail_h;
    begin
        print_header("report_timing_summary");

        $write("  Design              : counter\n");
        $write("  Corner              : TT (tt_1.8v_25c)\n");
        $write("  Clock Period        : %8.3f ns\n", CLK_PERIOD);
        $write("  Clock Uncertainty   : %8.3f ns\n", CLK_UNCERTAINTY);
        $write("  Input Delay         : %8.3f ns\n", INPUT_DELAY);
        $write("  Output Delay        : %8.3f ns\n", OUTPUT_DELAY);
        $write("\n");

        // Table header
        $write("  %-26s  %14s  %14s  %s\n",
               "Endpoint", "Setup Slack", "Hold Slack", "Status");
        print_dash;

        // Row per endpoint
        // count_reg[1]
        $write("  %-26s  %14.3f  %14s  ", "count_reg[1]", slk_s0, "N/A");
        if (slk_s0 >= 0.0) $write("PASS\n"); else $write("FAIL\n");

        // count_reg[2]
        $write("  %-26s  %14.3f  %14s  ", "count_reg[2]", slk_s1, "N/A");
        if (slk_s1 >= 0.0) $write("PASS\n"); else $write("FAIL\n");

        // count_reg[3]
        $write("  %-26s  %14.3f  %14s  ", "count_reg[3]", slk_s2, "N/A");
        if (slk_s2 >= 0.0) $write("PASS\n"); else $write("FAIL\n");

        // count_reg[0] setup
        $write("  %-26s  %14.3f  %14.3f  ", "count_reg[0]", slk_s3, slk_h0);
        if (slk_s3 >= 0.0 && slk_h0 >= 0.0) $write("PASS\n"); else $write("FAIL\n");

        print_dash;

        // Aggregates
        _wns = slk_s0;
        if (slk_s1 < _wns) _wns = slk_s1;
        if (slk_s2 < _wns) _wns = slk_s2;
        if (slk_s3 < _wns) _wns = slk_s3;

        _tns = 0.0;
        if (slk_s0 < 0.0) _tns = _tns + slk_s0;
        if (slk_s1 < 0.0) _tns = _tns + slk_s1;
        if (slk_s2 < 0.0) _tns = _tns + slk_s2;
        if (slk_s3 < 0.0) _tns = _tns + slk_s3;

        _whs = slk_h0;
        _ths = 0.0;
        if (slk_h0 < 0.0) _ths = slk_h0;

        fail_s = 0;
        if (slk_s0 < 0.0) fail_s = fail_s + 1;
        if (slk_s1 < 0.0) fail_s = fail_s + 1;
        if (slk_s2 < 0.0) fail_s = fail_s + 1;
        if (slk_s3 < 0.0) fail_s = fail_s + 1;
        fail_h = (slk_h0 < 0.0) ? 1 : 0;

        $write("\n");
        $write("  Setup Analysis Summary:\n");
        $write("    WNS (Worst Negative Slack)  : %8.3f ns\n", _wns);
        $write("    TNS (Total Negative Slack)  : %8.3f ns\n", _tns);
        $write("    Failing Endpoints           : %0d\n", fail_s);
        $write("    Total Endpoints (setup)     : 4\n");
        $write("\n");
        $write("  Hold Analysis Summary:\n");
        $write("    WHS (Worst Hold Slack)      : %8.3f ns\n", _whs);
        $write("    THS (Total Negative Slack)  : %8.3f ns\n", _ths);
        $write("    Failing Endpoints           : %0d\n", fail_h);
        $write("    Total Endpoints (hold)      : 1\n");
        $write("\n\n");
    end
endtask

// ============================================================
// REPORT 4: report_clock
// ============================================================
task report_clock;
    begin
        print_header("report_clock");

        print_dash;
        $write("  %-12s  %-12s  %-20s  %s\n",
               "Clock", "Period(ns)", "Waveform(ns)", "Sources");
        print_dash;
        $write("  %-12s  %-12.3f  { 0.000 %6.3f }      {clk}\n",
               "clk", CLK_PERIOD, CLK_PERIOD/2.0);
        print_dash;
        $write("\n");
        $write("  Clock Attributes:\n");
        $write("    Name                        : clk\n");
        $write("    Period                      : %8.3f ns\n", CLK_PERIOD);
        $write("    Waveform                    : { 0.000 %6.3f }\n", CLK_PERIOD/2.0);
        $write("    Sources                     : {clk}\n");
        $write("    Generated clocks            : (none)\n");
        $write("    Propagated                  : false  (ideal clock)\n");
        $write("    Uncertainty (setup)         : -%6.3f ns\n", CLK_UNCERTAINTY);
        $write("    Uncertainty (hold)          : +%6.3f ns\n", CLK_UNCERTAINTY);
        $write("\n");
        $write("  Cells clocked by 'clk':\n");
        $write("    count_reg[0]  (DFFRX2)\n");
        $write("    count_reg[1]  (DFFRHQX2)\n");
        $write("    count_reg[2]  (SDFFRHQX2)\n");
        $write("    count_reg[3]  (SDFFRHQX2)\n");
        $write("\n");
        $write("  Clock network statistics:\n");
        $write("    Skew                        :   0.000 ns  (ideal)\n");
        $write("    Insertion delay             :   0.000 ns\n");
        $write("    Latency                     :   0.000 ns\n");
        $write("\n\n");
    end
endtask

// ============================================================
// Main simulation flow
// ============================================================
initial begin
    run_analysis = 0;

    // Trigger the STA engine
    #5;
    run_analysis = 1;
    #1;
    run_analysis = 0;
    #5;

    // Compute all path values locally (for report tables)
    local_compute_paths;

    // ---- Generate all four Tempus reports ----
    report_timing_setup;
    report_timing_hold;
    report_timing_summary;
    report_clock;

    $finish;
end

endmodule

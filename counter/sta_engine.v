// ============================================================
// sta_engine.v
// Static Timing Analysis Engine for synthesized counter netlist
// Mimics Cadence Tempus pre-layout timing reports
//
// Netlist under analysis (Genus output):
//   module counter(clk, m, rst, count[3:0])
//   Cells: DFFRHQX2, DFFRX2, SDFFRHQX2, OAI211X1, MX2X1,
//          AND2X1, NAND2BX1, OR3XL, NAND2XL, CLKINVX1
// ============================================================

`include "sta_timing_pkg.v"
`timescale 1ns/1ps

module sta_engine (
    // SDC constraint inputs
    input real clk_period,       // clock period (ns)
    input real clk_uncertainty,  // clock uncertainty (ns)
    input real input_delay,      // input arrival delay (ns)
    input real output_delay,     // output load delay (ns)

    // Analysis trigger
    input      run_analysis,

    // Outputs: worst-case slacks
    output real wns_setup,       // worst negative setup slack
    output real tns_setup,       // total negative setup slack
    output real whs_hold,        // worst hold slack
    output real ths_hold         // total negative hold slack
);

// ============================================================
// Internal timing storage: 4 setup paths + 1 hold path
// ============================================================
real arrival   [0:4];   // data arrival time at endpoint
real required_s[0:3];   // required time (setup)
real required_h[0:0];   // required time (hold)
real slack_s   [0:3];   // setup slack per path
real slack_h   [0:0];   // hold slack per path

// ============================================================
// Path 0: count_reg[1] — critical setup path
//   clk -> count_reg[0]/Q -> NAND2XL -> OAI211X1 -> OAI211X1 -> count_reg[1]/D
// ============================================================
task compute_path0;
    real arr;
    begin
        arr = 0.0;
        arr = arr + `DFFRHQX2_CLKQ;   // count_reg[0] clk->Q
        arr = arr + `NAND2XL_DELAY;    // g245: NAND2XL
        arr = arr + `OAI211X1_DELAY;   // g241: OAI211X1
        arr = arr + `OAI211X1_DELAY;   // g238: OAI211X1
        arrival[0]    = arr;
        required_s[0] = clk_period - clk_uncertainty - `DFFRHQX2_SETUP;
        slack_s[0]    = required_s[0] - arrival[0];
    end
endtask

// ============================================================
// Path 1: count_reg[2] — setup path via MX2X1
//   clk -> count_reg[0]/Q -> NAND2BX1 -> AND2X1 -> MX2X1 -> count_reg[2]/D
// ============================================================
task compute_path1;
    real arr;
    begin
        arr = 0.0;
        arr = arr + `DFFRX2_CLKQ;      // count_reg[0] clk->Q
        arr = arr + `NAND2BX1_DELAY;   // g242: NAND2BX1
        arr = arr + `AND2X1_DELAY;     // g240: AND2X1
        arr = arr + `MX2X1_DELAY;      // g239: MX2X1
        arrival[1]    = arr;
        required_s[1] = clk_period - clk_uncertainty - `SDFFRHQX2_SETUP;
        slack_s[1]    = required_s[1] - arrival[1];
    end
endtask

// ============================================================
// Path 2: count_reg[3] — setup path via CLKINVX1
//   clk -> count_reg[2]/Q -> CLKINVX1 -> MX2X1 -> count_reg[3]/D
// ============================================================
task compute_path2;
    real arr;
    begin
        arr = 0.0;
        arr = arr + `SDFFRHQX2_CLKQ;   // count_reg[2] clk->Q
        arr = arr + `CLKINVX1_DELAY;   // g248: CLKINVX1
        arr = arr + `MX2X1_DELAY;      // g239: MX2X1
        arrival[2]    = arr;
        required_s[2] = clk_period - clk_uncertainty - `SDFFRHQX2_SETUP;
        slack_s[2]    = required_s[2] - arrival[2];
    end
endtask

// ============================================================
// Path 3: count_reg[0] — setup path (self-loop via QN->D)
//   clk -> count_reg[0]/QN -> count_reg[0]/D  (direct feedback)
// ============================================================
task compute_path3;
    real arr;
    begin
        arr = 0.0;
        arr = arr + `DFFRX2_CLKQ;     // count_reg[0] clk->QN
        arrival[3]    = arr;
        required_s[3] = clk_period - clk_uncertainty - `DFFRX2_SETUP;
        slack_s[3]    = required_s[3] - arrival[3];
    end
endtask

// ============================================================
// Path 4: count_reg[0] — hold path (self-loop QN->D)
//   Hold check: arrival must be >= hold_time + uncertainty
// ============================================================
task compute_path4_hold;
    real arr;
    begin
        arr = 0.0;
        arr = arr + `DFFRX2_CLKQ;     // count_reg[0] clk->QN (min path)
        arrival[4]    = arr;
        required_h[0] = `DFFRX2_HOLD + clk_uncertainty;
        slack_h[0]    = arrival[4] - required_h[0];
    end
endtask

// ============================================================
// Aggregate: WNS, TNS, WHS, THS
// ============================================================
real _wns, _tns, _whs, _ths;
integer i;

task compute_aggregates;
    begin
        _wns = slack_s[0];
        _tns = 0.0;
        for (i = 0; i <= 3; i = i + 1) begin
            if (slack_s[i] < _wns) _wns = slack_s[i];
            if (slack_s[i] < 0.0)  _tns = _tns + slack_s[i];
        end
        _whs = slack_h[0];
        _ths = 0.0;
        if (slack_h[0] < 0.0) _ths = slack_h[0];
    end
endtask

// ============================================================
// Continuous output assignment
// ============================================================
assign wns_setup = _wns;
assign tns_setup = _tns;
assign whs_hold  = _whs;
assign ths_hold  = _ths;

// ============================================================
// Trigger analysis on rising edge of run_analysis
// ============================================================
always @(posedge run_analysis) begin
    compute_path0;
    compute_path1;
    compute_path2;
    compute_path3;
    compute_path4_hold;
    compute_aggregates;
end

endmodule

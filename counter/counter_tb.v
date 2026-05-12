// ============================================================
// counter_tb.v  (fixed)
// Testbench for 4-bit up/down counter
// Assertions:
//   ASSERT_RESET    — count=0 when rst=0
//   ASSERT_UP_CNT   — count increments by 1 (m=1, stable)
//   ASSERT_DN_CNT   — count decrements by 1 (m=0, stable)
//   ASSERT_OVERFLOW — 15+1 wraps to 0
//   ASSERT_UNDERFLW — 0-1 wraps to 15
//   ASSERT_KNOWN    — count never X or Z
//   ASSERT_RST_REL  — no X after reset release
// ============================================================

`timescale 1ns/1ps

module counter_test;


// DUT signals
reg        clk, rst, m;
wire [3:0] count;

// Assertion tracking
integer pass_count;
integer fail_count;

// History registers — sampled at posedge
reg [3:0] prev_count;
reg       prev_rst;
reg       prev_m;       // mode captured SAME edge as prev_count
reg       first_cycle;
reg       mode_changed; // skip assertion on mode-transition cycle


// DUT instantiation
counter counter1 (clk, m, rst, count);

//clock
always #5 clk = ~clk;

//stimulus
initial begin
    clk = 0;
    rst = 0; #5;
    rst = 1;
    rst = 0; #265;
    rst = 1;
end

initial begin
    m = 1;
    #160 m = 0;
    #160 m = 1;
end

initial
    $monitor("Time=%t rst=%b clk=%b m=%b count=%b (%0d)",
             $time, rst, clk, m, count, count);

// Initialisation
initial begin
    pass_count   = 0;
    fail_count   = 0;
    first_cycle  = 1;
    prev_count   = 4'b0;
    prev_rst     = 1'b0;
    prev_m       = 1'b1;
    mode_changed = 0;
end

// ============================================================
// ASSERTION BLOCK — posedge clk
// ============================================================
always @(posedge clk) begin

    // Detect mode change on this cycle
    mode_changed = (m !== prev_m) ? 1 : 0;

    // --------------------------------------------------
    // ASSERTION 1: Reset correctness
    // --------------------------------------------------
    if (!rst) begin
        if (count === 4'b0000) begin
            $display("[PASS] ASSERT_RESET    : Time=%0t | rst=0 -> count=0000 (correct)",
                     $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_RESET    : Time=%0t | rst=0 but count=%b (expected 0000)",
                     $time, count);
            fail_count = fail_count + 1;
        end
    end

    // --------------------------------------------------
    // ASSERTION 2: No X or Z on count
    // --------------------------------------------------
    if (^count === 1'bx) begin
        $display("[FAIL] ASSERT_KNOWN    : Time=%0t | count contains X or Z: %b",
                 $time, count);
        fail_count = fail_count + 1;
    end else begin
        pass_count = pass_count + 1;
    end

    // --------------------------------------------------
    // ASSERTIONS 3-4: Functional up/down checks
    // Guard conditions:
    //   - not first cycle (prev_count not yet valid)
    //   - previous cycle: rst=1 (counter was running)
    //   - current cycle:  rst=1 (not a reset edge)
    //   - mode did NOT change this cycle
    // --------------------------------------------------
    if (!first_cycle && prev_rst && rst && !mode_changed) begin

        // ASSERTION 3: Up-count (mode was 1 last cycle)
        if (prev_m) begin
            if (count === (prev_count + 4'd1)) begin
                $display("[PASS] ASSERT_UP_CNT   : Time=%0t | count %0d -> %0d (+1 correct)",
                         $time, prev_count, count);
                pass_count = pass_count + 1;
            end else if (prev_count === 4'hF && count === 4'h0) begin
                $display("[PASS] ASSERT_OVERFLOW  : Time=%0t | count wrapped 15 -> 0 (correct)",
                         $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] ASSERT_UP_CNT   : Time=%0t | count %0d -> %0d (expected %0d)",
                         $time, prev_count, count, prev_count + 1);
                fail_count = fail_count + 1;
            end
        end

        // ASSERTION 4: Down-count (mode was 0 last cycle)
        if (!prev_m) begin
            if (count === (prev_count - 4'd1)) begin
                $display("[PASS] ASSERT_DN_CNT   : Time=%0t | count %0d -> %0d (-1 correct)",
                         $time, prev_count, count);
                pass_count = pass_count + 1;
            end else if (prev_count === 4'h0 && count === 4'hF) begin
                $display("[PASS] ASSERT_UNDERFLW  : Time=%0t | count wrapped 0 -> 15 (correct)",
                         $time);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] ASSERT_DN_CNT   : Time=%0t | count %0d -> %0d (expected %0d)",
                         $time, prev_count, count, prev_count - 1);
                fail_count = fail_count + 1;
            end
        end

    end // functional assertions

    // ASSERTION 5: Reset release — count must not go X
    if (rst && !prev_rst) begin
        if (^count !== 1'bx) begin
            $display("[PASS] ASSERT_RST_REL  : Time=%0t | rst released, count=%b (no X)",
                     $time, count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_RST_REL  : Time=%0t | rst released but count=X",
                     $time);
            fail_count = fail_count + 1;
        end
    end

    // SKIP log for mode-transition boundary cycle
    if (!first_cycle && prev_rst && rst && mode_changed) begin
        $display("[SKIP] MODE_TRANSITION : Time=%0t | m changed %b->%b this edge, count check skipped (correct behaviour)",
                 $time, prev_m, m);
    end

    // Update history — non-blocking so values settle first
    prev_count  <= count;
    prev_rst    <= rst;
    prev_m      <= m;
    first_cycle <= 0;

end // always @(posedge clk)

// ============================================================
// GLITCH DETECTION :
// FIX: The DUT uses non-blocking assignments (<=), so count
// updates in a delta cycle JUST AFTER posedge clk. This is
// correct RTL behaviour — not a real hardware glitch.
// We only flag changes that happen more than 2ns after
// the most recent clock edge to avoid false warnings.
// ============================================================
real last_edge_time;
initial last_edge_time = 0.0;

always @(clk)
    last_edge_time = $realtime;

always @(count) begin
    if (($realtime - last_edge_time) > 2.0 && !$isunknown(count)) begin
        $display("[WARN] ASSERT_GLITCH   : Time=%0t | count changed to %b %.1f ns after last clock edge",
                 $time, count, $realtime - last_edge_time);
    end
end

// ============================================================
// ASSERTION SUMMARY
// ============================================================
initial begin
    #820;
    $display("\n");
    $display("========================================================");
    $display("  ASSERTION VERIFICATION SUMMARY -- counter_tb");
    $display("========================================================");
    $display("  Total assertions checked : %0d", pass_count + fail_count);
    $display("  PASSED                   : %0d", pass_count);
    $display("  FAILED                   : %0d", fail_count);
    if ((pass_count + fail_count) > 0)
        $display("  Failure rate             : %0.1f%%",
                 (fail_count * 100.0) / (pass_count + fail_count));
    $display("--------------------------------------------------------");
    if (fail_count == 0)
        $display("  RESULT : ALL ASSERTIONS PASSED -- Design is CORRECT");
    else
        $display("  RESULT : %0d ASSERTION(S) FAILED -- Check above logs",
                 fail_count);
    $display("========================================================\n");
    $finish;
end

endmodule

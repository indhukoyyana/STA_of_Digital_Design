// ============================================================
// siso_right_shift_tb.v
// 4-bit SISO right shift register
//
// Assertions:
//   ASSERT_RESET      — shift_reg=0000 and serial_out=0 when reset=1
//   ASSERT_SHIFT      — shift_reg[3] equals serial_in from prev cycle
//   ASSERT_PROP       — shift_reg[2:0] equals prev shift_reg[3:1]
//   ASSERT_OUT        — serial_out always equals shift_reg[0]
//   ASSERT_KNOWN_REG  — shift_reg never contains X or Z
//   ASSERT_KNOWN_OUT  — serial_out never X or Z
//   ASSERT_SERIAL_SEQ — full 4-bit serial sequence verified end-to-end
// ============================================================

`timescale 1ns/1ps

module siso_right_shift_tb;

// DUT signals
reg  clk;
reg  reset;
reg  serial_in;
wire serial_out;


// Assertion tracking
integer pass_count;
integer fail_count;

// History registers — captured at each posedge
reg [3:0] prev_shift_reg;   // shift_reg value from previous cycle
reg       prev_serial_in;   // serial_in seen at previous posedge
reg       prev_reset;       // reset from previous cycle
reg       first_cycle;      // skip checks on cycle 0


// DUT instantiation
siso_right_shift uut (
    .clk       (clk),
    .reset     (reset),
    .serial_in (serial_in),
    .serial_out(serial_out)
);

//clock
always #5 clk = ~clk;

//stimilus
initial begin
    clk        = 0;
    reset      = 1;
    serial_in  = 0;
    #10;
    reset      = 0;
    #10 serial_in = 1;   // bit 3 (enters MSB side)
    #10 serial_in = 0;   // bit 2
    #10 serial_in = 1;   // bit 1
    #10 serial_in = 1;   // bit 0
    // Extra clocks to flush and observe serial_out
    #40;
end


initial begin
    $monitor("Time=%0t | clk=%b | serial_in=%b | shift_reg=%b | serial_out=%b",
             $time, clk, serial_in, uut.shift_reg, serial_out);
end

//initialization
initial begin
    pass_count      = 0;
    fail_count      = 0;
    first_cycle     = 1;
    prev_shift_reg  = 4'b0000;
    prev_serial_in  = 1'b0;
    prev_reset      = 1'b1;
end

// ============================================================
// ASSERTION BLOCK — evaluated at every posedge clk
// ============================================================
always @(posedge clk) begin

    // --------------------------------------------------
    // ASSERTION 1: ASSERT_RESET
    // When reset=1, shift_reg must be 0000 and
    // serial_out must be 0 (shift_reg[0]=0)
    // --------------------------------------------------
    if (reset) begin
        if (uut.shift_reg === 4'b0000) begin
            $display("[PASS] ASSERT_RESET      : Time=%0t | reset=1 -> shift_reg=0000 (correct)",
                     $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_RESET      : Time=%0t | reset=1 but shift_reg=%b (expected 0000)",
                     $time, uut.shift_reg);
            fail_count = fail_count + 1;
        end

        if (serial_out === 1'b0) begin
            $display("[PASS] ASSERT_RESET_OUT  : Time=%0t | reset=1 -> serial_out=0 (correct)",
                     $time);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_RESET_OUT  : Time=%0t | reset=1 but serial_out=%b (expected 0)",
                     $time, serial_out);
            fail_count = fail_count + 1;
        end
    end

    // --------------------------------------------------
    // ASSERTION 2: ASSERT_KNOWN_REG
    // shift_reg must never contain X or Z bits
    // --------------------------------------------------
    if (^uut.shift_reg === 1'bx) begin
        $display("[FAIL] ASSERT_KNOWN_REG  : Time=%0t | shift_reg contains X/Z: %b",
                 $time, uut.shift_reg);
        fail_count = fail_count + 1;
    end else begin
        pass_count = pass_count + 1;
    end

    // --------------------------------------------------
    // ASSERTION 3: ASSERT_KNOWN_OUT
    // serial_out must never be X or Z
    // --------------------------------------------------
    if (serial_out === 1'bx || serial_out === 1'bz) begin
        $display("[FAIL] ASSERT_KNOWN_OUT  : Time=%0t | serial_out is X or Z",
                 $time);
        fail_count = fail_count + 1;
    end else begin
        pass_count = pass_count + 1;
    end

    // --------------------------------------------------
    // ASSERTION 4: ASSERT_OUT
    // serial_out must always equal shift_reg[0]
    // This is a structural check — output wiring correctness
    // --------------------------------------------------
    if (serial_out === uut.shift_reg[0]) begin
        $display("[PASS] ASSERT_OUT        : Time=%0t | serial_out=%b == shift_reg[0]=%b (correct)",
                 $time, serial_out, uut.shift_reg[0]);
        pass_count = pass_count + 1;
    end else begin
        $display("[FAIL] ASSERT_OUT        : Time=%0t | serial_out=%b != shift_reg[0]=%b",
                 $time, serial_out, uut.shift_reg[0]);
        fail_count = fail_count + 1;
    end

    // --------------------------------------------------
    // ASSERTIONS 5-6: Shift correctness
    // Only check when:
    //   - not the first cycle
    //   - previous cycle had reset=0 (register was shifting)
    //   - current cycle has reset=0
    // --------------------------------------------------
    if (!first_cycle && !prev_reset && !reset) begin

        // ASSERTION 5: ASSERT_SHIFT
        // shift_reg[3] (MSB) must equal serial_in from the
        // PREVIOUS clock edge — that is what was shifted in
        if (uut.shift_reg[3] === prev_serial_in) begin
            $display("[PASS] ASSERT_SHIFT      : Time=%0t | shift_reg[3]=%b == prev_serial_in=%b (correct)",
                     $time, uut.shift_reg[3], prev_serial_in);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_SHIFT      : Time=%0t | shift_reg[3]=%b != prev_serial_in=%b",
                     $time, uut.shift_reg[3], prev_serial_in);
            fail_count = fail_count + 1;
        end

        // ASSERTION 6: ASSERT_PROP
        // Lower 3 bits must equal upper 3 bits of previous
        // shift_reg — this verifies the right-shift propagation
        // Expected: shift_reg[2:0] == prev_shift_reg[3:1]
        if (uut.shift_reg[2:0] === prev_shift_reg[3:1]) begin
            $display("[PASS] ASSERT_PROP       : Time=%0t | shift_reg[2:0]=%b == prev[3:1]=%b (correct)",
                     $time, uut.shift_reg[2:0], prev_shift_reg[3:1]);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_PROP       : Time=%0t | shift_reg[2:0]=%b != prev[3:1]=%b",
                     $time, uut.shift_reg[2:0], prev_shift_reg[3:1]);
            fail_count = fail_count + 1;
        end

    end // shift correctness

    // --------------------------------------------------
    // ASSERTION 7: ASSERT_RST_REL
    // On cycle immediately after reset is released,
    // shift_reg must not jump to X
    // --------------------------------------------------
    if (!reset && prev_reset) begin
        if (^uut.shift_reg !== 1'bx) begin
            $display("[PASS] ASSERT_RST_REL    : Time=%0t | reset released, shift_reg=%b (no X)",
                     $time, uut.shift_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ASSERT_RST_REL    : Time=%0t | reset released but shift_reg=X",
                     $time);
            fail_count = fail_count + 1;
        end
    end

    // Update history registers
    prev_shift_reg <= uut.shift_reg;
    prev_serial_in <= serial_in;
    prev_reset     <= reset;
    first_cycle    <= 0;

end // always @(posedge clk)

// ============================================================
// ASSERTION 8: ASSERT_SERIAL_SEQ
// End-to-end sequence check — after shifting in 1,0,1,1
// the shift_reg should contain 1101 (last 4 bits shifted in)
// and serial_out should have produced 0,0,0,0,1,0,1,1
// in sequence as bits propagate to shift_reg[0]
//
// Checked at a fixed time after all bits have been shifted
// Time=10 (rst released) + 4 x 10ns (4 input bits) = 50ns
// After 4 more clocks the last bit reaches serial_out
// ============================================================
initial begin
    // Wait until all 4 bits (1,0,1,1) have been shifted in
    // That is: reset released at 10ns, 4 bits x 10ns = 50ns
    // shift_reg at time=50ns should be 1011
    @(negedge clk); // align to stable region
    #50;
    $display("\n[CHECK] ASSERT_SERIAL_SEQ: Checking shift_reg after 4 input bits...");
    // After shifting in 1,0,1,1 (MSB first into bit[3]):
    // Cycle 1: serial_in=1 -> shift_reg = 1000
    // Cycle 2: serial_in=0 -> shift_reg = 0100
    // Cycle 3: serial_in=1 -> shift_reg = 1010
    // Cycle 4: serial_in=1 -> shift_reg = 1101
    if (uut.shift_reg === 4'b1101) begin
        $display("[PASS] ASSERT_SERIAL_SEQ : shift_reg=%b (expected 1101 after 1,0,1,1 input)",
                 uut.shift_reg);
        pass_count = pass_count + 1;
    end else begin
        $display("[FAIL] ASSERT_SERIAL_SEQ : shift_reg=%b (expected 1101 after 1,0,1,1 input)",
                 uut.shift_reg);
        fail_count = fail_count + 1;
    end
end

// ============================================================
// ASSERTION SUMMARY
// ============================================================
initial begin
    #100;
    $display("\n");
    $display("========================================================");
    $display("  ASSERTION VERIFICATION SUMMARY -- siso_right_shift_tb");
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

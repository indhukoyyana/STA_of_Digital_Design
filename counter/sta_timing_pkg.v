// ============================================================
// sta_timing_pkg.v
// Timing parameter definitions for SAED 32nm standard cells
// Corner: TT / 1.8V / 25C
// ============================================================

// ---------- Flip-flop timing (ns) ----------
`define DFFRHQX2_SETUP    0.080
`define DFFRHQX2_HOLD     0.020
`define DFFRHQX2_CLKQ     0.190

`define DFFRX2_SETUP      0.070
`define DFFRX2_HOLD       0.020
`define DFFRX2_CLKQ       0.210

`define SDFFRHQX2_SETUP   0.100
`define SDFFRHQX2_HOLD    0.030
`define SDFFRHQX2_CLKQ    0.220

// ---------- Combinational cell delays (ns) ----------
`define OAI211X1_DELAY    0.130
`define MX2X1_DELAY       0.150
`define AND2X1_DELAY      0.090
`define NAND2BX1_DELAY    0.100
`define OR3XL_DELAY       0.120
`define NAND2XL_DELAY     0.080
`define CLKINVX1_DELAY    0.060

// ---------- Wire/net delays (ideal, pre-layout) ----------
`define NET_DELAY         0.000

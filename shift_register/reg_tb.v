`timescale 1ns / 1ps

module siso_right_shift_tb;

    reg clk;
    reg reset;
    reg serial_in;
    wire serial_out;

    // Instantiate the DUT (Device Under Test)
    siso_right_shift uut (
        .clk(clk),
        .reset(reset),
        .serial_in(serial_in),
        .serial_out(serial_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin

        // Initialize signals
        clk = 0;
        reset = 1;
        serial_in = 0;

        // Apply reset
        #10;
        reset = 0;

        // Apply serial input bits: 1,0,1,1
        #10 serial_in = 1;
        #10 serial_in = 0;
        #10 serial_in = 1;
        #10 serial_in = 1;

        // Additional clocks to observe output
        #40;

        $finish;
    end

    // Monitor values
    initial begin
        $monitor("Time = %0t | clk = %b | serial_in = %b | shift_reg = %b | serial_out = %b",
                  $time, clk, serial_in, uut.shift_reg, serial_out);
    end

endmodule

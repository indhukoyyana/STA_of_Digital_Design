`timescale 1ns / 1ps

// Module declaration for 4-bit SISO (Serial In Serial Out) Right Shift Register
module siso_right_shift (

    input clk,          // Clock signal
    input reset,        // Reset signal
    input serial_in,    // Serial input data
    output serial_out   // Serial output data

);

    // 4-bit shift register to store data
    reg [3:0] shift_reg;

    // Sequential block triggered on:
    // 1. Positive edge of clock
    // 2. Positive edge of reset
    always @(posedge clk or posedge reset) begin

        // Reset condition
        // Clears the shift register when reset is HIGH
        if (reset)
            shift_reg <= 4'b0000;

        // Right shift operation
        // New serial input enters MSB position
        // Existing bits shift right by one position
        else
            shift_reg <= {serial_in, shift_reg[3:1]};
    end

    // Serial output is taken from LSB of shift register
    assign serial_out = shift_reg[0];

endmodule

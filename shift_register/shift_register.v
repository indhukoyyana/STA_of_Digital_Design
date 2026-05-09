`timescale 1ns / 1ps
module siso_right_shift (
    input clk,
    input reset,
    input serial_in,
    output serial_out
);

    reg [3:0] shift_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift_reg <= 4'b0000;
        else
            shift_reg <= {serial_in, shift_reg[3:1]};
    end

    assign serial_out = shift_reg[0];

endmodule

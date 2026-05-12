// 4-bit Up/Down Counter using Non-Blocking Assignments

module counter(clk, m, rst, count);

    // Input declarations
    input clk;       // Clock signal
    input m;         // Mode control: 1 = Up counter, 0 = Down counter
    input rst;       // Active-low asynchronous reset

    // Output declaration
    output reg [3:0] count;   // 4-bit counter output

    // Sequential block triggered on:
    // 1. Positive edge of clock
    // 2. Negative edge of reset
    always @(posedge clk or negedge rst)
    begin
        
        // Reset condition
        // If reset is LOW, counter becomes 0
        if (!rst)
            count <= 0;

        // Up-counting mode
        // If m = 1, increment counter by 1
        else if (m)
            count <= count + 1;

        // Down-counting mode
        // If m = 0, decrement counter by 1
        else
            count <= count - 1;
    end

endmodule

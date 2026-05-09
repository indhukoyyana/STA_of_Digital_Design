module counter_test;
reg clk,rst,m;
wire[3:0]count;
initial
begin
clk=0;
rst=0;#5;
rst=1;
rst=0;#265;
rst=1;
end
initial
begin
m=1;
#160 m=0;
#160 m=1;
end
counter counter1(clk,m,rst,count);
always #5 clk=~clk;
initial
$monitor("Time=%t rst=%bclk=%b count=%b",$time,rst,clk,count);
initial
#820 $finish;
endmodule

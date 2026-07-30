module Top (
	input wire rst,
	input wire clk,
	input wire [7:0] w_data,
	input wire [6:0] addr,
	input wire r_w,
	input wire start,
	output wire [7:0] r_data,
	output wire done,
	output wire SCL,
	inout SDA 
);
	Master #(.DIVIDER(3)) Master (
	.rst(rst), .clk(clk), .w_data(w_data), .addr(addr), .r_w(r_w),
	.start(start), .r_data(r_data), .done(done), .scl(SCL), .sda(SDA));

endmodule

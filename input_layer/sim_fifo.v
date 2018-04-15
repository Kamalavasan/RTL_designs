`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2018 01:42:30 PM
// Design Name: 
// Module Name: sim_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sim_fifo(

    );

	// variables
	reg clk;
	reg reset_n;
	reg [63:0] data_in;
	reg push;
	reg pop;
	wire [23:0] data_o;
	wire [3:0] count;

	reg_fifo reg_fifo_inst(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(data_in),
		.push(push),
		.pop(pop),
		.data_o(data_o),
		.count(count)
	);

	initial begin
		clk = 0;
		reset_n = 0;
		push = 0;
		pop = 0;
		#40
		reset_n = 1;
		#10
		data_in = 64'h2343253267384758;
		push = 1;
		#10
		push = 0;
		pop = 1;
		#70
		data_in = 64'h4567485739576944;
		push = 1;
		pop = 1;
		#10
		push = 0;
		pop = 1;
		//#10000
		//$finish();
	end

	always #5 clk = ~clk;
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/14/2018 08:21:52 AM
// Design Name: 
// Module Name: window_3x3
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


//module window_3x3(
//	// trigger signal
//	input start,
//
//	// block ram interface
//	//output [0:0] ena,
//	//output [0:0] wea,
//	//input  [7:0] addra,
//	//output [63:0] dina,
//
//	output [0:0] enb,
//	output [7:0] addrb,
//	input  [63:0] doutb,
//
//	// output to processing
//	output [71:0] window_data,
//	output [0:0] window_valid,
//	input        window_ready
//
//    );
//
//
//	
//endmodule

module reg_fifo(

	input clk,
	input reset_n,
	input [63:0] data_in,
	input [0:0] push,
	input [0:0] pop,
	output[23:0] data_o,
	output[3:0] count

	);

	reg [95:0] reg_file;
	reg [95:0] w_reg_file;
	reg [31:0] w_data_o;

	reg[3:0] r_ptr;
	reg[3:0] w_ptr;

	wire [3:0] w_ptr_next = (w_ptr +8 >= 12) ?  w_ptr - 4 : w_ptr +8;
	wire [3:0] r_ptr_next = (r_ptr +1 >= 12) ?  r_ptr -11 : r_ptr +1;

    assign count =  (w_ptr >= r_ptr) ? w_ptr - r_ptr : 11- r_ptr + w_ptr;

	always @(posedge clk) begin : proc_fifo_rpt
		if(~reset_n) begin
			r_ptr <= 0;
		end else if(pop & count > 3 ) begin
			r_ptr <= r_ptr_next ;
		end
	end

	always @(posedge clk) begin : proc_fifo_wptr
		if(~reset_n) begin
			w_ptr <= 0;
			reg_file <= 0;
		end else if(push & count <= 4) begin
			w_ptr <= w_ptr_next; 
			reg_file <= w_reg_file;
		end
	end

	always @(*) begin : proc_write
		case(w_ptr)
			4'b0000: w_reg_file <= {reg_file[95:64], data_in[63:0]};
			4'b0001: w_reg_file <= {reg_file[95:72], data_in[63:0], reg_file[7:0]};
			4'b0010: w_reg_file <= {reg_file[95:80], data_in[63:0], reg_file[15:0]};
			4'b0011: w_reg_file <= {reg_file[95:88], data_in[63:0], reg_file[23:0]};
			4'b0100: w_reg_file <= {data_in[63:0], reg_file[31:0]};
			4'b0101: w_reg_file <= {data_in[55:0], reg_file[31:0], data_in[63:56]};
			4'b0110: w_reg_file <= {data_in[47:0], reg_file[31:0], data_in[63:48]};
			4'b0111: w_reg_file <= {data_in[39:0], reg_file[31:0], data_in[63:40]};
			4'b1000: w_reg_file <= {data_in[31:0], reg_file[31:0], data_in[63:32]};
			4'b1001: w_reg_file <= {data_in[23:0], reg_file[31:0], data_in[63:24]};
			4'b1010: w_reg_file <= {data_in[15:0], reg_file[31:0], data_in[63:16]};
			4'b1011: w_reg_file <= {data_in[7:0], reg_file[31:0], data_in[63:8]};
			default : w_reg_file <= reg_file;
		endcase
	end


	always @(*) begin : proc_read
		case (r_ptr)
			4'b0000: w_data_o <= {reg_file[23:0]};
			4'b0001: w_data_o <= {reg_file[31:8]};
			4'b0010: w_data_o <= {reg_file[39:16]};
			4'b0011: w_data_o <= {reg_file[47:24]};
			4'b0100: w_data_o <= {reg_file[55:32]};
			4'b0101: w_data_o <= {reg_file[63:40]};
			4'b0110: w_data_o <= {reg_file[71:48]};
			4'b0111: w_data_o <= {reg_file[79:56]};
			4'b1000: w_data_o <= {reg_file[87:64]};
			4'b1001: w_data_o <= {reg_file[95:72]};
			4'b1010: w_data_o <= {reg_file[95:80], reg_file[7:0]};
			4'b1011: w_data_o <= {reg_file[95:88], reg_file[15:0]};
			default : w_data_o <= {reg_file[23:0]};
		endcase
	end

	assign data_o = w_data_o;
	

endmodule // reg_fifo
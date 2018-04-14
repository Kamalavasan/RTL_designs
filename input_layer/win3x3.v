module win3x3(
	// trigger signal
	input start,

	// block ram interface
	//output [0:0] ena,
	//output [0:0] wea,
	//input  [7:0] addra,
	//output [63:0] dina,

	output [0:0] enb,
	output [7:0] addrb,
	input  [63:0] doutb,

	// output to processing
	output [71:0] window_data,
	output [0:0] window_valid,
	input        window_ready

    );

	wire [3:0] row0_count;
	wire [3:0] row1_count;
	wire [3:0] row2_count;

	reg_fifo reg_fifo_inst0(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(data_in),
		.push(push),
		.pop(pop),
		.data_o(data_o),
		.count(row0_count)
	);

	reg_fifo reg_fifo_inst1(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(data_in),
		.push(push),
		.pop(pop),
		.data_o(data_o),
		.count(row1_count)
	);

	reg_fifo reg_fifo_inst2(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(data_in),
		.push(push),
		.pop(pop),
		.data_o(data_o),
		.count(row2_count)
	);


	reg[1:0] row_select;

	reg [7:0] row0_addr;
	reg [7:0] row1_addr;
	reg [7:0] row2_addr;

	always@(posedge clk) begin
		if(~reset_n | row_select >= 2) begin
			row_select <= 0;
		end else begin
			row_select <= row_select + 1;
		end
	end

	always@(posedge clk) begin 
		if(~reset_n | start) begin 
			row0_addr <= 0;
		end else if(row0_count <= 4 && row_select == 0) begin
			row0_addr <= row0_addr + 1;
		end
	end

	always@(posedge clk) begin 
		if(~reset_n | start) begin 
			row1_addr <= 0;
		end else if(row1_count <= 4 && row_select == 1) begin
			row1_addr <= row1_addr + 1;
		end
	end

	always@(posedge clk) begin 
		if(~reset_n | start) begin 
			row2_addr <= 0;
		end else if(row0_count <= 4 && row_select == 2) begin
			row2_addr <= row2 _addr + 1;
		end
	end

	
endmodule
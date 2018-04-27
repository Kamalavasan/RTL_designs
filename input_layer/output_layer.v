module output_layer# (

            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     64,
            parameter                           C_S_AXI_BURST_LEN             =     8,
            parameter                           STREAM_DATA_WIDTH             =     8
             
    ) (
	// parameters from axi_lite
	input Start,
	input [C_S_AXI_ADDR_WIDTH -1 : 0] axi_address,
	input [9:0] no_of_input_layers,
	input [9:0] input_layer_row_size,
	input [9:0] input_layer_col_size,


	// streaming data
	// ids will increment sequentially, but provieded as extra info
	// transsaction will occur when ready and valid are high
	// processing part should monitor valid before sending valid outputs
	input [STREAM_DATA_WIDTH-1:0] output_layer_1_data,
	input [9:0] out_fifo_1_dcount,
	output  out_fifo_1_rd_en, 


	// AXI signals
	input  wire                                                    clk,				// logic will operate in same clock as axi clock
    input  wire                                                    reset_n,
	// AXI Write Address Control Signals
	output  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_awid, 	
	output  wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_awaddr,	
	output  wire 			[7:0] 									M_axi_awlen,	
	output  wire 			[2:0] 									M_axi_awsize, 	
	output  wire 			[1:0]									M_axi_awburst,   
	output  wire 			[0:0]									M_axi_awlock,	
	output  wire 			[3:0]									M_axi_awcache, 	
	output  wire 			[2:0]									M_axi_awprot, 	
    output  wire 			[3:0]									M_axi_awqos, 	
	output  wire 													M_axi_awvalid,	
	input   wire 													M_axi_awready, 	

	// AXI Write Data Control Signals
	output  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_wdata,		
	output  wire 			[C_S_AXI_DATA_WIDTH/8-1:0]				M_axi_wstrb,		
	output  wire  													M_axi_wlast,		
	output  wire 													M_axi_wvalid,		
	input   wire 													M_axi_wready
	);



// axi settings
	// Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awlen = 8'h4;
	assign M_axi_awsize = 3;
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;

	// Read Address Control Signals


	// tying write port to ground
	assign M_axi_awaddr = 0;
	assign M_axi_awvalid = 0;

	assign M_axi_wdata  = 0;
	assign M_axi_wstrb = 0;
	assign M_axi_wlast = 0;
	assign M_axi_wvalid  = 0;

//---------------------------------------------------------------------------------
//---------------------------Implementation----------------------------------------
//---------------------------------------------------------------------------------



// state machine
// one input layer will be processed at a time
// this module will provide 3x3 inputs each clock
// loop structure
// foreach inputlayer
//		foreach row
//			foreach 3x3
// dual port ram will be used 
// one module will read fro ddr3 and write to block ram
// 


// a block ram will act as intermediate between 
// fifo output and ddr3 axi
// separate trackers for tracking inputlayer, coloumn and row
// for fifo side and axi ddr3 side

// block ram will be partitoned into four such that it can 
// store upto four rows at once


	reg [9:0] r_input_layer_id_fifo;
	reg [9:0] r_col_id_fifo;
	reg [9:0] r_row_id_fifo;

	reg [9:0] r_row_id_axi;
	reg [9:0] r_input_layer_id_axi;

	reg r_fifo_col_almost_end;
	reg r_fifo_layer_complete;


// logic for fifo counters
// incrementing r_col_id per fifo_rd_en

	always @(posedge clk) begin : proc_r_fifo_col_almost_end
		if(~reset_n | Start) begin
			r_fifo_col_almost_end <= 0;
		end else if(out_fifo_1_rd_en && r_col_id_fifo == input_layer_col_size-2) begin
			r_fifo_col_almost_end <= 1;
		end else if(out_fifo_1_rd_en)begin
			r_fifo_col_almost_end <= 0;
		end
	end

	always @(posedge clk) begin : proc_r_col_id_fifo
		if(~reset_n | Start) begin
			r_col_id_fifo <= 0;
		end else if(out_fifo_1_rd_en && r_fifo_col_almost_end)begin
			r_col_id_fifo <= 0;
		end else if(out_fifo_1_rd_en) begin
			r_col_id_fifo <= r_col_id_fifo + 1;
		end
	end

	always @(posedge clk) begin : proc_r_input_layer_id_fifo
		if(~reset_n | Start) begin
			r_input_layer_id_fifo <= 0;
		end else if(out_fifo_1_rd_en && r_fifo_col_almost_end && r_input_layer_id_fifo >= no_of_input_layers-1) begin
			r_input_layer_id_fifo <= 0;
		end else if(out_fifo_1_rd_en && r_fifo_col_almost_end) begin
			r_input_layer_id_fifo <= r_input_layer_id_fifo + 1;
		end
	end

	always @(posedge clk) begin : proc_r_row_id_fifo
		if(~reset_n | Start) begin
			r_row_id_fifo <= 0;
		end else if(out_fifo_1_rd_en && r_fifo_col_almost_end && r_input_layer_id_fifo >= no_of_input_layers-1)begin
			r_row_id_fifo <= r_row_id_fifo + 1;
		end
	end



	// logic for detecting layer complete 
	always @(posedge clk) begin : proc_r_fifo_layer_complete
		if(~reset_n | Start) begin
			r_fifo_layer_complete <= 0;
		end else if(r_row_id_fifo >= input_layer_row_size)begin
			r_fifo_layer_complete <= 1;
		end else begin
			r_fifo_layer_complete <= 0;
		end
	end



// FSM for writing fifo contents to blk ram
	reg [3:0] r_FSM_row_former;
	reg [63:0] r_blk_row;
	reg [63:0] r_dina;
	reg r_wea;

	// registering out_fifo_1_rd_en to syn with 
	// out fifo data

	reg r_out_fifo_1_rd_en;
	always @(posedge clk) begin : proc_r_out_fifo_1_rd_en
		if(~reset_n) begin
			r_out_fifo_1_rd_en <= 0;
		end else begin
			r_out_fifo_1_rd_en <= out_fifo_1_rd_en;
		end
	end

	always @(posedge clk) begin : proc_r_FSM_row_former
		if(~reset_n | Start) begin
			r_FSM_row_former <= 0;
		end else if(r_out_fifo_1_rd_en && r_FSM_row_former == 7)begin
			r_FSM_row_former <= 0;
		end else if(r_out_fifo_1_rd_en) begin
			r_FSM_row_former <= r_FSM_row_former + 1;
		end
	end

	// latching fifo data to reg
	always @(posedge clk) begin : proc_r_blk_row
		if(~reset_n | Start) begin
			r_blk_row <= 0;
		end else if(r_out_fifo_1_rd_en) begin
			 case(r_FSM_row_former)
			 	4'b0000 : r_blk_row[7:0] <= output_layer_1_data;
			 	4'b0001 : r_blk_row[15:8] <= output_layer_1_data;
			 	4'b0010 : r_blk_row[23:16] <= output_layer_1_data;
			 	4'b0011 : r_blk_row[31:24] <= output_layer_1_data;
			 	4'b0100 : r_blk_row[39:32] <= output_layer_1_data;
			 	4'b0101 : r_blk_row[47:40] <= output_layer_1_data;
			 	4'b0110 : r_blk_row[55:48] <= output_layer_1_data;
			 	4'b0111 : r_blk_row[63:56] <= output_layer_1_data;
			 endcase
		end
	end

	always @(posedge clk) begin : proc_r_dina
		if(~reset_n | Start) begin
			r_dina <= 0;
		end else if(r_FSM_row_former == 7 && r_out_fifo_1_rd_en) begin
			r_dina <= {output_layer_1_data, r_blk_row[55:0]};
		end
	end

	always @(posedge clk) begin : proc_r_wea
		if(~reset_n) begin
			r_wea <= 0;
		end else begin
			r_wea <= (r_FSM_row_former == 7 && r_out_fifo_1_rd_en) ? 1 : 0;
		end
	end

	// block ram address counter and offset select
	reg [1:0] r_blk_write_offset;
	reg [5:0] r_addra;

	// need to adjust this signal to sync with
	// data and addra
	wire row_complete = out_fifo_1_rd_en && r_fifo_col_almost_en;
	always @(posedge clk) begin : proc_r_blk_write_offset
		if(~reset_n | Start) begin
			r_blk_write_offset <= 0;
		end else if(row_complete)begin
			r_blk_write_offset <= r_blk_write_offset + 1;
		end
	end

	always @(posedge clk) begin : proc_r_addra
		if(~reset_n | Start | row_complete) begin
			r_addra <= 0;
		end else if(r_wea)begin
			r_addra <= r_addra + 1;;
		end
	end

	wire [7:0] w_blk_addra = {r_blk_write_offset, r_addra[5:0]};

	// creating a dual block ram instance
	dual_buffer dual_buffer_inst_0
  (
	    .clka(clk),
	    .ena(1'b1), 
	    .wea(r_wea), 
	    .addra(w_blk_addra), 
	    .dina(r_dina),
	    .clkb(clk),
	    .enb(1'b1), 
	    .addrb(w_addrb2), 
	    .doutb(dual_buffer_inst_doutb2) 
  );
 

endmodule // output_layer
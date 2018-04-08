// this module will read input layer data from ddr3 
// this will stream input layer data coressponding to 
// four, 3x3 sized kernels
// vaid will indicate  right data


// AXI lite interface will provide start adress of first layer
// and number of input layers
// it is assumed a fixed size of bytes are allocated for
// each  layer irrespective of its actual size
// 

#define STREAM_DATA_WIDTH 72 // 3x3x9

module input_layer# (

            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     64,
            parameter                           C_S_AXI_BURST_LEN             =     8
            
    ) (
	// parameters from axi_lite
	input [C_S_AXI_ADDR_WIDTH -1] axi_address,
	input [9:0] no_of_input_layers,
	input [9:0] input_layer_row_size,
	input [9:0] input_layer_col_size,
	input [0:0] in_layer_ddr3_data_rdy,

	// streaming data
	// ids will increment sequentially, but provieded as extra info
	// transsaction will occur when ready and valid are high
	// processing part should monitor valid before sending valid outputs

	output [STREAM_DATA_WIDTH-1:0] input_layer_1_data,
	output[0:0] input_layer_1_valid,
	input [0:0] input_layer_1_rdy, 
	output[9:0] input_layer_1_id, 


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
	input   wire 													M_axi_wready,		

	// AXI Response Control Signals
	input  wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_bid, 			
	input  wire 			[1:0]									M_axi_bresp,		
	input  wire 													M_axi_bvalid, 		
	output wire 												    M_axi_bready,		

	// AXI Read Address Control Signals
	output wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_arid, 		
	output wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_araddr, 		
	output wire 			[7:0] 									M_axi_arlen, 		
	output wire 			[2:0]									M_axi_arsize, 		
	output wire 			[1:0]									M_axi_arburst, 		
	output wire 			[0:0]									M_axi_arlock, 		
	output wire 			[3:0]									M_axi_arcache, 		
	output wire 			[2:0]									M_axi_arprot, 		
	output wire 			[3:0]									M_axi_arqos,		
	output wire 													M_axi_arvalid,		
	input  wire 													M_axi_arready,		

	// AXI Read Data Control Signals
	input  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_rid, 			
	input  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_rdata,		
	input  wire 			[1:0]									M_axi_rresp,		
    input  wire 													M_axi_rlast,		
	input  wire 													M_axi_rvalid,		
	output wire 												    M_axi_rready		
	);


// axi settings
	// Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awlen = C_S_AXI_BURST_LEN-1;
	assign M_axi_awsize = $clog2(C_S_AXI_DATA_WIDTH/8);
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;

	// Read Address Control Signals
	assign M_axi_arid = 1;
	assign M_axi_arlen = C_S_AXI_BURST_LEN - 1;
	assign M_axi_arsize = $clog2(C_S_AXI_DATA_WIDTH/8);;
	assign M_axi_arburst = 1;
	assign M_axi_arlock = 0;
	assign M_axi_arcache = 4'b0011;
	assign M_axi_arprot = 0;
	assign M_axi_arqos = 0;

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


	reg [9:0] r_inputlayer_id;
	reg [9:0] r_row_position_id;
	reg [9:0] r_col_postion_id;

	wire valid_transation = input_layer_1_valid & input_layer_1_rdy;
	wire one_row_complete = (r_col_postion_id >= input_layer_col_size - 1) & valid_transation;
	wire move_to_next_rows = (r_inputlayer_id >= no_of_input_layers - 1) & one_row_complete;


//---------------------------------------------------------------------------------------------
	// state machine for iteraating along
	// input layers
//---------------------------------------------------------------------------------------------
	// provide 3x3 window on each clockcycle moving 
	// along a row
	always @(posedge clk) begin : proc_
		if(~reset_n) begin
			r_col_postion_id <= 0;
		end else if(valid_transation)begin
			 if(r_col_postion_id >= input_layer_col_size - 1) begin
			 	r_col_postion_id <= 0;
			 end else begin
			 	r_col_postion_id <= r_col_postion_id + 1;
			 end
		end
	end

	// if a row completed move to same row 
	// of next layer
	always @(posedge clk) begin : proc_
		if(~reset_n) begin
			r_inputlayer_id <= 0;
		end else if(one_row_complete)begin
			 if(move_to_next_rows) begin
			 	r_inputlayer_id <= 0;
			 end else begin
			 	r_inputlayer_id <= r_inputlayer_id + 1;
			 end
		end
	end

	// after completeing all same row id in
	// all layers move to next row
	always @(posedge clk) begin : proc_
		if(~reset_n) begin
			r_row_position_id <= 0;
		end else if(move_to_next_rows)begin
			r_row_position_id <= r_row_position_id + 1;
		end
	end


//-----------------------------------------------------------------------------------------------
//-------- AXI Address calculation related to input layer----------------------------------------
//-----------------------------------------------------------------------------------------------

	// each AXI burst should not cross 4k boundry
	// max size for input layer is 55x55 bytes, which is  less than 4k
	// all input layers should be 4k block aligned
	// lets keep all rows aligned to 4bytes, as ddr3 width is 32 bit
	// for simplifying further lets keep all rows aligned to 64 bytes
	// initial plan is to keep 4 rows of input layers
	// one input layer will require 4 * 64 = 256 bytes
	// two blockrams will be used as  dual buffer


	

	//--------------------------------------------------------------------------------------------
	//------------------next_required row and input_layer id--------------------------------------
	//--------------------------------------------------------------------------------------------
		reg [9:0] r_next_inputlayer_id;
		reg [9:0] r_next_row_id;
		reg [0:0] r_next_layer_row_fetched;
		reg [0:0] r_current_layer_row_done;


		always @(posedge clk) begin : proc_
			if(~reset_n) begin
				next_inputlayer_id <= 0;
			end else if((r_inputlayer_id >= no_of_input_layers -1) & row_fetch_done) begin
				r_next_inputlayer_id <= 0;
			end
			else if(row_fetch_done)begin
				r_next_inputlayer_id <= r_inputlayer_id + 1;
			end
		end

		always @(posedge clk) begin : proc_
			if(~reset_n) begin
				r_next_row_id <= 0;
			end else if((r_inputlayer_id >= no_of_input_layers -1) & row_fetch_done) begin
				r_next_row_id <= r_row_position_id + 1;
			end
		end

		wire[31:0] next_AXI_burst_address = {r_next_inputlayer_id, 12'b0} + {r_next_row_id, 6'b0};


	//--------------------------------------------------------------------------------------------
	//----------- logic for writing required data in block ram-----------------------------------
	//--------------------------------------------------------------------------------------------

	wire next_blk_ram_write_address[7:0] = r_next_inputlayer_id[0] ? 32 : 0;
	wire blk_ram_write_enable = M_axi_rvalid & M_axi_rready;
	wire row_fetch_done = (blk_ram_wr_addr >= (next_blk_ram_write_address + 192) ? 1 :0 ) ;

	reg [7:0] blk_ram_wr_addr;
	always @(posedge clk) begin : proc_
		if(~reset_n | row_fetch_done) begin
			blk_ram_wr_addr <= next_blk_ram_write_address;
		end else if(blk_ram_write_enable) begin
			blk_ram_wr_addr <= blk_ram_wr_addr + 1;
		end
	end

	ram64x256 ram64x256_inst_0(
		.clock(clk),
		.data(M_axi_rdata),
		.rdaddress(),
		.wraddress(blk_ram_wr_addr),
		.wren(blk_ram_write_enable),
		.q);

	//--------------------------------------------------------------------------------------------
	//----------- logic for reading and providing required data-----------------------------------
	//--------------------------------------------------------------------------------------------

	// start ptoviding data with valid siginal if a row is fetched
	wire data_is_available = ((next_inputlayer_id > r_inputlayer_id) | (r_next_row_id > r_row_position_id) ? 1 : 0);

	reg[7:0] row_1[0:5];
	reg[7:0] row_2[0:5];
	reg[7:0] row_3[0:5];

	


endmodule


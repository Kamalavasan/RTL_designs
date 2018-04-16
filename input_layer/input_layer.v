// this module will read input layer data from ddr3 
// this will stream input layer data coressponding to 
// four, 3x3 sized kernels
// vaid will indicate  right data


// AXI lite interface will provide start adress of first layer
// and number of input layers
// it is assumed a fixed size of bytes are allocated for
// each  layer irrespective of its actual size
// 



module input_layer# (

            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     64,
            parameter                           C_S_AXI_BURST_LEN             =     8,
            parameter                           STREAM_DATA_WIDTH             =     72
             
    ) (
	// parameters from axi_lite
	input [C_S_AXI_ADDR_WIDTH -1 : 0] axi_address,
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
	assign M_axi_awlen = 8'h4;
	assign M_axi_awsize = 3;
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;

	// Read Address Control Signals
	assign M_axi_arid = 1;
	assign M_axi_arlen = 8'h17;
	assign M_axi_arsize = 3;
	assign M_axi_arburst = 1;
	assign M_axi_arlock = 0;
	assign M_axi_arcache = 4'b0011;
	assign M_axi_arprot = 0;
	assign M_axi_arqos = 0;


	// tying write port to ground
	assign M_axi_awaddr = 0;
	assign M_axi_awvalid = 0;

	assign M_axi_wdata  = 0;
	assign M_axi_wstrb = 0;
	assign M_axi_wlast = 0;
	assign M_axi_wvalid  = 0;

    assign M_axi_araddr = next_AXI_burst_address;



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
	wire layer_complete = (r_row_position_id >= input_layer_row_size ? 1 : 0);


//---------------------------------------------------------------------------------------------
	// state machine for iteraating along
	// input layers
//---------------------------------------------------------------------------------------------
	// provide 3x3 window on each clockcycle moving 
	// along a row
	always @(posedge clk) begin : proc_r_col_postion_id
		if(~reset_n | layer_complete) begin
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
	always @(posedge clk) begin : proc_r_inputlayer_id
		if(~reset_n | layer_complete) begin
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
	always @(posedge clk) begin : proc_r_row_position_id
		if(~reset_n) begin
			r_row_position_id <= 0;
		end else if(move_to_next_rows & (r_row_position_id < input_layer_row_size))begin
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
			if(~reset_n | in_layer_ddr3_data_rdy) begin
				r_next_inputlayer_id <= 0;
			end else if((r_inputlayer_id >= no_of_input_layers -1) & row_fetch_done) begin
				r_next_inputlayer_id <= 0;
			end
			else if(row_fetch_done)begin
				r_next_inputlayer_id <= r_inputlayer_id + 1;
			end
		end

		always @(posedge clk) begin : proc_r_next_row_id
			if(~reset_n | in_layer_ddr3_data_rdy) begin
				r_next_row_id <= 0;
			end else if((r_inputlayer_id >= no_of_input_layers -1) & row_fetch_done) begin
				r_next_row_id <= r_row_position_id + 1;
			end
		end

		wire fetch_rows = (r_next_inputlayer_id <= r_inputlayer_id ? 1 : 0);

		wire[31:0] next_AXI_burst_address = {r_next_inputlayer_id, 12'b0} + {r_next_row_id, 6'b0};


	//--------------------------------------------------------------------------------------------
	//----------- logic for writing required data in block ram-----------------------------------
	//--------------------------------------------------------------------------------------------

	wire [7:0] next_blk_ram_write_address;
	assign  next_blk_ram_write_address = (r_next_inputlayer_id[0] ? 8'd32 : 8'd0);
	
	wire blk_ram_write_enable = M_axi_rvalid & M_axi_rready;
	wire row_fetch_done = M_axi_rready & M_axi_rvalid & M_axi_rlast;

	reg [7:0] blk_ram_wr_addr;
	always @(posedge clk) begin : proc_blk_ram_wr_addr
		if(~reset_n | row_fetch_done) begin
			blk_ram_wr_addr <= next_blk_ram_write_address;
		end else if(blk_ram_write_enable) begin
			blk_ram_wr_addr <= blk_ram_wr_addr + 1;
		end
	end

//	ram64x256 ram64x256_inst_0(
//		.clock(clk),
//		.data(M_axi_rdata),
//		.rdaddress(),
//		.wraddress(blk_ram_wr_addr),
//		.wren(blk_ram_write_enable),
//		.q);


	wire [63:0] dual_buffer_inst_doutb;
	reg [7:0] addrb;
	dual_buffer dual_buffer_inst
  (
	    .clka(clk),
	    .ena(1'b1), 
	    .wea(blk_ram_write_enable), 
	    .addra(next_blk_ram_write_address), 
	    .dina(M_axi_rdata),
	    .clkb(clk),
	    .enb(1'b1), 
	    .addrb(addrb), 
	    .doutb(dual_buffer_inst_doutb) 
  );
	//--------------------------------------------------------------------------------------------
	//----------- logic for reading and providing required data-----------------------------------
	//--------------------------------------------------------------------------------------------


	reg[3:0] axi_read_FSM;

	always@(posedge clk) begin
		if(~reset_n) begin
			axi_read_FSM <= 0;
		end else begin
			case(axi_read_FSM) 
				4'b0000 : if(in_layer_ddr3_data_rdy & fetch_rows) axi_read_FSM <= 4'b0001;
				4'b0001 : if(M_axi_arvalid && M_axi_arready) axi_read_FSM <= 4'b0010;
				4'b0010 : if(M_axi_rready & M_axi_rvalid & M_axi_rlast) axi_read_FSM <= 4'b0000;
			endcase
		end
	end

	reg r_M_axi_rready;
	always @(posedge clk) begin
		if( ~reset_n || M_axi_rready & M_axi_rvalid & M_axi_rlast)
       		r_M_axi_rready <= 0;
       	else if(M_axi_rvalid)begin
       		r_M_axi_rready <= 1;
       	end
    end
    assign M_axi_rready = r_M_axi_rready;

    reg r_M_axi_arvalid;
    always @(posedge clk) begin
        if(~reset_n || (M_axi_arvalid && M_axi_arready)) begin
            r_M_axi_arvalid <= 0;
        end else if(axi_read_FSM == 4'b0001 & ~r_M_axi_arvalid) begin
            r_M_axi_arvalid <= 1;
        end
    end
    assign M_axi_arvalid = r_M_axi_arvalid;

	


	//-----------------------------------------------------------------------------------------------------
	//--------------- Reading from block ram and feeding to logic -----------------------------------------
	//-----------------------------------------------------------------------------------------------------

	wire [3:0] fifo_count_0;
	wire [3:0] fifo_count_1;
	wire [3:0] fifo_count_2;

	wire [23:0] data_o_0;
	wire [23:0] data_o_1;
	wire [23:0] data_o_2;

	reg r_push_0;
	reg r_push_1;
	reg r_push_2;

	wire pop_fifo = input_layer_1_valid & input_layer_1_rdy;

	reg_fifo reg_fifo_inst0(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(dual_buffer_inst_doutb),
		.push(r_push_0),
		.pop(pop_fifo),
		.data_o(data_o_0),
		.count(fifo_count_0)
	);

	reg_fifo reg_fifo_inst1(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(dual_buffer_inst_doutb),
		.push(r_push_1),
		.pop(pop_fifo),
		.data_o(data_o_1),
		.count(fifo_count_1)
	);

	reg_fifo reg_fifo_inst2(
		.clk(clk),
		.reset_n(reset_n),
		.data_in(dual_buffer_inst_doutb),
		.push(r_push_2),
		.pop(pop_fifo),
		.data_o(data_o_2),
		.count(fifo_count_2)
	);

	// start ptoviding data with valid siginal if a row is fetched
	wire data_is_available = (fifo_count_0 > 3) & (fifo_count_1 > 3) & (fifo_count_2 > 3);

	reg [1:0] r_row_select;
	reg [7:0] rdaddress;

	reg [7:0] r_read_ptr0;
	reg [7:0] r_read_ptr1;
	reg [7:0] r_read_ptr2;


	always @(posedge clk) begin : proc_r_row_select
		if(~reset_n || r_row_select >=2) begin
			r_row_select <= 0;
		end else begin
			r_row_select <= r_row_select +1;
		end
	end


	assign fetch_data_fifo_0 = (fifo_count_0 <= 3) ? 1 : 0;
	assign fetch_data_fifo_1 = (fifo_count_1 <= 3) ? 1 : 0;
	assign fetch_data_fifo_2 = (fifo_count_2 <= 3) ? 1 : 0;

	always@(posedge clk) begin
		if(~reset_n) begin
			r_read_ptr0 <= 0;
			r_read_ptr1 <= 0;
			r_read_ptr2 <= 0;
			addrb <= 0;
		end else begin
			case(r_row_select)
				2'b00: if(fetch_data_fifo_0) begin r_read_ptr0 <= r_read_ptr0 + 1; addrb <= r_read_ptr0; end
				2'b01: if(fetch_data_fifo_1) begin r_read_ptr1 <= r_read_ptr1 + 1; addrb <= r_read_ptr1; end
				2'b10: if(fetch_data_fifo_2) begin r_read_ptr2 <= r_read_ptr2 + 1; addrb <= r_read_ptr2; end
			endcase
		end
	end



	always@(posedge clk) begin
		if(~reset_n) begin
			r_push_0 <= 0;
			r_push_1 <= 0;
			r_push_2 <= 0;
		end else begin
			r_push_0 <= fetch_data_fifo_0;
			r_push_1 <= fetch_data_fifo_1;
			r_push_2 <= fetch_data_fifo_2;
		end
	end

	assign input_layer_1_valid = data_is_available;
	assign input_layer_1_data = {data_o_0, data_o_1, data_o_2};

	


endmodule



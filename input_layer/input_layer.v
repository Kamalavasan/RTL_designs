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
	input [0:0] in_layer_ddr3_data_rdy,

	// streaming data
	// ids will increment sequentially, but provieded as extra info
	// transsaction will occur when ready and valid are high
	// processing part should monitor valid before sending valid outputs

	output [STREAM_DATA_WIDTH-1:0] input_layer_1_data,
	output[0:0] input_layer_1_valid,
	input [0:0] input_layer_1_rdy, 
	output[9:0] input_layer_1_id, 

	output [STREAM_DATA_WIDTH-1:0] input_layer_2_data,
	output[0:0] input_layer_2_valid,
	input [0:0] input_layer_2_rdy,
	output[9:0] input_layer_2_id,

	output [STREAM_DATA_WIDTH-1:0] input_layer_3_data,
	output[0:0] input_layer_3_valid,
	input [0:0] input_layer_3_rdy,
	output[9:0] input_layer_3_id,

	output [STREAM_DATA_WIDTH-1:0] input_layer_4_data,
	output[0:0] input_layer_4_valid,
	input [0:0] input_layer_4_rdy,
	output[9:0] input_layer_4_id,

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

	// Read Address COntrol Signals
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






endmodule
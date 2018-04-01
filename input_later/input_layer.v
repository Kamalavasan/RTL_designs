// this module will read input layer data from ddr3 
// this will stream input layer data coressponding to 
// four, 3x3 sized kernels
// vaid will indicate  right data


// AXI lite interface will provide start adress of first layer
// and number of input layers
// it is assumed a fixed size of bytes are allocated for
// each  layer irrespective of its actual size
// 


#define ADDRESS_WIDTH 32
#define STREAM_DATA_WIDTH 72 // 3x3x9

module input_layer(
	// parameters from axi_lite
	input [ADDRESS_WIDTH -1] axi_address,
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



	) 

endmodule
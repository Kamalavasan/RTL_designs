//**************************************************************************************************
// Project/Product : IDCT
// Description     : Inverse Discrete Cosine Transform 
//                   row and column 1D IDCT operation 
//                   with 3 stage pipeline in each 1D IDCT
// Dependencies    : global_defs.v, global_func.v, synch_fifo.v
// References      : 
//
//**************************************************************************************************
   
`timescale 1ns / 1ps

module top(
	clk_i,
	rst_n_i,

	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,

	led_o
);


//----------------------------------------------------------------------------------------------------------------------
// Global constant and function headers
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// parameter definitions
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// localparam definitions
//----------------------------------------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------------------------------------
// I/O signals
//----------------------------------------------------------------------------------------------------------------------

	// System Clock Signals
	input 															clk_i;
	input 															rst_n_i;

	// DDR3 COntrol Signals
	output wire 		[14:0] 										memory_mem_a;
	output wire 		[2:0]  										memory_mem_ba;
	output wire 		       										memory_mem_ck;
	output wire 		       										memory_mem_ck_n;
	output wire 		       										memory_mem_cke;
	output wire 		       										memory_mem_cs_n; 
	output wire 		       										memory_mem_ras_n;
	output wire 		       										memory_mem_cas_n;
	output wire 		       										memory_mem_we_n;
	output wire 		       										memory_mem_reset_n;
	inout  wire 		[31:0] 										memory_mem_dq;
	inout  wire 		[3:0]  										memory_mem_dqs;
	inout  wire 		[3:0]  										memory_mem_dqs_n;
	output wire 		       										memory_mem_odt;
	output wire 		[3:0]  										memory_mem_dm;
	input  wire 		       										memory_oct_rzqin;

	output  						[7:0] 							led_o;

//----------------------------------------------------------------------------------------------------------------------
// Internal wires and registers
//----------------------------------------------------------------------------------------------------------------------

	// FPGA to HOST SDRAM
	wire 				[31:0] 										sdram0_data_araddr;
	wire 				[3:0]  										sdram0_data_arlen;
	wire 				[7:0]  										sdram0_data_arid;
	wire 				[2:0]  										sdram0_data_arsize;
	wire 				[1:0]  										sdram0_data_arburst;
	wire 				[1:0]  										sdram0_data_arlock;
	wire 				[2:0]  										sdram0_data_arprot;
	wire 				       										sdram0_data_arvalid;
	wire 				[3:0]  										sdram0_data_arcache;

	wire 				[31:0] 										sdram0_data_awaddr;
	wire 				[3:0]  										sdram0_data_awlen;
	wire 				[7:0]  										sdram0_data_awid;
	wire 				[2:0]  										sdram0_data_awsize;
	wire 				[1:0]  										sdram0_data_awburst;
	wire 				[1:0]  										sdram0_data_awlock;
	wire 				[2:0]  										sdram0_data_awprot;
	wire 				       										sdram0_data_awvalid;
	wire 				[3:0]  										sdram0_data_awcache;
 
	wire 				[1:0]  										sdram0_data_bresp;
	wire 				[7:0]  										sdram0_data_bid;
	wire 				       										sdram0_data_bvalid;
	wire 				       										sdram0_data_bready;

	wire 				       										sdram0_data_arready;
	wire 				       										sdram0_data_awready;

	wire 				       										sdram0_data_rready;
	wire 				[63:0] 										sdram0_data_rdata;
	wire 				[1:0]  										sdram0_data_rresp;
	wire 				       										sdram0_data_rlast;
	wire 				[7:0]  										sdram0_data_rid;
	wire 				       										sdram0_data_rvalid;

	wire 				       										sdram0_data_wlast;
	wire 				       										sdram0_data_wvalid;
	wire 				[63:0] 										sdram0_data_wdata;
	wire 				[7:0]  										sdram0_data_wstrb;
	wire 				       										sdram0_data_wready;
	wire 				[7:0]  										sdram0_data_wid;

	// DDR3 AXI Controller
	wire 				[7:0]  										axi_ddr3_awid;
	wire 				[31:0] 										axi_ddr3_awaddr;
	wire 				[7:0]  										axi_ddr3_awlen;
	wire 				[2:0]  										axi_ddr3_awsize;
	wire 				[1:0]  										axi_ddr3_awburst;
	wire 				[0:0]  										axi_ddr3_awlock;
	wire 				[3:0]  										axi_ddr3_awcache;
	wire 				[2:0]  										axi_ddr3_awprot;
	wire 				[3:0]  										axi_ddr3_awqos;
	wire 				       										axi_ddr3_awvalid;
	wire 				       										axi_ddr3_awready;
	
	wire 				[63:0] 										axi_ddr3_wdata;
	wire 				[7:0]  										axi_ddr3_wstrb;
	wire 				       										axi_ddr3_wlast;
	wire 				       										axi_ddr3_wvalid;
	wire 				       										axi_ddr3_wready;
	
	wire 				[7:0]  										axi_ddr3_bid;
	wire 				[1:0]  										axi_ddr3_bresp;
	wire 				       										axi_ddr3_bvalid;
	wire 				       										axi_ddr3_bready;
	
	wire 				[7:0]  										axi_ddr3_arid;
	wire 				[31:0] 										axi_ddr3_araddr;
	wire 				[7:0]  										axi_ddr3_arlen;
	wire 				[2:0]  										axi_ddr3_arsize;
	wire 				[1:0]  										axi_ddr3_arburst;
	wire 				[0:0]  										axi_ddr3_arlock;
	wire 				[3:0]  										axi_ddr3_arcache;
	wire 				[2:0]  										axi_ddr3_arprot;
	wire 				[3:0]  										axi_ddr3_arqos;
	wire 				       										axi_ddr3_arvalid;
	wire 				       										axi_ddr3_arready;
	
	wire 				[7:0]  										axi_ddr3_rid;
	wire 				[63:0] 										axi_ddr3_rdata;
	wire 				[1:0]  										axi_ddr3_rresp;
	wire 				       										axi_ddr3_rlast;
	wire 				       										axi_ddr3_rvalid;
	wire 				       										axi_ddr3_rready;



	// HPS to FPGA LWAXI

	 wire        													hps_0_h2f_axi_master_rready;        //                           .rready
	 wire 				[11:0] 										hps_0_h2f_lw_axi_master_awid;       //    hps_0_h2f_lw_axi_master.awid
	 wire 				[20:0] 										hps_0_h2f_lw_axi_master_awaddr;     //                           .awaddr
	 wire 				[3:0]  										hps_0_h2f_lw_axi_master_awlen;      //                           .awlen
	 wire 				[2:0]  										hps_0_h2f_lw_axi_master_awsize;     //                           .awsize
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_awburst;    //                           .awburst
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_awlock;    //                           .awlock
	 wire 				[3:0]  										hps_0_h2f_lw_axi_master_awcache;    //                           .awcache
	 wire 				[2:0]  										hps_0_h2f_lw_axi_master_awprot;     //                           .awprot
	 wire        													hps_0_h2f_lw_axi_master_awvalid;    //                           .awvalid
	 wire        													hps_0_h2f_lw_axi_master_awready;    //                           .awready

	 wire 				[11:0] 										hps_0_h2f_lw_axi_master_wid;        //                           .wid
	 wire 				[31:0] 										hps_0_h2f_lw_axi_master_wdata;      //                           .wdata
	 wire 				[3:0]  										hps_0_h2f_lw_axi_master_wstrb;      //                           .wstrb
	 wire        													hps_0_h2f_lw_axi_master_wlast;      //                           .wlast
	 wire        													hps_0_h2f_lw_axi_master_wvalid;     //                           .wvalid
	 wire        													hps_0_h2f_lw_axi_master_wready;     //                           .wready

	 wire 				[11:0] 										hps_0_h2f_lw_axi_master_bid;        //                           .bid
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_bresp;      //                           .bresp
	 wire        													hps_0_h2f_lw_axi_master_bvalid;     //                           .bvalid
	 wire        													hps_0_h2f_lw_axi_master_bready;     //                           .bready

	 wire 				[11:0] 										hps_0_h2f_lw_axi_master_arid;       //                           .arid
	 wire 				[20:0] 										hps_0_h2f_lw_axi_master_araddr;     //                           .araddr
	 wire 				[3:0]  										hps_0_h2f_lw_axi_master_arlen;      //                           .arlen
	 wire 				[2:0]  										hps_0_h2f_lw_axi_master_arsize;     //                           .arsize
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_arburst;    //                           .arburst
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_arlock;    //                           .arlock
	 wire 				[3:0]  										hps_0_h2f_lw_axi_master_arcache;    //                           .arcache
	 wire 				[2:0]  										hps_0_h2f_lw_axi_master_arprot;     //                           .arprot
	 wire        													hps_0_h2f_lw_axi_master_arvalid;    //                           .arvalid
	 wire        													hps_0_h2f_lw_axi_master_arready;    //                           .arready

	 wire 				[11:0] 										hps_0_h2f_lw_axi_master_rid;        //                           .rid
	 wire 				[31:0] 										hps_0_h2f_lw_axi_master_rdata;      //                           .rdata
	 wire 				[1:0]  										hps_0_h2f_lw_axi_master_rresp;      //                           .rresp
	 wire        													hps_0_h2f_lw_axi_master_rlast;      //                           .rlast
	 wire        													hps_0_h2f_lw_axi_master_rvalid;     //                           .rvalid
	 wire        													hps_0_h2f_lw_axi_master_rready;     //                           .rready



	 // merlin axi4 lite interface
	 wire 				[7:0]  										merlin_axi_translator_0_m0_awid;    // merlin_axi_translator_0_m0.awid
	 wire 				[31:0] 										merlin_axi_translator_0_m0_awaddr;  //                           .awaddr
	 wire 				[3:0]  										merlin_axi_translator_0_m0_awlen;   //                           .awlen
	 wire 				[2:0]  										merlin_axi_translator_0_m0_awsize;  //                           .awsize
	 wire 				[1:0]  										merlin_axi_translator_0_m0_awburst; //                           .awburst
	 wire 				[1:0]  										merlin_axi_translator_0_m0_awlock;  //                           .awlock
	 wire 				[3:0]  										merlin_axi_translator_0_m0_awcache; //                           .awcache
	 wire 				[2:0]  										merlin_axi_translator_0_m0_awprot;  //                           .awprot
	 wire        													merlin_axi_translator_0_m0_awvalid; //                           .awvalid
	 wire        													merlin_axi_translator_0_m0_awready; //                           .awready

	 wire 				[7:0]  										merlin_axi_translator_0_m0_wid;     //                           .wid
	 wire 				[32:0] 										merlin_axi_translator_0_m0_wdata;   //                           .wdata
	 wire 				[7:0]  										merlin_axi_translator_0_m0_wstrb;   //                           .wstrb
	 wire        													merlin_axi_translator_0_m0_wlast;   //                           .wlast
	 wire        													merlin_axi_translator_0_m0_wvalid;  //                           .wvalid
	 wire        													merlin_axi_translator_0_m0_wready;  //                           .wready

	 wire 				[7:0]  										merlin_axi_translator_0_m0_bid;     //                           .bid
	 wire 				[1:0]  										merlin_axi_translator_0_m0_bresp;   //                           .bresp
	 wire        													merlin_axi_translator_0_m0_bvalid;  //                           .bvalid
	 wire        													merlin_axi_translator_0_m0_bready;  //                           .bready

	 wire 				[7:0]  										merlin_axi_translator_0_m0_arid;    //                           .arid
	 wire 				[31:0] 										merlin_axi_translator_0_m0_araddr;  //                           .araddr
	 wire 				[3:0]  										merlin_axi_translator_0_m0_arlen;   //                           .arlen
	 wire 				[2:0]  										merlin_axi_translator_0_m0_arsize;  //                           .arsize
	 wire 				[1:0]  										merlin_axi_translator_0_m0_arburst; //                           .arburst
	 wire 				[1:0]  										merlin_axi_translator_0_m0_arlock;  //                           .arlock
	 wire 				[3:0]  										merlin_axi_translator_0_m0_arcache; //                           .arcache
	 wire 				[2:0]  										merlin_axi_translator_0_m0_arprot;  //                           .arprot
	 wire 		 													merlin_axi_translator_0_m0_arvalid; //                           .arvalid
	 wire        													merlin_axi_translator_0_m0_arready; //                           .arready

	 wire 				[7:0]  										merlin_axi_translator_0_m0_rid;     //                           .rid
	 wire 				[31:0] 										merlin_axi_translator_0_m0_rdata;   //                           .rdata
	 wire 				[1:0]  										merlin_axi_translator_0_m0_rresp;   //                           .rresp
	 wire        													merlin_axi_translator_0_m0_rlast;   //                           .rlast
	 wire        													merlin_axi_translator_0_m0_rvalid;  //                           .rvalid
	 wire        													merlin_axi_translator_0_m0_rready;  //                           .rready
//----------------------------------------------------------------------------------------------------------------------
// Implmentation
//----------------------------------------------------------------------------------------------------------------------
	reg 						[26:0] 								r_count;

	wire 															hps_rst_n;
	wire 															hps_clk;

	always @(posedge hps_clk) begin 
		if(~hps_rst_n) begin
			r_count <= 0;
		end else begin
			r_count <= r_count + 1;
		end
	end

	assign led_o = r_count[26:19];

//----------------------------------------------------------------------------------------------------------------------
// Sub module instantiation
//----------------------------------------------------------------------------------------------------------------------

	ddr3 ddr3_inst 
	(
		.clk_clk 												(hps_clk), //(clk_i),    //   clk.clk
		.reset_reset_n 											(hps_rst_n), //(rst_n_i),    //   reset.reset_n

		// DDR3 SDRAM
		.memory_mem_a 											(memory_mem_a),
		.memory_mem_ba 											(memory_mem_ba),
		.memory_mem_ck 											(memory_mem_ck),
		.memory_mem_ck_n 										(memory_mem_ck_n),
		.memory_mem_cke 										(memory_mem_cke),
		.memory_mem_cs_n 										(memory_mem_cs_n),
		.memory_mem_ras_n 										(memory_mem_ras_n),
		.memory_mem_cas_n 										(memory_mem_cas_n),
		.memory_mem_we_n 										(memory_mem_we_n),
		.memory_mem_reset_n 									(memory_mem_reset_n),
		.memory_mem_dq 											(memory_mem_dq),
		.memory_mem_dqs 										(memory_mem_dqs),
		.memory_mem_dqs_n 										(memory_mem_dqs_n),
		.memory_mem_odt 										(memory_mem_odt),
		.memory_mem_dm 											(memory_mem_dm),
		.memory_oct_rzqin 										(memory_oct_rzqin),

		// SDRAM AXI
		//.hps_0_f2h_sdram0_data_araddr 							(sdram0_data_araddr),
		//.hps_0_f2h_sdram0_data_arlen 							(sdram0_data_arlen),
		//.hps_0_f2h_sdram0_data_arid 							(sdram0_data_arid),
		//.hps_0_f2h_sdram0_data_arsize 							(sdram0_data_arsize),
		//.hps_0_f2h_sdram0_data_arburst 							(sdram0_data_arburst),
		//.hps_0_f2h_sdram0_data_arlock 							(sdram0_data_arlock),
		//.hps_0_f2h_sdram0_data_arprot 							(sdram0_data_arprot),
		//.hps_0_f2h_sdram0_data_arvalid 							(sdram0_data_arvalid),
		//.hps_0_f2h_sdram0_data_arcache 							(sdram0_data_arcache),
		//.hps_0_f2h_sdram0_data_awaddr 							(sdram0_data_awaddr),
		//.hps_0_f2h_sdram0_data_awlen 							(sdram0_data_awlen),
		//.hps_0_f2h_sdram0_data_awid 							(sdram0_data_awid),
		//.hps_0_f2h_sdram0_data_awsize 							(sdram0_data_awsize),
		//.hps_0_f2h_sdram0_data_awburst 							(sdram0_data_awburst),
		//.hps_0_f2h_sdram0_data_awlock 							(sdram0_data_awlock),
		//.hps_0_f2h_sdram0_data_awprot 							(sdram0_data_awprot),
		//.hps_0_f2h_sdram0_data_awvalid 							(sdram0_data_awvalid),
		//.hps_0_f2h_sdram0_data_awcache 							(sdram0_data_awcache),
		//.hps_0_f2h_sdram0_data_bresp 							(sdram0_data_bresp),
		//.hps_0_f2h_sdram0_data_bid 								(sdram0_data_bid),
		//.hps_0_f2h_sdram0_data_bvalid 							(sdram0_data_bvalid),
		//.hps_0_f2h_sdram0_data_bready 							(sdram0_data_bready),
		//.hps_0_f2h_sdram0_data_arready 							(sdram0_data_arready),
		//.hps_0_f2h_sdram0_data_awready 							(sdram0_data_awready),
		//.hps_0_f2h_sdram0_data_rready 							(sdram0_data_rready),
		//.hps_0_f2h_sdram0_data_rdata 							(sdram0_data_rdata),
		//.hps_0_f2h_sdram0_data_rresp 							(sdram0_data_rresp),
		//.hps_0_f2h_sdram0_data_rlast 							(sdram0_data_rlast),
		//.hps_0_f2h_sdram0_data_rid 								(sdram0_data_rid),
		//.hps_0_f2h_sdram0_data_rvalid 							(sdram0_data_rvalid),
		//.hps_0_f2h_sdram0_data_wlast 							(sdram0_data_wlast),
		//.hps_0_f2h_sdram0_data_wvalid 							(sdram0_data_wvalid),
		//.hps_0_f2h_sdram0_data_wdata 							(sdram0_data_wdata),
		//.hps_0_f2h_sdram0_data_wstrb 							(sdram0_data_wstrb),
		//.hps_0_f2h_sdram0_data_wready 							(sdram0_data_wready),
		//.hps_0_f2h_sdram0_data_wid 								(sdram0_data_wid),

		// AXI Master Translator
		//.merlin_axi_translator_0_m0_awid 						(sdram0_data_awid),    // merlin_axi_translator_0_m0.awid
		//.merlin_axi_translator_0_m0_awaddr 						(sdram0_data_awaddr),  //                           .awaddr
		//.merlin_axi_translator_0_m0_awlen 						(sdram0_data_awlen),   //                           .awlen
		//.merlin_axi_translator_0_m0_awsize 						(sdram0_data_awsize),  //                           .awsize
		//.merlin_axi_translator_0_m0_awburst 					(sdram0_data_awburst), //                           .awburst
		//.merlin_axi_translator_0_m0_awlock 						(sdram0_data_awlock),  //                           .awlock
		//.merlin_axi_translator_0_m0_awcache 					(sdram0_data_awcache), //                           .awcache
		//.merlin_axi_translator_0_m0_awprot 						(sdram0_data_awprot),  //                           .awprot
		//.merlin_axi_translator_0_m0_awvalid 					(sdram0_data_awvalid), //                           .awvalid
		//.merlin_axi_translator_0_m0_awready 					(sdram0_data_awready), //                           .awready
		//
		//.merlin_axi_translator_0_m0_wid 						(sdram0_data_wid),     //                           .wid
		//.merlin_axi_translator_0_m0_wdata 						(sdram0_data_wdata),   //                           .wdata
		//.merlin_axi_translator_0_m0_wstrb 						(sdram0_data_wstrb),   //                           .wstrb
		//.merlin_axi_translator_0_m0_wlast 						(sdram0_data_wlast),   //                           .wlast
		//.merlin_axi_translator_0_m0_wvalid 						(sdram0_data_wvalid),  //                           .wvalid
		//.merlin_axi_translator_0_m0_wready 						(sdram0_data_wready),  //                           .wready
		//
		//.merlin_axi_translator_0_m0_bid 						(sdram0_data_bid),     //                           .bid
		//.merlin_axi_translator_0_m0_bresp 						(sdram0_data_bresp),   //                           .bresp
		//.merlin_axi_translator_0_m0_bvalid						(sdram0_data_bvalid),  //                           .bvalid
		//.merlin_axi_translator_0_m0_bready						(sdram0_data_bready),  //                           .bready
		//
		//.merlin_axi_translator_0_m0_arid 						(sdram0_data_arid),    //                           .arid
		//.merlin_axi_translator_0_m0_araddr 						(sdram0_data_araddr),  //                           .araddr
		//.merlin_axi_translator_0_m0_arlen 						(sdram0_data_arlen),   //                           .arlen
		//.merlin_axi_translator_0_m0_arsize 						(sdram0_data_arsize),  //                           .arsize
		//.merlin_axi_translator_0_m0_arburst 					(sdram0_data_arburst), //                           .arburst
		//.merlin_axi_translator_0_m0_arlock 						(sdram0_data_arlock),  //                           .arlock
		//.merlin_axi_translator_0_m0_arcache 					(sdram0_data_arcache), //                           .arcache
		//.merlin_axi_translator_0_m0_arprot 						(sdram0_data_arprot),  //                           .arprot
		//.merlin_axi_translator_0_m0_arvalid 					(sdram0_data_arvalid), //                           .arvalid
		//.merlin_axi_translator_0_m0_arready 					(sdram0_data_arready), //                           .arready
		//
		//.merlin_axi_translator_0_m0_rid 						(sdram0_data_rid),     //                           .rid
		//.merlin_axi_translator_0_m0_rdata 						(sdram0_data_rdata),   //                           .rdata
		//.merlin_axi_translator_0_m0_rresp 						(sdram0_data_rresp),   //                           .rresp
		//.merlin_axi_translator_0_m0_rlast 						(sdram0_data_rlast),   //                           .rlast
		//.merlin_axi_translator_0_m0_rvalid 						(sdram0_data_rvalid),  //                           .rvalid
		//.merlin_axi_translator_0_m0_rready 						(sdram0_data_rready),  //                           .rready

		// AXI Slave Translator
		.merlin_axi_translator_0_s0_awid 						(axi_ddr3_awid),   
		.merlin_axi_translator_0_s0_awaddr 						(axi_ddr3_awaddr), 
		.merlin_axi_translator_0_s0_awlen 						(axi_ddr3_awlen),  
		.merlin_axi_translator_0_s0_awsize 						(axi_ddr3_awsize), 
		.merlin_axi_translator_0_s0_awburst 					(axi_ddr3_awburst),
		.merlin_axi_translator_0_s0_awlock 						(axi_ddr3_awlock), 
		.merlin_axi_translator_0_s0_awcache 					(axi_ddr3_awcache),
		.merlin_axi_translator_0_s0_awprot 						(axi_ddr3_awprot), 
		.merlin_axi_translator_0_s0_awqos 						(axi_ddr3_awqos), 
		.merlin_axi_translator_0_s0_awvalid 					(axi_ddr3_awvalid),
		.merlin_axi_translator_0_s0_awready 					(axi_ddr3_awready),
		
		.merlin_axi_translator_0_s0_wdata 						(axi_ddr3_wdata),  
		.merlin_axi_translator_0_s0_wstrb 						(axi_ddr3_wstrb),  
		.merlin_axi_translator_0_s0_wlast 						(axi_ddr3_wlast),  
		.merlin_axi_translator_0_s0_wvalid 						(axi_ddr3_wvalid), 
		.merlin_axi_translator_0_s0_wready 						(axi_ddr3_wready), 
		
		.merlin_axi_translator_0_s0_bid 						(axi_ddr3_bid),    
		.merlin_axi_translator_0_s0_bresp 						(axi_ddr3_bresp),  
		.merlin_axi_translator_0_s0_bvalid 						(axi_ddr3_bvalid), 
		.merlin_axi_translator_0_s0_bready 						(axi_ddr3_bready), 
		
		.merlin_axi_translator_0_s0_arid 						(axi_ddr3_arid),   
		.merlin_axi_translator_0_s0_araddr 						(axi_ddr3_araddr), 
		.merlin_axi_translator_0_s0_arlen 						(axi_ddr3_arlen),  
		.merlin_axi_translator_0_s0_arsize 						(axi_ddr3_arsize), 
		.merlin_axi_translator_0_s0_arburst 					(axi_ddr3_arburst),
		.merlin_axi_translator_0_s0_arlock 						(axi_ddr3_arlock), 
		.merlin_axi_translator_0_s0_arcache 					(axi_ddr3_arcache),
		.merlin_axi_translator_0_s0_arprot 						(axi_ddr3_arprot), 
		.merlin_axi_translator_0_s0_arqos 						(axi_ddr3_arqos), 
		.merlin_axi_translator_0_s0_arvalid 					(axi_ddr3_arvalid),
		.merlin_axi_translator_0_s0_arready 					(axi_ddr3_arready),
		
		.merlin_axi_translator_0_s0_rid 						(axi_ddr3_rid),    
		.merlin_axi_translator_0_s0_rdata 						(axi_ddr3_rdata),  
		.merlin_axi_translator_0_s0_rresp 						(axi_ddr3_rresp),  
		.merlin_axi_translator_0_s0_rlast 						(axi_ddr3_rlast),  
		.merlin_axi_translator_0_s0_rvalid 						(axi_ddr3_rvalid), 
		.merlin_axi_translator_0_s0_rready 						(axi_ddr3_rready), 

		//input  wire [7:0]  hps_0_f2h_axi_slave_awid,           //        hps_0_f2h_axi_slave.awid
		//input  wire [31:0] hps_0_f2h_axi_slave_awaddr,         //                           .awaddr
		//input  wire [3:0]  hps_0_f2h_axi_slave_awlen,          //                           .awlen
		//input  wire [2:0]  hps_0_f2h_axi_slave_awsize,         //                           .awsize
		//input  wire [1:0]  hps_0_f2h_axi_slave_awburst,        //                           .awburst
		//input  wire [1:0]  hps_0_f2h_axi_slave_awlock,         //                           .awlock
		//input  wire [3:0]  hps_0_f2h_axi_slave_awcache,        //                           .awcache
		//input  wire [2:0]  hps_0_f2h_axi_slave_awprot,         //                           .awprot
		//input  wire        hps_0_f2h_axi_slave_awvalid,        //                           .awvalid
		//output wire        hps_0_f2h_axi_slave_awready,        //                           .awready
		//input  wire [4:0]  hps_0_f2h_axi_slave_awuser,         //                           .awuser
		//input  wire [7:0]  hps_0_f2h_axi_slave_wid,            //                           .wid
		//input  wire [63:0] hps_0_f2h_axi_slave_wdata,          //                           .wdata
		//input  wire [7:0]  hps_0_f2h_axi_slave_wstrb,          //                           .wstrb
		//input  wire        hps_0_f2h_axi_slave_wlast,          //                           .wlast
		//input  wire        hps_0_f2h_axi_slave_wvalid,         //                           .wvalid
		//output wire        hps_0_f2h_axi_slave_wready,         //                           .wready
		//output wire [7:0]  hps_0_f2h_axi_slave_bid,            //                           .bid
		//output wire [1:0]  hps_0_f2h_axi_slave_bresp,          //                           .bresp
		//output wire        hps_0_f2h_axi_slave_bvalid,         //                           .bvalid
		//input  wire        hps_0_f2h_axi_slave_bready,         //                           .bready
		//input  wire [7:0]  hps_0_f2h_axi_slave_arid,           //                           .arid
		//input  wire [31:0] hps_0_f2h_axi_slave_araddr,         //                           .araddr
		//input  wire [3:0]  hps_0_f2h_axi_slave_arlen,          //                           .arlen
		//input  wire [2:0]  hps_0_f2h_axi_slave_arsize,         //                           .arsize
		//input  wire [1:0]  hps_0_f2h_axi_slave_arburst,        //                           .arburst
		//input  wire [1:0]  hps_0_f2h_axi_slave_arlock,         //                           .arlock
		//input  wire [3:0]  hps_0_f2h_axi_slave_arcache,        //                           .arcache
		//input  wire [2:0]  hps_0_f2h_axi_slave_arprot,         //                           .arprot
		//input  wire        hps_0_f2h_axi_slave_arvalid,        //                           .arvalid
		//output wire        hps_0_f2h_axi_slave_arready,        //                           .arready
		//input  wire [4:0]  hps_0_f2h_axi_slave_aruser,         //                           .aruser
		//output wire [7:0]  hps_0_f2h_axi_slave_rid,            //                           .rid
		//output wire [63:0] hps_0_f2h_axi_slave_rdata,          //                           .rdata
		//output wire [1:0]  hps_0_f2h_axi_slave_rresp,          //                           .rresp
		//output wire        hps_0_f2h_axi_slave_rlast,          //                           .rlast
		//output wire        hps_0_f2h_axi_slave_rvalid,         //                           .rvalid
		//input  wire        hps_0_f2h_axi_slave_rready,         //                           .rready

		

		//output wire [11:0] hps_0_h2f_axi_master_awid,          //       hps_0_h2f_axi_master.awid
		//output wire [29:0] hps_0_h2f_axi_master_awaddr,        //                           .awaddr
		//output wire [3:0]  hps_0_h2f_axi_master_awlen,         //                           .awlen
		//output wire [2:0]  hps_0_h2f_axi_master_awsize,        //                           .awsize
		//output wire [1:0]  hps_0_h2f_axi_master_awburst,       //                           .awburst
		//output wire [1:0]  hps_0_h2f_axi_master_awlock,        //                           .awlock
		//output wire [3:0]  hps_0_h2f_axi_master_awcache,       //                           .awcache
		//output wire [2:0]  hps_0_h2f_axi_master_awprot,        //                           .awprot
		//output wire        hps_0_h2f_axi_master_awvalid,       //                           .awvalid
		//input  wire        hps_0_h2f_axi_master_awready,       //                           .awready
		//output wire [11:0] hps_0_h2f_axi_master_wid,           //                           .wid
		//output wire [63:0] hps_0_h2f_axi_master_wdata,         //                           .wdata
		//output wire [7:0]  hps_0_h2f_axi_master_wstrb,         //                           .wstrb
		//output wire        hps_0_h2f_axi_master_wlast,         //                           .wlast
		//output wire        hps_0_h2f_axi_master_wvalid,        //                           .wvalid
		//input  wire        hps_0_h2f_axi_master_wready,        //                           .wready
		//input  wire [11:0] hps_0_h2f_axi_master_bid,           //                           .bid
		//input  wire [1:0]  hps_0_h2f_axi_master_bresp,         //                           .bresp
		//input  wire        hps_0_h2f_axi_master_bvalid,        //                           .bvalid
		//output wire        hps_0_h2f_axi_master_bready,        //                           .bready
		//output wire [11:0] hps_0_h2f_axi_master_arid,          //                           .arid
		//output wire [29:0] hps_0_h2f_axi_master_araddr,        //                           .araddr
		//output wire [3:0]  hps_0_h2f_axi_master_arlen,         //                           .arlen
		//output wire [2:0]  hps_0_h2f_axi_master_arsize,        //                           .arsize
		//output wire [1:0]  hps_0_h2f_axi_master_arburst,       //                           .arburst
		//output wire [1:0]  hps_0_h2f_axi_master_arlock,        //                           .arlock
		//output wire [3:0]  hps_0_h2f_axi_master_arcache,       //                           .arcache
		//output wire [2:0]  hps_0_h2f_axi_master_arprot,        //                           .arprot
		//output wire        hps_0_h2f_axi_master_arvalid,       //                           .arvalid
		//input  wire        hps_0_h2f_axi_master_arready,       //                           .arready
		//input  wire [11:0] hps_0_h2f_axi_master_rid,           //                           .rid
		//input  wire [63:0] hps_0_h2f_axi_master_rdata,         //                           .rdata
		//input  wire [1:0]  hps_0_h2f_axi_master_rresp,         //                           .rresp
		//input  wire        hps_0_h2f_axi_master_rlast,         //                           .rlast
		//input  wire        hps_0_h2f_axi_master_rvalid,        //                           .rvalid
		//output wire        hps_0_h2f_axi_master_rready,        //                           .rready
		.hps_0_h2f_lw_axi_clock_clk								(hps_clk),
		.hps_0_h2f_lw_axi_master_awid							(hps_0_h2f_lw_axi_master_awid),       
		.hps_0_h2f_lw_axi_master_awaddr							(hps_0_h2f_lw_axi_master_awaddr),   
		.hps_0_h2f_lw_axi_master_awlen							(hps_0_h2f_lw_axi_master_awlen),     
		.hps_0_h2f_lw_axi_master_awsize							(hps_0_h2f_lw_axi_master_awsize),   
		.hps_0_h2f_lw_axi_master_awburst						(hps_0_h2f_lw_axi_master_awburst), 
		.hps_0_h2f_lw_axi_master_awlock							(hps_0_h2f_lw_axi_master_awlock),   
		.hps_0_h2f_lw_axi_master_awcache						(hps_0_h2f_lw_axi_master_awcache), 
		.hps_0_h2f_lw_axi_master_awprot							(hps_0_h2f_lw_axi_master_awprot),   
		.hps_0_h2f_lw_axi_master_awvalid						(hps_0_h2f_lw_axi_master_awvalid), 
		.hps_0_h2f_lw_axi_master_awready						(hps_0_h2f_lw_axi_master_awready), 

		.hps_0_h2f_lw_axi_master_wid 							(hps_0_h2f_lw_axi_master_wid),       
		.hps_0_h2f_lw_axi_master_wdata 							(hps_0_h2f_lw_axi_master_wdata),     
		.hps_0_h2f_lw_axi_master_wstrb							(hps_0_h2f_lw_axi_master_wstrb),     
		.hps_0_h2f_lw_axi_master_wlast							(hps_0_h2f_lw_axi_master_wlast),     
		.hps_0_h2f_lw_axi_master_wvalid 						(hps_0_h2f_lw_axi_master_wvalid),    
		.hps_0_h2f_lw_axi_master_wready 						(hps_0_h2f_lw_axi_master_wready),    

		.hps_0_h2f_lw_axi_master_bid 							(hps_0_h2f_lw_axi_master_bid),        
		.hps_0_h2f_lw_axi_master_bresp 							(hps_0_h2f_lw_axi_master_bresp),      
		.hps_0_h2f_lw_axi_master_bvalid 						(hps_0_h2f_lw_axi_master_bvalid),     
		.hps_0_h2f_lw_axi_master_bready 						(hps_0_h2f_lw_axi_master_bready),     

		.hps_0_h2f_lw_axi_master_arid    						(hps_0_h2f_lw_axi_master_arid),       
		.hps_0_h2f_lw_axi_master_araddr    						(hps_0_h2f_lw_axi_master_araddr),     
		.hps_0_h2f_lw_axi_master_arlen    						(hps_0_h2f_lw_axi_master_arlen),      
		.hps_0_h2f_lw_axi_master_arsize    						(hps_0_h2f_lw_axi_master_arsize),     
		.hps_0_h2f_lw_axi_master_arburst    					(hps_0_h2f_lw_axi_master_arburst),    
		.hps_0_h2f_lw_axi_master_arlock    						(hps_0_h2f_lw_axi_master_arlock),     
		.hps_0_h2f_lw_axi_master_arcache    					(hps_0_h2f_lw_axi_master_arcache),    
		.hps_0_h2f_lw_axi_master_arprot    						(hps_0_h2f_lw_axi_master_arprot),     
		.hps_0_h2f_lw_axi_master_arvalid    					(hps_0_h2f_lw_axi_master_arvalid),    
		.hps_0_h2f_lw_axi_master_arready    					(hps_0_h2f_lw_axi_master_arready),    

		.hps_0_h2f_lw_axi_master_rid              				(hps_0_h2f_lw_axi_master_rid),        
		.hps_0_h2f_lw_axi_master_rdata              			(hps_0_h2f_lw_axi_master_rdata),      
		.hps_0_h2f_lw_axi_master_rresp              			(hps_0_h2f_lw_axi_master_rresp),      
		.hps_0_h2f_lw_axi_master_rlast              			(hps_0_h2f_lw_axi_master_rlast),      
		.hps_0_h2f_lw_axi_master_rvalid              			(hps_0_h2f_lw_axi_master_rvalid),     
		.hps_0_h2f_lw_axi_master_rready              			(hps_0_h2f_lw_axi_master_rready),     

		//input  wire        hps_0_h2f_mpu_events_eventi,        //       hps_0_h2f_mpu_events.eventi
		//output wire        hps_0_h2f_mpu_events_evento,        //                           .evento
		//output wire [1:0]  hps_0_h2f_mpu_events_standbywfe,    //                           .standbywfe
		//output wire [1:0]  hps_0_h2f_mpu_events_standbywfi,    //                           .standbywfi

		.hps_0_h2f_reset_reset_n 								(hps_rst_n),            //            hps_0_h2f_reset.reset_n
		.hps_0_h2f_user1_clock_clk 								(hps_clk)
	);

	ddr3_controller# (
        .C_S_AXI_ID_WIDTH              							(8),
        .C_S_AXI_ADDR_WIDTH            							(32),
        .C_S_AXI_DATA_WIDTH            							(64),
        .C_S_AXI_BURST_LEN             							(8)   
    ) ddr3_controller_inst
    (
    	.clk 													(hps_clk), //(clk_i),
    	.reset_n 												(hps_rst_n), //rst_n_i),
	// AXI Write Address Control Signals
		.M_axi_awid 											(axi_ddr3_awid), 	
		.M_axi_awaddr 											(axi_ddr3_awaddr),	
		.M_axi_awlen 											(axi_ddr3_awlen),	
		.M_axi_awsize 											(axi_ddr3_awsize), 	
		.M_axi_awburst 											(axi_ddr3_awburst), 
		.M_axi_awlock 											(axi_ddr3_awlock),	
		.M_axi_awcache 											(axi_ddr3_awcache), 
		.M_axi_awprot 											(axi_ddr3_awprot), 	
    	.M_axi_awqos 											(axi_ddr3_awqos), 	
		.M_axi_awvalid 											(axi_ddr3_awvalid),	
		.M_axi_awready 											(axi_ddr3_awready), 

	// AXI Write Data Control Signals
		.M_axi_wdata 											(axi_ddr3_wdata),
		.M_axi_wstrb 											(axi_ddr3_wstrb),
		.M_axi_wlast 											(axi_ddr3_wlast),
		.M_axi_wvalid 											(axi_ddr3_wvalid),
		.M_axi_wready 											(axi_ddr3_wready),

	// AXI Response Control Signals
		.M_axi_bid												(axi_ddr3_bid),
		.M_axi_bresp											(axi_ddr3_bresp),
		.M_axi_bvalid											(axi_ddr3_bvalid),
		.M_axi_bready											(axi_ddr3_bready),

	// AXI Read Address Control Signals
		.M_axi_arid 											(axi_ddr3_arid), 	
		.M_axi_araddr 											(axi_ddr3_araddr), 
		.M_axi_arlen 											(axi_ddr3_arlen), 	
		.M_axi_arsize 											(axi_ddr3_arsize), 
		.M_axi_arburst 											(axi_ddr3_arburst),
		.M_axi_arlock 											(axi_ddr3_arlock), 
		.M_axi_arcache 											(axi_ddr3_arcache),
		.M_axi_arprot 											(axi_ddr3_arprot), 
		.M_axi_arqos 											(axi_ddr3_arqos),	
		.M_axi_arvalid 											(axi_ddr3_arvalid),
		.M_axi_arready 											(axi_ddr3_arready),

	// AXI Read Data Control Signals
		.M_axi_rid 												(axi_ddr3_rid), 
		.M_axi_rdata 											(axi_ddr3_rdata),
		.M_axi_rresp 											(axi_ddr3_rresp),
    	.M_axi_rlast 											(axi_ddr3_rlast),
		.M_axi_rvalid 											(axi_ddr3_rvalid),
		.M_axi_rready 											(axi_ddr3_rready)
	
);



    // demo_axi_memory (
			 //       clk,   
			 //       reset_n,

			 //       axs_awid,
			 //       axs_awaddr,
			 //       axs_awlen,
			 //       axs_awsize,
			 //       axs_awburst,
			 //       axs_awlock,
			 //       axs_awcache,
			 //       axs_awprot,
			 //       axs_awvalid,
			 //       axs_awready,

			 //       axs_wid,
			 //       axs_wdata,
			 //       axs_wstrb,
			 //       axs_wlast,
			 //       axs_wvalid,
			 //       axs_wready,

			 //       axs_bid,
			 //       axs_bresp,
			 //       axs_bvalid,
			 //       axs_bready,
				  
			 //       axs_arid,
			 //       axs_araddr,
			 //       axs_arlen,
			 //       axs_arsize,
			 //       axs_arburst,
			 //       axs_arlock,
			 //       axs_arcache,
			 //       axs_arprot,
			 //       axs_arvalid,
			 //       axs_arready,

			 //       axs_rid,
			 //       axs_rdata,
			 //       axs_rlast,
			 //       axs_rvalid,
			 //       axs_rready,
			 //       axs_rresp,

 			//        avs_waitrequest,
 			//        avs_write,
 			//        avs_read,
 			//        avs_address,
 			//        avs_byteenable,
 			//        avs_writedata,
 			//        avs_readdata,

			 //       aso_data,
			 //       aso_valid,
			 //       aso_ready
			 //       );

    axi_mem #
	(
		.C_S_AXI_ID_WIDTH										(12),
		.C_S_AXI_DATA_WIDTH										(32),
		.C_S_AXI_ADDR_WIDTH										(10),
		.C_S_AXI_AWUSER_WIDTH									(0),
		.C_S_AXI_ARUSER_WIDTH									(0),
		.C_S_AXI_WUSER_WIDTH									(0),
		.C_S_AXI_RUSER_WIDTH									(0),
		.C_S_AXI_BUSER_WIDTH									(0)
	)
	axi_mem_inst
	(
		.S_AXI_ACLK												(hps_clk),
		.S_AXI_ARESETN											(hps_rst_n),

		.S_AXI_AWID												(hps_0_h2f_lw_axi_master_awid),
		.S_AXI_AWADDR											(hps_0_h2f_lw_axi_master_awaddr),
		.S_AXI_AWLEN											(hps_0_h2f_lw_axi_master_awlen),
		.S_AXI_AWSIZE											(hps_0_h2f_lw_axi_master_awsize),
		.S_AXI_AWBURST											(hps_0_h2f_lw_axi_master_awburst),
		.S_AXI_AWLOCK											(hps_0_h2f_lw_axi_master_awlock),
		.S_AXI_AWCACHE											(hps_0_h2f_lw_axi_master_awcache),
		.S_AXI_AWPROT											(hps_0_h2f_lw_axi_master_awprot),
		.S_AXI_AWQOS											(hps_0_h2f_lw_axi_master_awqos),
		.S_AXI_AWREGION											(hps_0_h2f_lw_axi_master_awregion),
	//	.S_AXI_AWUSER											(hps_0_h2f_lw_axi_master_awuser),
		.S_AXI_AWVALID											(hps_0_h2f_lw_axi_master_awvalid),
		.S_AXI_AWREADY											(hps_0_h2f_lw_axi_master_awready),

		.S_AXI_WDATA											(hps_0_h2f_lw_axi_master_wdata),
		.S_AXI_WSTRB											(hps_0_h2f_lw_axi_master_wstrb),
		.S_AXI_WLAST											(hps_0_h2f_lw_axi_master_wlast),
	//	.S_AXI_WUSER											(hps_0_h2f_lw_axi_master_wuser),
		.S_AXI_WVALID											(hps_0_h2f_lw_axi_master_wvalid),
		.S_AXI_WREADY											(hps_0_h2f_lw_axi_master_wready),

		.S_AXI_BID												(hps_0_h2f_lw_axi_master_bid),
		.S_AXI_BRESP											(hps_0_h2f_lw_axi_master_bresp),
	//	.S_AXI_BUSER											(hps_0_h2f_lw_axi_master_buser),
		.S_AXI_BVALID											(hps_0_h2f_lw_axi_master_bvalid),
		.S_AXI_BREADY											(hps_0_h2f_lw_axi_master_bready),

		.S_AXI_ARID												(hps_0_h2f_lw_axi_master_arid),
		.S_AXI_ARADDR											(hps_0_h2f_lw_axi_master_araddr),
		.S_AXI_ARLEN											(hps_0_h2f_lw_axi_master_arlen),
		.S_AXI_ARSIZE											(hps_0_h2f_lw_axi_master_arsize),
		.S_AXI_ARBURST											(hps_0_h2f_lw_axi_master_arburst),
		.S_AXI_ARLOCK											(hps_0_h2f_lw_axi_master_arlock),
		.S_AXI_ARCACHE											(hps_0_h2f_lw_axi_master_arcache),
		.S_AXI_ARPROT											(hps_0_h2f_lw_axi_master_arprot),
		.S_AXI_ARQOS											(hps_0_h2f_lw_axi_master_arqos),
		.S_AXI_ARREGION											(hps_0_h2f_lw_axi_master_arregion),
	//	.S_AXI_ARUSER										(hps_0_h2f_lw_axi_master_aruser),
		.S_AXI_ARVALID											(hps_0_h2f_lw_axi_master_arvalid),
		.S_AXI_ARREADY											(hps_0_h2f_lw_axi_master_arready),

		.S_AXI_RID												(hps_0_h2f_lw_axi_master_rid),
		.S_AXI_RDATA											(hps_0_h2f_lw_axi_master_rdata),
		.S_AXI_RRESP											(hps_0_h2f_lw_axi_master_rresp),
		.S_AXI_RLAST											(hps_0_h2f_lw_axi_master_rlast),
	//	.S_AXI_RUSER											(hps_0_h2f_lw_axi_master_ruser),
		.S_AXI_RVALID											(hps_0_h2f_lw_axi_master_rvalid),
		.S_AXI_RREADY											(hps_0_h2f_lw_axi_master_rready)
	);
endmodule

	
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2018 09:40:45 AM
// Design Name: 
// Module Name: ddr3_controller
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


module ddr3_controller# (
            parameter                           C_S_AXI_ID_WIDTH              =     3,
            parameter                           C_S_AXI_ADDR_WIDTH            =     32,
            parameter                           C_S_AXI_DATA_WIDTH            =     64,
            parameter                           C_S_AXI_BURST_LEN             =     8
            
            // take care to xsize
 
    ) (


     input  wire                                                    clk,
     input  wire                                                    reset_n,
	// AXI Write Address Control Signals
	 output  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_awid, 			// Write Address Channel Transaction ID  				(Input)
	 output  wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_awaddr,			// Write Address Channel Address 						(Input)
	 output  wire 			[7:0] 									M_axi_awlen,			// Write Address Channel Burst Length (0-255) 			(Input)
	 output  wire 			[2:0] 									M_axi_awsize, 			// Write Address Channel Transfer Size code (0-7) 		(Input)
	 output  wire 			[1:0]									M_axi_awburst,      	// Write Address Channel Burst Type code (0-2). 		(Input)
	 output  wire 			[0:0]									M_axi_awlock,			// Write Address Channel Atomic Access Type (0, 1) 		(Input)
	 output  wire 			[3:0]									M_axi_awcache, 		// Write Address Channel Cache Characteristics 			(Input)
	 output  wire 			[2:0]									M_axi_awprot, 		// Write Address Channel Protection Bits 				(Input)
     output  wire 			[3:0]									M_axi_awqos, 			// AXI4 Write Address Channel Quality of Service 		(Input)
	 output  wire 													M_axi_awvalid,		// Write Address Channel Valid 							(Input)
	 input   wire 													M_axi_awready, 		// Write Address Channel Ready 							(Output)

	// AXI Write Data Control Signals
	 output  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_wdata,			// Write Data Channel Data								(Input)
	 output  wire 			[C_S_AXI_DATA_WIDTH/8-1:0]				M_axi_wstrb,			// Write Data Channel Byte Strobes						(Input)
	 output  wire  													M_axi_wlast,			// Write Data Channel Last Data Beat					(Input)
	 output  wire 													M_axi_wvalid,			// Write Data Channel Valid.							(Input)
	 input   wire 													M_axi_wready,			// Write Data Channel Ready. 							(Output)

	// AXI Response Control Signals
	 input  wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_bid, 			// Write Response Channel Transaction ID.				(Output)
	 input  wire 			[1:0]									M_axi_bresp,			// Write Response Channel Response Code (0-3).			(Output)
	 input  wire 													M_axi_bvalid, 		// Write Response Channel Valid.						(Output)
	 output wire 												    M_axi_bready,			// Write Response Channel Ready.						(Input)

	// AXI Read Address Control Signals
	 output wire 			[C_S_AXI_ID_WIDTH-1:0]					M_axi_arid, 			// Read Address Channel transaction ID.					(Input)
	 output wire 			[C_S_AXI_ADDR_WIDTH-1:0]				M_axi_araddr, 		// Read Address Channel Address.						(Input)
	 output wire 			[7:0] 									M_axi_arlen, 			// Read Address Channel Burst Length code (0-255).		(Input)
	 output wire 			[2:0]									M_axi_arsize, 			// Read Address Channel Transfer Size code (0-7).		(Input)
	 output wire 			[1:0]									M_axi_arburst, 		// Read Address Channel Burst Type (0-2).				(Input)
	 output wire 			[0:0]									M_axi_arlock, 		// Read Address Channel Atomic Access Type (0, 1).		(Input)
	 output wire 			[3:0]									M_axi_arcache, 		// Read Address Channel Cache Characteristics.			(Input)
	 output wire 			[2:0]									M_axi_arprot, 		// Read Address Channel Protection Bits.				(Input)
	 output wire 			[3:0]									M_axi_arqos,			// AXI4 Read Address Channel Quality of Service.		(Input)
	 output wire 													M_axi_arvalid,		// Read Address Channel Valid.							(Input)
	 input  wire 													M_axi_arready,		// Read Address Channel Ready.							(Output)

	// AXI Read Data Control Signals
	 input  wire 			[C_S_AXI_ID_WIDTH-1:0] 					M_axi_rid, 			// Read Data Channel Transaction ID.					(Output)
	 input  wire 			[C_S_AXI_DATA_WIDTH-1:0]				M_axi_rdata,			// Read Data Channel Data.								(Output)
	 input  wire 			[1:0]									M_axi_rresp,			// Read Data Channel Response Code (0-3).				(Output)
     input  wire 													M_axi_rlast,			// Read Data Channel Last Data Beat.					(Output)
	 input  wire 													M_axi_rvalid,			// Read Data Channel Valid.								(Output)
	 output wire 												    M_axi_rready			// Read Data Channel Ready.								(Input)
	
);


//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------
    
	// Write Address Control Signals
	assign M_axi_awid = 0;
	assign M_axi_awaddr = r_counter_write;
	assign M_axi_awlen = C_S_AXI_BURST_LEN-1;
	assign M_axi_awsize = $clog2(C_S_AXI_DATA_WIDTH/8);
	assign M_axi_awburst = 1;
	assign M_axi_awlock = 0;
	assign M_axi_awcache = 4'b0011;
	assign M_axi_awprot = 0;
	assign M_axi_awqos = 0;

	// Write Data Control Signals	
	assign M_axi_wdata  = 64'haaaaaaaaaaaaaaaa;//{r_counter_write_data,r_counter_write_data}; //{32'b0, r_counter_write}; //(w_s_axi_wready) ? r_counter_write : 0;
	assign M_axi_wstrb  = {(C_S_AXI_DATA_WIDTH/8){1'b1}}; //*************************************** correction

	// Read Address COntrol Signals
	assign M_axi_arid = 1;
	assign M_axi_araddr = r_counter_read;
	assign M_axi_arlen = C_S_AXI_BURST_LEN - 1;
	assign M_axi_arsize = $clog2(C_S_AXI_DATA_WIDTH/8);;
	assign M_axi_arburst = 1;
	assign M_axi_arlock = 0;
	assign M_axi_arcache = 4'b0011;
	assign M_axi_arprot = 0;
	assign M_axi_arqos = 0;


//********************************************************************************
//********** DDR3 Write **********************************************************
//********************************************************************************


    reg state_;
    
    always@(posedge clk) begin
        if(~reset_n || r_counter_read> 32'h10000000 )
            state_ <= 0;
        else if (r_counter_write > 32'h10000000)
            state_ <= 1;
    end
	
	(* mark_debug = "true" *) reg[3:0] r_axi_write_FSM;
        always@(posedge clk) begin
            if(~reset_n || state_ == 1) begin
                r_axi_write_FSM <= 0;
            end else begin 
                case(r_axi_write_FSM) 
                    4'b0000 : if(M_axi_awvalid & M_axi_awready)    r_axi_write_FSM <= 4'b0001;
                    4'b0001 : if(M_axi_wvalid & M_axi_wready & M_axi_wlast) r_axi_write_FSM<= 4'b0010;
                    4'b0010 : if(r_M_axi_bready & M_axi_bvalid) r_axi_write_FSM<= 4'b0000;
                endcase
            end
        end


	// Valid for write address
	reg r_M_axi_awvalid;
	always @(posedge clk) begin
		if(   ~reset_n || state_ == 1 ) 
			r_M_axi_awvalid <= 0;
		else if(r_M_axi_awvalid && M_axi_awready)
		    r_M_axi_awvalid <= 0;
	    else if(~r_M_axi_awvalid && r_axi_write_FSM == 4'b0000) 
            r_M_axi_awvalid <= 1;
	end
	assign M_axi_awvalid = r_M_axi_awvalid;


	// Valid for write data
	reg r_M_axi_wvalid;
	always @(posedge clk) begin
		if(~reset_n) 
			r_M_axi_wvalid <= 0;
		else if (r_M_axi_wlast && r_M_axi_wvalid && M_axi_wready)
		    r_M_axi_wvalid <= 0;
		else  if(r_axi_write_FSM == 4'b0001)
            r_M_axi_wvalid <= 1;
	end
	assign M_axi_wvalid = r_M_axi_wvalid;


	// valid for response signal
	reg r_M_axi_bready;
	always @(posedge clk) begin
	   if(~reset_n || M_axi_wlast && M_axi_wvalid && M_axi_wready)
	         r_M_axi_bready <= 0;    
	   else
		     r_M_axi_bready <= 1; 		  
	end
	assign M_axi_bready = r_M_axi_bready;


	reg [7:0] r_M_w_burst_count;
	always @(posedge clk) begin
        if(~reset_n || M_axi_wlast && M_axi_wvalid && M_axi_wready ) begin
            r_M_w_burst_count <= 0;
        end
        else if(M_axi_wvalid && M_axi_wready)begin
            r_M_w_burst_count <= r_M_w_burst_count + 1;
        end
    end


    reg r_M_axi_wlast;
    always @(posedge clk) begin
	    if(~reset_n)
	        r_M_axi_wlast <= 0;
	    else if((r_M_w_burst_count == M_axi_awlen -1) && M_axi_wvalid && M_axi_wready)
	        r_M_axi_wlast <= 1;
	    else
	        r_M_axi_wlast <= 0;
    end
    assign M_axi_wlast = r_M_axi_wlast;


    reg[31:0] r_counter_write;
    always @(posedge clk) begin
		if( ~reset_n || r_counter_write > 32'h10000000) begin
			r_counter_write <= 32'h01000000;
		end 
		else if((M_axi_awvalid && M_axi_awready))begin
			r_counter_write <= r_counter_write + (C_S_AXI_DATA_WIDTH * (C_S_AXI_BURST_LEN))/8;
		end
	end
	
	reg[31:0] r_counter_write_data;
        always @(posedge clk) begin
            if( ~reset_n || r_counter_write > 32'h10000000) begin
                r_counter_write_data <= 32'h01000000;
            end 
            else if((M_axi_wvalid && M_axi_wready))begin
                r_counter_write_data <= r_counter_write_data + 8;
            end
        end





//********************************************************************************
//********** DDR3 Read **********************************************************
//********************************************************************************


	(* mark_debug = "true" *) reg[3:0] axi_read_FSM;

	always@(posedge clk) begin
		if(~reset_n || state_ == 0) begin
			axi_read_FSM <= 0;
		end else begin
			case(axi_read_FSM) 
				4'b0000 : if(M_axi_arvalid && M_axi_arready) axi_read_FSM <= 4'b0001;
				4'b0001 : if(M_axi_rready & M_axi_rvalid & M_axi_rlast) axi_read_FSM <= 4'b0000;
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


    reg[31:0] r_counter_read;
    always @(posedge clk) begin 
        if(~reset_n || r_counter_read > 32'h10000000) 
            r_counter_read <= 32'h01000000;
        else if(M_axi_arvalid && M_axi_arready) 
            r_counter_read <= r_counter_read + (C_S_AXI_DATA_WIDTH * (C_S_AXI_BURST_LEN))/8;
    end


    reg r_M_axi_arvalid;
    always @(posedge clk) begin
        if(~reset_n || (M_axi_arvalid && M_axi_arready) || state_ == 0) begin
            r_M_axi_arvalid <= 0;
        end else if(axi_read_FSM == 4'b0000 & ~r_M_axi_arvalid) begin
            r_M_axi_arvalid <= 1;
        end
    end
    assign M_axi_arvalid = r_M_axi_arvalid;


endmodule

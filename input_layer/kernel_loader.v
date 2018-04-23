module kernel_loader #(

        parameter                           C_S_AXI_ID_WIDTH              =     3,
        parameter                           C_S_AXI_ADDR_WIDTH            =     32,
        parameter                           C_S_AXI_DATA_WIDTH            =     64,
        parameter                           C_S_AXI_BURST_LEN             =     8
         
    )(

	// input from parameter fetcher
	// skip unnecessary fifos
	input															Start,
	input 					[2:0] 									skip_en,

	input  wire 			[31:0]									kernel_0_start_addr,
	input  wire 			[31:0]									kernel_0_end_addr,
	input															kernel_0_wrap_en,
	input															load_kernel_0,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_0_fifo_wr_data,
	output 															kernel_0_fifo_wr_en,
	output 					[7:0] 									kernel_0_fifo_count,


	input  wire 			[31:0]									kernel_1_start_addr,
	input  wire 			[31:0]									kernel_1_end_addr,
	input															kernel_1_wrap_en,
	input															load_kernel_1,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_1_fifo_wr_data,
	output 															kernel_1_fifo_wr_en,
	output 					[7:0] 									kernel_1_fifo_count,

	input  wire 			[31:0]									kernel_2_start_addr,
	input  wire 			[31:0]									kernel_2_end_addr,
	input															kernel_2_wrap_en,
	input															load_kernel_2,
	output 					[C_S_AXI_DATA_WIDTH-1:0]  				kernel_2_fifo_wr_data,
	output 															kernel_2_fifo_wr_en,
	output 					[7:0] 									kernel_2_fifo_count,


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


//---------------------------------------------------------------------------------------------------------------------
// Implmentation
//---------------------------------------------------------------------------------------------------------------------

    // state machine will push data to output fifo according to 
    // random robin method
    // state will change according to rvalid & rready & rlast
    // fifo will be skiped according to input



    // AXI Settings
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
	assign M_axi_wdata  = 64'haaaaaaaaaaaaaaaa;
	assign M_axi_wstrb  = {(C_S_AXI_DATA_WIDTH/8){1'b1}}; 

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

    reg [1:0] r_fifo_select;

    // kernel address trackers
    reg [31:0] r_kernel_0_addr;
    reg [31:0] r_kernel_1_addr;
    reg [31:0] r_kernel_2_addr;


	// address tracker
	// tracks address within a burst
    reg [31:0] r_addr_tracker;

    // registering input fifo data and write
    // enable
    reg [63:0] r_fifo_wdata;
    reg r_fifo_0_wr_en;
    reg r_fifo_1_wr_en;
    reg r_fifo_2_wr_en;

    reg [31:0] r_read_axi_addr;
    assign read_burst_done = M_axi_rready & M_axi_rvalid & M_axi_rlast;
    always @(posedge clk) begin : proc_r_fifo_select
    	if(~reset_n | Start) begin
    		r_fifo_select <= 0;
    	end else begin
    		case(r_fifo_select)
    		 	2'b00 : begin if(skip_en[0]) r_fifo_select <= 2'b01 else if(read_burst_done) r_fifo_select <= 2'b01; end
    		 	2'b01 : begin if(skip_en[1]) r_fifo_select <= 2'b10 else if(read_burst_done) r_fifo_select <= 2'b10; end
    			2'b10 : begin if(skip_en[2]) r_fifo_select <= 2'b00 else if(read_burst_done) r_fifo_select <= 2'b00; end
    			default : r_fifo_select <= 2'b00;
    		endcase
    	end
    end


    // kernel 0 address logic
    // it will wrap if it is enabled
    assign addres_set_done = M_axi_arvalid & M_axi_arready;
    always @(posedge clk) begin : proc_r_kernel_0_addr
    	if(~reset_n) begin
    		r_kernel_0_addr <= 0;
    	end else if(Start || (kernel_0_wrap_en && (kernel_0_end_addr <= kernel_0_start_addr))) begin
    		r_kernel_0_addr <= kernel_0_start_addr;
    	end else if(r_fifo_select == 2'b00 && addres_set_done ) begin
    		r_kernel_0_addr <= r_kernel_0_addr + C_S_AXI_BURST_LEN * 4;
    	end
    end

    // kernel 1 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_1_addr
    	if(~reset_n) begin
    		r_kernel_1_addr <= 0;
    	end else if(Start || (kernel_1_wrap_en && (kernel_1_end_addr <= kernel_1_start_addr))) begin
    		r_kernel_1_addr <= kernel_1_start_addr;
    	end else if(r_fifo_select == 2'b01 && addres_set_done) begin
    		r_kernel_1_addr <= r_kernel_1_addr + C_S_AXI_BURST_LEN * 4;
    	end
    end

    // kernel 1 address logic
    // it will wrap if it is enabled
    always @(posedge clk) begin : proc_r_kernel_0_addr
    	if(~reset_n) begin
    		r_kernel_2_addr <= 0;
    	end else if(Start || (kernel_2_wrap_en && (kernel_2_end_addr <= kernel_2_start_addr))) begin
    		r_kernel_2_addr <= kernel_2_start_addr;
    	end else if(r_fifo_select == 2'b10 && addres_set_done) begin
    		r_kernel_2_addr <= r_kernel_2_addr + C_S_AXI_BURST_LEN * 4;
    	end
    end


    // assigning address 
    always @(posedge clk) begin : proc_r_read_axi_addr
    	if(~reset_n | Start) begin
    		r_read_axi_addr <= 0;
    	end else begin
    		case(r_fifo_select)
    			2'b00: r_read_axi_addr <= r_kernel_0_addr;
    			2'b01: r_read_axi_addr <= r_kernel_1_addr;
    			2'b10: r_read_axi_addr <= r_kernel_2_addr;
    			default : r_read_axi_addr <= 0;
    		endcase
    	end
    end

    always @(posedge clk) begin : proc_
    	if(~reset_n | Start) begin
    		r_addr_tracker <= 0;
    	end else if(addres_set_done) begin
    		r_addr_tracker <= M_axi_araddr;
    	end else if(M_axi_rvalid & M_axi_rready) begin
    		r_addr_tracker <= r_addr_tracker + 1;
    	end
    end


    always @(posedge clk) begin : proc_
    	if(~reset_n | Start) begin
    		r_fifo_wdata <= 0;
    	end else begin
    		r_fifo_wdata <= M_axi_wdata;
    	end
    end

    assign valid_rd_data = M_axi_rvalid & M_axi_rready;
    always @(posedge clk) begin : proc_
    	if(~reset_n | Start) begin
    		r_fifo_0_wr_en <= 0;
    	end else if(r_fifo_select == 2'b00) begin
    		r_fifo_0_wr_en <= valid_rd_data;
    	end else begin
    		r_fifo_0_wr_en <= 0;
    	end
    end

    always @(posedge clk) begin : proc_
    	if(~reset_n | Start) begin
    		r_fifo_1_wr_en <= 0;
    	end else if(r_fifo_select == 2'b01) begin
    		r_fifo_1_wr_en <= valid_rd_data;
    	end else begin
    		r_fifo_1_wr_en <= 0;
    	end
    end

    always @(posedge clk) begin : proc_
    	if(~reset_n | Start) begin
    		r_fifo_2_wr_en <= 0;
    	end else if(r_fifo_select == 2'b10) begin
    		r_fifo_2_wr_en <= valid_rd_data;
    	end else begin
    		r_fifo_2_wr_en <= 0;
    	end
    end



 	//********************************************************************************
	//********** AXI Read **********************************************************
	//********************************************************************************


	reg[3:0] axi_read_FSM;

	always@(posedge clk) begin
		if(~reset_n) begin
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



endmodule // kernel_loader
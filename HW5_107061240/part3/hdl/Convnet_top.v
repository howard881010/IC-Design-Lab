module Convnet_top #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12,
parameter WEIGHT_PER_ADDR = 9, 
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input clk,                          
input rst_n,  // synchronous reset (active low)
input enable, // start sending image from testbanch
output busy,  // control signal for stopping loading input image
output reg valid, // output valid for testbench to check answers in corresponding SRAM groups
input [BW_PER_ACT-1:0] input_data, // input image data
// read data from SRAM group A
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3,
// read data from SRAM group B
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_b3,
// read data from parameter SRAM
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight,  
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias,     
// read address to SRAM group A
output reg [5:0] sram_raddr_a0,
output reg [5:0] sram_raddr_a1,
output reg [5:0] sram_raddr_a2,
output reg [5:0] sram_raddr_a3,
// read address to SRAM group B
output [5:0] sram_raddr_b0,
output [5:0] sram_raddr_b1,
output [5:0] sram_raddr_b2,
output [5:0] sram_raddr_b3,
// read address to parameter SRAM
output reg [9:0] sram_raddr_weight,       
output reg [5:0] sram_raddr_bias,         
// write enable for SRAM groups A & B
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
output reg sram_wen_b0,
output reg sram_wen_b1,
output reg sram_wen_b2,
output reg sram_wen_b3,
// word mask for SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
// write addrress to SRAM groups A & B
output reg [5:0] sram_waddr_a,
output reg [5:0] sram_waddr_b,
// write data to SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b
);
parameter IDLE = 4'd0, UNSUFFULE = 4'd1, LOAD_WECONV1 = 4'd2, CONV1 = 4'd3, LOAD_WECONV2 = 4'd4, CONV2 = 4'd5, POOL = 4'd6; 


wire [5:0]sram_raddr_a0_convp, sram_raddr_a0_conv;
wire [5:0]sram_raddr_a1_convp, sram_raddr_a1_conv;
wire [5:0]sram_raddr_a2_convp, sram_raddr_a2_conv;
wire [5:0]sram_raddr_a3_convp, sram_raddr_a3_conv;
wire [9:0]sram_raddr_weight_convp, sram_raddr_weight_conv;
wire [5:0]sram_raddr_bias_convp, sram_raddr_bias_conv;
wire sram_wen_b0_convp, sram_wen_b0_conv;
wire sram_wen_b1_convp, sram_wen_b1_conv;
wire sram_wen_b2_convp, sram_wen_b2_conv;
wire sram_wen_b3_convp, sram_wen_b3_conv;

reg [3:0]state, n_state;
reg fakevalid;
wire [5:0] sram_waddr_a_unshuff;
wire [5:0] sram_waddr_a_conv;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata_a_unshuff;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata_a_conv;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_unshuff;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_conv;
//wire conv_all_done;
wire CONV_DONE;
wire CONV_ALLDONE;
wire LOAD_DONE;
wire sram_wen_a0_conv, sram_wen_a0_unshuff;
wire sram_wen_a1_conv, sram_wen_a1_unshuff;
wire sram_wen_a2_conv, sram_wen_a2_unshuff;
wire sram_wen_a3_conv, sram_wen_a3_unshuff;
wire [1:0]CNT_NoP;
wire [1:0]bank_arrange;
wire unshuffle_done;
wire [CH_NUM*ACT_PER_ADDR-1:0]sram_wordmask_b_convp, sram_wordmask_b_conv;
wire [5:0]sram_waddr_b_convp, sram_waddr_b_conv;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata_b_convp, sram_wdata_b_conv;
wire new_valid;

unshuffle U0(
.state(state),
.clk(clk),                          
.rst_n(rst_n),
.busy(busy),  
.valid(unshuffle_done), 
.input_data(input_data),    
// write enable for SRAM group A 
.sram_wen_a0(sram_wen_a0_unshuff), .sram_wen_a1(sram_wen_a1_unshuff), .sram_wen_a2(sram_wen_a2_unshuff), .sram_wen_a3(sram_wen_a3_unshuff),
// wordmask for SRAM group A 
.sram_wordmask_a(sram_wordmask_a_unshuff),
// write addrress to SRAM group A 
.sram_waddr_a(sram_waddr_a_unshuff),
// write data to SRAM group A 
.sram_wdata_a(sram_wdata_a_unshuff)
);


addr U1(
.conv_done(CONV_DONE),
.unshuffle_done(unshuffle_done),
.state(state),
.clk(clk),                          
.rst_n(rst_n),  // synchronous reset (active low)    
// read address to SRAM group A
.sram_raddr_a0(sram_raddr_a0_conv), .sram_raddr_a1(sram_raddr_a1_conv), .sram_raddr_a2(sram_raddr_a2_conv), .sram_raddr_a3(sram_raddr_a3_conv),
// read address to SRAM group B
.sram_raddr_b0(sram_raddr_b0), .sram_raddr_b1(sram_raddr_b1), .sram_raddr_b2(sram_raddr_b2), .sram_raddr_b3(sram_raddr_b3),
// read address to parameter SRAM
.sram_raddr_weight(sram_raddr_weight_conv),       
.sram_raddr_bias(sram_raddr_bias_conv),
.LOAD_DONE(LOAD_DONE)
);

conv U2(
.bank_arrange(bank_arrange),
.CNT_NoP(CNT_NoP),
.state(state),
.clk(clk),                          
.rst_n(rst_n), 
// read data from SRAM group A
.sram_rdata_a0(sram_rdata_a0), .sram_rdata_a1(sram_rdata_a1), .sram_rdata_a2(sram_rdata_a2), .sram_rdata_a3(sram_rdata_a3),
// read address to SRAM group B
.sram_rdata_b0(sram_rdata_b0), .sram_rdata_b1(sram_rdata_b1), .sram_rdata_b2(sram_rdata_b2), .sram_rdata_b3(sram_rdata_b3),
// read data from parameter SRAM
.sram_rdata_weight(sram_rdata_weight),  
.sram_rdata_bias(sram_rdata_bias),     
// write data to SRAM groups A & B
.sram_wdata_a(sram_wdata_a_conv), .sram_wdata_b(sram_wdata_b_conv)         
);

write U3(
.state(state),
.clk(clk),                          
.rst_n(rst_n),  // synchronous reset (active low)      
// write enable for SRAM groups A & B
.sram_wen_a0(sram_wen_a0_conv),
.sram_wen_a1(sram_wen_a1_conv),
.sram_wen_a2(sram_wen_a2_conv),
.sram_wen_a3(sram_wen_a3_conv),
.sram_wen_b0(sram_wen_b0_conv),
.sram_wen_b1(sram_wen_b1_conv),
.sram_wen_b2(sram_wen_b2_conv),
.sram_wen_b3(sram_wen_b3_conv),
// word mask for SRAM groups A & B
.sram_wordmask_a(sram_wordmask_a_conv),
.sram_wordmask_b(sram_wordmask_b_conv),
// write addrress to SRAM groups A & B
.sram_waddr_a(sram_waddr_a_conv),
.sram_waddr_b(sram_waddr_b_conv),
.conv_done(CONV_DONE),
.conv_all_done(CONV_ALLDONE),
.CNT_WORDMASK(CNT_NoP),
.bank_arrange(bank_arrange)
);

conv_pool U4(
.clk(clk),                          
.rst_n(rst_n),  // synchronous reset (active low)
.enable(fakevalid), 
.valid(new_valid), // output valid for testbench to check answers in corresponding SRAM groups
// read data from SRAM group A
.sram_rdata_a0(sram_rdata_a0),
.sram_rdata_a1(sram_rdata_a1),
.sram_rdata_a2(sram_rdata_a2),
.sram_rdata_a3(sram_rdata_a3),
// read data from parameter SRAM
.sram_rdata_weight(sram_rdata_weight),  
.sram_rdata_bias(sram_rdata_bias),     
// read address to SRAM group A
.sram_raddr_a0(sram_raddr_a0_convp),
.sram_raddr_a1(sram_raddr_a1_convp),
.sram_raddr_a2(sram_raddr_a2_convp),
.sram_raddr_a3(sram_raddr_a3_convp),
// read address to parameter SRAM
.sram_raddr_weight(sram_raddr_weight_convp),       
.sram_raddr_bias(sram_raddr_bias_convp),         
// write enable for SRAM groups B
.sram_wen_b0(sram_wen_b0_convp),
.sram_wen_b1(sram_wen_b1_convp),
.sram_wen_b2(sram_wen_b2_convp),
.sram_wen_b3(sram_wen_b3_convp),
// word mask for SRAM groups B
.sram_wordmask_b(sram_wordmask_b_convp),
// write addrress to SRAM groups B
.sram_waddr_b(sram_waddr_b_convp),
// write data to SRAM groups B
.sram_wdata_b(sram_wdata_b_convp)
);

always @(posedge clk) begin
	if(~rst_n) begin
		state <= 0;
		valid <= 0;
	end
	else begin
		state <= n_state;
		valid <= new_valid;
	end
end

/////////FSM////////
always @* begin
	fakevalid = 0;
	case(state)
		IDLE: begin
			n_state = enable ? UNSUFFULE : IDLE;
		end
		UNSUFFULE: begin
			n_state = unshuffle_done ? LOAD_WECONV1 : UNSUFFULE;
		end
		LOAD_WECONV1: begin
			n_state = LOAD_DONE ? CONV1 : LOAD_WECONV1;
		end		
        CONV1: begin
			if(CONV_ALLDONE) begin
            	n_state = LOAD_WECONV2;
				
			end
			else if(CONV_DONE)
				n_state = LOAD_WECONV1;
			else
				n_state = CONV1;
        end
		LOAD_WECONV2: begin
			n_state = LOAD_DONE ? CONV2 : LOAD_WECONV2;
		end		
        CONV2: begin
			if(CONV_ALLDONE) begin
            	n_state = POOL;
				fakevalid = 1;
			end
			else if(CONV_DONE) begin
				n_state = LOAD_WECONV2;
				
			end
			else
				n_state = CONV2;
        end
		POOL: begin
			n_state = POOL;

		end

		default: begin
			n_state = IDLE;
		end	
	endcase
end

/////////Choose output/////////
always@* begin

	case(state)
		UNSUFFULE: begin
			sram_wen_a0 = sram_wen_a0_unshuff;
			sram_wen_a1 = sram_wen_a1_unshuff;
			sram_wen_a2 = sram_wen_a2_unshuff;
			sram_wen_a3 = sram_wen_a3_unshuff;
			sram_wordmask_a = sram_wordmask_a_unshuff;
			sram_waddr_a = sram_waddr_a_unshuff;
			sram_wdata_a = sram_wdata_a_unshuff;
		end

		default: begin
			sram_wen_a0 = sram_wen_a0_conv;
			sram_wen_a1 = sram_wen_a1_conv;
			sram_wen_a2 = sram_wen_a2_conv;
			sram_wen_a3 = sram_wen_a3_conv;
			sram_wordmask_a = sram_wordmask_a_conv;
			sram_waddr_a = sram_waddr_a_conv;
			sram_wdata_a = sram_wdata_a_conv;
		end
	endcase
end

always@*begin
	
	if(state == POOL) begin
		sram_raddr_a0 = sram_raddr_a0_convp;
		sram_raddr_a1 = sram_raddr_a1_convp;
		sram_raddr_a2 = sram_raddr_a2_convp;
		sram_raddr_a3 = sram_raddr_a3_convp;
		sram_raddr_weight = sram_raddr_weight_convp;
		sram_raddr_bias = sram_raddr_bias_convp;
		sram_wen_b0 = sram_wen_b0_convp;
		sram_wen_b1 = sram_wen_b1_convp;
		sram_wen_b2 = sram_wen_b2_convp;
		sram_wen_b3 = sram_wen_b3_convp;
		sram_wordmask_b = sram_wordmask_b_convp;
		sram_waddr_b = sram_waddr_b_convp;
		sram_wdata_b = sram_wdata_b_convp;
	end
	else begin
		sram_raddr_a0 = sram_raddr_a0_conv;
		sram_raddr_a1 = sram_raddr_a1_conv;
		sram_raddr_a2 = sram_raddr_a2_conv;
		sram_raddr_a3 = sram_raddr_a3_conv;
		sram_raddr_weight = sram_raddr_weight_conv;
		sram_raddr_bias = sram_raddr_bias_conv;
		sram_wen_b0 = sram_wen_b0_conv;
		sram_wen_b1 = sram_wen_b1_conv;
		sram_wen_b2 = sram_wen_b2_conv;
		sram_wen_b3 = sram_wen_b3_conv;
		sram_wordmask_b = sram_wordmask_b_conv;
		sram_waddr_b = sram_waddr_b_conv;
		sram_wdata_b = sram_wdata_b_conv;
	end
end



endmodule
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
output valid, // output valid for testbench to check answers in corresponding SRAM groups
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
output [5:0] sram_raddr_a0,
output [5:0] sram_raddr_a1,
output [5:0] sram_raddr_a2,
output [5:0] sram_raddr_a3,
// read address to SRAM group B
output [5:0] sram_raddr_b0,
output [5:0] sram_raddr_b1,
output [5:0] sram_raddr_b2,
output [5:0] sram_raddr_b3,
// read address to parameter SRAM
output [9:0] sram_raddr_weight,       
output [5:0] sram_raddr_bias,         
// write enable for SRAM groups A & B
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
output sram_wen_b0,
output sram_wen_b1,
output sram_wen_b2,
output sram_wen_b3,
// word mask for SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
output [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
// write addrress to SRAM groups A & B
output reg [5:0] sram_waddr_a,
output [5:0] sram_waddr_b,
// write data to SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b
);
parameter IDLE = 4'd0, UNSHUFFLE = 4'd1, LOAD_W1 = 4'd2, CONV1 = 4'd3, CONV2 = 4'd4; 	

reg [3:0]state, n_state;
wire [5:0] sram_waddr_a_un;
wire [5:0] sram_waddr_a_conv;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata_a_un;
wire [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0]sram_wdata_a_conv;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_un;
wire [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a_conv;
wire CONV_DONE;
wire LOAD_DONE;
wire sram_wen_a0_conv;
wire sram_wen_a1_conv;
wire sram_wen_a2_conv;
wire sram_wen_a3_conv;
wire sram_wen_a0_un;
wire sram_wen_a1_un;
wire sram_wen_a2_un;
wire sram_wen_a3_un;
wire [5:0]CNT_No;
wire [1:0]bank_arrange;
wire unshuffle_done;


unshuffle U0(
.state(state),
.clk(clk),                          
.rst_n(rst_n),
.busy(busy),  
.valid(unshuffle_done), 
.input_data(input_data),    
// write enable for SRAM group A 
.sram_wen_a0(sram_wen_a0_un), .sram_wen_a1(sram_wen_a1_un), .sram_wen_a2(sram_wen_a2_un), .sram_wen_a3(sram_wen_a3_un),
// wordmask for SRAM group A 
.sram_wordmask_a(sram_wordmask_a_un),
// write addrress to SRAM group A 
.sram_waddr_a(sram_waddr_a_un),
// write data to SRAM group A 
.sram_wdata_a(sram_wdata_a_un)
);

addr U1(
.conv_done(CONV_DONE), .unshuffle_done(unshuffle_done), .state(state), .clk(clk), .rst_n(rst_n),  // synchronous reset (active low)    
.sram_raddr_a0(sram_raddr_a0), .sram_raddr_a1(sram_raddr_a1), .sram_raddr_a2(sram_raddr_a2), .sram_raddr_a3(sram_raddr_a3),
.sram_raddr_b0(sram_raddr_b0), .sram_raddr_b1(sram_raddr_b1), .sram_raddr_b2(sram_raddr_b2), .sram_raddr_b3(sram_raddr_b3),
.sram_raddr_weight(sram_raddr_weight), .sram_raddr_bias(sram_raddr_bias), .LOAD_DONE(LOAD_DONE)
);


conv U2(
.bank_arrange(bank_arrange),
.CNT_No(CNT_No),
.state(state),
.clk(clk), .rst_n(rst_n), 
.sram_rdata_a0(sram_rdata_a0), .sram_rdata_a1(sram_rdata_a1), .sram_rdata_a2(sram_rdata_a2), .sram_rdata_a3(sram_rdata_a3),
.sram_rdata_b0(sram_rdata_b0), .sram_rdata_b1(sram_rdata_b1), .sram_rdata_b2(sram_rdata_b2), .sram_rdata_b3(sram_rdata_b3),
.sram_rdata_weight(sram_rdata_weight), .sram_rdata_bias(sram_rdata_bias),     
.sram_wdata_a(sram_wdata_a_conv), .sram_wdata_b(sram_wdata_b)         
);

write U3(
.state(state),
.clk(clk),                          
.rst_n(rst_n),
.sram_wen_a0(sram_wen_a0_conv), .sram_wen_a1(sram_wen_a1_conv), .sram_wen_a2(sram_wen_a2_conv), .sram_wen_a3(sram_wen_a3_conv),
.sram_wen_b0(sram_wen_b0), .sram_wen_b1(sram_wen_b1), .sram_wen_b2(sram_wen_b2), .sram_wen_b3(sram_wen_b3),
.sram_wordmask_a(sram_wordmask_a_conv), .sram_wordmask_b(sram_wordmask_b),
.sram_waddr_a(sram_waddr_a_conv), .sram_waddr_b(sram_waddr_b),
.conv_done(CONV_DONE),
.conv_all_done1(valid),
.CNT_No(CNT_No),
.bank_arrange(bank_arrange)
);

/////////DFF/////////
always @(posedge clk) begin
	if(~rst_n) begin
		state <= 0;
	end
	else begin
		state <= n_state;
	end
end

/////////FSM/////////
always @* begin
	case(state)
		IDLE: begin
			n_state = enable ? UNSHUFFLE : IDLE;
		end
		UNSHUFFLE: begin
			n_state = unshuffle_done ? LOAD_W1 : UNSHUFFLE;
		end
		LOAD_W1: begin
			n_state = LOAD_DONE ? CONV1 : LOAD_W1;
		end		
        CONV1: begin
			if(valid)
            	n_state = IDLE;
			else if(CONV_DONE)
				n_state = LOAD_W1;
			else
				n_state = CONV1;
        end
		default: begin
			n_state = IDLE;
		end	
	endcase
end

/////////Choose output/////////
always@* begin
	case(state)
		UNSHUFFLE: begin
			sram_wen_a0 = sram_wen_a0_un;
			sram_wen_a1 = sram_wen_a1_un;
			sram_wen_a2 = sram_wen_a2_un;
			sram_wen_a3 = sram_wen_a3_un;
			sram_wordmask_a = sram_wordmask_a_un;
			sram_waddr_a = sram_waddr_a_un;
			sram_wdata_a = sram_wdata_a_un;
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






endmodule
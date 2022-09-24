module write#(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12,
parameter WEIGHT_PER_ADDR = 9, 
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input [3:0]state,
input clk,                          
input rst_n,  // synchronous reset (active low)      
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
output reg conv_done,
output reg conv_all_done,
output [1:0] CNT_WORDMASK,
output reg [1:0] bank_arrange
);
parameter IDLE = 4'd0, UNSUFFULE = 4'd1, LOAD_WECONV1 = 4'd2, CONV1 = 4'd3, LOAD_WECONV2 = 4'd4, CONV2 = 4'd5, LOAD_WECONV3 = 4'd6, CONV3 = 4'd7; 
reg start_CNT, n_start_CNT;
reg [3:0] CNT_DELAY, n_CNT_DELAY;
reg [2:0] CNT_ADDR, n_CNT_ADDR;
reg [5:0] CNT_No, n_CNT_No;
reg [2:0] CNT_ADDR_R, n_CNT_ADDR_R;
reg [2:0] CNT_HALF, n_CNT_HALF;
reg n_conv_all_done;
reg n_conv_done;


always @(posedge clk) begin
	if(~rst_n) begin
		CNT_ADDR <= 0;
		CNT_No <= 0;
		CNT_ADDR_R <= 0;
		CNT_HALF <= 0;
		conv_all_done <= 0;
		CNT_DELAY <= 0;
		start_CNT <= 0;
		conv_done <= 0;
	end
	else begin
		CNT_ADDR <= n_CNT_ADDR;
		CNT_No <= n_CNT_No;
		CNT_ADDR_R <= n_CNT_ADDR_R;
		CNT_HALF <= n_CNT_HALF;
		conv_all_done <= n_conv_all_done;
		CNT_DELAY <= n_CNT_DELAY;
		start_CNT <= n_start_CNT;
		conv_done <= n_conv_done;
	end
end

always @* begin
	if(state == LOAD_WECONV1 || state == LOAD_WECONV2)
		n_start_CNT = 0;
	else if(state == CONV1 || state == CONV2) begin
		if(CNT_DELAY ==4)
			n_start_CNT = 1;
		else
			n_start_CNT = start_CNT;
	end
	else
		n_start_CNT = 0;
end


always @* begin

	n_CNT_DELAY = 0;
	n_CNT_ADDR = 0;
	n_CNT_ADDR_R = 0;
	n_CNT_HALF = 0;
	if(state == CONV1) begin
		if(start_CNT == 1) begin
			n_CNT_DELAY = CNT_DELAY ;
			n_CNT_ADDR = CNT_ADDR + 1;
			n_CNT_ADDR_R = CNT_ADDR_R;
			if(CNT_ADDR == 1 || CNT_ADDR == 3)
				n_CNT_HALF = CNT_HALF + 1;
			else if(CNT_ADDR==5 && CNT_ADDR_R==5) begin
				n_CNT_ADDR = 0;
				n_CNT_ADDR_R = 0;
			end
			else if(CNT_ADDR==5) begin
				n_CNT_ADDR = 0;
				n_CNT_ADDR_R = CNT_ADDR_R + 1;
				n_CNT_HALF = 0;
			end
			else 
				n_CNT_HALF = CNT_HALF;
		end
		else begin
			n_CNT_DELAY = CNT_DELAY + 1;
		end
	end
	else if(state == CONV2) begin
		if(start_CNT == 1) begin
			n_CNT_DELAY = CNT_DELAY ;
			n_CNT_ADDR = CNT_ADDR + 1;
			n_CNT_ADDR_R = CNT_ADDR_R;
			if(CNT_ADDR == 1 || CNT_ADDR == 3)
				n_CNT_HALF = CNT_HALF + 1;
			else if(CNT_ADDR == 4 && CNT_ADDR_R == 4) begin
				n_CNT_ADDR = 0;
				n_CNT_ADDR_R = 0;
			end
			else if(CNT_ADDR==4) begin
				n_CNT_ADDR = 0;
				n_CNT_ADDR_R = CNT_ADDR_R + 1;
				n_CNT_HALF = 0;
			end
			else 
				n_CNT_HALF = CNT_HALF;
		end
		else begin
			n_CNT_DELAY = CNT_DELAY + 1;
		end
	end
end


always @* begin
	n_conv_done = 0;
	n_conv_all_done = 0;
	if(state == CONV1) begin
		if(CNT_ADDR == 5 && CNT_ADDR_R == 5 && CNT_No == 3) begin
			n_conv_all_done = 1;
			n_conv_done = 1;
		end
		else if(CNT_ADDR == 5 && CNT_ADDR_R == 5)
			n_conv_done = 1;
	end
	else if(state == CONV2) begin
		if(CNT_ADDR == 4 && CNT_ADDR_R == 4 && CNT_No == 11) begin
			n_conv_all_done = 1;
			n_conv_done = 1;
		end
		else if(CNT_ADDR == 4 && CNT_ADDR_R == 4)
			n_conv_done = 1;
	end
end

always @* begin
	if(n_conv_all_done == 1)
		n_CNT_No = 0;
	else if(n_conv_done == 1)
		n_CNT_No = CNT_No + 1;
	else
		n_CNT_No = CNT_No;
end



always @* begin
	sram_wen_a0 = 1;
	sram_wen_a1 = 1;
	sram_wen_a2 = 1;
	sram_wen_a3 = 1;
	sram_wen_b0 = 1;
	sram_wen_b1 = 1;
	sram_wen_b2 = 1;
	sram_wen_b3 = 1;
	if(conv_all_done) begin
	end
	else if(state == CONV1) begin
		if(CNT_ADDR_R % 2 == 0) begin
			if(CNT_ADDR % 2 == 0) begin
				sram_wen_b0 = 0;
				sram_wen_b1 = 1;
				sram_wen_b2 = 1;
				sram_wen_b3 = 1;
			end
			else begin
				sram_wen_b0 = 1;
				sram_wen_b1 = 0;
				sram_wen_b2 = 1;
				sram_wen_b3 = 1;
			end
		end
		else begin
			if(CNT_ADDR % 2 == 0) begin
				sram_wen_b0 = 1;
				sram_wen_b1 = 1;
				sram_wen_b2 = 0;
				sram_wen_b3 = 1;
			end
			else begin
				sram_wen_b0 = 1;
				sram_wen_b1 = 1;
				sram_wen_b2 = 1;
				sram_wen_b3 = 0;
			end
		end
	end
	else if(state == CONV2) begin
		if(CNT_ADDR_R % 2 == 0) begin
			if(CNT_ADDR % 2 == 0) begin
				sram_wen_a0 = 0;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
			else begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 0;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
		end
		else begin
			if(CNT_ADDR % 2 == 0) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 0;
				sram_wen_a3 = 1;
			end
			else begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 0;
			end
		end
	end
end

assign CNT_WORDMASK = CNT_No % 4;
always @* begin
	sram_wordmask_b = 16'b1111_1111_1111_1111;
	sram_wordmask_a = 16'b1111_1111_1111_1111;


	if(state == CONV1)begin
		case(CNT_WORDMASK) //synopsys parallel_case
			0:sram_wordmask_b = 16'b0000_1111_1111_1111;
			1:sram_wordmask_b = 16'b1111_0000_1111_1111;
			2:sram_wordmask_b = 16'b1111_1111_0000_1111;
			3:sram_wordmask_b = 16'b1111_1111_1111_0000;
		endcase		
	end
	else if(state == CONV2)begin
		case(CNT_WORDMASK) //synopsys parallel_case
			0:sram_wordmask_a = 16'b0000_1111_1111_1111;
			1:sram_wordmask_a = 16'b1111_0000_1111_1111;
			2:sram_wordmask_a = 16'b1111_1111_0000_1111;
			3:sram_wordmask_a = 16'b1111_1111_1111_0000;
		endcase		
	end
end

always @* begin
sram_waddr_a = 0;
sram_waddr_b = 0;
	if(state == CONV1) begin
		case(CNT_ADDR_R)
			0,1:sram_waddr_b = 0 + CNT_HALF;
			2,3:sram_waddr_b = 6 + CNT_HALF;
			4,5:sram_waddr_b = 12 + CNT_HALF;
			default:sram_waddr_b = 0 + CNT_HALF;
		endcase
	end
	if(state == CONV2) begin
		case(CNT_No)
			0,1,2,3: begin
				case(CNT_ADDR_R)
					0,1:sram_waddr_a = 0 + CNT_HALF;
					2,3:sram_waddr_a = 6 + CNT_HALF;
					4:sram_waddr_a = 12 + CNT_HALF;
					default:sram_waddr_a = 0 + CNT_HALF;
				endcase
			end
			4,5,6,7: begin
				case(CNT_ADDR_R)
					0,1:sram_waddr_a = 3 + CNT_HALF;
					2,3:sram_waddr_a = 9 + CNT_HALF;
					4:sram_waddr_a = 15 + CNT_HALF;
					default:sram_waddr_a = 3 + CNT_HALF;
				endcase
			end
			8,9,10,11: begin
				case(CNT_ADDR_R)
					0,1:sram_waddr_a = 18 + CNT_HALF;
					2,3:sram_waddr_a = 24 + CNT_HALF;
					4:sram_waddr_a = 30 + CNT_HALF;
					default:sram_waddr_a = 18 + CNT_HALF;
				endcase
			end
		endcase
	end
end

/////////bank arrange/////////
reg [5:0] CNT_ADDR_BA, n_CNT_ADDR_BA;
reg [2:0] CNT_ADDR_R_BA, n_CNT_ADDR_R_BA;

always @(posedge clk) begin
	if(~rst_n) begin
		CNT_ADDR_BA <= 0;
		CNT_ADDR_R_BA <= 0;
	end
	else begin
		CNT_ADDR_BA <= n_CNT_ADDR_BA;
		CNT_ADDR_R_BA <= n_CNT_ADDR_R_BA;
	end
end


always @* begin
	bank_arrange = 0;
	if(state == CONV1 || state == CONV2) begin
		if(CNT_ADDR_R_BA % 2 == 0) begin
			if(CNT_ADDR_BA % 2 == 0) begin
				bank_arrange = 0;
			end
			else begin
				bank_arrange = 1;
			end
		end
		else begin
			if(CNT_ADDR_BA % 2 == 0) begin
				bank_arrange = 2;
			end
			else begin
				bank_arrange = 3;
			end
		end
	end
end

always @* begin
	n_CNT_ADDR_BA = 0;
	n_CNT_ADDR_R_BA = 0;

	if(state == CONV1) begin
		n_CNT_ADDR_BA = CNT_ADDR_BA + 1;
		n_CNT_ADDR_R_BA = CNT_ADDR_R_BA;
		if(CNT_ADDR_BA==5 && CNT_ADDR_R_BA==5) begin
			n_CNT_ADDR_BA = 0;
			n_CNT_ADDR_R_BA = 0;
		end
		else if(CNT_ADDR_BA==5) begin
			n_CNT_ADDR_BA = 0;
			n_CNT_ADDR_R_BA = CNT_ADDR_R_BA + 1;
		end
	end
	else if(state == CONV2) begin
		n_CNT_ADDR_BA = CNT_ADDR_BA + 1;
		n_CNT_ADDR_R_BA = CNT_ADDR_R_BA;
		if(CNT_ADDR_BA==4 && CNT_ADDR_R_BA==4) begin
			n_CNT_ADDR_BA = 0;
			n_CNT_ADDR_R_BA = 0;
		end
		else if(CNT_ADDR_BA==4) begin
			n_CNT_ADDR_BA = 0;
			n_CNT_ADDR_R_BA = CNT_ADDR_R_BA + 1;
		end
	end
end

endmodule
module unshuffle #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12
)
(
input [3:0]state,
input clk,                          
input rst_n,  // synchronous reset (active low)
output reg busy,  // control signal for stopping loading input image
output reg valid, // output valid for testbench to check answers in corresponding SRAM groups
input [BW_PER_ACT-1:0] input_data, // input image data
output reg sram_wen_a0,
output reg sram_wen_a1,
output reg sram_wen_a2,
output reg sram_wen_a3,
// wordmask for SRAM group A 
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_a,
// write addrress to SRAM group A 
output reg [5:0] sram_waddr_a,
// write data to SRAM group A 
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a
);

parameter UNSUFFULE = 2'd1; 
reg n_valid;
reg [9:0]CNT, n_cnt;
reg [1:0]CNT_PIXEL, n_cnt_pixel;
reg [2:0]CNT_IDX, n_CNT_IDX;  // 0:CNT=0~111, 1:next CNT=0~111
reg [4:0]cnt_wen, n_cnt_wen;
reg [5:0]addr_offset;

always @(posedge clk) begin
	if(~rst_n) begin
		CNT   <= 0;
		CNT_PIXEL <= 0;
		CNT_IDX <= 0;
		cnt_wen <= 0;
		valid <= 0;
	end
	else begin
		CNT   <= n_cnt;
		CNT_PIXEL <= n_cnt_pixel;
		CNT_IDX <= n_CNT_IDX;
		cnt_wen <= n_cnt_wen;
		valid <= n_valid;
	end
end


always @* begin
	if(state == UNSUFFULE) begin
		n_cnt = CNT + 1;
		n_cnt_pixel = CNT_PIXEL + 1;
		n_cnt_wen = cnt_wen + 1;
		if(CNT == 111)
			n_cnt = 0;
		if(CNT_PIXEL == 3)
			n_cnt_pixel = 0;
		if(CNT==27 || CNT==55 || CNT==83 || CNT==111)
			n_cnt_wen = 0;
	end
	else begin
		n_cnt = 0; 
		n_cnt_pixel = 0;
		n_cnt_wen = 0;
	end
end

always @* begin
	if(state == UNSUFFULE) begin
		if(CNT == 111)
			n_CNT_IDX = CNT_IDX + 1;
		else
			n_CNT_IDX = CNT_IDX;
	end
	else begin
		n_CNT_IDX = 0;
	end
end

always @* begin
	busy = 1;
	n_valid = 0;
	if(state == UNSUFFULE) begin
		busy = 0;
		n_valid = 0;
		if(CNT==111 && CNT_IDX==6)
			n_valid = 1;	
	end
end

/////////addr_control/////////choose addr0~addr21
always @* begin
	if(CNT_IDX==0 || CNT_IDX==1) begin
		addr_offset = 0;
		if((CNT>=0 && CNT<8)||(CNT>=28 && CNT<36)||(CNT>=56 && CNT<64)||(CNT>=84 && CNT<92))
			sram_waddr_a = addr_offset;
		else if((CNT>=8 && CNT<16)||(CNT>=36 && CNT<44)||(CNT>=64 && CNT<72)||(CNT>=92 && CNT<100))
			sram_waddr_a = addr_offset + 1;
		else if((CNT>=16 && CNT<24)||(CNT>=44 && CNT<52)||(CNT>=72 && CNT<80)||(CNT>=100 && CNT<108))
			sram_waddr_a = addr_offset + 2;
		else if((CNT>=24 && CNT<28)||(CNT>=52 && CNT<56)||(CNT>=80 && CNT<84)||(CNT>=108 && CNT<112))
			sram_waddr_a = addr_offset + 3;
		else
			sram_waddr_a = 0;
	end
	else if(CNT_IDX==2 || CNT_IDX==3) begin
		addr_offset = 6;
		if((CNT>=0 && CNT<8)||(CNT>=28 && CNT<36)||(CNT>=56 && CNT<64)||(CNT>=84 && CNT<92))
			sram_waddr_a = addr_offset;
		else if((CNT>=8 && CNT<16)||(CNT>=36 && CNT<44)||(CNT>=64 && CNT<72)||(CNT>=92 && CNT<100))
			sram_waddr_a = addr_offset + 1;
		else if((CNT>=16 && CNT<24)||(CNT>=44 && CNT<52)||(CNT>=72 && CNT<80)||(CNT>=100 && CNT<108))
			sram_waddr_a = addr_offset + 2;
		else if((CNT>=24 && CNT<28)||(CNT>=52 && CNT<56)||(CNT>=80 && CNT<84)||(CNT>=108 && CNT<112))
			sram_waddr_a = addr_offset + 3;
		else
			sram_waddr_a = 0;
	end
	else if(CNT_IDX==4 || CNT_IDX==5) begin
		addr_offset = 12;
		if((CNT>=0 && CNT<8)||(CNT>=28 && CNT<36)||(CNT>=56 && CNT<64)||(CNT>=84 && CNT<92))
			sram_waddr_a = addr_offset;
		else if((CNT>=8 && CNT<16)||(CNT>=36 && CNT<44)||(CNT>=64 && CNT<72)||(CNT>=92 && CNT<100))
			sram_waddr_a = addr_offset + 1;
		else if((CNT>=16 && CNT<24)||(CNT>=44 && CNT<52)||(CNT>=72 && CNT<80)||(CNT>=100 && CNT<108))
			sram_waddr_a = addr_offset + 2;
		else if((CNT>=24 && CNT<28)||(CNT>=52 && CNT<56)||(CNT>=80 && CNT<84)||(CNT>=108 && CNT<112))
			sram_waddr_a = addr_offset + 3;
		else
			sram_waddr_a = 0;
	end
	else if(CNT_IDX==6) begin
		addr_offset = 18;
		if((CNT>=0 && CNT<8)||(CNT>=28 && CNT<36)||(CNT>=56 && CNT<64)||(CNT>=84 && CNT<92))
			sram_waddr_a = addr_offset;
		else if((CNT>=8 && CNT<16)||(CNT>=36 && CNT<44)||(CNT>=64 && CNT<72)||(CNT>=92 && CNT<100))
			sram_waddr_a = addr_offset + 1;
		else if((CNT>=16 && CNT<24)||(CNT>=44 && CNT<52)||(CNT>=72 && CNT<80)||(CNT>=100 && CNT<108))
			sram_waddr_a = addr_offset + 2;
		else if((CNT>=24 && CNT<28)||(CNT>=52 && CNT<56)||(CNT>=80 && CNT<84)||(CNT>=108 && CNT<112))
			sram_waddr_a = addr_offset + 3;
		else
			sram_waddr_a = 0;
	end
	else begin
		addr_offset = 0;
		sram_waddr_a = 0;
	end
end

/////////wen_control/////////choose bank
always @* begin
	if(state == UNSUFFULE) begin
		if(CNT_IDX==0 || CNT_IDX==2 || CNT_IDX==4 || CNT_IDX ==6) begin
			if((cnt_wen>=0 && cnt_wen<4)||(cnt_wen>=8 && cnt_wen<12)||(cnt_wen>=16 && cnt_wen<20)||(cnt_wen>=24 && cnt_wen<28)) begin
				sram_wen_a0 = 0;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
			else if((cnt_wen>=4 && cnt_wen<8)||(cnt_wen>=12 && cnt_wen<16)||(cnt_wen>=20 && cnt_wen<24)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 0;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
			else begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
		end	
		else if(CNT_IDX==1 || CNT_IDX==3 || CNT_IDX==5) begin
			if((cnt_wen>=0 && cnt_wen<4)||(cnt_wen>=8 && cnt_wen<12)||(cnt_wen>=16 && cnt_wen<20)||(cnt_wen>=24 && cnt_wen<28)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 0;
				sram_wen_a3 = 1;
			end
			else if((cnt_wen>=4 && cnt_wen<8)||(cnt_wen>=12 && cnt_wen<16)||(cnt_wen>=20 && cnt_wen<24)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 0;
			end
			else begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
		end
		else begin
			sram_wen_a0 = 1;
			sram_wen_a1 = 1;
			sram_wen_a2 = 1;
			sram_wen_a3 = 1;
		end
	end
	else begin
		sram_wen_a0 = 1;
		sram_wen_a1 = 1;
		sram_wen_a2 = 1;
		sram_wen_a3 = 1;
	end
end

/////////pixel_control/////////choose ch0~ch3
always @* begin
	sram_wdata_a = 0;
	if(CNT >= 0 && CNT < 28) begin
		case(CNT_PIXEL)
			0: begin
				sram_wdata_a[191:180] = input_data;
				sram_wordmask_a = 16'b0111_1111_1111_1111;
			end
			1: begin
				sram_wdata_a[143:132] = input_data;
				sram_wordmask_a = 16'b1111_0111_1111_1111;
			end
			2: begin
				sram_wdata_a[179:168] = input_data;
				sram_wordmask_a = 16'b1011_1111_1111_1111;
			end
			3: begin
				sram_wdata_a[131:120] = input_data;
				sram_wordmask_a = 16'b1111_1011_1111_1111;
			end
			default: begin
				sram_wdata_a = 0;
				sram_wordmask_a = 16'b1111_1111_1111_1111;		
			end
		endcase
	end
	else if(CNT >= 28 && CNT < 56) begin
		case(CNT_PIXEL)
			0: begin
				sram_wdata_a[95:84] = input_data;
				sram_wordmask_a = 16'b1111_1111_0111_1111;
			end
			1: begin
				sram_wdata_a[47:36] = input_data;
				sram_wordmask_a = 16'b1111_1111_1111_0111;
			end
			2: begin
				sram_wdata_a[83:72] = input_data;
				sram_wordmask_a = 16'b1111_1111_1011_1111;
			end
			3: begin
				sram_wdata_a[35:24] = input_data;
				sram_wordmask_a = 16'b1111_1111_1111_1011;
			end
			default: begin
				sram_wdata_a = 0;
				sram_wordmask_a = 16'b1111_1111_1111_1111;		
			end
		endcase
	end
	else if(CNT >= 56 && CNT < 84) begin
		case(CNT_PIXEL)
			0: begin
				sram_wdata_a[167:156] = input_data;
				sram_wordmask_a = 16'b1101_1111_1111_1111;
			end
			1: begin
				sram_wdata_a[119:108] = input_data;
				sram_wordmask_a = 16'b1111_1101_1111_1111;
			end
			2: begin
				sram_wdata_a[155:144] = input_data;
				sram_wordmask_a = 16'b1110_1111_1111_1111;
			end
			3: begin
				sram_wdata_a[107:96] = input_data;
				sram_wordmask_a = 16'b1111_1110_1111_1111;
			end
			default: begin
				sram_wdata_a = 0;
				sram_wordmask_a = 16'b1111_1111_1111_1111;		
			end
		endcase
	end
	else if(CNT >= 84 && CNT < 112) begin
		case(CNT_PIXEL)
			0: begin
				sram_wdata_a[71:60] = input_data;
				sram_wordmask_a = 16'b1111_1111_1101_1111;
			end
			1: begin
				sram_wdata_a[23:12] = input_data;
				sram_wordmask_a = 16'b1111_1111_1111_1101;
			end
			2: begin
				sram_wdata_a[59:48] = input_data;
				sram_wordmask_a = 16'b1111_1111_1110_1111;
			end
			3: begin
				sram_wdata_a[11:0] = input_data;
				sram_wordmask_a = 16'b1111_1111_1111_1110;
			end
			default: begin
				sram_wdata_a = 0;
				sram_wordmask_a = 16'b1111_1111_1111_1111;		
			end
		endcase
	end
	else begin
		sram_wdata_a = 0;
		sram_wordmask_a = 16'b1111_1111_1111_1111;	
	end
end

endmodule
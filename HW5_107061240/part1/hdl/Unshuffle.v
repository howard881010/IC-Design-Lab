module Unshuffle#(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12
)
(
    input clk,                          
    input rst_n,  // synchronous reset (active low)
    input [3:0] state,
    input [BW_PER_ACT-1:0] input_data, // input image data
    output reg valid,
    output reg busy,
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

reg [9:0]cnt, new_cnt;
reg [1:0]cnt_ch, new_cnt_ch;
reg [2:0]cnt_idx, new_cnt_idx;  // 0:cnt=0~111, 1:next cnt=0~111
reg [4:0]cnt_wen, new_cnt_wen;
reg [5:0]addr_init;
reg new_valid;

always @(posedge clk) begin
	if(~rst_n) begin
		//state <=0;
		cnt <= 0;
		cnt_ch <= 0;
		cnt_idx <= 0;
		cnt_wen <= 0;
        valid <= 0;
	end
	else begin
		//state <= new_state;
		cnt <= new_cnt;
		cnt_ch <= new_cnt_ch;
		cnt_idx <= new_cnt_idx;
		cnt_wen <= new_cnt_wen;
        valid <= new_valid;
	end
end

always @* begin

    new_cnt = 0; 
	new_cnt_ch = 0;
	new_cnt_wen = 0;
    new_cnt_idx = 0;
	if(state == 1) begin
		new_cnt = cnt + 1;
		new_cnt_ch = cnt_ch + 1;
		new_cnt_wen = cnt_wen + 1;
        new_cnt_idx = cnt_idx;
		if(cnt == 111) begin 
			new_cnt = 0;
            new_cnt_idx = cnt_idx + 1;
        end
		if(cnt_ch == 3)
			new_cnt_ch = 0;
		if((cnt + 1) % 28 == 0)
			new_cnt_wen = 0;
	end
end

always @* begin
    busy = 1;
    new_valid = 0;
	if(state == 1) begin
		busy = 0;
		if(cnt==111 && cnt_idx == 6)
			new_valid = 1;	
	end
end

//====control for addr====//
always @* begin
    addr_init = 0;
	sram_waddr_a = 0;

	if(cnt_idx == 0 || cnt_idx == 1) begin
		addr_init = 0;
		if((cnt >= 0 && cnt < 8)||(cnt >= 28 && cnt < 36)||(cnt >= 56 && cnt < 64)||(cnt >= 84 && cnt < 92))
			sram_waddr_a = addr_init;
		else if((cnt >= 8 && cnt < 16)||(cnt >= 36 && cnt < 44)||(cnt >= 64 && cnt < 72)||(cnt >= 92 && cnt < 100))
			sram_waddr_a = addr_init + 1;
		else if((cnt >= 16 && cnt < 24)||(cnt >= 44 && cnt < 52)||(cnt >= 72 && cnt < 80)||(cnt >= 100 && cnt < 108))
			sram_waddr_a = addr_init + 2;
		else if((cnt >= 24 && cnt < 28)||(cnt >= 52 && cnt < 56)||(cnt >= 80 && cnt < 84)||(cnt >= 108 && cnt < 112))
			sram_waddr_a = addr_init + 3;
	end
	else if(cnt_idx == 2 || cnt_idx == 3) begin
		addr_init = 6;
		if((cnt >= 0 && cnt < 8)||(cnt >= 28 && cnt < 36)||(cnt >= 56 && cnt < 64)||(cnt >= 84 && cnt < 92))
			sram_waddr_a = addr_init;
		else if((cnt >= 8 && cnt < 16)||(cnt >= 36 && cnt < 44)||(cnt >= 64 && cnt < 72)||(cnt >= 92 && cnt < 100))
			sram_waddr_a = addr_init + 1;
		else if((cnt >= 16 && cnt < 24)||(cnt >= 44 && cnt < 52)||(cnt >= 72 && cnt < 80)||(cnt >= 100 && cnt < 108))
			sram_waddr_a = addr_init + 2;
		else if((cnt >= 24 && cnt < 28)||(cnt >= 52 && cnt < 56)||(cnt >= 80 && cnt < 84)||(cnt >= 108 && cnt < 112))
			sram_waddr_a = addr_init + 3;
	end
	else if(cnt_idx == 4 || cnt_idx == 5) begin
		addr_init = 12;
		if((cnt >= 0 && cnt < 8)||(cnt >= 28 && cnt < 36)||(cnt >= 56 && cnt < 64)||(cnt >= 84 && cnt < 92))
			sram_waddr_a = addr_init;
		else if((cnt >= 8 && cnt < 16)||(cnt >= 36 && cnt < 44)||(cnt >= 64 && cnt < 72)||(cnt >= 92 && cnt < 100))
			sram_waddr_a = addr_init + 1;
		else if((cnt >= 16 && cnt < 24)||(cnt >= 44 && cnt < 52)||(cnt >= 72 && cnt < 80)||(cnt >= 100 && cnt < 108))
			sram_waddr_a = addr_init + 2;
		else if((cnt >= 24 && cnt < 28)||(cnt >= 52 && cnt < 56)||(cnt >= 80 && cnt < 84)||(cnt >= 108 && cnt < 112))
			sram_waddr_a = addr_init + 3;
	end
	else if(cnt_idx == 6) begin
		addr_init = 18;
		if((cnt >= 0 && cnt < 8)||(cnt >= 28 && cnt < 36)||(cnt >= 56 && cnt < 64)||(cnt >= 84 && cnt < 92))
			sram_waddr_a = addr_init;
		else if((cnt >= 8 && cnt < 16)||(cnt >= 36 && cnt < 44)||(cnt >= 64 && cnt < 72)||(cnt >= 92 && cnt < 100))
			sram_waddr_a = addr_init + 1;
		else if((cnt >= 16 && cnt < 24)||(cnt >= 44 && cnt < 52)||(cnt >= 72 && cnt < 80)||(cnt >= 100 && cnt < 108))
			sram_waddr_a = addr_init + 2;
		else if((cnt >= 24 && cnt < 28)||(cnt >= 52 && cnt < 56)||(cnt >= 80 && cnt < 84)||(cnt >= 108 && cnt < 112))
			sram_waddr_a = addr_init + 3;
	end
end

//====control for wen====//
always @* begin

    sram_wen_a0 = 1;
    sram_wen_a1 = 1;
    sram_wen_a2 = 1;
    sram_wen_a3 = 1;
	if(state == 1) begin
		if(cnt_idx == 0 || cnt_idx == 2 || cnt_idx == 4 || cnt_idx == 6) begin
			if((cnt_wen >= 0 && cnt_wen < 4)||(cnt_wen >= 8 && cnt_wen < 12)||(cnt_wen >= 16 && cnt_wen < 20)||(cnt_wen >= 24 && cnt_wen < 28)) begin
				sram_wen_a0 = 0;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
			else if((cnt_wen >= 4 && cnt_wen < 8)||(cnt_wen >= 12 && cnt_wen < 16)||(cnt_wen >= 20 && cnt_wen < 24)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 0;
				sram_wen_a2 = 1;
				sram_wen_a3 = 1;
			end
		end	
		else if(cnt_idx == 1 || cnt_idx == 3 || cnt_idx == 5) begin
			if((cnt_wen >= 0 && cnt_wen < 4)||(cnt_wen >= 8 && cnt_wen < 12)||(cnt_wen >= 16 && cnt_wen < 20)||(cnt_wen >= 24 && cnt_wen < 28)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 0;
				sram_wen_a3 = 1;
			end
			else if((cnt_wen >= 4 && cnt_wen < 8)||(cnt_wen >= 12 && cnt_wen < 16)||(cnt_wen >= 20 && cnt_wen < 24)) begin
				sram_wen_a0 = 1;
				sram_wen_a1 = 1;
				sram_wen_a2 = 1;
				sram_wen_a3 = 0;
			end
		end
	end
end

//====control for ch====//
always @* begin
	sram_wdata_a = 0;
    sram_wordmask_a = 16'b1111_1111_1111_1111;
	if(cnt >= 0 && cnt < 28) begin
		case(cnt_ch)
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
	else if(cnt >= 28 && cnt < 56) begin
		case(cnt_ch)
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
	else if(cnt >= 56 && cnt < 84) begin
		case(cnt_ch)
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
	else if(cnt >= 84 && cnt < 112) begin
		case(cnt_ch)
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
end

endmodule
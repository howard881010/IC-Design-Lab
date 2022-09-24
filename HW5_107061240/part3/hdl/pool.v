module conv_pool #(
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
input enable, 
output reg valid, // output valid for testbench to check answers in corresponding SRAM groups
// read data from SRAM group A
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a0,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a1,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a2,
input [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_rdata_a3,
// read data from parameter SRAM
input [WEIGHT_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_weight,  
input [BIAS_PER_ADDR*BW_PER_PARAM-1:0] sram_rdata_bias,     
// read address to SRAM group A
output reg [5:0] sram_raddr_a0,
output reg [5:0] sram_raddr_a1,
output reg [5:0] sram_raddr_a2,
output reg [5:0] sram_raddr_a3,
// read address to parameter SRAM
output reg [9:0] sram_raddr_weight,       
output reg [5:0] sram_raddr_bias,         
// write enable for SRAM groups B
output reg sram_wen_b0,
output reg sram_wen_b1,
output reg sram_wen_b2,
output reg sram_wen_b3,
// word mask for SRAM groups B
output reg [CH_NUM*ACT_PER_ADDR-1:0] sram_wordmask_b,
// write addrress to SRAM groups B
output reg [5:0] sram_waddr_b,
// write data to SRAM groups B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b
);

parameter IDLE = 4'd0, PREPARE = 4'd1, CONV1 = 4'd2, CONV2 = 4'd3, CONV3 = 4'd4, POOL = 4'd5;
parameter P1 = 4'd6, P2 = 4'd7, P3 = 4'd8;
reg [3:0] state, nstate;
reg pool_done;

integer i, j;
reg [5:0] cnt, n_cnt;
reg [5:0] cnt_no, n_cnt_no;
reg [1:0] cnt_ch, n_cnt_ch;
reg [1:0] cnt_addr_idx, n_cnt_addr_idx;
reg [1:0] cnt_conv, n_cnt_conv;
reg [1:0] cnt_conv1, n_cnt_conv1;
reg [3:0] cnt_table, n_cnt_table;

reg [9:0] addr_weight_init;
reg signed [7:0] n_weight[0:11][0:8];
reg signed [7:0] weight[0:11][0:8];
reg signed [7:0] n_bias, bias;

reg [5:0] addr_a0_init, addr_a1_init, addr_a2_init, addr_a3_init;
reg [3:0] idx;
reg signed [11:0] data_bk0 [0:15], data_bk1 [0:15], data_bk2 [0:15], data_bk3 [0:15];
reg signed [20:0] conv_out_ch[0:3];
reg signed [20:0] tmp [0:63];
reg signed [20:0] n_tmp [0:63];
reg signed [20:0] accuout_ch0_3 [0:63];
reg signed [20:0] n_accuout_ch0_3 [0:63];
reg signed [20:0] accuout_ch4_7 [0:63];
reg signed [20:0] n_accuout_ch4_7 [0:63];
reg signed [20:0] accuout_ch8_11 [0:63];
reg signed [20:0] n_accuout_ch8_11 [0:63];
reg signed [20:0] accu_out [0:63];
reg signed [20:0] accu_out1 [0:63];
reg signed [20:0] q_out, q_out1;

always @(posedge clk) begin
	if(~rst_n) begin
		state <= 0;
		cnt <= 0;
		cnt_no <= 0;
		cnt_ch <= 0;
		cnt_addr_idx <= 0;
		cnt_conv <= 0;
		cnt_conv1 <= 0;
		cnt_table <= 0;
		bias <= 0;
		for(j=0; j<12; j=j+1) begin
			for(i=0; i<9; i=i+1) begin
				weight[j][i] <= 0;
			end
		end
		for(i=0; i<64; i=i+1) begin
			tmp[i] <= 0;
			accuout_ch0_3[i] <= 0;
			accuout_ch4_7[i] <= 0;
			accuout_ch8_11[i] <= 0;
		end
	end
	else begin
		state <= nstate;
		cnt <= n_cnt;
		cnt_no <= n_cnt_no;
		cnt_ch <= n_cnt_ch;
		cnt_addr_idx <= n_cnt_addr_idx;
		cnt_conv <= n_cnt_conv;
		cnt_conv1 <= n_cnt_conv1;
		cnt_table <= n_cnt_table;
		bias <= n_bias;
		for(j=0; j<12; j=j+1) begin
			for(i=0; i<9; i=i+1) begin
				weight[j][i] <= n_weight[j][i];
			end
		end
		for(i=0; i<64; i=i+1) begin
			tmp[i] <= n_tmp[i];
			accuout_ch0_3[i] <= n_accuout_ch0_3[i];
			accuout_ch4_7[i] <= n_accuout_ch4_7[i];
			accuout_ch8_11[i] <= n_accuout_ch8_11[i];
		end
	end
end

// =====FSM===== //
always @* begin
	case(state)
		IDLE: begin
			if(enable)
				nstate = PREPARE;
			else
				nstate = IDLE;
		end
		PREPARE: begin
			if(cnt==11)
				nstate = CONV1;
			else
				nstate = PREPARE;
		end
		CONV1: begin
			if(cnt==15 && cnt_addr_idx==3)
				nstate = P1;
			else
				nstate = CONV1;
		end
		P1: nstate = CONV2;
		CONV2: begin
			if(cnt==15 && cnt_addr_idx==3)
				nstate = P2;
			else
				nstate = CONV2;
		end
		P2: nstate = CONV3;
		CONV3: begin
			if(cnt==15 && cnt_addr_idx==3)
				nstate = P3;
			else
				nstate = CONV3;
		end
		P3: nstate = POOL;
		POOL: begin
			if(pool_done)
				nstate = PREPARE;
			else
				nstate = POOL;
		end
		default: begin
			nstate = IDLE;
		end
	endcase
end

always @* begin
	if(state==PREPARE) begin
		n_cnt = cnt + 1;
		n_cnt_addr_idx = 0;
		n_cnt_conv = 0;
		n_cnt_conv1 = 0;
		n_cnt_table = 0;
		if(cnt==11)
			n_cnt = 0;
	end
	else if(state==CONV1 || state==CONV2 || state==CONV3) begin
		n_cnt = cnt + 1;
		n_cnt_addr_idx = cnt_addr_idx;
		n_cnt_conv = cnt_conv + 1;
		n_cnt_conv1 = cnt_conv1;
		n_cnt_table = cnt_table;
		if(cnt==15) begin
			n_cnt = 0;
			n_cnt_addr_idx = cnt_addr_idx + 1;
		end
		if(cnt==7 || cnt==15)
			n_cnt_conv1 = cnt_conv1 + 1;
		if(cnt_conv==3)
			n_cnt_table = cnt_table + 1;
	end
	else if(state==POOL) begin
		n_cnt = cnt + 1;
		n_cnt_addr_idx = 0;
		n_cnt_conv = 0;
		n_cnt_conv1 = 0;
		n_cnt_table = 0;	
		if(cnt==15)
			n_cnt = 0;
	end
	else begin
		n_cnt = 0;
		n_cnt_addr_idx = 0;
		n_cnt_conv = 0;
		n_cnt_conv1 = 0;
		n_cnt_table = 0;
	end
end

// =====control for conv done =====//
always @* begin
	if(pool_done) begin
		n_cnt_no = cnt_no + 1;
		n_cnt_ch = cnt_ch + 1;
	end
	else begin
		n_cnt_no = cnt_no;
		n_cnt_ch = cnt_ch;
	end
end

always @* begin
	if(state==POOL) begin
		pool_done = 0;
		valid = 0;
		if(cnt==15 && cnt_no!=47) begin
			pool_done = 1;
			valid = 0;
		end
		else if(cnt==15 && cnt_no==47) begin
			pool_done = 1;
			valid = 1;
		end
	end
	else begin
		pool_done = 0;
		valid = 0;
	end	
end

// =====control for read in bank addr===== //
always @* begin
	if(state==CONV1) begin
		case(cnt_addr_idx) //synopsys parallel_case
			0: begin
				addr_a0_init = 0;
				addr_a1_init = 0;
				addr_a2_init = 0;
				addr_a3_init = 0;
				if(cnt==15) begin
					addr_a0_init = 6;
					addr_a1_init = 6;
					addr_a2_init = 0;
					addr_a3_init = 0;
				end
			end
			1: begin
				addr_a0_init = 6;
				addr_a1_init = 6;
				addr_a2_init = 0;
				addr_a3_init = 0;
				if(cnt==15) begin
					addr_a0_init = 6;
					addr_a1_init = 6;
					addr_a2_init = 6;
					addr_a3_init = 6;
				end
			end
			2: begin
				addr_a0_init = 6;
				addr_a1_init = 6;
				addr_a2_init = 6;
				addr_a3_init = 6;
				if(cnt==15) begin
					addr_a0_init = 12;
					addr_a1_init = 12;
					addr_a2_init = 6;
					addr_a3_init = 6;
				end
			end
			3: begin
				addr_a0_init = 12;
				addr_a1_init = 12;
				addr_a2_init = 6;
				addr_a3_init = 6;
				if(cnt==15) begin
					addr_a0_init = 3;
					addr_a1_init = 3;
					addr_a2_init = 3;
					addr_a3_init = 3;
				end
			end
			default: begin
				addr_a0_init = 0;
				addr_a1_init = 0;
				addr_a2_init = 0;
				addr_a3_init = 0;
			end
		endcase
	end
	else if(state==CONV2) begin
		case(cnt_addr_idx)
			0: begin
				addr_a0_init = 3;
				addr_a1_init = 3;
				addr_a2_init = 3;
				addr_a3_init = 3;
				if(cnt==15) begin
					addr_a0_init = 9;
					addr_a1_init = 9;
					addr_a2_init = 3;
					addr_a3_init = 3;
				end
			end
			1: begin
				addr_a0_init = 9;
				addr_a1_init = 9;
				addr_a2_init = 3;
				addr_a3_init = 3;
				if(cnt==15) begin
					addr_a0_init = 9;
					addr_a1_init = 9;
					addr_a2_init = 9;
					addr_a3_init = 9;
				end
			end
			2: begin
				addr_a0_init = 9;
				addr_a1_init = 9;
				addr_a2_init = 9;
				addr_a3_init = 9;
				if(cnt==15) begin
					addr_a0_init = 15;
					addr_a1_init = 15;
					addr_a2_init = 9;
					addr_a3_init = 9;
				end
			end
			3: begin
				addr_a0_init = 15;
				addr_a1_init = 15;
				addr_a2_init = 9;
				addr_a3_init = 9;
				if(cnt==15) begin
					addr_a0_init = 18;
					addr_a1_init = 18;
					addr_a2_init = 18;
					addr_a3_init = 18;
				end
			end
			default: begin
				addr_a0_init = 0;
				addr_a1_init = 0;
				addr_a2_init = 0;
				addr_a3_init = 0;
			end
		endcase
	end
	else if(state==CONV3) begin
		case(cnt_addr_idx)
			0: begin
				addr_a0_init = 18;
				addr_a1_init = 18;
				addr_a2_init = 18;
				addr_a3_init = 18;
				if(cnt==15) begin
					addr_a0_init = 24;
					addr_a1_init = 24;
					addr_a2_init = 18;
					addr_a3_init = 18;
				end
			end
			1: begin
				addr_a0_init = 24;
				addr_a1_init = 24;
				addr_a2_init = 18;
				addr_a3_init = 18;
				if(cnt==15) begin
					addr_a0_init = 24;
					addr_a1_init = 24;
					addr_a2_init = 24;
					addr_a3_init = 24;
				end
			end
			2: begin
				addr_a0_init = 24;
				addr_a1_init = 24;
				addr_a2_init = 24;
				addr_a3_init = 24;
				if(cnt==15) begin
					addr_a0_init = 30;
					addr_a1_init = 30;
					addr_a2_init = 24;
					addr_a3_init = 24;
				end
			end
			3: begin
				addr_a0_init = 30;
				addr_a1_init = 30;
				addr_a2_init = 24;
				addr_a3_init = 24;
			end
			default: begin
				addr_a0_init = 0;
				addr_a1_init = 0;
				addr_a2_init = 0;
				addr_a3_init = 0;
			end
		endcase
	end
	else begin
		addr_a0_init = 0;
		addr_a1_init = 0;
		addr_a2_init = 0;
		addr_a3_init = 0;
	end
end

always @* begin


	sram_raddr_a0 = 0;
	sram_raddr_a1 = 0;
	sram_raddr_a2 = 0;
	sram_raddr_a3 = 0;

	if(state==CONV1 || state==CONV2 || state==CONV3) begin
		case(cnt) //synopsys parallel_case
			0, 7, 8, 15: begin
				sram_raddr_a0 = addr_a0_init;
				sram_raddr_a1 = addr_a1_init;
				sram_raddr_a2 = addr_a2_init;
				sram_raddr_a3 = addr_a3_init;
			end
			1, 2, 9, 10: begin
				sram_raddr_a0 = addr_a0_init + 1;
				sram_raddr_a1 = addr_a1_init;
				sram_raddr_a2 = addr_a2_init + 1;
				sram_raddr_a3 = addr_a3_init;
			end
			3, 4, 11, 12: begin
				sram_raddr_a0 = addr_a0_init + 1;
				sram_raddr_a1 = addr_a1_init + 1;
				sram_raddr_a2 = addr_a2_init + 1;
				sram_raddr_a3 = addr_a3_init + 1;
			end
			5, 6, 13, 14: begin
				sram_raddr_a0 = addr_a0_init + 2;
				sram_raddr_a1 = addr_a1_init + 1;
				sram_raddr_a2 = addr_a2_init + 2;
				sram_raddr_a3 = addr_a3_init + 1;
			end
	    	default: begin
				sram_raddr_a0 = addr_a0_init;
				sram_raddr_a1 = addr_a1_init;
				sram_raddr_a2 = addr_a2_init;
				sram_raddr_a3 = addr_a3_init;
			end
		endcase
	end
	else if(state==P1) begin
		sram_raddr_a0 = 3;
		sram_raddr_a1 = 3;
		sram_raddr_a2 = 3;
		sram_raddr_a3 = 3;
	end		
	else if(state==P2) begin
		sram_raddr_a0 = 18;
		sram_raddr_a1 = 18;
		sram_raddr_a2 = 18;
		sram_raddr_a3 = 18;
	end
end

// =====start conv===== //
always @* begin
	idx = 0;
	for(i=0; i<64; i=i+1) begin
		n_accuout_ch0_3[i] = accuout_ch0_3[i];
		n_accuout_ch4_7[i] = accuout_ch4_7[i];
		n_accuout_ch8_11[i] = accuout_ch8_11[i];
	end
	for(i=0; i<16; i=i+1) begin
		data_bk0[i] = sram_rdata_a0[191-i*12 -: 12];
		data_bk1[i] = sram_rdata_a1[191-i*12 -: 12];
		data_bk2[i] = sram_rdata_a2[191-i*12 -: 12];
		data_bk3[i] = sram_rdata_a3[191-i*12 -: 12];
	end
	if(state == CONV1 || state == P1) begin
		idx = 0;
		for(i=0; i<64; i=i+1) begin
			n_accuout_ch0_3[i] = tmp[i];
		end
	end
	else if(state==CONV2 || state==P2) begin
		idx = 4;
		for(i=0; i<64; i=i+1) begin
			n_accuout_ch4_7[i] = tmp[i];
		end
	end
	else if(state==CONV3 || state==P3) begin
		idx = 8;
		for(i=0; i<64; i=i+1) begin
			n_accuout_ch8_11[i] = tmp[i];
		end
	end
end

always @* begin
	for(i=0; i<64; i=i+1)
		n_tmp[i] = tmp[i];
	case(cnt_conv1) //synopsys parallel_case
		0: begin
			case(cnt_conv)
				0: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk0[0+i*4]*weight[idx+i][0] + data_bk0[1+i*4]*weight[idx+i][1] + data_bk1[0+i*4]*weight[idx+i][2]+
								   	 	 data_bk0[2+i*4]*weight[idx+i][3] + data_bk0[3+i*4]*weight[idx+i][4] + data_bk1[2+i*4]*weight[idx+i][5]+
								   	 	 data_bk2[0+i*4]*weight[idx+i][6] + data_bk2[1+i*4]*weight[idx+i][7] + data_bk3[0+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];	
				end
				1: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk0[1+i*4]*weight[idx+i][0] + data_bk1[0+i*4]*weight[idx+i][1] + data_bk1[1+i*4]*weight[idx+i][2]+
								   	 	 data_bk0[3+i*4]*weight[idx+i][3] + data_bk1[2+i*4]*weight[idx+i][4] + data_bk1[3+i*4]*weight[idx+i][5]+
								   	 	 data_bk2[1+i*4]*weight[idx+i][6] + data_bk3[0+i*4]*weight[idx+i][7] + data_bk3[1+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 1] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				2: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk1[0+i*4]*weight[idx+i][0] + data_bk1[1+i*4]*weight[idx+i][1] + data_bk0[0+i*4]*weight[idx+i][2]+
								   	 	 data_bk1[2+i*4]*weight[idx+i][3] + data_bk1[3+i*4]*weight[idx+i][4] + data_bk0[2+i*4]*weight[idx+i][5]+
								   	 	 data_bk3[0+i*4]*weight[idx+i][6] + data_bk3[1+i*4]*weight[idx+i][7] + data_bk2[0+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 2] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];		
				end
				3: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk1[1+i*4]*weight[idx+i][0] + data_bk0[0+i*4]*weight[idx+i][1] + data_bk0[1+i*4]*weight[idx+i][2]+
								   	 	 data_bk1[3+i*4]*weight[idx+i][3] + data_bk0[2+i*4]*weight[idx+i][4] + data_bk0[3+i*4]*weight[idx+i][5]+
								   	 	 data_bk3[1+i*4]*weight[idx+i][6] + data_bk2[0+i*4]*weight[idx+i][7] + data_bk2[1+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 3] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
			endcase
		end
		1: begin
			case(cnt_conv)
				0: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk0[2+i*4]*weight[idx+i][0]+data_bk0[3+i*4]*weight[idx+i][1]+data_bk1[2+i*4]*weight[idx+i][2]+
								   	 	 data_bk2[0+i*4]*weight[idx+i][3]+data_bk2[1+i*4]*weight[idx+i][4]+data_bk3[0+i*4]*weight[idx+i][5]+
								   	 	data_bk2[2+i*4]*weight[idx+i][6]+data_bk2[3+i*4]*weight[idx+i][7]+data_bk3[2+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				1: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk0[3+i*4]*weight[idx+i][0]+data_bk1[2+i*4]*weight[idx+i][1]+data_bk1[3+i*4]*weight[idx+i][2]+
								   	 	 data_bk2[1+i*4]*weight[idx+i][3]+data_bk3[0+i*4]*weight[idx+i][4]+data_bk3[1+i*4]*weight[idx+i][5]+
								   	 	data_bk2[3+i*4]*weight[idx+i][6]+data_bk3[2+i*4]*weight[idx+i][7]+data_bk3[3+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 1] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];	
				end
				2: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk1[2+i*4]*weight[idx+i][0]+data_bk1[3+i*4]*weight[idx+i][1]+data_bk0[2+i*4]*weight[idx+i][2]+
								   	 	 data_bk3[0+i*4]*weight[idx+i][3]+data_bk3[1+i*4]*weight[idx+i][4]+data_bk2[0+i*4]*weight[idx+i][5]+
								   	 	data_bk3[2+i*4]*weight[idx+i][6]+data_bk3[3+i*4]*weight[idx+i][7]+data_bk2[2+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 2] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				3: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk1[3+i*4]*weight[idx+i][0]+data_bk0[2+i*4]*weight[idx+i][1]+data_bk0[3+i*4]*weight[idx+i][2]+
								   	 	 data_bk3[1+i*4]*weight[idx+i][3]+data_bk2[0+i*4]*weight[idx+i][4]+data_bk2[1+i*4]*weight[idx+i][5]+
								   	 	data_bk3[3+i*4]*weight[idx+i][6]+data_bk2[2+i*4]*weight[idx+i][7]+data_bk2[3+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 3] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
			endcase
		end
		2: begin
			case(cnt_conv)
				0: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk2[0+i*4]*weight[idx+i][0]+data_bk2[1+i*4]*weight[idx+i][1]+data_bk3[0+i*4]*weight[idx+i][2]+
								   	 	 data_bk2[2+i*4]*weight[idx+i][3]+data_bk2[3+i*4]*weight[idx+i][4]+data_bk3[2+i*4]*weight[idx+i][5]+
								   	 	data_bk0[0+i*4]*weight[idx+i][6]+data_bk0[1+i*4]*weight[idx+i][7]+data_bk1[0+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				1: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk2[1+i*4]*weight[idx+i][0]+data_bk3[0+i*4]*weight[idx+i][1]+data_bk3[1+i*4]*weight[idx+i][2]+
								   	 	 data_bk2[3+i*4]*weight[idx+i][3]+data_bk3[2+i*4]*weight[idx+i][4]+data_bk3[3+i*4]*weight[idx+i][5]+
								   	 	data_bk0[1+i*4]*weight[idx+i][6]+data_bk1[0+i*4]*weight[idx+i][7]+data_bk1[1+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 1] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				2: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk3[0+i*4]*weight[idx+i][0]+data_bk3[1+i*4]*weight[idx+i][1]+data_bk2[0+i*4]*weight[idx+i][2]+
								   	 	 data_bk3[2+i*4]*weight[idx+i][3]+data_bk3[3+i*4]*weight[idx+i][4]+data_bk2[2+i*4]*weight[idx+i][5]+
								   	 	data_bk1[0+i*4]*weight[idx+i][6]+data_bk1[1+i*4]*weight[idx+i][7]+data_bk0[0+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 2] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				3: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk3[1+i*4]*weight[idx+i][0]+data_bk2[0+i*4]*weight[idx+i][1]+data_bk2[1+i*4]*weight[idx+i][2]+
								   	 	 data_bk3[3+i*4]*weight[idx+i][3]+data_bk2[2+i*4]*weight[idx+i][4]+data_bk2[3+i*4]*weight[idx+i][5]+
								   	 	data_bk1[1+i*4]*weight[idx+i][6]+data_bk0[0+i*4]*weight[idx+i][7]+data_bk0[1+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 3] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
			endcase
		end
		3: begin
			case(cnt_conv)
				0: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk2[2+i*4]*weight[idx+i][0]+data_bk2[3+i*4]*weight[idx+i][1]+data_bk3[2+i*4]*weight[idx+i][2]+
								   	 	 data_bk0[0+i*4]*weight[idx+i][3]+data_bk0[1+i*4]*weight[idx+i][4]+data_bk1[0+i*4]*weight[idx+i][5]+
								   	 	data_bk0[2+i*4]*weight[idx+i][6]+data_bk0[3+i*4]*weight[idx+i][7]+data_bk1[2+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				1: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk2[3+i*4]*weight[idx+i][0]+data_bk3[2+i*4]*weight[idx+i][1]+data_bk3[3+i*4]*weight[idx+i][2]+
								   	 	 data_bk0[1+i*4]*weight[idx+i][3]+data_bk1[0+i*4]*weight[idx+i][4]+data_bk1[1+i*4]*weight[idx+i][5]+
								   	 	data_bk0[3+i*4]*weight[idx+i][6]+data_bk1[2+i*4]*weight[idx+i][7]+data_bk1[3+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 1] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				2: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk3[2+i*4]*weight[idx+i][0]+data_bk3[3+i*4]*weight[idx+i][1]+data_bk2[2+i*4]*weight[idx+i][2]+
								   	 	 data_bk1[0+i*4]*weight[idx+i][3]+data_bk1[1+i*4]*weight[idx+i][4]+data_bk0[0+i*4]*weight[idx+i][5]+
								   	 	data_bk1[2+i*4]*weight[idx+i][6]+data_bk1[3+i*4]*weight[idx+i][7]+data_bk0[2+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 2] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
				3: begin
					for(i=0; i<4; i=i+1)
						conv_out_ch[i] = data_bk3[3+i*4]*weight[idx+i][0]+data_bk2[2+i*4]*weight[idx+i][1]+data_bk2[3+i*4]*weight[idx+i][2]+
								   	 	 data_bk1[1+i*4]*weight[idx+i][3]+data_bk0[0+i*4]*weight[idx+i][4]+data_bk0[1+i*4]*weight[idx+i][5]+
								   	 	data_bk1[3+i*4]*weight[idx+i][6]+data_bk0[2+i*4]*weight[idx+i][7]+data_bk0[3+i*4]*weight[idx+i][8];	
					n_tmp[cnt_table*4 + 3] = conv_out_ch[0] + conv_out_ch[1] + conv_out_ch[2] + conv_out_ch[3];
				end
			endcase
		end
		default: begin
			for(i=0; i<4; i=i+1)
				conv_out_ch[i] = 0;
			for(i=0; i<64; i=i+1)
				n_tmp[i] = 0;
		end
	endcase
end

// =====pooling===== //
always @* begin
	if(state==POOL) begin
		for(i=0; i<64; i=i+1) begin
			accu_out[i] = accuout_ch0_3[i] + accuout_ch4_7[i] + accuout_ch8_11[i] + (bias << 8);
			if(accu_out[i]<0)
				accu_out1[i] = 0;
			else
				accu_out1[i] = accu_out[i];
		end
		sram_wdata_b = 0;
		case(cnt) //synopsys parallel_case
			0, 1, 2, 3: begin
				q_out = (accu_out1[cnt * 2]+accu_out1[cnt * 2 + 1]+accu_out1[cnt * 2 + 8]+accu_out1[cnt * 2 + 9]) / 4 + 64;
				if(q_out[20]==1) begin
					q_out1[20:14] = 7'b111_1111;
					q_out1[13:0] = q_out[20:7];
				end
				else q_out1 = q_out >> 7;
				if(q_out1 > 2047) sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = 2047;
				else if(q_out1 < -2048) sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = -2048;
				else sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = q_out1[11:0];
			end
			4, 5, 6, 7: begin
				q_out = (accu_out1[8 + cnt * 2]+accu_out1[9 + cnt * 2]+accu_out1[16 + cnt * 2]+accu_out1[17 + cnt * 2])/4 + 64;
				if(q_out[20]==1) begin
					q_out1[20:14] = 7'b111_1111;
					q_out1[13:0] = q_out[20:7];
				end
				else q_out1 = q_out >> 7;
				if(q_out1 > 2047) sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = 2047;
				else if(q_out1 < -2048) sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = -2048;
				else sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = q_out1[11:0];
			end
			8, 9, 10, 11: begin
				q_out = (accu_out1[16 + cnt * 2]+accu_out1[17 + cnt * 2]+accu_out1[24 + cnt * 2]+accu_out1[25 + cnt * 2])/4 + 64;
				if(q_out[20]==1) begin
					q_out1[20:14] = 7'b111_1111;
					q_out1[13:0] = q_out[20:7];
				end
				else q_out1 = q_out >> 7;
				if(q_out1 > 2047) sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = 2047;
				else if(q_out1 < -2048) sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = -2048;
				else sram_wdata_b[191 - (12 * (cnt % 2)) -48*cnt_ch -: 12] = q_out1[11:0];
			end
			12, 13, 14, 15: begin
				q_out = (accu_out1[24 + cnt * 2]+accu_out1[25 + cnt * 2]+accu_out1[32 + cnt * 2]+accu_out1[33 + cnt * 2])/4 + 64;
				if(q_out[20]==1) begin
					q_out1[20:14] = 7'b111_1111;
					q_out1[13:0] = q_out[20:7];
				end
				else q_out1 = q_out >> 7;
				if(q_out1 > 2047) sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = 2047;
				else if(q_out1 < -2048) sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = -2048;
				else sram_wdata_b[167-(12 * (cnt % 2)) -48*cnt_ch -: 12] = q_out1[11:0];
			end
			default: begin
				q_out = 0;
				q_out1 = 0;		
			end
		endcase
	end
	else begin
		for(i=0; i<64; i=i+1) begin
			accu_out[i] = 0;
			accu_out1[i] = 0;
		end
		q_out = 0;
		q_out1 = 0;	
		sram_wdata_b = 0;
	end
end

// =====control for writing sram b===== //
always @* begin
	if(state==POOL) begin
		if(cnt_no>=0 && cnt_no<4) begin
			sram_waddr_b = 0;
		end
		else if(cnt_no>=4 && cnt_no<8) begin
			sram_waddr_b = 1;
		end
		else if(cnt_no>=8 && cnt_no<12) begin
			sram_waddr_b = 2;
		end
		else if(cnt_no>=12 && cnt_no<16) begin
			sram_waddr_b = 3;
		end
		else if(cnt_no>=16 && cnt_no<20) begin
			sram_waddr_b = 4;
		end
		else if(cnt_no>=20 && cnt_no<24) begin
			sram_waddr_b = 5;
		end
		else if(cnt_no>=24 && cnt_no<28) begin
			sram_waddr_b = 6;
		end
		else if(cnt_no>=28 && cnt_no<32) begin
			sram_waddr_b = 7;
		end
		else if(cnt_no>=32 && cnt_no<36) begin
			sram_waddr_b = 8;
		end
		else if(cnt_no>=36 && cnt_no<40) begin
			sram_waddr_b = 9;
		end
		else if(cnt_no>=40 && cnt_no<44) begin
			sram_waddr_b = 10;
		end
		else if(cnt_no>=44 && cnt_no<48) begin
			sram_waddr_b = 11;
		end
		else begin
			sram_waddr_b = 0;
		end
	end
	else begin
		sram_waddr_b = 0;
	end
end

always @* begin

	sram_wen_b0 = 1;
	sram_wen_b1 = 1;
	sram_wen_b2 = 1;
	sram_wen_b3 = 1;
	if(state==POOL) begin
		if(cnt==0 || cnt==1 || cnt==4 || cnt==5) begin
			sram_wen_b0 = 0;
			sram_wen_b1 = 1;
			sram_wen_b2 = 1;
			sram_wen_b3 = 1;
		end
		else if(cnt==2 || cnt==3 || cnt==6 || cnt==7) begin
			sram_wen_b0 = 1;
			sram_wen_b1 = 0;
			sram_wen_b2 = 1;
			sram_wen_b3 = 1;
		end
		else if(cnt==8 || cnt==9 || cnt==12 || cnt==13) begin
			sram_wen_b0 = 1;
			sram_wen_b1 = 1;
			sram_wen_b2 = 0;
			sram_wen_b3 = 1;
		end
		else if(cnt==10 || cnt==11 || cnt==14 || cnt==15) begin
			sram_wen_b0 = 1;
			sram_wen_b1 = 1;
			sram_wen_b2 = 1;
			sram_wen_b3 = 0;
		end
	end
end

always @* begin
	sram_wordmask_b = 16'b1111_1111_1111_1111;
	if(state==POOL) begin
		case (cnt_ch) 
			0: begin
				if(cnt==0 || cnt==2 || cnt==8 || cnt==10) sram_wordmask_b = 16'b0111_1111_1111_1111;
				else if(cnt==1 || cnt==3 || cnt==9 || cnt==11) sram_wordmask_b = 16'b1011_1111_1111_1111;
				else if(cnt==4 || cnt==6 || cnt==12 || cnt==14) sram_wordmask_b = 16'b1101_1111_1111_1111;
				else if(cnt==5 || cnt==7 || cnt==13 || cnt==15) sram_wordmask_b = 16'b1110_1111_1111_1111;
			end
			1: begin
				if(cnt==0 || cnt==2 || cnt==8 || cnt==10) sram_wordmask_b = 16'b1111_0111_1111_1111;
				else if(cnt==1 || cnt==3 || cnt==9 || cnt==11) sram_wordmask_b = 16'b1111_1011_1111_1111;
				else if(cnt==4 || cnt==6 || cnt==12 || cnt==14) sram_wordmask_b = 16'b1111_1101_1111_1111;
				else if(cnt==5 || cnt==7 || cnt==13 || cnt==15) sram_wordmask_b = 16'b1111_1110_1111_1111;
			end
			2: begin
				if(cnt==0 || cnt==2 || cnt==8 || cnt==10) sram_wordmask_b = 16'b1111_1111_0111_1111;
				else if(cnt==1 || cnt==3 || cnt==9 || cnt==11) sram_wordmask_b = 16'b1111_1111_1011_1111;
				else if(cnt==4 || cnt==6 || cnt==12 || cnt==14) sram_wordmask_b = 16'b1111_1111_1101_1111;
				else if(cnt==5 || cnt==7 || cnt==13 || cnt==15) sram_wordmask_b = 16'b1111_1111_1110_1111;
			end
			3: begin
				if(cnt==0 || cnt==2 || cnt==8 || cnt==10) sram_wordmask_b = 16'b1111_1111_1111_0111;
				else if(cnt==1 || cnt==3 || cnt==9 || cnt==11) sram_wordmask_b = 16'b1111_1111_1111_1011;
				else if(cnt==4 || cnt==6 || cnt==12 || cnt==14) sram_wordmask_b = 16'b1111_1111_1111_1101;
				else if(cnt==5 || cnt==7 || cnt==13 || cnt==15) sram_wordmask_b = 16'b1111_1111_1111_1110;
			end
		endcase

	end
end

// ======load weight & bias====== //
always @* begin
	n_bias = bias;
	sram_raddr_bias = 0;
	addr_weight_init = 64;
	sram_raddr_weight = 64;
	for(i = 0; i < 12; i = i + 1) begin
		for(j = 0; j < 9; j = j + 1) begin
			n_weight[i][j] = weight[i][j];
		end
	end
	if(state==PREPARE) begin
		addr_weight_init = 64 + cnt_no*12;
		sram_raddr_bias = cnt_no + 16;
		n_bias = sram_rdata_bias;
		sram_raddr_weight = addr_weight_init + cnt + 1;
		for(i=0; i<9; i=i+1) begin
			n_weight[cnt][i] = sram_rdata_weight[71 - i * 8 -: 8];
		end	
	end
	else if(state==CONV1 || state==CONV2 || state==CONV3 || state==POOL) begin
		addr_weight_init = 64 + cnt_no*12;
		sram_raddr_weight = addr_weight_init + 12;
	end	
end

endmodule

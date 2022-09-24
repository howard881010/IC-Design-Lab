module conv #(
parameter CH_NUM = 4,
parameter ACT_PER_ADDR = 4,
parameter BW_PER_ACT = 12,
parameter WEIGHT_PER_ADDR = 9, 
parameter BIAS_PER_ADDR = 1,
parameter BW_PER_PARAM = 8
)
(
input [1:0] bank_arrange,
input [5:0]CNT_No,
input [3:0]state,
input clk,                          
input rst_n,  // synchronous reset (active low)
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
// write data to SRAM groups A & B
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_a,
output reg [CH_NUM*ACT_PER_ADDR*BW_PER_ACT-1:0] sram_wdata_b
);

integer i, j, k;
reg [9:0] CNT_WE, n_CNT_WE;

reg signed [7:0] n_weight[0:3][0:8];
reg signed [7:0] weight[0:3][0:8];


reg signed [11:0] data_bk0 [0:15];
reg signed [11:0] data_bk1 [0:15];
reg signed [11:0] data_bk2 [0:15];
reg signed [11:0] data_bk3 [0:15];
reg signed [20:0] conv_out_ch0[0:3];
reg signed [20:0] conv_out_ch1[0:3];
reg signed [20:0] conv_out_ch2[0:3];
reg signed [20:0] conv_out_ch3[0:3];
reg signed [20:0] n_conv_out_ch0[0:3];
reg signed [20:0] n_conv_out_ch1[0:3];
reg signed [20:0] n_conv_out_ch2[0:3];
reg signed [20:0] n_conv_out_ch3[0:3];
reg signed [20:0] accu_out0, accu_out01, n_accu_out0, n_accu_out01;
reg signed [20:0] accu_out1, accu_out11, n_accu_out1, n_accu_out11;
reg signed [20:0] accu_out2, accu_out21, n_accu_out2, n_accu_out21;
reg signed [20:0] accu_out3, accu_out31, n_accu_out3, n_accu_out31;
reg signed [20:0] q_out0, q_out01, n_q_out0, n_q_out01;
reg signed [20:0] q_out1, q_out11, n_q_out1, n_q_out11;
reg signed [20:0] q_out2, q_out21, n_q_out2, n_q_out21;
reg signed [20:0] q_out3, q_out31, n_q_out3, n_q_out31;
reg signed [20:0] tmp0, tmp1, tmp2, tmp3;
reg signed [20:0] n_tmp0, n_tmp1, n_tmp2, n_tmp3;
wire [1:0] CNWE =CNT_WE%4;




always @(posedge clk) begin
	if(~rst_n) begin
		CNT_WE <= 0;
		for(j=0; j<4; j=j+1) begin
			for(i=0; i<9; i=i+1) begin
				weight[j][i] <= 0;
			end
		end
		for(k=0;k<4;k=k+1) begin
			conv_out_ch0[k] <= 0;
			conv_out_ch1[k] <= 0;
			conv_out_ch2[k] <= 0;
			conv_out_ch3[k] <= 0;
		end
		accu_out0 <= 0;
		accu_out1 <= 0;
		accu_out2 <= 0;
		accu_out3 <= 0;
		q_out0 <= 0;
		q_out1 <= 0;
		q_out2 <= 0;
		q_out3 <= 0;
		q_out01 <= 0;
		q_out11 <= 0;
		q_out21 <= 0;
		q_out31 <= 0;
		tmp0 <= 0;
		tmp1 <= 0;
		tmp2 <= 0;
		tmp3 <= 0;
	end
	else begin
		CNT_WE <= n_CNT_WE;
		for(j=0; j<4; j=j+1) begin
			for(i=0; i<9; i=i+1) begin
				weight[j][i] <= n_weight[j][i];
			end
		end
		for(k=0;k<4;k=k+1) begin
			conv_out_ch0[k] <= n_conv_out_ch0[k];
			conv_out_ch1[k] <= n_conv_out_ch1[k];
			conv_out_ch2[k] <= n_conv_out_ch2[k];
			conv_out_ch3[k] <= n_conv_out_ch3[k];
		end
		accu_out0 <= n_accu_out0;
		accu_out1 <= n_accu_out1;
		accu_out2 <= n_accu_out2;
		accu_out3 <= n_accu_out3;
		q_out0 <= n_q_out0;
		q_out1 <= n_q_out1;
		q_out2 <= n_q_out2;
		q_out3 <= n_q_out3;
		q_out01 <= n_q_out01;
		q_out11 <= n_q_out11;
		q_out21 <= n_q_out21;
		q_out31 <= n_q_out31;
		tmp0 <= n_tmp0;
		tmp1 <= n_tmp1;
		tmp2 <= n_tmp2;
		tmp3 <= n_tmp3;
	end
end

always @* begin
	if(state == 2) begin
		n_CNT_WE = CNT_WE + 1;
	end
	else if(state == 3) begin
		n_CNT_WE = CNT_WE;
	end
	else begin
		n_CNT_WE = 0; 
	end
end


// =====start 3===== //
always @* begin

	for(i=0; i<16; i=i+1) begin
		data_bk0[i] = 0;
		data_bk1[i] = 0;
		data_bk2[i] = 0;
		data_bk3[i] = 0;
	end	
	if(state == 3) begin
		case(bank_arrange) //synopsys parallel_case
			0: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_a0[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_a1[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_a2[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_a3[191-i*12 -: 12];
				end
			end
			1: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_a1[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_a0[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_a3[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_a2[191-i*12 -: 12];
				end
			end
			2: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_a2[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_a3[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_a0[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_a1[191-i*12 -: 12];
				end
			end
			3: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_a3[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_a2[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_a1[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_a0[191-i*12 -: 12];
				end
			end
		endcase
	end
	else if(state == 4) begin
		case(bank_arrange) //synopsys parallel_case
			0: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_b0[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_b1[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_b2[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_b3[191-i*12 -: 12];
				end
			end
			1: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_b1[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_b0[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_b3[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_b2[191-i*12 -: 12];
				end
			end
			2: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_b2[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_b3[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_b0[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_b1[191-i*12 -: 12];
				end
			end
			3: begin
				for(i=0; i<16; i=i+1) begin
					data_bk0[i] = sram_rdata_b3[191-i*12 -: 12];
					data_bk1[i] = sram_rdata_b2[191-i*12 -: 12];
					data_bk2[i] = sram_rdata_b1[191-i*12 -: 12];
					data_bk3[i] = sram_rdata_b0[191-i*12 -: 12];
				end
			end
		endcase
	end
end

always @* begin
	sram_wdata_a =0;
	sram_wdata_b =0;
	for(i=0;i<4;i=i+1) begin
		n_conv_out_ch0[i] = conv_out_ch0[i];
		n_conv_out_ch1[i] = conv_out_ch1[i];
		n_conv_out_ch2[i] = conv_out_ch2[i];
		n_conv_out_ch3[i] = conv_out_ch3[i];
	end
	n_accu_out0 = 0;
	n_accu_out1 = 0;
	n_accu_out2 = 0;
	n_accu_out3 = 0;
	n_q_out0 = 0;
	n_q_out01 = 0;
	n_q_out1 = 0;
	n_q_out11 = 0;
	n_q_out2 = 0;
	n_q_out21 = 0;
	n_q_out3 = 0;
	n_q_out31 = 0;
	n_tmp0 = 0;
	n_tmp1 = 0;
	n_tmp2 = 0;
	n_tmp3 = 0;

		/////////PIXEL 0/////////
	if(state == 3 || state == 4)begin
		for(i=0; i<4; i=i+1)
			n_conv_out_ch0[i] = data_bk0[0+i*4]*weight[i][0] + data_bk0[1+i*4]*weight[i][1] + data_bk1[0+i*4]*weight[i][2] +
							 data_bk0[2+i*4]*weight[i][3] + data_bk0[3+i*4]*weight[i][4] + data_bk1[2+i*4]*weight[i][5] +
							 data_bk2[0+i*4]*weight[i][6] + data_bk2[1+i*4]*weight[i][7] + data_bk3[0+i*4]*weight[i][8] ;
		//$display("weight[0][0] = %d",weight[0][0]);	
		n_tmp0 = conv_out_ch0[0] + conv_out_ch0[1] + conv_out_ch0[2] + conv_out_ch0[3];
		n_accu_out0 = tmp0  + (sram_rdata_bias << 8);

		if(accu_out0 < 0) 
			accu_out01 = 0;
		else 
			accu_out01 = accu_out0;
		n_q_out0 = (accu_out01 + 2**6);
		n_q_out01 = q_out0 >> 7;
		if (state == 3)
			sram_wdata_b[191-48*CNT_No -: 12] = q_out01[11:0];
		else if (state == 4)
			sram_wdata_a[191-48*CNT_No -: 12] = q_out01[11:0];
		/////////PIXEL 1////////
		for(i=0; i<4; i=i+1)
			n_conv_out_ch1[i] = data_bk0[1+i*4]*weight[i][0] + data_bk1[0+i*4]*weight[i][1] + data_bk1[1+i*4]*weight[i][2] +
							 data_bk0[3+i*4]*weight[i][3] + data_bk1[2+i*4]*weight[i][4] + data_bk1[3+i*4]*weight[i][5] +
							 data_bk2[1+i*4]*weight[i][6] + data_bk3[0+i*4]*weight[i][7] + data_bk3[1+i*4]*weight[i][8] ;	
		n_tmp1 = conv_out_ch1[0] + conv_out_ch1[1] + conv_out_ch1[2] + conv_out_ch1[3];
		n_accu_out1 = tmp1 + (sram_rdata_bias << 8);

		if(accu_out1 < 0) 
			accu_out11 = 0;
		else 
			accu_out11 = accu_out1;
		n_q_out1 = (accu_out11 + 2**6);
		n_q_out11 = q_out1 >> 7;
		if (state == 3)
			sram_wdata_b[179-48*CNT_No -: 12] = q_out11[11:0];
		else if (state == 4)
			sram_wdata_a[191-48*CNT_No -: 12] = q_out01[11:0];

		/////////PIXEL 2/////////
		for(i=0; i<4; i=i+1)
			n_conv_out_ch2[i] = data_bk0[2+i*4]*weight[i][0] + data_bk0[3+i*4]*weight[i][1] + data_bk1[2+i*4]*weight[i][2] +
							 data_bk2[0+i*4]*weight[i][3] + data_bk2[1+i*4]*weight[i][4] + data_bk3[0+i*4]*weight[i][5] +
							 data_bk2[2+i*4]*weight[i][6] + data_bk2[3+i*4]*weight[i][7] + data_bk3[2+i*4]*weight[i][8] ;	
		n_tmp2 = conv_out_ch2[0] + conv_out_ch2[1] + conv_out_ch2[2] + conv_out_ch2[3] ;
		n_accu_out2 = tmp2 + (sram_rdata_bias << 8);
		if(accu_out2 < 0) 
			accu_out21 = 0;
		else 
			accu_out21 = accu_out2;
		n_q_out2 = (accu_out21 + 2**6);
		n_q_out21 = q_out2 >> 7;
		if (state == 3)
			sram_wdata_b[167-48*CNT_No -: 12] = q_out21[11:0];
		else if (state == 4)
			sram_wdata_a[191-48*CNT_No -: 12] = q_out01[11:0];

		/////////PIXEL 3/////////		
		for(i=0; i<4; i=i+1)
			n_conv_out_ch3[i] = data_bk0[3+i*4]*weight[i][0] + data_bk1[2+i*4]*weight[i][1] + data_bk1[3+i*4]*weight[i][2] +
							 data_bk2[1+i*4]*weight[i][3] + data_bk3[0+i*4]*weight[i][4] + data_bk3[1+i*4]*weight[i][5] +
							 data_bk2[3+i*4]*weight[i][6] + data_bk3[2+i*4]*weight[i][7] + data_bk3[3+i*4]*weight[i][8] ;	
		n_tmp3 = conv_out_ch3[0] + conv_out_ch3[1] + conv_out_ch3[2] + conv_out_ch3[3] ;
		n_accu_out3 = tmp3 + (sram_rdata_bias << 8);
		if(accu_out3 < 0) accu_out31 = 0;
		else accu_out31 = accu_out3;
		n_q_out3 = (accu_out31 + 2**6);
		n_q_out31 = q_out3 >> 7;
		if (state == 3)
			sram_wdata_b[155-48*CNT_No -: 12] = q_out31[11:0];	
		else if (state == 4)
			sram_wdata_a[155-48*CNT_No -: 12] = q_out31[11:0];
	end
end






/////////load weight/////////

always @* begin
	if (state == 1 || state == 2) begin
		case(CNWE) //synopsys parallel_case
			0: begin
				for(i=0; i<9; i=i+1) begin
					n_weight[0][i] = sram_rdata_weight[71-i*8-:8];
					n_weight[1][i] = weight[1][i];
					n_weight[2][i] = weight[2][i];
					n_weight[3][i] = weight[3][i];	
				end								
			end
			1: begin
				for(i=0; i<9; i=i+1) begin
					n_weight[0][i] = weight[0][i];
					n_weight[1][i] = sram_rdata_weight[71-i*8-:8];
					n_weight[2][i] = weight[2][i];
					n_weight[3][i] = weight[3][i];	
				end										
			end
			2: begin
				for(i=0; i<9; i=i+1) begin
					n_weight[0][i] = weight[0][i];
					n_weight[1][i] = weight[1][i];
					n_weight[2][i] = sram_rdata_weight[71-i*8-:8];
					n_weight[3][i] = weight[3][i];	
				end										
			end
			3: begin
				for(i=0; i<9; i=i+1) begin
					n_weight[0][i] = weight[0][i];
					n_weight[1][i] = weight[1][i];
					n_weight[2][i] = weight[2][i];
					n_weight[3][i] = sram_rdata_weight[71-i*8-:8];	
				end										
			end
		endcase
	end
	else begin
		for(i = 0; i < 4; i = i + 1) begin
			for(j = 0; j < 9; j = j + 1) begin
				n_weight[i][j] = weight[i][j];
			end
		end	
	end
end

endmodule

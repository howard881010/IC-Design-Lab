module qr_decode(
input clk,                           //clock input
input srstn,                         //synchronous reset (active low)
input qr_decode_start,               //start decoding for one QR code
                                     //1: start (one-cycle pulse)
input sram_rdata,                    //read data from SRAM
output reg [11:0] sram_raddr,        //read address to SRAM

output reg decode_valid,                 //decoded code is valid
output reg [7:0] decode_jis8_code,       //decoded JIS8 code
output reg qr_decode_finish              //1: decoding one QR code is finished
);

parameter IDLE = 4'd0, POS = 4'd1, DEMASK = 4'd2, CODEWORD = 4'd3, CORRECT = 4'd4, DECODE = 4'd5,FIND = 4'd6 ,ROT = 4'd7, FIND_S = 4'd8, FIND_SIGMA = 4'd9, FIND_ERR = 4'd10, DEMASK_F = 4'd11, MASK_PAT = 4'd12;
reg [3:0] state, new_state;
reg qr_enable;

integer i, j, pat;
reg n_qr[0:24][0:24];
reg qr[0:24][0:24];
reg mid_qr[0:24][0:24];

reg [12:0] cnt, new_cnt;
reg [6:0] cnt_idx, new_cnt_idx;
reg [6:0] cnt_i, new_cnt_i;
reg [6:0] cnt_j, new_cnt_j;

reg [2:0] mask_pattern, new_mask_pattern;
//reg n_mask[0:24][0:24];
//reg mask[0:24][0:24];

reg [7:0] codeword[0:43];
reg [7:0] mid_codeword[0:43];
reg [7:0] new_codeword[0:43];
reg [7:0] text_length;
reg [7:0] n_code_out;

reg [7:0] Eq[1:10][0:4], new_Eq[1:10][0:4];
reg [7:0] YEq[1:10][0:4], new_YEq[1:10][0:4];
reg [7:0] S[0:7], new_S[0:7];
reg [7:0] new_SS[0:3], SS[0:3];
reg [7:0] sigma[1:4];
reg [7:0] new_sigma[1:4];
reg [7:0] new_Y[1:4];
reg [6:0] det_pat[0:6];
reg [7:0] Y[1:4];
reg [7:0] error_loc[0:3], new_error_loc[0:3];
reg [5:0] start[0:1];
reg flag;
reg [11:0] start_point;
reg [11:0] new_start_point;
reg [1:0]corner;
reg correct_end, new_correct_end;
reg [2:0] new_err_num, err_num;
reg find_position;
reg find_S, new_find_S;
reg find_Sigma, new_find_Sigma;
reg [5:0] cnt_S, new_cnt_S;
reg [8:0] cnt_SEq, new_cnt_SEq;
reg find_Error, new_find_Error;
reg [5:0] cnt_ERR, new_cnt_ERR;
reg [4:0] cnt_x, new_cnt_x;
reg [4:0] cnt_y, new_cnt_y;
reg [4:0] cnt_Eq, new_cnt_Eq;
reg [4:0] cnt_YEq, new_cnt_YEq;
reg [7:0] alpha_a, alpha_b, alpha_c, alpha_d, value_e, value_f, value_g, value_h, alpha_i;
reg [7:0] new_alpha_a, new_alpha_b, new_alpha_c, new_alpha_d, new_value_e, new_value_f, new_value_g, new_value_h, new_alpha_i;
wire [7:0] value_a, value_b, value_c, value_d, alpha_e, alpha_f, alpha_g , alpha_h, value_i;
reg find_1, find_0, find_00;
reg new_find_1, new_find_0, new_find_position, new_find_00;
reg new_angle_180, angle_180;
reg a;

Alpha_table U0 (.clk(clk), .srstn(srstn), .alpha_a(new_alpha_a), .alpha_b(new_alpha_b), .alpha_c(new_alpha_c), .alpha_d(new_alpha_d), .alpha_i(new_alpha_i),
				.value_e(new_value_e), .value_f(new_value_f), .value_g(new_value_g), .value_h(new_value_h),
				.value_a(value_a), .value_b(value_b), .value_c(value_c), .value_d(value_d), .alpha_e(alpha_e), .alpha_f(alpha_f),
				.alpha_g(alpha_g), .alpha_h(alpha_h), .value_i(value_i));


always @(posedge clk) begin
	if(~srstn) begin
		state <= 0;
		cnt <= 0;
		for(i=0; i<25; i=i+1) begin
			for(j=0; j<25; j=j+1) begin
				qr[i][j] <= 0;
				//mask[i][j] <= 0;
			end
		end
		cnt_i <= 0;
		cnt_j <= 0;
		cnt_idx <= 0;
		qr_enable <= 0;
		decode_jis8_code <= 0;
		for (i = 0; i < 44; i = i + 1)
			codeword[i] <= 0;
		start_point <= 0;
		correct_end <= 0;
		for (i = 0; i < 8; i = i + 1) 
			S[i] <= 0;
		find_S <= 0;
		find_Sigma <= 0;
		for (i = 1; i < 5; i = i + 1) begin
			sigma[i] <= 0;
			Y[i] <= 0;
		end
		for (i = 0; i < 4; i = i + 1)
			SS[i] <= 0;
		cnt_S <= 0;
		find_Error <= 0;
		err_num <= 0;
		cnt_ERR <= 0;
		for (i = 0; i < 4; i = i + 1)
			error_loc[i] <= 0;
		cnt_x <= 0;
		cnt_y <= 0;
        cnt_Eq <= 0;
		alpha_a <= 0;
		alpha_b <= 0;
		alpha_c <= 0;
		alpha_d <= 0;
		value_e <= 0;
		value_f <= 0;
		value_g <= 0;
		value_h <= 0;
		alpha_i <= 0;
		for (i = 1; i < 11; i = i + 1)
			for (j = 0; j < 5; j = j + 1) begin
				Eq[i][j] <= 0;
				YEq[i][j] <= 0;
			end
		//mask_pattern <= 0;
		cnt_YEq <= 0;
		cnt_SEq <= 0;
		find_0 <= 0;
		find_00 <= 0;
		find_1 <= 0;
		find_position <= 0;
		angle_180 <= 0;
		mask_pattern <= 0;

	end
	else begin		
		find_0 <= new_find_0;
		if (new_angle_180)
			angle_180 <= 1;
		else
			angle_180 <= angle_180;
		if (new_find_1)
			find_1 <= new_find_1;
		else
			find_1 <= find_1;
		if(find_0)
			find_00 <= 1;
		else 
			find_00 <= 0;
		if(new_find_position) begin
			find_position <= new_find_position;
		end
		else
			find_position <= find_position;

		state <= new_state;
		cnt <= new_cnt;

		for(i=0; i<25; i=i+1) begin
			for(j=0; j<25; j=j+1) begin
				qr[i][j] <= n_qr[i][j];
			end
		end
		cnt_i <= new_cnt_i;
		cnt_j <= new_cnt_j;
		cnt_idx <= new_cnt_idx;
		if(qr_decode_start)
			qr_enable <= 1;
		decode_jis8_code <= n_code_out;
		find_S <= new_find_S;

		if (state == MASK_PAT) begin
			mask_pattern <= new_mask_pattern;
		end
		else if (state == DEMASK) begin
			cnt_x <= new_cnt_x;
			cnt_y <= new_cnt_y;
			if (cnt_x == 25 && cnt_y == 0) begin
				for(i=0; i<25; i=i+1)
					for(j=0; j<25; j=j+1) begin
						qr[i][j] <= qr[i][j];
						//mask[i][j] <= mask[i][j];
					end
			end
		end
		else if (state == CODEWORD) begin
			for (i = 0; i < 44; i = i + 1) begin
				codeword[i] <= mid_codeword[i];
			end
		end
		else if (state == FIND_S) begin
			value_e <= new_value_e;
			alpha_a <= new_alpha_a;
			alpha_b <= new_alpha_b;
			alpha_c <= new_alpha_c;
			alpha_d <= new_alpha_d;
			value_f <= new_value_f;
			value_g <= new_value_g;
			value_h <= new_value_h;
			alpha_i <= new_alpha_i;

			for (i = 0; i < 8; i = i + 1) begin
				S[i] <= new_S[i];
			end
			
			for (i = 0; i < 4; i = i + 1) begin
				SS[i] <= new_SS[i];
			end

			cnt_SEq <= new_cnt_SEq;
			if (cnt_SEq % 10 == 9) begin
				cnt_S <= new_cnt_S;
			end
			else 
				cnt_S <= cnt_S;

			if (cnt_SEq == 113) begin
				find_S <= new_find_S;
				for (i = 0; i < 8; i = i + 1) 
					S[i] <= S[i];
				for (i = 0; i < 4; i = i + 1)
					SS[i] <= SS[i];
			end
		end
		else if (state == FIND_SIGMA) begin
			value_e <= new_value_e;
			alpha_a <= new_alpha_a;
			alpha_b <= new_alpha_b;
			alpha_c <= new_alpha_c;
			alpha_d <= new_alpha_d;
			alpha_i <= new_alpha_i;
			value_f <= new_value_f;
			value_g <= new_value_g;
			value_h <= new_value_h;

            cnt_Eq <= new_cnt_Eq;
			for (i = 5; i < 11; i = i + 1) begin
				for (j = 0; j < 5; j = j + 1) begin
					if (new_Eq[i][j] != 0)
						Eq[i][j] <= new_Eq[i][j];
					else
						Eq[i][j] <= Eq[i][j];
				end
			end
			find_Sigma <= new_find_Sigma;
			for (i = 1; i < 5; i = i + 1)
				if (new_sigma[i] %255 == 0)
					sigma[i] <= sigma[i];
				else
					sigma[i] <= new_sigma[i];
		end
		else if (state == FIND_ERR) begin
			alpha_a <= new_alpha_a;
			alpha_b <= new_alpha_b;
			alpha_c <= new_alpha_c;
			alpha_d <= new_alpha_d;
			alpha_i <= new_alpha_i;

			err_num <= new_err_num;
			////$display("err_num = %d, cnt_ERR = %d", err_num, cnt_ERR);
			cnt_ERR <= new_cnt_ERR;
			//find_Error <= find_Error;
			for (i = 0; i < 4; i = i + 1) begin
				if (new_error_loc[i] != 0)
					error_loc[i] <= new_error_loc[i];
				else	
					error_loc[i] <= error_loc[i];
			end
				
			if (cnt_ERR == 46) begin
				find_Error <= new_find_Error;
				//$display("%d", find_Error);
				err_num <= err_num;
				for (i = 0; i < 4; i = i + 1) begin
					//$display("error_loc: %d", error_loc[i]);
					error_loc[i] <= error_loc[i];
				end
			end
			else 
				find_Error <= find_Error;
		end
		else if (state == CORRECT) begin
			value_e <= new_value_e;
			alpha_a <= new_alpha_a;
			alpha_b <= new_alpha_b;
			alpha_c <= new_alpha_c;
			alpha_d <= new_alpha_d;
			value_f <= new_value_f;
			value_g <= new_value_g;
			value_h <= new_value_h;
			
			cnt_YEq <= new_cnt_YEq;
			for (i = 5; i < 11; i = i + 1) begin
				for (j = 0; j < 5; j = j + 1) begin
					if (new_YEq[i][j] != 0)
						YEq[i][j] <= new_YEq[i][j];
					else
						YEq[i][j] <= YEq[i][j];
				end
			end
			correct_end <= new_correct_end;
			for (i = 1; i < 5; i = i + 1)
				if (new_Y[i] %255 == 0)
					Y[i] <= Y[i];
				else
					Y[i] <= new_Y[i];

			for (i = 0; i < 44; i = i + 1) 
				codeword[i] <= new_codeword[i];
		end
		else if (state == DECODE) begin
			for (i = 0; i < 44; i = i + 1)
				codeword[i] <= codeword[i];
		end
		else begin
			for (i = 0; i < 44; i = i + 1)
				codeword[i] <= 0;
			correct_end <= correct_end;
			for (i = 0; i < 8; i = i + 1) 
				S[i] <= 0;
			//find_S <= 0;
			find_Sigma <= 0;
			for (i = 1; i < 5; i = i + 1)
				sigma[i] <= sigma[i];
		end
		start_point <= new_start_point;


	end
end



//==========FSM===========//
always @* begin
	case(state)
		IDLE: begin
			if(qr_enable)
				new_state = FIND;
			else
				new_state = IDLE;
		end
		FIND: begin
			if(find_position == 1)
				new_state = POS;
			else
				new_state = FIND;
		end	
		POS: begin
			if(cnt==start_point+1600)
				new_state = ROT;
			else
				new_state = POS;
		end
		ROT: begin
			new_state = MASK_PAT;	
		end	
		MASK_PAT: begin
			new_state = DEMASK;
		end
		DEMASK: begin
			if(cnt_x == 25)
				new_state = CODEWORD;
			else
				new_state = DEMASK;
		end
		CODEWORD: begin
			new_state = FIND_S;
		end
		FIND_S: begin
		  	if (find_S)
				new_state = FIND_SIGMA;
			else	
				new_state = FIND_S;
		end
		FIND_SIGMA: begin
			if(find_Sigma) 
				new_state = FIND_ERR;
			else	
				new_state = FIND_SIGMA;
		end
		FIND_ERR: begin
		  	if (find_Error)
				new_state = CORRECT;
			else 
				new_state = FIND_ERR;
		end
        CORRECT: begin
			if (new_correct_end)
            	new_state = DECODE;
			else 
				new_state = CORRECT;
        end
		DECODE: begin
			new_state = DECODE;
		end
		default: new_state = IDLE;
	endcase
end

always @* begin
	new_cnt_idx = 0;
	// Pattern
	det_pat[0][0] = 1;det_pat[0][1] = 1; det_pat[0][2] = 1; det_pat[0][3] = 1; det_pat[0][4] = 1; det_pat[0][5] = 1; det_pat[0][6] = 1;
	det_pat[1][0] = 1;det_pat[1][1] = 0; det_pat[1][2] = 0; det_pat[1][3] = 0; det_pat[1][4] = 0; det_pat[1][5] = 0; det_pat[1][6] = 1;
	det_pat[2][0] = 1;det_pat[2][1] = 0; det_pat[2][2] = 1; det_pat[2][3] = 1; det_pat[2][4] = 1; det_pat[2][5] = 0; det_pat[2][6] = 1;
	det_pat[3][0] = 1;det_pat[3][1] = 0; det_pat[3][2] = 1; det_pat[3][3] = 1; det_pat[3][4] = 1; det_pat[3][5] = 0; det_pat[3][6] = 1;
	det_pat[4][0] = 1;det_pat[4][1] = 0; det_pat[4][2] = 1; det_pat[4][3] = 1; det_pat[4][4] = 1; det_pat[4][5] = 0; det_pat[4][6] = 1;
	det_pat[5][0] = 1;det_pat[5][1] = 0; det_pat[5][2] = 0; det_pat[5][3] = 0; det_pat[5][4] = 0; det_pat[5][5] = 0; det_pat[5][6] = 1;
	det_pat[6][0] = 1;det_pat[6][1] = 1; det_pat[6][2] = 1; det_pat[6][3] = 1; det_pat[6][4] = 1; det_pat[6][5] = 1; det_pat[6][6] = 1;
	
	if(state == POS) begin
		//$display("start = %d cnt = %d", start_point, cnt);
		new_cnt_idx = cnt_idx + 1;
		if(cnt_idx == 24)
			new_cnt_idx = 0;
	end
	else if (state == FIND) begin
		if (cnt_idx < 35)
			new_cnt_idx = cnt_idx + 7;
		else if (cnt_idx == 35)
			new_cnt_idx = cnt_idx + 4;
		else if (cnt_idx == 39 || new_find_position == 1)
			new_cnt_idx = 0;
	end
	else if(state == DECODE) begin
		new_cnt_idx = cnt_idx + 1;
	end
end

always @* begin
	sram_raddr = 0;
	new_cnt_i = 0;
	new_cnt_j = 0;
	new_start_point = start_point;
	new_find_position = 0;
	new_find_1 = 0;
	new_find_0 = 0;
	//new_find_00 = 0;
	new_cnt = 0;
	new_angle_180 = 0;
	if(state == FIND) begin
		sram_raddr = cnt;
		//$display("%d %d %d find_00 = %d find_0 = %d find_1 = %d find_position = %d", cnt, sram_rdata, cnt_idx, find_00, find_0, find_1, find_position);
		if(sram_rdata == 1 && find_1 == 0 && find_0 == 0 && find_00 == 0)begin
			//$display("%d", cnt);
			new_find_1 = 1;
			new_cnt = cnt - 1;
		end
		else if (find_1 == 1 && find_0 == 0 && find_00 == 0) begin
			//$display("find1 ctnt_idx = %d", cnt_idx);
			if (sram_rdata == 0 && find_position != 1) begin
				new_find_0 = 1;
				new_cnt= cnt + 25;
				//$display("find0");
			end
			else begin
				new_cnt = cnt - 1;
				new_find_0 = 0;
			end
		end
		else if (find_0 == 1) begin
			new_cnt = cnt;
			//new_find_00 = 1;		
		end
		else if (find_00 == 1) begin
			//$display("find_0 = %d sram_rdata = %d", find_0, sram_rdata);
			if (sram_rdata) begin
				new_find_position = 1;
				//$display("find_position");
				new_cnt = cnt - 23;
				new_start_point = cnt - 24;
			end
			else begin
				new_cnt = cnt - 26;
				new_angle_180 = 1;
			end
		end
		else begin
			if (cnt % 64 == 49)
				new_cnt = cnt + 15;
			else 
				new_cnt = cnt + 7;
		end
	end
	else if(state == POS) begin
		new_cnt = cnt + 1;
		new_cnt_j = cnt_j + 1;
		new_cnt_i = cnt_i;
		sram_raddr = cnt;
		if((cnt - start_point) % 64 ==24) begin
			new_cnt = cnt + 40;
			new_cnt_j = 0;
			new_cnt_i = cnt_i + 1;
		end
	end

end

//table//
always @* begin
	new_cnt_y = cnt_y;
	new_cnt_x = cnt_x;
	a = 0;
	for(i=0; i<25; i=i+1) begin
		for(j=0; j<25; j=j+1) begin
			n_qr[i][j] = qr[i][j];
		end			
	end
	if(state == FIND) begin
	end	
	else if(state == POS) begin		
		n_qr[cnt_i][cnt_j] = sram_rdata;
	end
	else if(state == ROT) begin
		pat = 0;
		for (i = 0; i < 7; i = i + 1) begin
			for(j = 0; j < 7; j = j + 1) begin
				if (qr[i+18][j+18] != det_pat[i][j])
					pat = 0;
				else if (qr[i][j+18] != det_pat[i][j])
					pat = 1;
				else if (qr[i][j] != det_pat[i][j])
					pat = 2;
				else if (qr[i+18][j] != det_pat[i][j])
					pat = 3;
				
			end
			
		end
		case(pat)
			0: begin
				for (i = 0; i < 25; i = i + 1) begin
					for (j = 0; j < 25; j = j + 1) begin
						n_qr[i][j] = qr[i][j]; 
					end
				end
			end
			1: begin
				for (i = 0; i < 25; i = i + 1) begin
				    for (j = 0; j < 25; j = j + 1) begin
						n_qr[i][j] = qr[24-j][i];
					end 
				end
			end
			2: begin
				for (i = 0; i < 25; i = i + 1) begin
				    for (j = 0; j < 25; j = j + 1) begin
						n_qr[i][j] = qr[24 - i][24 - j];
					end 
				end
			end
			3: begin
				for (i = 0; i < 25; i = i + 1) begin
				    for (j = 0; j < 25; j = j + 1) begin
						n_qr[i][j] = qr[j][24 - i];
					end 
				end
			end
			default: begin
				for (i = 0; i < 25; i = i + 1) begin
				    for (j = 0; j < 25; j = j + 1) begin
						n_qr[i][j] = qr[i][j];
					end 
				end
			end
		endcase
	end

	else if(state == DEMASK) begin
		case (mask_pattern) //synopsys parallel_case
			0: begin 
				for (j = 0; j < 5; j = j + 1) begin
					a = (cnt_x + cnt_y + j) % 2 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			1: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = cnt_x % 2 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			2: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = (cnt_y + j) % 3 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			3: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = (cnt_x + cnt_y + j) % 3 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			4: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = (cnt_x / 2 + (cnt_y + j) / 3) % 2 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			5: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = ((cnt_x * (cnt_y + j)) % 2 + (cnt_x * (cnt_y + j)) % 3) == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end	
			6: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = (((cnt_x * (cnt_y + j)) % 2 + (cnt_x * (cnt_y + j)) %3)) %2 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
			7: begin
				for (j = 0; j < 5; j = j + 1) begin
					a = (((cnt_x * (cnt_y + j)) % 3 + (cnt_x + (cnt_y + j)) % 2)) %2 == 0 ? 1 : 0;
					n_qr[new_cnt_x][new_cnt_y + j] = qr[cnt_x][cnt_y + j] ^ a;
				end
			end
		endcase
		if (cnt_y == 20) begin
			new_cnt_x = cnt_x + 1;
			new_cnt_y = 0;
		end
		else begin
			new_cnt_x = cnt_x;
			new_cnt_y = cnt_y + 5;
		end

	end
end

//DEMASK
always @* begin
	new_mask_pattern = 0;
	if (state == MASK_PAT) begin
		new_mask_pattern = {qr[8][2],qr[8][3],qr[8][4]} ^ 3'b101;
		/*case(mask_pattern)
			3'b000: begin
				for(i = 0; i < 25; i=i+1) begin
					for(j = 0; j < 25; j=j+1) begin
						if((i+j)%2 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b001: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if(i%2 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b010: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if(j%3 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b011: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if((i+j)%3 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b100: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if((i/2+j/3)%2 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b101: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if(((i*j)%2 + (i*j)%3) == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b110: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if((((i*j)%2 + (i*j)%3))%2 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
			3'b111: begin
				for(i=0; i<25; i=i+1) begin
					for(j=0; j<25; j=j+1) begin
						if((((i*j)%3 + (i+j)%2))%2 == 0) begin
							n_mask[i][j] = 1;
						end
						else begin
							n_mask[i][j] = 0;											
						end
					end
				end
			end
		endcase
		*/	
	end
end

//DECODE
always @* begin
    text_length = 0;
	n_code_out = 0;
	if(state == DECODE) begin
		text_length = {codeword[0][3:0], codeword[1][7:4]};
		n_code_out = {codeword[cnt_idx+1][3:0], codeword[cnt_idx+2][7:4]};
	end
end

always @* begin
	if(state == DECODE) begin
		if(cnt_idx > 0 && cnt_idx < text_length + 1) begin
			decode_valid = 1;
			qr_decode_finish = 0;
		end
		else if(cnt_idx >= text_length + 1) begin
			decode_valid = 0;
			qr_decode_finish = 1;
		end
		else begin
			decode_valid = 0;
			qr_decode_finish = 0;
		end
	end
    else begin
		decode_valid = 0;
		qr_decode_finish = 0;
	end
end


//Codeword preparation
always @* begin
	for (i = 0; i < 44; i = i + 1)
		mid_codeword[i] = 0;
	if(state==CODEWORD) begin
		mid_codeword[0][0] = qr[21][23];
		mid_codeword[0][1] = qr[21][24];
		mid_codeword[0][2] = qr[22][23];
		mid_codeword[0][3] = qr[22][24];
		mid_codeword[0][4] = qr[23][23];
		mid_codeword[0][5] = qr[23][24];
		mid_codeword[0][6] = qr[24][23];
		mid_codeword[0][7] = qr[24][24];

		mid_codeword[1][0] = qr[17][23];
		mid_codeword[1][1] = qr[17][24];
		mid_codeword[1][2] = qr[18][23];
		mid_codeword[1][3] = qr[18][24];
		mid_codeword[1][4] = qr[19][23];
		mid_codeword[1][5] = qr[19][24];
		mid_codeword[1][6] = qr[20][23];
		mid_codeword[1][7] = qr[20][24];

		mid_codeword[2][0] = qr[13][23];
		mid_codeword[2][1] = qr[13][24];
		mid_codeword[2][2] = qr[14][23];
		mid_codeword[2][3] = qr[14][24];
		mid_codeword[2][4] = qr[15][23];
		mid_codeword[2][5] = qr[15][24];
		mid_codeword[2][6] = qr[16][23];
		mid_codeword[2][7] = qr[16][24];

		mid_codeword[3][0] = qr[9][23];
		mid_codeword[3][1] = qr[9][24];
		mid_codeword[3][2] = qr[10][23];
		mid_codeword[3][3] = qr[10][24];
		mid_codeword[3][4] = qr[11][23];
		mid_codeword[3][5] = qr[11][24];
		mid_codeword[3][6] = qr[12][23];
		mid_codeword[3][7] = qr[12][24];

		mid_codeword[4][0] = qr[12][21];
		mid_codeword[4][1] = qr[12][22];
		mid_codeword[4][2] = qr[11][21];
		mid_codeword[4][3] = qr[11][22];
		mid_codeword[4][4] = qr[10][21];
		mid_codeword[4][5] = qr[10][22];
		mid_codeword[4][6] = qr[9][21];
		mid_codeword[4][7] = qr[9][22];

		mid_codeword[5][0] = qr[16][21];
		mid_codeword[5][1] = qr[16][22];
		mid_codeword[5][2] = qr[15][21];
		mid_codeword[5][3] = qr[15][22];
		mid_codeword[5][4] = qr[14][21];
		mid_codeword[5][5] = qr[14][22];
		mid_codeword[5][6] = qr[13][21];
		mid_codeword[5][7] = qr[13][22];

		mid_codeword[6][0] = qr[20][21];
		mid_codeword[6][1] = qr[20][22];
		mid_codeword[6][2] = qr[19][21];
		mid_codeword[6][3] = qr[19][22];
		mid_codeword[6][4] = qr[18][21];
		mid_codeword[6][5] = qr[18][22];
		mid_codeword[6][6] = qr[17][21];
		mid_codeword[6][7] = qr[17][22];

		mid_codeword[7][0] = qr[24][21];
		mid_codeword[7][1] = qr[24][22];
		mid_codeword[7][2] = qr[23][21];
		mid_codeword[7][3] = qr[23][22];
		mid_codeword[7][4] = qr[22][21];
		mid_codeword[7][5] = qr[22][22];
		mid_codeword[7][6] = qr[21][21];
		mid_codeword[7][7] = qr[21][22];

		mid_codeword[8][0] = qr[21][19];
		mid_codeword[8][1] = qr[21][20];
		mid_codeword[8][2] = qr[22][19];
		mid_codeword[8][3] = qr[22][20];
		mid_codeword[8][4] = qr[23][19];
		mid_codeword[8][5] = qr[23][20];
		mid_codeword[8][6] = qr[24][19];
		mid_codeword[8][7] = qr[24][20];

		mid_codeword[9][0] = qr[12][19];
		mid_codeword[9][1] = qr[12][20];
		mid_codeword[9][2] = qr[13][19];
		mid_codeword[9][3] = qr[13][20];
		mid_codeword[9][4] = qr[14][19];
		mid_codeword[9][5] = qr[14][20];
		mid_codeword[9][6] = qr[15][19];
		mid_codeword[9][7] = qr[15][20];

		mid_codeword[10][0] = qr[9][17];
		mid_codeword[10][1] = qr[9][18];
		mid_codeword[10][2] = qr[9][19];
		mid_codeword[10][3] = qr[9][20];
		mid_codeword[10][4] = qr[10][19];
		mid_codeword[10][5] = qr[10][20];
		mid_codeword[10][6] = qr[11][19];
		mid_codeword[10][7] = qr[11][20];

		mid_codeword[11][0] = qr[13][17];
		mid_codeword[11][1] = qr[13][18];
		mid_codeword[11][2] = qr[12][17];
		mid_codeword[11][3] = qr[12][18];
		mid_codeword[11][4] = qr[11][17];
		mid_codeword[11][5] = qr[11][18];
		mid_codeword[11][6] = qr[10][17];
		mid_codeword[11][7] = qr[10][18];

		mid_codeword[12][0] = qr[22][17];
		mid_codeword[12][1] = qr[22][18];
		mid_codeword[12][2] = qr[21][17];
		mid_codeword[12][3] = qr[21][18];
		mid_codeword[12][4] = qr[15][17];
		mid_codeword[12][5] = qr[15][18];
		mid_codeword[12][6] = qr[14][17];
		mid_codeword[12][7] = qr[14][18];

		mid_codeword[13][0] = qr[23][15];
		mid_codeword[13][1] = qr[23][16];
		mid_codeword[13][2] = qr[24][15];
		mid_codeword[13][3] = qr[24][16];
		mid_codeword[13][4] = qr[24][17];
		mid_codeword[13][5] = qr[24][18];
		mid_codeword[13][6] = qr[23][17];
		mid_codeword[13][7] = qr[23][18];

		mid_codeword[14][0] = qr[17][15];
		mid_codeword[14][1] = qr[18][15];
		mid_codeword[14][2] = qr[19][15];
		mid_codeword[14][3] = qr[20][15];
		mid_codeword[14][4] = qr[21][15];
		mid_codeword[14][5] = qr[21][16];
		mid_codeword[14][6] = qr[22][15];
		mid_codeword[14][7] = qr[22][16];

		mid_codeword[15][0] = qr[12][16];
		mid_codeword[15][1] = qr[13][15];
		mid_codeword[15][2] = qr[13][16];
		mid_codeword[15][3] = qr[14][15];
		mid_codeword[15][4] = qr[14][16];
		mid_codeword[15][5] = qr[15][15];
		mid_codeword[15][6] = qr[15][16];
		mid_codeword[15][7] = qr[16][15];

		mid_codeword[16][0] = qr[8][16];
		mid_codeword[16][1] = qr[9][15];
		mid_codeword[16][2] = qr[9][16];
		mid_codeword[16][3] = qr[10][15];
		mid_codeword[16][4] = qr[10][16];
		mid_codeword[16][5] = qr[11][15];
		mid_codeword[16][6] = qr[11][16];
		mid_codeword[16][7] = qr[12][15];

		mid_codeword[17][0] = qr[3][16];
		mid_codeword[17][1] = qr[4][15];
		mid_codeword[17][2] = qr[4][16];
		mid_codeword[17][3] = qr[5][15];
		mid_codeword[17][4] = qr[5][16];
		mid_codeword[17][5] = qr[7][15];
		mid_codeword[17][6] = qr[7][16];
		mid_codeword[17][7] = qr[8][15];

		mid_codeword[18][0] = qr[0][14];
		mid_codeword[18][1] = qr[0][15];
		mid_codeword[18][2] = qr[0][16];
		mid_codeword[18][3] = qr[1][15];
		mid_codeword[18][4] = qr[1][16];
		mid_codeword[18][5] = qr[2][15];
		mid_codeword[18][6] = qr[2][16];
		mid_codeword[18][7] = qr[3][15];

		mid_codeword[19][0] = qr[4][14];
		mid_codeword[19][1] = qr[3][13];
		mid_codeword[19][2] = qr[3][14];
		mid_codeword[19][3] = qr[2][13];
		mid_codeword[19][4] = qr[2][14];
		mid_codeword[19][5] = qr[1][13];
		mid_codeword[19][6] = qr[1][14];
		mid_codeword[19][7] = qr[0][13];

		mid_codeword[20][0] = qr[9][14];
		mid_codeword[20][1] = qr[8][13];
		mid_codeword[20][2] = qr[8][14];
		mid_codeword[20][3] = qr[7][13];
		mid_codeword[20][4] = qr[7][14];
		mid_codeword[20][5] = qr[5][13];
		mid_codeword[20][6] = qr[5][14];
		mid_codeword[20][7] = qr[4][13];

		mid_codeword[21][0] = qr[13][14];
		mid_codeword[21][1] = qr[12][13];
		mid_codeword[21][2] = qr[12][14];
		mid_codeword[21][3] = qr[11][13];
		mid_codeword[21][4] = qr[11][14];
		mid_codeword[21][5] = qr[10][13];
		mid_codeword[21][6] = qr[10][14];
		mid_codeword[21][7] = qr[9][13];

		mid_codeword[22][0] = qr[17][14];
		mid_codeword[22][1] = qr[16][13];
		mid_codeword[22][2] = qr[16][14];
		mid_codeword[22][3] = qr[15][13];
		mid_codeword[22][4] = qr[15][14];
		mid_codeword[22][5] = qr[14][13];
		mid_codeword[22][6] = qr[14][14];
		mid_codeword[22][7] = qr[13][13];

		mid_codeword[23][0] = qr[21][14];
		mid_codeword[23][1] = qr[20][13];
		mid_codeword[23][2] = qr[20][14];
		mid_codeword[23][3] = qr[19][13];
		mid_codeword[23][4] = qr[19][14];
		mid_codeword[23][5] = qr[18][13];
		mid_codeword[23][6] = qr[18][14];
		mid_codeword[23][7] = qr[17][13];

		mid_codeword[24][0] = qr[24][12];
		mid_codeword[24][1] = qr[24][13];
		mid_codeword[24][2] = qr[24][14];
		mid_codeword[24][3] = qr[23][13];
		mid_codeword[24][4] = qr[23][14];
		mid_codeword[24][5] = qr[22][13];
		mid_codeword[24][6] = qr[22][14];
		mid_codeword[24][7] = qr[21][13];

		mid_codeword[25][0] = qr[20][12];
		mid_codeword[25][1] = qr[21][11];
		mid_codeword[25][2] = qr[21][12];
		mid_codeword[25][3] = qr[22][11];
		mid_codeword[25][4] = qr[22][12];
		mid_codeword[25][5] = qr[23][11];
		mid_codeword[25][6] = qr[23][12];
		mid_codeword[25][7] = qr[24][11];

		mid_codeword[26][0] = qr[16][12];
		mid_codeword[26][1] = qr[17][11];
		mid_codeword[26][2] = qr[17][12];
		mid_codeword[26][3] = qr[18][11];
		mid_codeword[26][4] = qr[18][12];
		mid_codeword[26][5] = qr[19][11];
		mid_codeword[26][6] = qr[19][12];
		mid_codeword[26][7] = qr[20][11];

		mid_codeword[27][0] = qr[12][12];
		mid_codeword[27][1] = qr[13][11];
		mid_codeword[27][2] = qr[13][12];
		mid_codeword[27][3] = qr[14][11];
		mid_codeword[27][4] = qr[14][12];
		mid_codeword[27][5] = qr[15][11];
		mid_codeword[27][6] = qr[15][12];
		mid_codeword[27][7] = qr[16][11];

		mid_codeword[28][0] = qr[8][12];
		mid_codeword[28][1] = qr[9][11];
		mid_codeword[28][2] = qr[9][12];
		mid_codeword[28][3] = qr[10][11];
		mid_codeword[28][4] = qr[10][12];
		mid_codeword[28][5] = qr[11][11];
		mid_codeword[28][6] = qr[11][12];
		mid_codeword[28][7] = qr[12][11];

		mid_codeword[29][0] = qr[3][12];
		mid_codeword[29][1] = qr[4][11];
		mid_codeword[29][2] = qr[4][12];
		mid_codeword[29][3] = qr[5][11];
		mid_codeword[29][4] = qr[5][12];
		mid_codeword[29][5] = qr[7][11];
		mid_codeword[29][6] = qr[7][12];
		mid_codeword[29][7] = qr[8][11];

		mid_codeword[30][0] = qr[0][10];
		mid_codeword[30][1] = qr[0][11];
		mid_codeword[30][2] = qr[0][12];
		mid_codeword[30][3] = qr[1][11];
		mid_codeword[30][4] = qr[1][12];
		mid_codeword[30][5] = qr[2][11];
		mid_codeword[30][6] = qr[2][12];
		mid_codeword[30][7] = qr[3][11];

		mid_codeword[31][0] = qr[4][10];
		mid_codeword[31][1] = qr[3][9];
		mid_codeword[31][2] = qr[3][10];
		mid_codeword[31][3] = qr[2][9];
		mid_codeword[31][4] = qr[2][10];
		mid_codeword[31][5] = qr[1][9];
		mid_codeword[31][6] = qr[1][10];
		mid_codeword[31][7] = qr[0][9];

		mid_codeword[32][0] = qr[9][10];
		mid_codeword[32][1] = qr[8][9];
		mid_codeword[32][2] = qr[8][10];
		mid_codeword[32][3] = qr[7][9];
		mid_codeword[32][4] = qr[7][10];
		mid_codeword[32][5] = qr[5][9];
		mid_codeword[32][6] = qr[5][10];
		mid_codeword[32][7] = qr[4][9];

		mid_codeword[33][0] = qr[13][10];
		mid_codeword[33][1] = qr[12][9];
		mid_codeword[33][2] = qr[12][10];
		mid_codeword[33][3] = qr[11][9];
		mid_codeword[33][4] = qr[11][10];
		mid_codeword[33][5] = qr[10][9];
		mid_codeword[33][6] = qr[10][10];
		mid_codeword[33][7] = qr[9][9];

		mid_codeword[34][0] = qr[17][10];
		mid_codeword[34][1] = qr[16][9];
		mid_codeword[34][2] = qr[16][10];
		mid_codeword[34][3] = qr[15][9];
		mid_codeword[34][4] = qr[15][10];
		mid_codeword[34][5] = qr[14][9];
		mid_codeword[34][6] = qr[14][10];
		mid_codeword[34][7] = qr[13][9];

		mid_codeword[35][0] = qr[21][10];
		mid_codeword[35][1] = qr[20][9];
		mid_codeword[35][2] = qr[20][10];
		mid_codeword[35][3] = qr[19][9];
		mid_codeword[35][4] = qr[19][10];
		mid_codeword[35][5] = qr[18][9];
		mid_codeword[35][6] = qr[18][10];
		mid_codeword[35][7] = qr[17][9];

		mid_codeword[36][0] = qr[16][8];
		mid_codeword[36][1] = qr[24][9];
		mid_codeword[36][2] = qr[24][10];
		mid_codeword[36][3] = qr[23][9];
		mid_codeword[36][4] = qr[23][10];
		mid_codeword[36][5] = qr[22][9];
		mid_codeword[36][6] = qr[22][10];
		mid_codeword[36][7] = qr[21][9];

		mid_codeword[37][0] = qr[12][8];
		mid_codeword[37][1] = qr[13][7];
		mid_codeword[37][2] = qr[13][8];
		mid_codeword[37][3] = qr[14][7];
		mid_codeword[37][4] = qr[14][8];
		mid_codeword[37][5] = qr[15][7];
		mid_codeword[37][6] = qr[15][8];
		mid_codeword[37][7] = qr[16][7];

		mid_codeword[38][0] = qr[9][5];
		mid_codeword[38][1] = qr[9][7];
		mid_codeword[38][2] = qr[9][8];
		mid_codeword[38][3] = qr[10][7];
		mid_codeword[38][4] = qr[10][8];
		mid_codeword[38][5] = qr[11][7];
		mid_codeword[38][6] = qr[11][8];
		mid_codeword[38][7] = qr[12][7];

		mid_codeword[39][0] = qr[13][5];
		mid_codeword[39][1] = qr[12][4];
		mid_codeword[39][2] = qr[12][5];
		mid_codeword[39][3] = qr[11][4];
		mid_codeword[39][4] = qr[11][5];
		mid_codeword[39][5] = qr[10][4];
		mid_codeword[39][6] = qr[10][5];
		mid_codeword[39][7] = qr[9][4];

		mid_codeword[40][0] = qr[16][3];
		mid_codeword[40][1] = qr[16][4];
		mid_codeword[40][2] = qr[16][5];
		mid_codeword[40][3] = qr[15][4];
		mid_codeword[40][4] = qr[15][5];
		mid_codeword[40][5] = qr[14][4];
		mid_codeword[40][6] = qr[14][5];
		mid_codeword[40][7] = qr[13][4];

		mid_codeword[41][0] = qr[12][3];
		mid_codeword[41][1] = qr[13][2];
		mid_codeword[41][2] = qr[13][3];
		mid_codeword[41][3] = qr[14][2];
		mid_codeword[41][4] = qr[14][3];
		mid_codeword[41][5] = qr[15][2];
		mid_codeword[41][6] = qr[15][3];
		mid_codeword[41][7] = qr[16][2];

		mid_codeword[42][0] = qr[9][1];
		mid_codeword[42][1] = qr[9][2];
		mid_codeword[42][2] = qr[9][3];
		mid_codeword[42][3] = qr[10][2];
		mid_codeword[42][4] = qr[10][3];
		mid_codeword[42][5] = qr[11][2];
		mid_codeword[42][6] = qr[11][3];
		mid_codeword[42][7] = qr[12][2];

		mid_codeword[43][0] = qr[13][1];
		mid_codeword[43][1] = qr[12][0];
		mid_codeword[43][2] = qr[12][1];
		mid_codeword[43][3] = qr[11][0];
		mid_codeword[43][4] = qr[11][1];
		mid_codeword[43][5] = qr[10][0];
		mid_codeword[43][6] = qr[10][1];
		mid_codeword[43][7] = qr[9][0];
	end
end

// Error correction
always @* begin
	for (i = 5; i < 11; i = i + 1) begin
		for (j = 0; j < 5; j = j + 1) begin
			new_YEq[i][j] = 0;
			new_Eq[i][j] = 0;
		end
	end

	for (i = 0; i < 4; i = i + 1)
		new_SS[i] = SS[i];

	for (i = 0; i < 44; i = i + 1)
		new_codeword[i] = codeword[i];

	new_correct_end = 0;
	new_find_S = 0;
	for (i = 0; i < 8; i = i + 1) begin
        new_S[i] = S[i];
    end
	new_find_Sigma = 0;
	for (i = 1; i < 5; i = i + 1)begin
		new_sigma[i] = 0;
		new_Y[i] = 0;
	end

	new_cnt_S = cnt_S;
	for (i = 0; i < 4; i = i + 1) begin
		new_error_loc[i] = 0;
		//Y[i + 1] = 0;
	end
	new_err_num = 0;
	new_cnt_ERR = 0;
	new_find_Error = 1;
    new_cnt_Eq = 0;
	new_cnt_YEq = 0;

	new_alpha_a = alpha_a;
	new_alpha_b = alpha_b;
	new_alpha_c = alpha_c;
	new_alpha_d = alpha_d;
	new_alpha_i = alpha_i;
	new_value_f = value_f;
	new_value_e = value_e;
	new_value_g = value_g;
	new_value_h = value_h;




	new_cnt_SEq = 0;
    if (state == FIND_S) begin
		if (cnt_SEq < 110) begin
			case(cnt_SEq % 10)
				0: begin
					new_value_e = codeword[cnt_S];
					new_value_f = codeword[cnt_S + 1];
					new_value_g = codeword[cnt_S + 2];
					new_value_h = codeword[cnt_S + 3];
					////$display("S[0] = %d a = %d b = %d c = %d d = %d", new_S[0], cnt_S, cnt_S + 1, cnt_S + 2, cnt_S + 3);
				end
				1: begin
					new_alpha_a = alpha_e;
					new_alpha_b = alpha_f;
					new_alpha_c = alpha_g;
					new_alpha_d = alpha_h;
				end
				2: begin
					new_S[0] = S[0] ^ value_a ^ value_b ^ value_c ^ value_d;
					
					new_alpha_a = (alpha_e + 43 - cnt_S) % 255;
					new_alpha_b = (alpha_f + 42 - cnt_S) % 255;
					new_alpha_c = (alpha_g + 41 - cnt_S) % 255;
					new_alpha_d = (alpha_h + 40 - cnt_S) % 255;
				end
				3: begin
					new_S[1] = S[1] ^ value_a ^ value_b ^ value_c ^ value_d;
					//$display("S[1] = %d , new_S[1] = %d", S[1],new_S[1]);
					new_alpha_a = (alpha_e + 86 - 2 * cnt_S) % 255;
					new_alpha_b = (alpha_f + 84 - 2 * cnt_S) % 255;
					new_alpha_c = (alpha_g + 82 - 2 * cnt_S) % 255;
					new_alpha_d = (alpha_h + 80 - 2 * cnt_S) % 255;
				end
				4: begin
					new_S[2] = S[2] ^ value_a ^ value_b ^ value_c ^ value_d;
					////$display("alpha_4 = %d", alpha_e);
					new_alpha_a = (alpha_e + 129 - 3 * cnt_S) % 255;
					new_alpha_b = (alpha_f + 126 - 3 * cnt_S) % 255;
					new_alpha_c = (alpha_g + 123 - 3 * cnt_S) % 255;
					new_alpha_d = (alpha_h + 120 - 3 * cnt_S) % 255;
				end
				5: begin
					new_S[3] = S[3] ^ value_a ^ value_b ^ value_c ^ value_d;
					new_alpha_a = (alpha_e + 172 - 4 * cnt_S) % 255;
					new_alpha_b = (alpha_f + 168 - 4 * cnt_S) % 255;
					new_alpha_c = (alpha_g + 164 - 4 * cnt_S) % 255;
					new_alpha_d = (alpha_h + 160 - 4 * cnt_S) % 255;
				end
				6: begin
					new_S[4] = S[4] ^ value_a ^ value_b ^ value_c ^ value_d;
					new_alpha_a = (alpha_e + 215 - 5 * cnt_S) % 255;
					new_alpha_b = (alpha_f + 210 - 5 * cnt_S) % 255;
					new_alpha_c = (alpha_g + 205 - 5 * cnt_S) % 255;
					new_alpha_d = (alpha_h + 200 - 5 * cnt_S) % 255;
				end
				7: begin
					new_S[5] = S[5] ^ value_a ^ value_b ^ value_c ^ value_d;
					if(cnt_S == 0) begin
						new_alpha_a = (alpha_e + 3) % 255;
						new_alpha_b = (alpha_f + 252) % 255;
						new_alpha_c = (alpha_g + 246) % 255;
						new_alpha_d = (alpha_h + 240) % 255;
					end
					else begin
						new_alpha_a = (alpha_e + 258 - 6 * cnt_S) % 255;
						new_alpha_b = (alpha_f + 252 - 6 * cnt_S) % 255;
						new_alpha_c = (alpha_g + 246 - 6 * cnt_S) % 255;
						new_alpha_d = (alpha_h + 240 - 6 * cnt_S) % 255;
					end
				end
				8: begin
					new_S[6] = S[6] ^ value_a ^ value_b ^ value_c ^ value_d;
					if (cnt_S == 0) begin
						new_alpha_a = (alpha_e + 46) % 255;
						new_alpha_b = (alpha_f + 39) % 255;
						new_alpha_c = (alpha_g + 32) % 255;
						new_alpha_d = (alpha_h + 25) % 255;
					end
					else if (cnt_S < 8) begin
						new_alpha_a = (alpha_e + 18) % 255;
						new_alpha_b = (alpha_f + 11) % 255;
						new_alpha_c = (alpha_g + 4) % 255;
						new_alpha_d = (alpha_h + 252) % 255;
					end
					else begin
						new_alpha_a = (alpha_e + 301 - 7 * cnt_S) % 255;
						new_alpha_b = (alpha_f + 294 - 7 * cnt_S) % 255;
						new_alpha_c = (alpha_g + 287 - 7 * cnt_S) % 255;
						new_alpha_d = (alpha_h + 280 - 7 * cnt_S) % 255;
					end
				end
				9: begin
					new_S[7] = S[7] ^ value_a ^ value_b ^ value_c ^ value_d;
					new_cnt_S = cnt_S + 4;
					//$display("%d %d %d", new_cnt_S, cnt_SEq, S[1]);
				end
				default: new_cnt_S = cnt_S;
			endcase
		end
		
		else if (cnt_SEq == 110) begin
        	//for (i = 0; i < 8; i = i + 1) begin
            	//new_S[i] = Value_table[S[i]];
				////$display("%d", new_S[i]);
        	//end
			new_value_e = S[0];
			new_value_f = S[1];
			new_value_g = S[2];
			new_value_h = S[3];
		end	
		else if (cnt_SEq == 111) begin
			new_S[0] = alpha_e;
			new_S[1] = alpha_f;
			new_S[2] = alpha_g;
			new_S[3] = alpha_h;
			new_SS[0] = new_S[0]; new_SS[1] = new_S[1]; new_SS[2] = new_S[2]; new_SS[3] = new_S[3];
			new_value_e = S[4];
			new_value_f = S[5];
			new_value_g = S[6];
			new_value_h = S[7];
		end
		else if (cnt_SEq == 112) begin
			new_S[4] = alpha_e;
			new_S[5] = alpha_f;
			new_S[6] = alpha_g;
			new_S[7] = alpha_h;
			new_cnt_SEq = cnt_SEq + 1;
			new_find_S = 1;
		end
		new_cnt_SEq = cnt_SEq + 1;
	end
	else if (state == FIND_SIGMA) begin
		    Eq[1][0] = S[4]; Eq[1][1] = S[3]; Eq[1][2] = S[2]; Eq[1][3] = S[1]; Eq[1][4] = S[0];
			Eq[2][0] = S[5]; Eq[2][1] = S[4]; Eq[2][2] = S[3]; Eq[2][3] = S[2]; Eq[2][4] = S[1];
			Eq[3][0] = S[6]; Eq[3][1] = S[5]; Eq[3][2] = S[4]; Eq[3][3] = S[3]; Eq[3][4] = S[2];
			Eq[4][0] = S[7]; Eq[4][1] = S[6]; Eq[4][2] = S[5]; Eq[4][3] = S[4]; Eq[4][4] = S[3];
        case (cnt_Eq)
            0: begin
                if (Eq[2][4] > Eq[1][4]) begin
                    new_alpha_a = (Eq[1][0] + Eq[2][4] - Eq[1][4]) % 255;
					new_alpha_b = Eq[2][0];
					new_alpha_c = (Eq[1][1] + Eq[2][4] - Eq[1][4]) % 255;
					new_alpha_d = Eq[2][1];
                end
                else begin
                    new_alpha_a = (Eq[2][0] + Eq[1][4] - Eq[2][4]) % 255;
					new_alpha_b = Eq[1][0];
					new_alpha_c = (Eq[2][1] + Eq[1][4] - Eq[2][4]) % 255;
					new_alpha_d = Eq[1][1];
                end
            end
            1: begin
				new_value_e = value_a ^ value_b;
				////$display("value_a = %d, alpha_a = %d", value_a, new_alpha_a);
				new_value_f = value_c ^ value_d;
			end
			2: begin
				new_Eq[5][0] = alpha_e;
				
				new_Eq[5][1] = alpha_f;
				if (Eq[2][4] > Eq[1][4]) begin
                    new_alpha_a = (Eq[1][2] + Eq[2][4] - Eq[1][4]) % 255;
					new_alpha_b = Eq[2][2];
					new_alpha_c = (Eq[1][3] + Eq[2][4] - Eq[1][4]) % 255;
					new_alpha_d = Eq[2][3];
                end
                else begin
                    new_alpha_a = (Eq[2][2] + Eq[1][4] - Eq[2][4]) % 255;
					new_alpha_b = Eq[1][2];
					new_alpha_c = (Eq[2][3] + Eq[1][4] - Eq[2][4]) % 255;
					new_alpha_d = Eq[1][3];
                end
			end
			3: begin
				
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
			4: begin
			////$display("new_value_e = %d", Eq[5][0]);
				new_Eq[5][2] = alpha_e;
				new_Eq[5][3] = alpha_f;
                if (Eq[3][4] > Eq[2][4]) begin
                    new_alpha_a = (Eq[2][0] + Eq[3][4] - Eq[2][4]) % 255;
					new_alpha_b = Eq[3][0];
					new_alpha_c = (Eq[2][1] + Eq[3][4] - Eq[2][4]) % 255;
					new_alpha_d = Eq[3][1];
                end
                else begin
					new_alpha_a = (Eq[3][0] + Eq[2][4] - Eq[3][4]) % 255;
					new_alpha_b = Eq[2][0];
					new_alpha_c = (Eq[3][1] + Eq[2][4] - Eq[3][4]) % 255;
					new_alpha_d = Eq[2][1];
                end
            end
            5: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
			6: begin
				new_Eq[6][0] = alpha_e;
				new_Eq[6][1] = alpha_f;
				////$display("Eq[6][0] = %d", alpha_e);
                if (Eq[3][4] > Eq[2][4]) begin
                    new_alpha_a = (Eq[2][2] + Eq[3][4] - Eq[2][4]) % 255;
					new_alpha_b = Eq[3][2];
					new_alpha_c = (Eq[2][3] + Eq[3][4] - Eq[2][4]) % 255;
					new_alpha_d = Eq[3][3];
                end
                else begin
					new_alpha_a = (Eq[3][2] + Eq[2][4] - Eq[3][4]) % 255;
					new_alpha_b = Eq[2][2];
					new_alpha_c = (Eq[3][3] + Eq[2][4] - Eq[3][4]) % 255;
					new_alpha_d = Eq[2][3];
                end
			end
			7: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
			8: begin
				new_Eq[6][2] = alpha_e;
				new_Eq[6][3] = alpha_f;
                if (Eq[4][4] > Eq[3][4]) begin
					new_alpha_a = (Eq[3][0] + Eq[4][4] - Eq[3][4]) % 255;
					new_alpha_b = Eq[4][0];
					new_alpha_c = (Eq[3][1] + Eq[4][4] - Eq[3][4]) % 255;
					new_alpha_d = Eq[4][1];
                end
                else begin
					new_alpha_a = (Eq[4][0] + Eq[3][4] - Eq[4][4]) % 255;
					new_alpha_b = Eq[3][0];
					new_alpha_c = (Eq[4][1] + Eq[3][4] - Eq[4][4]) % 255;
					new_alpha_d = Eq[3][1];
                end
            end
			9: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
            10: begin
				new_Eq[7][0] = alpha_e;
				new_Eq[7][1] = alpha_f;
                if (Eq[4][4] > Eq[3][4]) begin
					new_alpha_a = (Eq[3][2] + Eq[4][4] - Eq[3][4]) % 255;
					new_alpha_b = Eq[4][2];
					new_alpha_c = (Eq[3][3] + Eq[4][4] - Eq[3][4]) % 255;
					new_alpha_d = Eq[4][3];
                end
                else begin
					new_alpha_a = (Eq[4][2] + Eq[3][4] - Eq[4][4]) % 255;
					new_alpha_b = Eq[3][2];
					new_alpha_c = (Eq[4][3] + Eq[3][4] - Eq[4][4]) % 255;
					new_alpha_d = Eq[3][3];
                end			
			end
			11: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
			12: begin
				new_Eq[7][2] = alpha_e;
				new_Eq[7][3] = alpha_f;
                if (Eq[6][3] > Eq[5][3]) begin
					new_alpha_a = (Eq[5][0] + Eq[6][3] - Eq[5][3]) % 255;
					new_alpha_b = Eq[6][0];
					new_alpha_c = (Eq[5][1] + Eq[6][3] - Eq[5][3]) % 255;
					new_alpha_d = Eq[6][1];
                end
                else begin 
					new_alpha_a = (Eq[6][0] + Eq[5][3] - Eq[6][3]) % 255;
					new_alpha_b = Eq[5][0];
					new_alpha_c = (Eq[6][1] + Eq[5][3] - Eq[6][3]) % 255;
					new_alpha_d = Eq[5][1];
                end
            end
			13: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
			14: begin
				new_Eq[8][0] = alpha_e;
				new_Eq[8][1] = alpha_f;
                if (Eq[6][3] > Eq[5][3]) begin
					new_alpha_a = (Eq[5][2] + Eq[6][3] - Eq[5][3]) % 255;
					new_alpha_b = Eq[6][2];
                end
                else begin
					new_alpha_a = (Eq[6][2] + Eq[5][3] - Eq[6][3]) % 255;
					new_alpha_b = Eq[5][2];
                end

				if (Eq[7][3] > Eq[6][3]) begin
					new_alpha_c = (Eq[6][0] + Eq[7][3] - Eq[6][3]) % 255;
					new_alpha_d = Eq[7][0];
				end
				else begin
					new_alpha_c = (Eq[7][0] + Eq[6][3] - Eq[7][3]) % 255;
					new_alpha_d = Eq[6][0];
				end
			end
			15: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;
			end
            16: begin
				new_Eq[8][2] = alpha_e;
				new_Eq[9][0] = alpha_f;
                if (Eq[7][3] > Eq[6][3]) begin
					new_alpha_a = (Eq[6][1] + Eq[7][3] - Eq[6][3]) % 255;
					new_alpha_b = Eq[7][1];
					new_alpha_c = (Eq[6][2] + Eq[7][3] - Eq[6][3]) % 255;
					new_alpha_d = Eq[7][2];
                end
                else begin
					new_alpha_a = (Eq[7][1] + Eq[6][3] - Eq[7][3]) % 255;
					new_alpha_b = Eq[6][1];
					new_alpha_c = (Eq[7][2] + Eq[6][3] - Eq[7][3]) % 255;
					new_alpha_d = Eq[6][2];
                end
            end
			17: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;			
			end
            18: begin
				new_Eq[9][1] = alpha_e;
				new_Eq[9][2] = alpha_f;
			end
			19:begin
                // b = sigma1 coefficient c = sigma0 coefficient
                if (Eq[9][2] > Eq[8][2]) begin
					new_alpha_a = (Eq[8][0] + Eq[9][2] - Eq[8][2]) % 255;
					new_alpha_b = Eq[9][0];
					new_alpha_c = (Eq[8][1] + Eq[9][2] - Eq[8][2]) % 255;
					new_alpha_d = Eq[9][1];
                end
                else begin
					new_alpha_a = (Eq[9][0] + Eq[8][2] - Eq[9][2]) % 255;
					new_alpha_b = Eq[8][0];
					new_alpha_c = (Eq[9][1] + Eq[8][2] - Eq[9][2]) % 255;
					new_alpha_d = Eq[8][1];
                end
            end
			20: begin
				new_value_e = value_a ^ value_b;
				new_value_f = value_c ^ value_d;	
			end
        	21: begin
				new_Eq[10][0] = alpha_e;
				new_Eq[10][1] = alpha_f;
			end
			22: begin
				////$display("Eq[10][0] = %d", Eq[10][0]);
                if (Eq[10][1] > Eq[10][0]) 
                    new_sigma[1] = Eq[10][0] + 255 - Eq[10][1];
                else 
                    new_sigma[1] = Eq[10][0] - Eq[10][1];
				new_alpha_a = Eq[8][0];
				new_alpha_b = (Eq[8][1] + new_sigma[1]) % 255;
            end
			23: begin
				new_value_e = value_a ^ value_b;
				//new_value_f = value_a ^ value_b;
			end
			24:begin
				if (alpha_e > Eq[8][2])
					new_sigma[2] = alpha_e - Eq[8][2];
				else 
					new_sigma[2] = alpha_e - Eq[8][2] + 255;
				
				new_alpha_a = Eq[5][0];
				new_alpha_b = (Eq[5][1] + sigma[1]) % 255;
				new_alpha_c = (Eq[5][2] + new_sigma[2]) % 255;
			end
			25: begin
				new_value_e = value_a ^ value_b ^ value_c;
			end
            26: begin
                if (alpha_e > Eq[5][3])
                    new_sigma[3] = alpha_e - Eq[5][3];
                else
                    new_sigma[3] = alpha_e - Eq[5][3] + 255;
				
				new_alpha_a = Eq[1][0];
				new_alpha_b = (Eq[1][1] + sigma[1]) % 255;
				new_alpha_c = (Eq[1][2] + sigma[2]) % 255;
				new_alpha_d = (Eq[1][3] + new_sigma[3]) % 255;
            end
			27: begin
				new_value_e = value_a ^ value_b ^ value_c ^ value_d;
			end
            28: begin
                if (alpha_e > Eq[1][4])
                    new_sigma[4] = alpha_e - Eq[1][4];
                else
                    new_sigma[4] = alpha_e - Eq[1][4] + 255;
            end
            default: begin 
				new_value_e = value_e;
			end
        endcase
        new_cnt_Eq = cnt_Eq + 1;
		////$display("cnt_Eq = %d, sigma = %d", cnt_Eq, find_Sigma);
        if (cnt_Eq == 28) begin
			for (i = 1; i < 5; i = i + 1)
				////$display("%d = %d", i, sigma[i]);
		    new_find_Sigma = 1;
		end
	end
	else if(state == FIND_ERR) begin
        // finding the error location

		if (cnt_ERR == 0) begin
			new_alpha_a = sigma[4];
			new_alpha_b = (sigma[3] + cnt_ERR) % 255;
			new_alpha_c = (sigma[2] + 2 * cnt_ERR) % 255;
			new_alpha_d = (sigma[1] + 3 * cnt_ERR) % 255;
			new_alpha_i = 4 * cnt_ERR % 255;
		end
		else begin
			if ((value_a ^ value_b ^ value_c ^ value_d ^ value_i) == 0) begin
				new_error_loc[err_num] = error_loc[err_num] + cnt_ERR - 1;
				new_err_num = err_num + 1;
			end
			else
				new_err_num = err_num;
			new_alpha_a = sigma[4];
			new_alpha_b = (sigma[3] + cnt_ERR) % 255;
			new_alpha_c = (sigma[2] + 2 * cnt_ERR) % 255;
			new_alpha_d = (sigma[1] + 3 * cnt_ERR) % 255;
			new_alpha_i = 4 * cnt_ERR % 255;
		end
		/*if ((Alpha_table[sigma[4]] ^ Alpha_table[(sigma[3] + cnt_ERR) % 255] ^ Alpha_table[(sigma[2] + 2 * cnt_ERR) % 255] ^ Alpha_table[(sigma[1] + 3 * cnt_ERR) % 255] ^ Alpha_table[4 * cnt_ERR % 255]) == 0) begin
			new_error_loc[err_num] = error_loc[err_num] + cnt_ERR;
			////$display("%d: cnt_ERR = %d", err_num,new_error_loc[err_num]);
			new_err_num = err_num + 1; 
			////$display("new_err_num = %d", new_err_num);
		end
		else 
			new_err_num = err_num;
		*/
		new_cnt_ERR = cnt_ERR + 1;

		if (cnt_ERR == 45) begin
			new_find_Error = 1;
			new_cnt_ERR = cnt_ERR + 1;
		end
	end
	else if (state == CORRECT) begin
		////$display("err_num%d", err_num);
        // finding the value of Y1 ~ Y4
		if (err_num == 3) begin
			YEq[1][3] = error_loc[0];             YEq[1][2] = error_loc[1];             YEq[1][1] = error_loc[2];             YEq[1][0] = SS[0];
			YEq[2][3] = (error_loc[0] * 2 % 255); YEq[2][2] = (error_loc[1] * 2 % 255); YEq[2][1] = (error_loc[2] * 2 % 255); YEq[2][0] = SS[1];
			YEq[3][3] = (error_loc[0] * 3 % 255); YEq[3][2] = (error_loc[1] * 3 % 255); YEq[3][1] = (error_loc[2] * 3 % 255); YEq[3][0] = SS[2];
            case (cnt_YEq)
                0: begin if (YEq[2][3] > YEq[1][3]) begin
						//a = YEq[2][3] - YEq[1][3];
						new_alpha_a = (YEq[1][0] + YEq[2][3] - YEq[1][3]) % 255;
						new_alpha_b = YEq[2][0];
						new_alpha_c = (YEq[1][1] + YEq[2][3] - YEq[1][3]) % 255;
						new_alpha_d = YEq[2][1];
					end
					else begin
						//a = YEq[1][3] - YEq[2][3];
						new_alpha_a = (YEq[2][0] + YEq[1][3] - YEq[2][3]) % 255;
						new_alpha_b = YEq[1][0];
						new_alpha_c = (YEq[2][1] + YEq[1][3] - YEq[2][3]) % 255;
						new_alpha_d = YEq[1][1];
					end
				end
				1: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				2: begin
					new_YEq[5][0] = alpha_e;
					new_YEq[5][1] = alpha_f;
					if (YEq[2][3] > YEq[1][3]) begin
						//a = YEq[2][3] - YEq[1][3];
						new_alpha_a = (YEq[1][2] + YEq[2][3] - YEq[1][3]) % 255;
						new_alpha_b = YEq[2][2];
					end
					else begin
						//a = YEq[1][3] - YEq[2][3];
						new_alpha_a = (YEq[2][2] + YEq[1][3] - YEq[2][3]) % 255;
						new_alpha_b = YEq[1][2];
					end

					if (YEq[3][3] > YEq[2][3]) begin
						//c = YEq[3][3] - YEq[2][3];
						new_alpha_c = (YEq[2][0] + YEq[3][3] - YEq[2][3]) % 255;
						new_alpha_d = YEq[3][0];
					end
					else begin
						//c = YEq[2][3] - YEq[3][3];
						new_alpha_c = (YEq[3][0] + YEq[2][3] - YEq[3][3]) % 255;
						new_alpha_d = YEq[2][0];
					end
				end
				3: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				4: begin
					new_YEq[5][2] = alpha_e;
					new_YEq[6][0] = alpha_f;
					if (YEq[3][3] > YEq[2][3]) begin
						//a = YEq[3][3] - YEq[2][3];
						new_alpha_a = (YEq[2][1] + YEq[3][3] - YEq[2][3]) % 255;
						new_alpha_b = YEq[3][1];
						new_alpha_c = (YEq[2][2] + YEq[3][3] - YEq[2][3]) % 255;
						new_alpha_d = YEq[3][2];
					end
					else begin
						//a = YEq[2][3] - YEq[3][3];
						new_alpha_a = (YEq[3][1] + YEq[2][3] - YEq[3][3]) % 255;
						new_alpha_b = YEq[2][1];
						new_alpha_c = (YEq[3][2] + YEq[2][3] - YEq[3][3]) % 255;
						new_alpha_d = YEq[2][2];
					end
				end
				5: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;			
				end
				6: begin
					new_YEq[6][1] = alpha_e;
					new_YEq[6][2] = alpha_f;
				end
				7:begin
					// b = sigma1 coefficient c = sigma0 coefficient
					if (YEq[6][2] > YEq[5][2]) begin
						//a = YEq[6][2] - YEq[5][2];
						new_alpha_a = (YEq[5][0] + YEq[6][2] - YEq[5][2]) % 255;
						new_alpha_b = YEq[6][0];
						new_alpha_c = (YEq[5][1] + YEq[6][2] - YEq[5][2]) % 255;
						new_alpha_d = YEq[6][1];
					end
					else begin
						//a = YEq[5][2] - YEq[6][2];
						new_alpha_a = (YEq[6][0] + YEq[5][2] - YEq[6][2]) % 255;
						new_alpha_b = YEq[5][0];
						new_alpha_c = (YEq[6][1] + YEq[5][2] - YEq[6][2]) % 255;
						new_alpha_d = YEq[5][1];
					end
				end
				8: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;	
				end
				9: begin
					new_YEq[7][0] = alpha_e;
					new_YEq[7][1] = alpha_f;
					//$display("YEq[10][0] = %d", alpha_e);
				end
				10: begin
					if (YEq[7][1] > YEq[7][0]) 
						new_Y[1] = YEq[7][0] + 255 - YEq[7][1];
					else 
						new_Y[1] = YEq[7][0] - YEq[7][1];
					
					new_alpha_a = YEq[5][0];
					new_alpha_b = (YEq[5][1] + new_Y[1]) % 255;
				end
				11: begin
					new_value_e = value_a ^ value_b;
					////$display("%d", new_Y[1]);
					//new_value_f = value_a ^ value_b;
				end
				12:begin
					if (alpha_e > YEq[5][2])
						new_Y[2] = alpha_e - YEq[5][2];
					else 
						new_Y[2] = alpha_e - YEq[5][2] + 255;
					
					new_alpha_a = YEq[1][0];
					new_alpha_b = (YEq[1][1] + Y[1]) % 255;
					new_alpha_c = (YEq[1][2] + new_Y[2]) % 255;
				end
				13: begin
					new_value_e = value_a ^ value_b ^ value_c;
				end
				14: begin
					if (alpha_e > YEq[1][3])
						new_Y[3] = alpha_e - YEq[1][3];
					else
						new_Y[3] = alpha_e - YEq[1][3] + 255;
				end
				15: begin
					new_alpha_a = (Y[3] + error_loc[0]) % 255;
					new_alpha_b = (Y[2] + error_loc[1]) % 255;
					new_alpha_c = (Y[1] + error_loc[2]) % 255;
				end
				16: begin
					new_codeword[43-error_loc[0]] = value_a ^ codeword[43-error_loc[0]];
					new_codeword[43-error_loc[1]] = value_b ^ codeword[43-error_loc[1]];
					new_codeword[43-error_loc[2]] = value_c ^ codeword[43-error_loc[2]];
				end
				default: begin 
					new_value_e = value_e;
				end
			endcase
        	new_cnt_YEq = cnt_YEq + 1;
			////$display("%d", cnt_YEq);
			if (cnt_YEq == 16) begin
				for (i = 1; i < 5; i = i + 1)
					//$display("Y[%d] = %d", i, Y[i]);
				new_correct_end = 1;
			end	
		end
		else if (err_num == 4) begin
			YEq[1][4] = error_loc[0];             YEq[1][3] = error_loc[1];             YEq[1][2] = error_loc[2];             YEq[1][1] = error_loc[3];             YEq[1][0] = SS[0];
			YEq[2][4] = (error_loc[0] * 2 % 255); YEq[2][3] = (error_loc[1] * 2 % 255); YEq[2][2] = (error_loc[2] * 2 % 255); YEq[2][1] = (error_loc[3] * 2 % 255); YEq[2][0] = SS[1];
			YEq[3][4] = (error_loc[0] * 3 % 255); YEq[3][3] = (error_loc[1] * 3 % 255); YEq[3][2] = (error_loc[2] * 3 % 255); YEq[3][1] = (error_loc[3] * 3 % 255); YEq[3][0] = SS[2];
			YEq[4][4] = (error_loc[0] * 4 % 255); YEq[4][3] = (error_loc[1] * 4 % 255); YEq[4][2] = (error_loc[2] * 4 % 255); YEq[4][1] = (error_loc[3] * 4 % 255); YEq[4][0] = SS[3];
			// for 5. 6. 7
			////$display("error_loc[0] = %d", error_loc[0]);
			case (cnt_YEq)
				0: begin
					if (YEq[2][4] > YEq[1][4]) begin
						//a = YEq[2][4] - YEq[1][4];
						////$display("a = %d", a);
						new_alpha_a = (YEq[1][0] + YEq[2][4] - YEq[1][4]) % 255;
						new_alpha_b = YEq[2][0];
						new_alpha_c = (YEq[1][1] + YEq[2][4] - YEq[1][4]) % 255;
						new_alpha_d = YEq[2][1];
					end
					else begin
						//a = YEq[1][4] - YEq[2][4];
						new_alpha_a = (YEq[2][0] + YEq[1][4] - YEq[2][4]) % 255;
						new_alpha_b = YEq[1][0];
						new_alpha_c = (YEq[2][1] + YEq[1][4] - YEq[2][4]) % 255;
						new_alpha_d = YEq[1][1];
					end
				end
				1: begin
					new_value_e = value_a ^ value_b;
					////$display("value_a = %d, alpha_a = %d", value_a, new_alpha_a);
					new_value_f = value_c ^ value_d;
				end
				2: begin
					new_YEq[5][0] = alpha_e;
					new_YEq[5][1] = alpha_f;
					if (YEq[2][4] > YEq[1][4]) begin
						//a = YEq[2][4] - YEq[1][4];
						new_alpha_a = (YEq[1][2] + YEq[2][4] - YEq[1][4]) % 255;
						new_alpha_b = YEq[2][2];
						new_alpha_c = (YEq[1][3] + YEq[2][4] - YEq[1][4]) % 255;
						new_alpha_d = YEq[2][3];
					end
					else begin
						//a = YEq[1][4] - YEq[2][4];
						new_alpha_a = (YEq[2][2] + YEq[1][4] - YEq[2][4]) % 255;
						new_alpha_b = YEq[1][2];
						new_alpha_c = (YEq[2][3] + YEq[1][4] - YEq[2][4]) % 255;
						new_alpha_d = YEq[1][3];
					end
				end
				3: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				4: begin
				////$display("new_value_e = %d", YEq[5][0]);
					new_YEq[5][2] = alpha_e;
					new_YEq[5][3] = alpha_f;
					if (YEq[3][4] > YEq[2][4]) begin
						//a = YEq[3][4] - YEq[2][4];
						new_alpha_a = (YEq[2][0] + YEq[3][4] - YEq[2][4]) % 255;
						new_alpha_b = YEq[3][0];
						new_alpha_c = (YEq[2][1] + YEq[3][4] - YEq[2][4]) % 255;
						new_alpha_d = YEq[3][1];
					end
					else begin
						//a = YEq[2][4] - YEq[3][4];
						new_alpha_a = (YEq[3][0] + YEq[2][4] - YEq[3][4]) % 255;
						new_alpha_b = YEq[2][0];
						new_alpha_c = (YEq[3][1] + YEq[2][4] - YEq[3][4]) % 255;
						new_alpha_d = YEq[2][1];
					end
				end
				5: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				6: begin
					new_YEq[6][0] = alpha_e;
					new_YEq[6][1] = alpha_f;
					////$display("YEq[6][0] = %d", alpha_e);
					if (YEq[3][4] > YEq[2][4]) begin
						//a = YEq[3][4] - YEq[2][4];
						new_alpha_a = (YEq[2][2] + YEq[3][4] - YEq[2][4]) % 255;
						new_alpha_b = YEq[3][2];
						new_alpha_c = (YEq[2][3] + YEq[3][4] - YEq[2][4]) % 255;
						new_alpha_d = YEq[3][3];
					end
					else begin
						//a = YEq[2][4] - YEq[3][4];
						new_alpha_a = (YEq[3][2] + YEq[2][4] - YEq[3][4]) % 255;
						new_alpha_b = YEq[2][2];
						new_alpha_c = (YEq[3][3] + YEq[2][4] - YEq[3][4]) % 255;
						new_alpha_d = YEq[2][3];
					end
				end
				7: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				8: begin
					new_YEq[6][2] = alpha_e;
					new_YEq[6][3] = alpha_f;
					if (YEq[4][4] > YEq[3][4]) begin
						//a = YEq[4][4] - YEq[3][4];
						new_alpha_a = (YEq[3][0] + YEq[4][4] - YEq[3][4]) % 255;
						new_alpha_b = YEq[4][0];
						new_alpha_c = (YEq[3][1] + YEq[4][4] - YEq[3][4]) % 255;
						new_alpha_d = YEq[4][1];
					end
					else begin
						//a = YEq[3][4] - YEq[4][4];
						new_alpha_a = (YEq[4][0] + YEq[3][4] - YEq[4][4]) % 255;
						new_alpha_b = YEq[3][0];
						new_alpha_c = (YEq[4][1] + YEq[3][4] - YEq[4][4]) % 255;
						new_alpha_d = YEq[3][1];
					end
				end
				9: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				10: begin
					new_YEq[7][0] = alpha_e;
					new_YEq[7][1] = alpha_f;
					if (YEq[4][4] > YEq[3][4]) begin
						//a = YEq[4][4] - YEq[3][4];
						new_alpha_a = (YEq[3][2] + YEq[4][4] - YEq[3][4]) % 255;
						new_alpha_b = YEq[4][2];
						new_alpha_c = (YEq[3][3] + YEq[4][4] - YEq[3][4]) % 255;
						new_alpha_d = YEq[4][3];
					end
					else begin
						//a = YEq[3][4] - YEq[4][4];
						new_alpha_a = (YEq[4][2] + YEq[3][4] - YEq[4][4]) % 255;
						new_alpha_b = YEq[3][2];
						new_alpha_c = (YEq[4][3] + YEq[3][4] - YEq[4][4]) % 255;
						new_alpha_d = YEq[3][3];
					end			
				end
				11: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				12: begin
					new_YEq[7][2] = alpha_e;
					new_YEq[7][3] = alpha_f;
					if (YEq[6][3] > YEq[5][3]) begin
						//a = YEq[6][3] - YEq[5][3];
						new_alpha_a = (YEq[5][0] + YEq[6][3] - YEq[5][3]) % 255;
						new_alpha_b = YEq[6][0];
						new_alpha_c = (YEq[5][1] + YEq[6][3] - YEq[5][3]) % 255;
						new_alpha_d = YEq[6][1];
					end
					else begin
						//a = YEq[5][3] - YEq[6][3];
						new_alpha_a = (YEq[6][0] + YEq[5][3] - YEq[6][3]) % 255;
						new_alpha_b = YEq[5][0];
						new_alpha_c = (YEq[6][1] + YEq[5][3] - YEq[6][3]) % 255;
						new_alpha_d = YEq[5][1];
					end
				end
				13: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				14: begin
					new_YEq[8][0] = alpha_e;
					new_YEq[8][1] = alpha_f;
					if (YEq[6][3] > YEq[5][3]) begin
						//a = YEq[6][3] - YEq[5][3];
						new_alpha_a = (YEq[5][2] + YEq[6][3] - YEq[5][3]) % 255;
						new_alpha_b = YEq[6][2];
					end
					else begin
						//a = YEq[5][3] - YEq[6][3];
						new_alpha_a = (YEq[6][2] + YEq[5][3] - YEq[6][3]) % 255;
						new_alpha_b = YEq[5][2];
					end

					if (YEq[7][3] > YEq[6][3]) begin
						//c = YEq[7][3] - YEq[6][3];
						new_alpha_c = (YEq[6][0] + YEq[7][3] - YEq[6][3]) % 255;
						new_alpha_d = YEq[7][0];
					end
					else begin
						//c = YEq[6][3] - YEq[7][3];
						new_alpha_c = (YEq[7][0] + YEq[6][3] - YEq[7][3]) % 255;
						new_alpha_d = YEq[6][0];
					end
				end
				15: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;
				end
				16: begin
					new_YEq[8][2] = alpha_e;
					new_YEq[9][0] = alpha_f;
					if (YEq[7][3] > YEq[6][3]) begin
						//a = YEq[7][3] - YEq[6][3];
						new_alpha_a = (YEq[6][1] + YEq[7][3] - YEq[6][3]) % 255;
						new_alpha_b = YEq[7][1];
						new_alpha_c = (YEq[6][2] + YEq[7][3] - YEq[6][3]) % 255;
						new_alpha_d = YEq[7][2];
					end
					else begin
						//a = YEq[6][3] - YEq[7][3];
						new_alpha_a = (YEq[7][1] + YEq[6][3] - YEq[7][3]) % 255;
						new_alpha_b = YEq[6][1];
						new_alpha_c = (YEq[7][2] + YEq[6][3] - YEq[7][3]) % 255;
						new_alpha_d = YEq[6][2];
					end
				end
				17: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;			
				end
				18: begin
					new_YEq[9][1] = alpha_e;
					new_YEq[9][2] = alpha_f;
				end
				19:begin
					// b = sigma1 coefficient c = sigma0 coefficient
					if (YEq[9][2] > YEq[8][2]) begin
						//a = YEq[9][2] - YEq[8][2];
						new_alpha_a = (YEq[8][0] + YEq[9][2] - YEq[8][2]) % 255;
						new_alpha_b = YEq[9][0];
						new_alpha_c = (YEq[8][1] + YEq[9][2] - YEq[8][2]) % 255;
						new_alpha_d = YEq[9][1];
					end
					else begin
						//a = YEq[8][2] - YEq[9][2];
						new_alpha_a = (YEq[9][0] + YEq[8][2] - YEq[9][2]) % 255;
						new_alpha_b = YEq[8][0];
						new_alpha_c = (YEq[9][1] + YEq[8][2] - YEq[9][2]) % 255;
						new_alpha_d = YEq[8][1];
					end
				end
				20: begin
					new_value_e = value_a ^ value_b;
					new_value_f = value_c ^ value_d;	
				end
				21: begin
					new_YEq[10][0] = alpha_e;
					new_YEq[10][1] = alpha_f;
					////$display("YEq[10][0] = %d", alpha_e);
				end
				22: begin
					if (YEq[10][1] > YEq[10][0]) 
						new_Y[1] = YEq[10][0] + 255 - YEq[10][1];
					else 
						new_Y[1] = YEq[10][0] - YEq[10][1];
					
					new_alpha_a = YEq[8][0];
					new_alpha_b = (YEq[8][1] + new_Y[1]) % 255;
				end
				23: begin
					new_value_e = value_a ^ value_b;
					////$display("%d", new_Y[1]);
					//new_value_f = value_a ^ value_b;
				end
				24:begin
					if (alpha_e > YEq[8][2])
						new_Y[2] = alpha_e - YEq[8][2];
					else 
						new_Y[2] = alpha_e - YEq[8][2] + 255;
					
					new_alpha_a = YEq[5][0];
					new_alpha_b = (YEq[5][1] + Y[1]) % 255;
					new_alpha_c = (YEq[5][2] + new_Y[2]) % 255;
				end
				25: begin
					new_value_e = value_a ^ value_b ^ value_c;
				end
				26: begin
					if (alpha_e > YEq[5][3])
						new_Y[3] = alpha_e - YEq[5][3];
					else
						new_Y[3] = alpha_e - YEq[5][3] + 255;
					
					new_alpha_a = YEq[1][0];
					new_alpha_b = (YEq[1][1] + Y[1]) % 255;
					new_alpha_c = (YEq[1][2] + Y[2]) % 255;
					new_alpha_d = (YEq[1][3] + new_Y[3]) % 255;
				end
				27: begin
					new_value_e = value_a ^ value_b ^ value_c ^ value_d;
				end
				28: begin
					if (alpha_e > YEq[1][4])
						new_Y[4] = alpha_e - YEq[1][4];
					else
						new_Y[4] = alpha_e - YEq[1][4] + 255;
				end
				29: begin
					new_alpha_a = (Y[4] + error_loc[0]) % 255;
					new_alpha_b = (Y[3] + error_loc[1]) % 255;
					new_alpha_c = (Y[2] + error_loc[2]) % 255;
					new_alpha_d = (Y[1] + error_loc[3]) % 255;
				end
				30: begin
					new_codeword[43-error_loc[0]] = value_a ^ codeword[43-error_loc[0]];
					new_codeword[43-error_loc[1]] = value_b ^ codeword[43-error_loc[1]];
					new_codeword[43-error_loc[2]] = value_c ^ codeword[43-error_loc[2]];
					new_codeword[43-error_loc[3]] = value_d ^ codeword[43-error_loc[3]];
				end
				default: begin 
					new_value_e = value_e;
				end
			endcase
        	new_cnt_YEq = cnt_YEq + 1;
			////$display("%d", cnt_YEq);
			if (cnt_YEq == 30) begin
				//for (i = 1; i < 5; i = i + 1)
					////$display("Y[%d] = %d", i, Y[i]);
				new_correct_end = 1;
			end	
		end
		else
			new_correct_end = 1;
    end
end
endmodule

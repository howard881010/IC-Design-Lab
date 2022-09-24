module enigma_part2(clk,srstn,load,encrypt,crypt_mode,load_idx,code_in,code_out,code_valid);
input clk;               //clock input
input srstn;             //synchronous reset (active low)
input load;              //load control signal (level sensitive). 0/1: inactive/active
                         //effective in IDLE and LOAD states
input encrypt;           //encrypt control signal (level sensitive). 0/1: inactive/active
                         //effective in READY state
input crypt_mode;        //0: encrypt; 1:decrypt
input [8-1:0] load_idx;		//index of rotor table to be loaded; A:0~63; B:64~127; C:128~191;
input [6-1:0] code_in;		//When load is active, 
                        //rotorA[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b00
                        //rotorB[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b01
						//rotorC[load_idx[5:0]] <= code_in if load_idx[7:6]==2'b10
output reg [6-1:0] code_out;   //encrypted code word (register output)
output reg code_valid;         //0: non-valid code_out; 1: valid code_out (register output)

parameter IDLE = 2'b00, LOAD = 2'b01, READY = 2'b10;
integer i, j, k;

reg [1:0] state, new_state;

reg [6-1:0] new_rotorA_table[0:64-1];
reg [6-1:0] rotorA_table[0:64-1];
reg [6-1:0] new_rotorB_table[0:64-1];
reg [6-1:0] rotorB_table[0:64-1];
reg [6-1:0] mid_rotorC_table[0:64-1];
reg [6-1:0] new_rotorC_table[0:64-1];
reg [6-1:0] rotorC_table[0:64-1];
reg [6-1:0] reflector_table[0:64-1];
reg [6-1:0] rotA_o, rotB_o, rotC_o;
reg [6-1:0] new_rotA_o, new_rotB_o;
reg [6-1:0] ref_o;
reg new_code_valid;
reg [6-1:0] last_A, last_B;
reg [6-1:0] new_code_out;
reg [6-1:0] cout, bout;
reg [6-1:0] new_cout, new_bout;
reg cnt;
reg [3:0] cycle;

/// FSM ///
always @(posedge clk) begin
	if(~srstn) begin
		state <= IDLE;
		code_out <= 0;
		code_valid <= 0;
    	rotA_o <= 0;
    	rotB_o <= 0;
		cout <= 0;
		bout <= 0;
	end
	else begin
		state <= new_state;
		code_out <= new_code_out;
		code_valid <= new_code_valid;
    	rotA_o <= new_rotA_o;
    	rotB_o <= new_rotB_o;
		cout <= new_cout;
		bout <= new_bout;
	end
end 

always @* begin
	case(state)
		IDLE: begin
			if(load) begin
				new_state = LOAD;
			end
			else begin
				new_state = IDLE;
			end
		end
		LOAD: begin
			if(load) begin
				 new_state = LOAD; 
			end 
			else begin 
				 new_state = READY;
			end 
		end
		READY: new_state = READY;
		default: new_state = IDLE;
	endcase

	for (i=0; i<64; i = i+1) begin 
		reflector_table[i] = 63-i;
	end
end 

always @(posedge clk) begin
	if((encrypt==1) && (state==READY)) begin
		if(cycle==4) begin
			cycle <= 4;
			cnt <= cnt + 1;
		end
		else if (cycle >= 1)begin
			cycle <= cycle + 1;
			cnt <= cnt + 1;
		end
		else begin
			cycle <= cycle + 1;
			cnt <= 0;
		end
	end
	else if((encrypt==0) && (cycle>=4)) begin
		cycle <= cycle + 1; 
		cnt <= cnt + 1;
	end
	else if(~srstn) begin
		cycle <= 0; 
		cnt <= 0;
	end
	else begin
		cycle <= 0; 
		cnt <= 0;
	end
end

always @* begin
	for(i=0; i<64; i=i+1) begin
		new_rotorA_table[i] = rotorA_table[i];
		new_rotorB_table[i] = rotorB_table[i];
		new_rotorC_table[i] = rotorC_table[i];
	end
	if(state==LOAD) begin
		case(load_idx[7:6])
			2'b00: new_rotorA_table[load_idx[5:0]] = code_in;
			2'b01: new_rotorB_table[load_idx[5:0]] = code_in;
			2'b10: new_rotorC_table[load_idx[5:0]] = code_in;		
		endcase
	end
	else if((encrypt==1 || cycle==1) && (state==READY)) begin
		// tableA
		last_A = rotorA_table[63];
		for (i=62; i>=0; i = i-1) begin
			new_rotorA_table[i+1] = rotorA_table[i];
		end
		new_rotorA_table[0] = last_A;
		// tableB
		if(cnt==1) begin
			last_B = rotorB_table[63];
			for(i=62; i>=0; i=i-1) begin
				new_rotorB_table[i+1] = rotorB_table[i];
			end
			new_rotorB_table[0] = last_B;
		end
		else begin
			for(i=0; i<64; i=i+1) begin
				new_rotorB_table[i] = rotorB_table[i];
			end
		end  
		// tableC
		if(cycle>=2) begin
			if(crypt_mode==0) begin
				case(rotC_o[1:0])
					2'b00: begin
						for(i=0; i<64; i=i+1) begin
							mid_rotorC_table[i] = rotorC_table[i];
						end
					end
					2'b01: begin
						for(i=0; i<63; i=i+4) begin
							mid_rotorC_table[i+1] = rotorC_table[i];
							mid_rotorC_table[i] = rotorC_table[i+1];
							mid_rotorC_table[i+2] = rotorC_table[i+3];
							mid_rotorC_table[i+3] = rotorC_table[i+2];
						end
					end
					2'b10: begin
						for(i=0; i<61; i=i+4) begin
							mid_rotorC_table[i+2] = rotorC_table[i];
							mid_rotorC_table[i+3] = rotorC_table[i+1];
							mid_rotorC_table[i] = rotorC_table[i+2];
							mid_rotorC_table[i+1] = rotorC_table[i+3];
						end
					end
					2'b11: begin
						for(i=0; i<61; i=i+4) begin
							mid_rotorC_table[i+3] = rotorC_table[i];
							mid_rotorC_table[i+2] = rotorC_table[i+1];
							mid_rotorC_table[i+1] = rotorC_table[i+2];
							mid_rotorC_table[i] = rotorC_table[i+3];
						end
					end
				endcase	
			end	
			else if(crypt_mode==1) begin
				case(ref_o[1:0])
					2'b00: begin
						for(i=0; i<64; i=i+1) begin
							mid_rotorC_table[i] = rotorC_table[i];
						end
					end
					2'b01: begin
						for(i=0; i<63; i=i+4) begin
							mid_rotorC_table[i+1] = rotorC_table[i];
							mid_rotorC_table[i] = rotorC_table[i+1];
							mid_rotorC_table[i+2] = rotorC_table[i+3];
							mid_rotorC_table[i+3] = rotorC_table[i+2];
						end
					end
					2'b10: begin
						for(i=0; i<61; i=i+4) begin
							mid_rotorC_table[i+2] = rotorC_table[i];
							mid_rotorC_table[i+3] = rotorC_table[i+1];
							mid_rotorC_table[i] = rotorC_table[i+2];
							mid_rotorC_table[i+1] = rotorC_table[i+3];
						end
					end
					2'b11: begin
						for(i=0; i<61; i=i+4) begin
							mid_rotorC_table[i+3] = rotorC_table[i];
							mid_rotorC_table[i+2] = rotorC_table[i+1];
							mid_rotorC_table[i+1] = rotorC_table[i+2];
							mid_rotorC_table[i] = rotorC_table[i+3];
						end
					end
				endcase	
			end	
			new_rotorC_table[0] = mid_rotorC_table[41];
			new_rotorC_table[1] = mid_rotorC_table[56];
			new_rotorC_table[2] = mid_rotorC_table[61];
			new_rotorC_table[3] = mid_rotorC_table[29];
			new_rotorC_table[4] = mid_rotorC_table[0];
			new_rotorC_table[5] = mid_rotorC_table[26];
    	    new_rotorC_table[6] = mid_rotorC_table[28];
			new_rotorC_table[7] = mid_rotorC_table[63];
			new_rotorC_table[8] = mid_rotorC_table[34];
			new_rotorC_table[9] = mid_rotorC_table[19];
			new_rotorC_table[10] = mid_rotorC_table[36];
			new_rotorC_table[11] = mid_rotorC_table[46];
			new_rotorC_table[12] = mid_rotorC_table[23];
			new_rotorC_table[13] = mid_rotorC_table[54];
			new_rotorC_table[14] = mid_rotorC_table[44];
			new_rotorC_table[15] = mid_rotorC_table[7];
			new_rotorC_table[16] = mid_rotorC_table[43];
			new_rotorC_table[17] = mid_rotorC_table[1];
    	    new_rotorC_table[18] = mid_rotorC_table[42];
			new_rotorC_table[19] = mid_rotorC_table[5];
			new_rotorC_table[20] = mid_rotorC_table[40];
			new_rotorC_table[21] = mid_rotorC_table[22];
			new_rotorC_table[22] = mid_rotorC_table[6];
			new_rotorC_table[23] = mid_rotorC_table[33];
			new_rotorC_table[24] = mid_rotorC_table[21];
			new_rotorC_table[25] = mid_rotorC_table[58];
			new_rotorC_table[26] = mid_rotorC_table[13];
			new_rotorC_table[27] = mid_rotorC_table[51];
			new_rotorC_table[28] = mid_rotorC_table[53];
			new_rotorC_table[29] = mid_rotorC_table[24];
    	    new_rotorC_table[30] = mid_rotorC_table[37];
			new_rotorC_table[31] = mid_rotorC_table[32];
			new_rotorC_table[32] = mid_rotorC_table[31];
			new_rotorC_table[33] = mid_rotorC_table[11];
			new_rotorC_table[34] = mid_rotorC_table[47];
			new_rotorC_table[35] = mid_rotorC_table[25];
			new_rotorC_table[36] = mid_rotorC_table[48];
			new_rotorC_table[37] = mid_rotorC_table[2];
			new_rotorC_table[38] = mid_rotorC_table[10];
			new_rotorC_table[39] = mid_rotorC_table[9];
			new_rotorC_table[40] = mid_rotorC_table[4];
			new_rotorC_table[41] = mid_rotorC_table[52];
    	    new_rotorC_table[42] = mid_rotorC_table[55];
			new_rotorC_table[43] = mid_rotorC_table[17];
			new_rotorC_table[44] = mid_rotorC_table[8];
			new_rotorC_table[45] = mid_rotorC_table[62];
			new_rotorC_table[46] = mid_rotorC_table[16];
			new_rotorC_table[47] = mid_rotorC_table[50];
    	 	new_rotorC_table[48] = mid_rotorC_table[38];
			new_rotorC_table[49] = mid_rotorC_table[14];
			new_rotorC_table[50] = mid_rotorC_table[30];
			new_rotorC_table[51] = mid_rotorC_table[27];
			new_rotorC_table[52] = mid_rotorC_table[57];
    	    new_rotorC_table[53] = mid_rotorC_table[18];
			new_rotorC_table[54] = mid_rotorC_table[60];
			new_rotorC_table[55] = mid_rotorC_table[15];
			new_rotorC_table[56] = mid_rotorC_table[49];
			new_rotorC_table[57] = mid_rotorC_table[59];
			new_rotorC_table[58] = mid_rotorC_table[20];
			new_rotorC_table[59] = mid_rotorC_table[12];
			new_rotorC_table[60] = mid_rotorC_table[39];
			new_rotorC_table[61] = mid_rotorC_table[3];
			new_rotorC_table[62] = mid_rotorC_table[35];
			new_rotorC_table[63] = mid_rotorC_table[45];
		end
	end
end

always @(posedge clk) begin
	for(j=0; j<64; j=j+1) begin
		rotorA_table[j] <= new_rotorA_table[j];	
		rotorB_table[j] <= new_rotorB_table[j];
		rotorC_table[j] <= new_rotorC_table[j];
	end	

end

// encrypt
always @* begin
	new_code_out = code_out;
	new_cout = 0;
	new_bout = 0;
	new_code_valid = 0;
	new_rotA_o = 0;
	new_rotB_o = 0;
	rotC_o = 0;
	ref_o = 0;
	if((encrypt==1 || cycle>=1) && (state==READY)) begin
		if(cycle>=4)
			new_code_valid = 1;

		new_rotA_o = rotorA_table[code_in];
		if(cycle >= 1)
			new_rotB_o = rotorB_table[rotA_o];
		if(cycle>=2)
			rotC_o = rotorC_table[rotB_o];
		ref_o = reflector_table[rotC_o];

		case(ref_o) //synopsys parallel_case
			rotorC_table[0]: new_cout = 0;
			rotorC_table[1]: new_cout = 1;
			rotorC_table[2]: new_cout = 2;
			rotorC_table[3]: new_cout = 3;			
			rotorC_table[4]: new_cout = 4;
			rotorC_table[5]: new_cout = 5;
			rotorC_table[6]: new_cout = 6;
			rotorC_table[7]: new_cout = 7;
			rotorC_table[8]: new_cout = 8;
			rotorC_table[9]: new_cout = 9;
			rotorC_table[10]: new_cout = 10;
			rotorC_table[11]: new_cout = 11;			
			rotorC_table[12]: new_cout = 12;
			rotorC_table[13]: new_cout = 13;
			rotorC_table[14]: new_cout = 14;
			rotorC_table[15]: new_cout = 15;		
			rotorC_table[16]: new_cout = 16;
			rotorC_table[17]: new_cout = 17;
			rotorC_table[18]: new_cout = 18;
			rotorC_table[19]: new_cout = 19;			
			rotorC_table[20]: new_cout = 20;
			rotorC_table[21]: new_cout = 21;
			rotorC_table[22]: new_cout = 22;
			rotorC_table[23]: new_cout = 23;
			rotorC_table[24]: new_cout = 24;
			rotorC_table[25]: new_cout = 25;
			rotorC_table[26]: new_cout = 26;
			rotorC_table[27]: new_cout = 27;			
			rotorC_table[28]: new_cout = 28;
			rotorC_table[29]: new_cout = 29;
			rotorC_table[30]: new_cout = 30;
			rotorC_table[31]: new_cout = 31;
			rotorC_table[32]: new_cout = 32;
			rotorC_table[33]: new_cout = 33;
			rotorC_table[34]: new_cout = 34;
			rotorC_table[35]: new_cout = 35;			
			rotorC_table[36]: new_cout = 36;
			rotorC_table[37]: new_cout = 37;
			rotorC_table[38]: new_cout = 38;
			rotorC_table[39]: new_cout = 39;
			rotorC_table[40]: new_cout = 40;
			rotorC_table[41]: new_cout = 41;
			rotorC_table[42]: new_cout = 42;
			rotorC_table[43]: new_cout = 43;			
			rotorC_table[44]: new_cout = 44;
			rotorC_table[45]: new_cout = 45;
			rotorC_table[46]: new_cout = 46;
			rotorC_table[47]: new_cout = 47;		
			rotorC_table[48]: new_cout = 48;
			rotorC_table[49]: new_cout = 49;
			rotorC_table[50]: new_cout = 50;
			rotorC_table[51]: new_cout = 51;			
			rotorC_table[52]: new_cout = 52;
			rotorC_table[53]: new_cout = 53;
			rotorC_table[54]: new_cout = 54;
			rotorC_table[55]: new_cout = 55;
			rotorC_table[56]: new_cout = 56;
			rotorC_table[57]: new_cout = 57;
			rotorC_table[58]: new_cout = 58;
			rotorC_table[59]: new_cout = 59;			
			rotorC_table[60]: new_cout = 60;
			rotorC_table[61]: new_cout = 61;
			rotorC_table[62]: new_cout = 62;
			rotorC_table[63]: new_cout = 63;
		endcase
		case(cout) //synopsys parallel_case
			rotorB_table[0]: new_bout = 63;
			rotorB_table[1]: new_bout = 0;
			rotorB_table[2]: new_bout = 1;
			rotorB_table[3]: new_bout = 2;			
			rotorB_table[4]: new_bout = 3;
			rotorB_table[5]: new_bout = 4;
			rotorB_table[6]: new_bout = 5;
			rotorB_table[7]: new_bout = 6;
			rotorB_table[8]: new_bout = 7;
			rotorB_table[9]: new_bout = 8;
			rotorB_table[10]: new_bout = 9;
			rotorB_table[11]: new_bout = 10;			
			rotorB_table[12]: new_bout = 11;
			rotorB_table[13]: new_bout = 12;
			rotorB_table[14]: new_bout = 13;
			rotorB_table[15]: new_bout = 14;		
			rotorB_table[16]: new_bout = 15;
			rotorB_table[17]: new_bout = 16;
			rotorB_table[18]: new_bout = 17;
			rotorB_table[19]: new_bout = 18;			
			rotorB_table[20]: new_bout = 19;
			rotorB_table[21]: new_bout = 20;
			rotorB_table[22]: new_bout = 21;
			rotorB_table[23]: new_bout = 22;
			rotorB_table[24]: new_bout = 23;
			rotorB_table[25]: new_bout = 24;
			rotorB_table[26]: new_bout = 25;
			rotorB_table[27]: new_bout = 26;			
			rotorB_table[28]: new_bout = 27;
			rotorB_table[29]: new_bout = 28;
			rotorB_table[30]: new_bout = 29;
			rotorB_table[31]: new_bout = 30;
			rotorB_table[32]: new_bout = 31;
			rotorB_table[33]: new_bout = 32;
			rotorB_table[34]: new_bout = 33;
			rotorB_table[35]: new_bout = 34;			
			rotorB_table[36]: new_bout = 35;
			rotorB_table[37]: new_bout = 36;
			rotorB_table[38]: new_bout = 37;
			rotorB_table[39]: new_bout = 38;
			rotorB_table[40]: new_bout = 39;
			rotorB_table[41]: new_bout = 40;
			rotorB_table[42]: new_bout = 41;
			rotorB_table[43]: new_bout = 42;			
			rotorB_table[44]: new_bout = 43;
			rotorB_table[45]: new_bout = 44;
			rotorB_table[46]: new_bout = 45;
			rotorB_table[47]: new_bout = 46;		
			rotorB_table[48]: new_bout = 47;
			rotorB_table[49]: new_bout = 48;
			rotorB_table[50]: new_bout = 49;
			rotorB_table[51]: new_bout = 50;			
			rotorB_table[52]: new_bout = 51;
			rotorB_table[53]: new_bout = 52;
			rotorB_table[54]: new_bout = 53;
			rotorB_table[55]: new_bout = 54;
			rotorB_table[56]: new_bout = 55;
			rotorB_table[57]: new_bout = 56;
			rotorB_table[58]: new_bout = 57;
			rotorB_table[59]: new_bout = 58;			
			rotorB_table[60]: new_bout = 59;
			rotorB_table[61]: new_bout = 60;
			rotorB_table[62]: new_bout = 61;
			rotorB_table[63]: new_bout = 62;
		endcase
		case(bout) //synopsys parallel_case
			rotorA_table[0]: new_code_out = 60;
			rotorA_table[1]: new_code_out = 61;
			rotorA_table[2]: new_code_out = 62;
			rotorA_table[3]: new_code_out = 63;			
			rotorA_table[4]: new_code_out = 0;
			rotorA_table[5]: new_code_out = 1;
			rotorA_table[6]: new_code_out = 2;
			rotorA_table[7]: new_code_out = 3;
			rotorA_table[8]: new_code_out = 4;
			rotorA_table[9]: new_code_out = 5;
			rotorA_table[10]: new_code_out = 6;
			rotorA_table[11]: new_code_out = 7;			
			rotorA_table[12]: new_code_out = 8;
			rotorA_table[13]: new_code_out = 9;
			rotorA_table[14]: new_code_out = 10;
			rotorA_table[15]: new_code_out = 11;		
			rotorA_table[16]: new_code_out = 12;
			rotorA_table[17]: new_code_out = 13;
			rotorA_table[18]: new_code_out = 14;
			rotorA_table[19]: new_code_out = 15;			
			rotorA_table[20]: new_code_out = 16;
			rotorA_table[21]: new_code_out = 17;
			rotorA_table[22]: new_code_out = 18;
			rotorA_table[23]: new_code_out = 19;
			rotorA_table[24]: new_code_out = 20;
			rotorA_table[25]: new_code_out = 21;
			rotorA_table[26]: new_code_out = 22;
			rotorA_table[27]: new_code_out = 23;			
			rotorA_table[28]: new_code_out = 24;
			rotorA_table[29]: new_code_out = 25;
			rotorA_table[30]: new_code_out = 26;
			rotorA_table[31]: new_code_out = 27;
			rotorA_table[32]: new_code_out = 28;
			rotorA_table[33]: new_code_out = 29;
			rotorA_table[34]: new_code_out = 30;
			rotorA_table[35]: new_code_out = 31;			
			rotorA_table[36]: new_code_out = 32;
			rotorA_table[37]: new_code_out = 33;
			rotorA_table[38]: new_code_out = 34;
			rotorA_table[39]: new_code_out = 35;
			rotorA_table[40]: new_code_out = 36;
			rotorA_table[41]: new_code_out = 37;
			rotorA_table[42]: new_code_out = 38;
			rotorA_table[43]: new_code_out = 39;			
			rotorA_table[44]: new_code_out = 40;
			rotorA_table[45]: new_code_out = 41;
			rotorA_table[46]: new_code_out = 42;
			rotorA_table[47]: new_code_out = 43;		
			rotorA_table[48]: new_code_out = 44;
			rotorA_table[49]: new_code_out = 45;
			rotorA_table[50]: new_code_out = 46;
			rotorA_table[51]: new_code_out = 47;			
			rotorA_table[52]: new_code_out = 48;
			rotorA_table[53]: new_code_out = 49;
			rotorA_table[54]: new_code_out = 50;
			rotorA_table[55]: new_code_out = 51;
			rotorA_table[56]: new_code_out = 52;
			rotorA_table[57]: new_code_out = 53;
			rotorA_table[58]: new_code_out = 54;
			rotorA_table[59]: new_code_out = 55;			
			rotorA_table[60]: new_code_out = 56;
			rotorA_table[61]: new_code_out = 57;
			rotorA_table[62]: new_code_out = 58;
			rotorA_table[63]: new_code_out = 59;
		endcase
	end
end

endmodule

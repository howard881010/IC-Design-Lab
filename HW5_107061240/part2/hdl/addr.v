module addr(
input conv_done,
input unshuffle_done,
input [3:0]state,
input clk,                          
input rst_n,  // synchronous reset (active low)  
// read address to SRAM group A
output reg [5:0] sram_raddr_a0,
output reg [5:0] sram_raddr_a1,
output reg [5:0] sram_raddr_a2,
output reg [5:0] sram_raddr_a3,
// read address to SRAM group B
output reg [5:0] sram_raddr_b0,
output reg [5:0] sram_raddr_b1,
output reg [5:0] sram_raddr_b2,
output reg [5:0] sram_raddr_b3,
// read address to parameter SRAM
output reg [9:0] sram_raddr_weight,
output reg [5:0] sram_raddr_bias,
output reg LOAD_DONE
);


reg [6:0]CNT, n_CNT; 
reg [6:0]CNT_BIAS, n_CNT_BIAS;
reg [9:0]CNT_WE, n_CNT_WE;
reg [3:0]CNT_ADDR, n_CNT_ADDR;
reg [3:0]CNT_ADDR_R, n_CNT_ADDR_R;
reg [4:0]addr_start01, addr_start23;

/////////DFF/////////
always @(posedge clk) begin
	if(~rst_n) begin
		CNT <= 0;
		CNT_BIAS <= 0;
		CNT_WE <= 0;
		CNT_ADDR <= 0;
		CNT_ADDR_R <= 0;
	end
	else begin
		CNT <= n_CNT;
		CNT_BIAS <= n_CNT_BIAS;
		CNT_WE <= n_CNT_WE;
		CNT_ADDR <= n_CNT_ADDR;
		CNT_ADDR_R <= n_CNT_ADDR_R;
	end
end


always @* begin
	n_CNT = 0;
	n_CNT_BIAS = 0;
	n_CNT_WE = 0; 
	n_CNT_ADDR = 0;
	n_CNT_ADDR_R = 0;
	LOAD_DONE = 0;
	if(state == 1 && unshuffle_done)
		n_CNT_WE = CNT_WE + 1;

	else if(state == 2) begin
		n_CNT = CNT + 1;
		n_CNT_WE = CNT_WE + 1;
		n_CNT_BIAS = CNT_BIAS;
		n_CNT_ADDR = 0;
		if(CNT == 3) begin
			LOAD_DONE = 1;
			n_CNT_WE = CNT_WE;
			n_CNT_ADDR = 1;
			n_CNT_ADDR_R = 0;
			n_CNT = 0;
		end

	end
	else if(state == 3) begin
		n_CNT = CNT;
		n_CNT_ADDR_R = CNT_ADDR_R;
		n_CNT_WE = CNT_WE;
		n_CNT_ADDR = CNT_ADDR + 1;
		n_CNT_BIAS = CNT_BIAS;
		if(conv_done)
			n_CNT_BIAS = CNT_BIAS +1;
		if (CNT_ADDR == 5 && CNT_ADDR_R ==5) begin
			n_CNT_ADDR_R = 0;
			n_CNT_ADDR = 0;
		end
		else if(CNT_ADDR == 5) begin
			n_CNT_ADDR = 0;
			n_CNT_ADDR_R = CNT_ADDR_R + 1;
		end

		if(conv_done)
			n_CNT_WE = CNT_WE + 1;
	end

	else if (state == 4) begin
		n_CNT = CNT;
		n_CNT_ADDR_R = CNT_ADDR_R;
		n_CNT_WE = CNT_WE;
		n_CNT_ADDR = CNT_ADDR + 1;
		n_CNT_BIAS = CNT_BIAS;
		if(conv_done)
			n_CNT_BIAS = CNT_BIAS +1;
		if (CNT_ADDR == 4 && CNT_ADDR_R == 4) begin
			n_CNT_ADDR_R = 0;
			n_CNT_ADDR = 0;
		end
		else if(CNT_ADDR == 4) begin
			n_CNT_ADDR = 0;
			n_CNT_ADDR_R = CNT_ADDR_R + 1;
		end
		if(conv_done)
			n_CNT_WE = CNT_WE + 1;
	end


end

always @* begin
	case(CNT_ADDR_R) //synopsys parallel_case
		0: begin
			addr_start01 =0;
			addr_start23 =0;
		end
		1: begin
			addr_start01 =6;
			addr_start23 =0;
		end
		2: begin
			addr_start01 =6;
			addr_start23 =6;
		end
		3: begin
			addr_start01 =12;
			addr_start23 =6;
		end
		4: begin
			addr_start01 =12;
			addr_start23 =12;
		end
		5: begin
			addr_start01 =18;
			addr_start23 =12;
		end
		default: begin
			addr_start01 =0;
			addr_start23 =0;		
		end
	endcase
end
/////////det sram_addr/////////

always @* begin
	sram_raddr_bias = CNT_BIAS;
	sram_raddr_weight = CNT_WE;
	sram_raddr_a0 = 0;
	sram_raddr_a1 = 0;
	sram_raddr_a2 = 0;
	sram_raddr_a3 = 0;
	sram_raddr_b0 = 0;
	sram_raddr_b1 = 0;
	sram_raddr_b2 = 0;
	sram_raddr_b3 = 0;
	if(state == 2) begin
		sram_raddr_a0 = 0;
		sram_raddr_a1 = 0;
		sram_raddr_a2 = 0;
		sram_raddr_a3 = 0;
		sram_raddr_b0 = 0;
		sram_raddr_b1 = 0;
		sram_raddr_b2 = 0;
		sram_raddr_b3 = 0;
	end
    else if(state == 3) begin
        sram_raddr_b0 = 0;
        sram_raddr_b1 = 0;
        sram_raddr_b2 = 0;
        sram_raddr_b3 = 0;
        case(CNT_ADDR)
            0: begin
                sram_raddr_a0 = addr_start01;
				sram_raddr_a1 =	addr_start01;
				sram_raddr_a2 =	addr_start23;
				sram_raddr_a3 =	addr_start23;
            end
            1: begin
                sram_raddr_a0 = addr_start01 +1;
				sram_raddr_a1 =	addr_start01;
				sram_raddr_a2 =	addr_start23 +1;
				sram_raddr_a3 =	addr_start23;
            end
            2: begin
                sram_raddr_a0 = addr_start01 +1;
				sram_raddr_a1 =	addr_start01 +1;
				sram_raddr_a2 =	addr_start23 +1;
				sram_raddr_a3 =	addr_start23 +1;
            end
            3: begin
                sram_raddr_a0 = addr_start01 +2;
				sram_raddr_a1 =	addr_start01 +1;
				sram_raddr_a2 =	addr_start23 +2;
				sram_raddr_a3 =	addr_start23 +1;
            end	
            4: begin
                sram_raddr_a0 = addr_start01 +2;
				sram_raddr_a1 =	addr_start01 +2;
				sram_raddr_a2 =	addr_start23 +2;
				sram_raddr_a3 =	addr_start23 +2;
            end
            5: begin
                sram_raddr_a0 = addr_start01 +3;
				sram_raddr_a1 =	addr_start01 +2;
				sram_raddr_a2 =	addr_start23 +3;
				sram_raddr_a3 =	addr_start23 +2;
            end	
			default: begin
                sram_raddr_a0 = addr_start01;
				sram_raddr_a1 =	addr_start01;
				sram_raddr_a2 =	addr_start23;
				sram_raddr_a3 =	addr_start23;
			end
		endcase
    end
	else if (state == 4) begin
		case(CNT_ADDR) 
			0: begin
                sram_raddr_a0 = addr_start01;
				sram_raddr_a1 =	addr_start01;
				sram_raddr_a2 =	addr_start23;
				sram_raddr_a3 =	addr_start23;
			end
			1: begin
				sram_raddr_a0 = addr_start01 + 1;
				sram_raddr_a1 =	addr_start01 + 1;
				sram_raddr_a2 =	addr_start23;
				sram_raddr_a3 =	addr_start23;
			end
			2: begin
				sram_raddr_a0 = addr_start01 + 1;
				sram_raddr_a1 =	addr_start01 + 1;
				sram_raddr_a2 =	addr_start23 + 1;
				sram_raddr_a3 =	addr_start23 + 1;
			end
			3: begin
				sram_raddr_a0 = addr_start01 + 2;
				sram_raddr_a1 =	addr_start01 + 1;
				sram_raddr_a2 =	addr_start23 + 2;
				sram_raddr_a3 =	addr_start23 + 1;
			end
			4: begin
				sram_raddr_a0 = addr_start01 + 2;
				sram_raddr_a1 =	addr_start01 + 2;
				sram_raddr_a2 =	addr_start23 + 2;
				sram_raddr_a3 =	addr_start23 + 2;
			end
		endcase
	end
end

endmodule
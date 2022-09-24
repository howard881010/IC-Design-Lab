module enigma_part1(clk,srstn,load,encrypt,crypt_mode,load_idx,code_in,code_out,code_valid);
input clk;               //clock input
input srstn;             //synchronous reset (active low)
input load;              //load control signal (level sensitive). 0/1: inactive/active
                         //effective in IDLE and LOAD states
input encrypt;           //encrypt control signal (level sensitive). 0/1: inactive/active
                         //effective in READY state
input crypt_mode;        //0: encrypt; 1:decrypt
input [8-1:0] load_idx;     //index of rotor table to be loaded; A:0~63; B:64~127; C:128~191;
input [6-1:0] code_in;      //When load is active,
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

reg [6-1:0] reflector_table[0:64-1];
reg [6-1:0] rotA_o;
reg [6-1:0] ref_o;
reg new_code_valid;
reg [6-1:0] last_A;


reg [6-1:0] new_code_out;



always @(posedge clk) begin
    if(~srstn) begin
        state <= IDLE;
        code_out <= 0;
        code_valid <= 0;
    end
    else begin
        state <= new_state;
        code_out <= new_code_out;
        code_valid <= new_code_valid;
    end
end

/// FSM ///
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
        default: new_state = READY;
    endcase

    for (i=0; i<64; i = i+1) begin
        reflector_table[i] = 63-i;
    end
end


always @* begin
    for(i = 0; i < 64; i = i + 1) begin
        new_rotorA_table[i] = rotorA_table[i];
    end

    if(state == LOAD) begin
        new_rotorA_table[load_idx[5:0]] = code_in;
    end
    else if((new_code_valid==1) && (state==READY)) begin
        last_A = rotorA_table[63];
        for (i=62; i>=0; i = i-1) begin
            new_rotorA_table[i+1] = rotorA_table[i];
        end
        new_rotorA_table[0] = last_A;
    end
end

always @(posedge clk) begin
    for(j=0; j<64; j=j+1) begin
        rotorA_table[j] <= new_rotorA_table[j];
    end
end

//encrypt
always @* begin
    new_code_out = 0;
    new_code_valid = 0;
    rotA_o = 0;
    ref_o = 0;


    if((encrypt==1) && (state==READY)) begin
        rotA_o = rotorA_table[code_in];
        ref_o = reflector_table[rotA_o];
        new_code_valid = 1;
        case(ref_o)
            rotorA_table[0]: new_code_out = 0;
            rotorA_table[1]: new_code_out = 1;
            rotorA_table[2]: new_code_out = 2;
            rotorA_table[3]: new_code_out = 3;
            rotorA_table[4]: new_code_out = 4;
            rotorA_table[5]: new_code_out = 5;
            rotorA_table[6]: new_code_out = 6;
            rotorA_table[7]: new_code_out = 7;
            rotorA_table[8]: new_code_out = 8;
            rotorA_table[9]: new_code_out = 9;
            rotorA_table[10]: new_code_out = 10;
            rotorA_table[11]: new_code_out = 11;
            rotorA_table[12]: new_code_out = 12;
            rotorA_table[13]: new_code_out = 13;
            rotorA_table[14]: new_code_out = 14;
            rotorA_table[15]: new_code_out = 15;
            rotorA_table[16]: new_code_out = 16;
            rotorA_table[17]: new_code_out = 17;
            rotorA_table[18]: new_code_out = 18;
            rotorA_table[19]: new_code_out = 19;
            rotorA_table[20]: new_code_out = 20;
            rotorA_table[21]: new_code_out = 21;
            rotorA_table[22]: new_code_out = 22;
            rotorA_table[23]: new_code_out = 23;
            rotorA_table[24]: new_code_out = 24;
            rotorA_table[25]: new_code_out = 25;
            rotorA_table[26]: new_code_out = 26;
            rotorA_table[27]: new_code_out = 27;
            rotorA_table[28]: new_code_out = 28;
            rotorA_table[29]: new_code_out = 29;
            rotorA_table[30]: new_code_out = 30;
            rotorA_table[31]: new_code_out = 31;
            rotorA_table[32]: new_code_out = 32;
            rotorA_table[33]: new_code_out = 33;
            rotorA_table[34]: new_code_out = 34;
            rotorA_table[35]: new_code_out = 35;
            rotorA_table[36]: new_code_out = 36;
            rotorA_table[37]: new_code_out = 37;
            rotorA_table[38]: new_code_out = 38;
            rotorA_table[39]: new_code_out = 39;
            rotorA_table[40]: new_code_out = 40;
            rotorA_table[41]: new_code_out = 41;
            rotorA_table[42]: new_code_out = 42;
            rotorA_table[43]: new_code_out = 43;
            rotorA_table[44]: new_code_out = 44;
            rotorA_table[45]: new_code_out = 45;
            rotorA_table[46]: new_code_out = 46;
            rotorA_table[47]: new_code_out = 47;
            rotorA_table[48]: new_code_out = 48;
            rotorA_table[49]: new_code_out = 49;
            rotorA_table[50]: new_code_out = 50;
            rotorA_table[51]: new_code_out = 51;
            rotorA_table[52]: new_code_out = 52;
            rotorA_table[53]: new_code_out = 53;
            rotorA_table[54]: new_code_out = 54;
            rotorA_table[55]: new_code_out = 55;
            rotorA_table[56]: new_code_out = 56;
            rotorA_table[57]: new_code_out = 57;
            rotorA_table[58]: new_code_out = 58;
            rotorA_table[59]: new_code_out = 59;
            rotorA_table[60]: new_code_out = 60;
            rotorA_table[61]: new_code_out = 61;
            rotorA_table[62]: new_code_out = 62;
            rotorA_table[63]: new_code_out = 63;
            default: new_code_out = 0;
        endcase
    end
end

endmodule

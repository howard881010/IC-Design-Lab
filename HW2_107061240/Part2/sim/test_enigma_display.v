`define CYCLE 2
`define EN 0
`define DE 0

module test_enigma_display;
parameter TEXT_LENGTH_2 = 112;
parameter TEXT_LENGTH_3 = 122836;

// create clk
reg clk;
reg srstn;
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
    srstn = 1;
    // system reset
    #(`CYCLE) srstn = 0;
    #(`CYCLE) srstn = 1;
    #(310*`CYCLE) srstn = 0; 
    #(`CYCLE) srstn = 1;
end

// RTL instantiation
wire [6-1:0] code_out;
wire code_valid;
reg  load, encrypt, crypt_mode;
reg  [7:0]   load_idx;
reg  [6-1:0] code_in;

enigma_part2 U0
(
  .clk(clk),
  .srstn(srstn),
  .load(load),
  .encrypt(encrypt),
  .crypt_mode(crypt_mode),
  .load_idx(load_idx),
  .code_in(code_in),
  .code_out(code_out),
  .code_valid(code_valid)
);


// input feeding;
integer j, k, i;
reg [6-1:0] table_a [0:63];
reg [6-1:0] table_b [0:63];
reg [6-1:0] table_c [0:63];
reg [6-1:0] in2 [0:TEXT_LENGTH_2-1];
reg [6-1:0] in3 [0:TEXT_LENGTH_3-1];

initial begin
    code_in = 6'hzz;
    #(4) load = 1;
    #(`CYCLE*194) load = 0;
    #(3) encrypt = 1;
    #(112*`CYCLE) encrypt = 0;
    #(11) load = 1;
    #(`CYCLE*194) load = 0;
    #(3) encrypt = 1;

end

initial begin
    crypt_mode = 1;
    wait(load==1);
    $readmemh("./rotor/rotorA.dat", table_a);
    $readmemh("./rotor/rotorB.dat", table_b);
    $readmemh("./rotor/rotorC.dat", table_c);
    for(i=0; i<192; i=i+1) begin
        @(negedge clk) #1;
        load_idx = i;
        case(load_idx[7:6])
            2'b00: code_in = table_a[i];
            2'b01: code_in = table_b[i[5:0]];
            2'b10: code_in = table_c[i[5:0]];
            default: code_in = table_a[i];
        endcase
    end
    #(`CYCLE)
    wait(U0.state==2'b10);
    $readmemh("./pat/ciphertext2.dat", in2);
    for(k=0; k<TEXT_LENGTH_2; k=k+1) begin
        @(posedge clk) #1;
        code_in = in2[k];
    end

    wait(srstn==0);
    wait(U0.state==2'b01);
    $readmemh("./rotor/rotorA.dat", table_a);
    $readmemh("./rotor/rotorB.dat", table_b);
    $readmemh("./rotor/rotorC.dat", table_c);
    for(j=0; j<192; j=j+1) begin
        @(negedge clk) #1;
        load_idx = j;
        if(load_idx[7:6]==2'b00) code_in = table_a[j[5:0]];
        else if(load_idx[7:6]==2'b01) code_in = table_b[j[5:0]];
        else if(load_idx[7:6]==2'b10) code_in = table_c[j[5:0]];
    end
    wait(U0.state==2'b10);
    $readmemh("./pat/ciphertext3.dat", in3);
    for(k=0; k<TEXT_LENGTH_3; k=k+1) begin
        @(posedge clk) #1;
        code_in = in3[k];
    end
    

end


// DECRYPT
reg [7:0] ascii_code;
integer out2, out3;

initial begin
    wait(encrypt==1);
    #(`CYCLE);
    out2 = $fopen("plaintext2.dat");
    for(i=0;i<TEXT_LENGTH_2;i=i+1) begin
        @(negedge clk) #1;
        EnigmaCodetoASCII(code_out,ascii_code);
        $fwrite(out2,"%s",ascii_code);
    end

    wait(encrypt==0);
    wait(encrypt==1);
    #(`CYCLE);
    out3 = $fopen("plaintext3.dat");
    for(i=0;i<TEXT_LENGTH_3;i=i+1) begin
        @(negedge clk) #1;
        EnigmaCodetoASCII(code_out,ascii_code);
        $fwrite(out3,"%s",ascii_code);
    end

    $finish;
end


task EnigmaCodetoASCII;
input [6-1:0] eingmacode;
output reg [8-1:0] ascii_out;


begin
  case(eingmacode)
    6'h00: ascii_out = 8'h61; //'a'
    6'h01: ascii_out = 8'h62; //'b'
    6'h02: ascii_out = 8'h63; //'c'
    6'h03: ascii_out = 8'h64; //'d'
    6'h04: ascii_out = 8'h65; //'e'
    6'h05: ascii_out = 8'h66; //'f'
    6'h06: ascii_out = 8'h67; //'g'
    6'h07: ascii_out = 8'h68; //'h'
    6'h08: ascii_out = 8'h69; //'i'
    6'h09: ascii_out = 8'h6a; //'j'
    6'h0a: ascii_out = 8'h6b; //'k'
    6'h0b: ascii_out = 8'h6c; //'l'
    6'h0c: ascii_out = 8'h6d; //'m'
    6'h0d: ascii_out = 8'h6e; //'n'
    6'h0e: ascii_out = 8'h6f; //'o'
    6'h0f: ascii_out = 8'h70; //'p'
    6'h10: ascii_out = 8'h71; //'q'
    6'h11: ascii_out = 8'h72; //'r'
    6'h12: ascii_out = 8'h73; //'s'
    6'h13: ascii_out = 8'h74; //'t'
    6'h14: ascii_out = 8'h75; //'u'
    6'h15: ascii_out = 8'h76; //'v'
    6'h16: ascii_out = 8'h77; //'w'
    6'h17: ascii_out = 8'h78; //'x'
    6'h18: ascii_out = 8'h79; //'y'
    6'h19: ascii_out = 8'h7a; //'z'
    6'h1a: ascii_out = 8'h20; //' '
    6'h1b: ascii_out = 8'h21; //'!'
    6'h1c: ascii_out = 8'h2c; //','
    6'h1d: ascii_out = 8'h2d; //'-'
    6'h1e: ascii_out = 8'h2e; //'.'
    6'h1f: ascii_out = 8'h0a; //'\n' (change line)
    6'h20: ascii_out = 8'h41; //'A'
    6'h21: ascii_out = 8'h42; //'B'
    6'h22: ascii_out = 8'h43; //'C'
    6'h23: ascii_out = 8'h44; //'D'
    6'h24: ascii_out = 8'h45; //'E'
    6'h25: ascii_out = 8'h46; //'F'
    6'h26: ascii_out = 8'h47; //'G'
    6'h27: ascii_out = 8'h48; //'H'
    6'h28: ascii_out = 8'h49; //'I'
    6'h29: ascii_out = 8'h4a; //'J'
    6'h2a: ascii_out = 8'h4b; //'K'
    6'h2b: ascii_out = 8'h4c; //'L'
    6'h2c: ascii_out = 8'h4d; //'M'
    6'h2d: ascii_out = 8'h4e; //'N'
    6'h2e: ascii_out = 8'h4f; //'O'
    6'h2f: ascii_out = 8'h50; //'P'
    6'h30: ascii_out = 8'h51; //'Q'
    6'h31: ascii_out = 8'h52; //'R'
    6'h32: ascii_out = 8'h53; //'S'
    6'h33: ascii_out = 8'h54; //'T'
    6'h34: ascii_out = 8'h55; //'U'
    6'h35: ascii_out = 8'h56; //'V'
    6'h36: ascii_out = 8'h57; //'W'
    6'h37: ascii_out = 8'h58; //'X'
    6'h38: ascii_out = 8'h59; //'Y'
    6'h39: ascii_out = 8'h5a; //'Z'
    6'h3a: ascii_out = 8'h3a; //':'
    6'h3b: ascii_out = 8'h23; //'#'
    6'h3c: ascii_out = 8'h3b; //';'
    6'h3d: ascii_out = 8'h5f; //'_'
    6'h3e: ascii_out = 8'h2b; //'+'
    6'h3f: ascii_out = 8'h26; //'&'
  endcase
end
endtask


initial begin
  $fsdbDumpfile("enigma_display.fsdb");
  $fsdbDumpvars;
end


endmodule




`define CYCLE 2
`define EN 0
`define DE 0

module test_enigma_part2;

reg clk;
reg srstn;

initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;

end

initial begin
    srstn = 1;
    #(`CYCLE) srstn = 0;
    #(`CYCLE) srstn = 1;
end

reg load;
reg crypt_mode, encrypt;
reg [7:0] load_idx;
reg [5:0] code_in;
wire [5:0]code_out;
wire code_valid;

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
integer i, j, k;
reg [5:0] in [0:22];
reg [5:0] table_a [0:63];
reg [5:0] table_b [0:63];
reg [5:0] table_c [0:63];

initial begin
    code_in = 6'hzz;
    #(4) load = 1;
    #(`CYCLE*194) load = 0;
    #(3)encrypt = 1;
end

initial begin
    if((`EN==1) && (`DE==0))
        crypt_mode = 0;
    else if((`EN==0) && (`DE==1))
        crypt_mode = 1;
    
    wait(load==1);
    $readmemh("./rotor/rotorA.dat", table_a);
    $readmemh("./rotor/rotorB.dat", table_b);
    $readmemh("./rotor/rotorC.dat", table_c);
    for(i = 0; i < 192; i = i + 1) begin
        @(negedge clk)
        load_idx = i;
        case(load_idx[7:6])
            2'b00: code_in = table_a[i];
            2'b01: code_in = table_b[i[5:0]];
            2'b10: code_in = table_c[i[5:0]];
            default: code_in = table_a[i];
        endcase
    end
    #(`CYCLE)
    //$display("tableA");
    for(i = 0; i < 64; i = i+1) begin
        //$display("table = %h", U0.rotorA_table[i]);
    end
    //$display("tableB");
    for(i = 0; i < 64; i = i+1) begin
        //$display("table = %h", U0.rotorB_table[i]);
    end
    //$display("tableC");
    for(i = 0; i < 64; i = i+1) begin
        //$display("table = %h", U0.rotorC_table[i]);
    end


	wait(U0.state==2'b10);
	if(crypt_mode==0)
		$readmemh("./pat/plaintext1.dat", in);
	else if(crypt_mode==1)
		$readmemh("./pat/ciphertext1.dat", in);	
	for(i=0; i<23; i=i+1) begin
		@(posedge clk) #1;
		code_in = in[i];
	end
end


// output comparision
integer l;
reg [6-1:0] out [0:22];

initial begin
    wait(encrypt==1);
	#3;
	if(crypt_mode==0)
		$readmemh("./pat/ciphertext1.dat", out);
	else if(crypt_mode==1)
		$readmemh("./pat/plaintext1.dat", out);
	for(j=0; j<23; j=j+1) begin
		@(negedge clk)
        if(code_out !== out[j])
            $display("THE Answer is %h, and result is %h, WRONG!! ", out[j], code_out);
        else
            $display("THE Answer is %h, and result is %h, CORRECT!! ", out[j], code_out);
	end
	$finish;
end


initial begin
  $fsdbDumpfile("enigma_part2.fsdb");
  $fsdbDumpvars;
end


endmodule







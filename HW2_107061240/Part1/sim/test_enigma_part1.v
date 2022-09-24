`define CYCLE 2

module test_enigma_part1;

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

enigma_part1 U0
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

initial begin
    code_in = 6'hzz;
    #(4) load = 1;
    #(128) load = 0;
    #(2)encrypt = 1;
end

initial begin
    wait(load==1);
    $readmemh("./rotor/rotorA.dat", table_a);
    for(i = 0; i < 64; i = i + 1) begin
        @(negedge clk)
        load_idx = i;
        code_in = table_a[i];
    end
    #(`CYCLE)
    for(i = 0; i < 64; i = i+1) begin
        //$display("table = %h", U0.rotorA_table[i]);
    end

    wait(U0.state == 2);  // ready
    $readmemh("./pat/plaintext1.dat", in);

    for(k = 0; k < 23; k = k + 1) begin
        @(negedge clk)
            code_in = in[k];
    end
end


// output comparision
integer l;
reg [6-1:0] out [0:22];

initial begin
    wait(encrypt==1);
    $readmemh("./pat/ciphertext1.dat", out);
    for(j = 0; j<23; j=j+1) begin
        @(negedge clk)
        if(code_out !== out[j])
            $display("THE Answer is %h, and result is %h, WRONG!! ", out[j], code_out);
        else
            $display("THE Answer is %h, and result is %h, CORRECT!! ", out[j], code_out);
    end
    $finish;
end


initial begin
  $fsdbDumpfile("enigma_part1.fsdb");
  $fsdbDumpvars;
end


endmodule







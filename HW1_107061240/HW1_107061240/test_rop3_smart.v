
`define CYCLE 2
`define TEST_DATA_NUM 1024

module test_rop3_smart;

parameter N = 8;


// create clk
reg clk;
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end




// RTL instantiation
wire [N-1:0] Result_RTL_lut16, Result_RTL_smart;
reg  [N-1:0] P_in, S_in, D_in;
reg  [7:0]   Mode_in;


rop3_lut16 #(.N(N)) ROP3_U0
(
  .clk(clk),
  .P(P_in),
  .S(S_in),
  .D(D_in),
  .Mode(Mode_in),
  .Result(Result_RTL_lut16)
);

rop3_smart #(.N(N)) ROP3_U1
(
  .clk(clk),
  .P(P_in),
  .S(S_in),
  .D(D_in),
  .Mode(Mode_in),
  .Result(Result_RTL_smart)
);

// input feeding
integer i, j, k, l;
reg [7:0] mode_sel  [0:14];



initial begin


    mode_sel[0][7:0] = 8'h00;
    mode_sel[1][7:0] = 8'h11;
    mode_sel[2][7:0] = 8'h33;
    mode_sel[3][7:0] = 8'h44;
    mode_sel[4][7:0] = 8'h55;
    mode_sel[5][7:0] = 8'h5A;
    mode_sel[6][7:0] = 8'h66;
    mode_sel[7][7:0] = 8'h88;
    mode_sel[8][7:0] = 8'hBB;
    mode_sel[9][7:0] = 8'hC0;
    mode_sel[10][7:0] = 8'hCC;
    mode_sel[11][7:0] = 8'hEE;
    mode_sel[12][7:0] = 8'hF0;
    mode_sel[13][7:0] = 8'hFB;
    mode_sel[14][7:0] = 8'hFF;


    // input feeding init
    Mode_in = 0;
    P_in    = 0;
    S_in    = 0;
    D_in    = 0;

    // input feeding start
    #(`CYCLE);
    for(i = 0; i < 15; i = i + 1) begin
          for(j = 0; j < 2**N; j = j + 1) begin
                P_in = P_in + 1;
                for(k = 0; k < 2**N; k = k + 1) begin
                      S_in = S_in + 1;
                      for(l = 0; l < 2**N; l = l + 1) begin
                            @(posedge clk)
                            Mode_in = mode_sel[i][7:0];
                            D_in = D_in + 1;
                      end
                end
          end
    end

    // input feeding stop
end
// output comparision
integer output_i = 0;
integer total_error = 0;
initial begin


    // output comparison start
    // two stage pipeline register delay
    @(negedge clk);
    @(negedge clk);
    while(output_i < 15*(2**24)) begin
        @(negedge clk)
        if (Result_RTL_smart !== Result_RTL_lut16) begin
            $display("!!!!! Comparison Fail @ pattern %0d !!!!!", output_i);
            $display("[pattern %0d]     Mode=%2h, {P,S,D}={%2h,%2h,%2h}, smart=%2h, lut16=%2h",
                      output_i, Mode_in, P_in, S_in, D_in, Result_RTL_smart, Result_RTL_lut16);
            total_error = total_error + 1;
        end
        output_i = output_i + 1;
    end


    if (total_error > 0) begin
        $display("\nxxxxxxxxxxx Comparison Fail xxxxxxxxxxx");
        $display("            Total %0d errors\n  Please check your error messages...", total_error);
        $display("xxxxxxxxxxx Comparison Fail xxxxxxxxxxx\n");

        if (total_error > `TEST_DATA_NUM*0.8) begin
            $display("! Hmm...There are so many errors, Did you make the output registered?\n");
        end

    end else begin
        $display("\n============= Congratulations =============");
        $display("    You can move on to the next part !");
        $display("============= Congratulations =============\n");
    end
    $finish;
end

endmodule



`define CYCLE 2
`define TEST_DATA_NUM 1024

module test_rop3_lut256;

parameter N = 8;


// create clk
reg clk;
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end




// RTL instantiation
wire [N-1:0] Result_RTL_lut256, Result_RTL_smart;
reg  [N-1:0] P_in, S_in, D_in;
reg  [7:0]   Mode_in;


rop3_lut256 #(.N(N)) ROP3_U0
(
  .clk(clk),
  .P(P_in),
  .S(S_in),
  .D(D_in),
  .Mode(Mode_in),
  .Result(Result_RTL_lut256)
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
integer i, j, k, l ,g;



initial begin


    // input feeding init
    Mode_in = 8'h00;
    P_in    = 8'hff;
    S_in    = 8'hff;
    D_in    = 8'hff;

    // input feeding start
    #(`CYCLE);
    for(i = 0; i < 2**N; i = i + 1) begin
          for(j = 0; j < 2**N; j = j + 1) begin
                P_in = P_in + 1;
                for(k = 0; k < 2**N; k = k + 1) begin
                      S_in = S_in + 1;
                      for(l = 0; l < 2**N; l = l + 1) begin
                            @(posedge clk)
                            D_in = D_in + 1;
                      end
                end
          end
          Mode_in = Mode_in + 1;
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
    for (g = 0; g < 2**N; g = g + 1) begin
        output_i = 0;
        $display("!!!!! Comparison Mode = %d", Mode_in);
        while(output_i < 2**24) begin
            @(negedge clk)
            if (Result_RTL_smart !== Result_RTL_lut256) begin
                $display("!!!!! Comparison Fail @ pattern %0d !!!!!", output_i);
                $display("[pattern %0d]     Mode=%2h, {P,S,D}={%2h,%2h,%2h}, smart=%2h, lut256=%2h",
                          output_i, Mode_in, P_in, S_in, D_in, Result_RTL_smart, Result_RTL_lut256);
                total_error = total_error + 1;
            end

            output_i = output_i + 1;
        end
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

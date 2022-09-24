`timescale 1ns/100ps
`define CYCLE 10

module test_top;


reg enable;
reg clk;
reg rst_n;
reg [63:0] operand_1;
reg [63:0] operand_2;
reg [2:0] mode;
wire [63:0] result;
wire done;
reg [130:0] input_golden [1:100];
reg [63:0] output_golden[1:100];


CHIP CHIP0(
.clk(clk),
.rst_n(rst_n),
.enable(enable),
.operand_1(operand_1),
.operand_2(operand_2),
.mode(mode),
.result(result),
.done(done)
);

initial begin
  $fsdbDumpfile("post_sim.fsdb");
  $fsdbDumpvars;
end
//=========== for netlist simulation
//SDF annotation
initial begin
  $sdf_annotate("../icc/post_layout/CHIP_layout.sdf",CHIP0);
end

//========================================
initial begin
    clk = 0;
    while(1) #(`CYCLE/2) clk = ~clk;
end

initial begin
    $readmemb("golden/answer.dat", output_golden);
    $readmemb("golden/input.dat", input_golden);

end

integer N_TEST;

initial begin
	enable = 0;
	rst_n = 1;
	#10;
	rst_n = 0;
	#10;
	rst_n = 1;
    for(N_TEST = 1; N_TEST < 81; N_TEST = N_TEST + 1) begin 
        wait(`CYCLE);
        enable = 1;   
        //mode = 0;
        operand_1 = input_golden[N_TEST][130:67];
        mode = input_golden[N_TEST][66:64];
        operand_2 = input_golden[N_TEST][63:0];
        #10;
        enable = 0;
        wait (done);
        #10;
        if (output_golden[N_TEST] === result) begin		
            $display("\n Congratulations! the answer is %h \n!", result);
        end
        else
            $display("\n Failed! the answer is %h, and the golden is %h\n!", result, output_golden[N_TEST]);
    end
    #10 $finish;
end


endmodule









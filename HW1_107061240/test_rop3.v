

// 1. variable declaration and clock connection
// -----------------------------

// declare variables and connect clock here

// -----------------------------



// 2. connect RTL module 
// -----------------------------

// add your module here

// -----------------------------
`define MODE_L 0
`define MODE_U 63
`define CYCLE 2
`define TEST_DATA_NUM 1024

module test_rop3;

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
integer i, j, k, l, g;
integer output_i = 0;
integer total_error = 0;


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

// Don't modify this two blocks
// -----------------------------
// input preparation
initial begin
    input_preparation;
end
// output comparision
initial begin
    output_comparison;
end
// -----------------------------


// 3. implement the above two functions in the task file
`include "./rop3.task"


endmodule

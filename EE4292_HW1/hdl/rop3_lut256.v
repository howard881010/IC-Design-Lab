/*
* Module      : rop3_lut256
* Description : Implement this module using the look-up table (LUT) 
*               This module should support all the possible modes of ROP3.
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the input/output to be a register
*/

module rop3_lut256
#(
  parameter N = 4
)
(
  input clk,
  input [N-1:0] P,
  input [N-1:0] S,
  input [N-1:0] D,
  input [7:0] Mode,
  output reg [N-1:0] Result
);



endmodule
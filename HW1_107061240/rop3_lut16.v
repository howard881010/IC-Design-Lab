/*
* Module      : rop3_lut16
* Description : Implement this module using the look-up table (LUT) 
*               This module should support all the 15-modes listed in table-1
*               For modes not in the table-1, set the Result to 0
* Notes       : Please remember to
*               (1) make the bit-length of {P, S, D, Result} parameterizable
*               (2) make the input/output to be a register 
*/

module rop3_lut16
#(
  parameter N = 8
)
(
  input clk,
  input [N-1:0] P,
  input [N-1:0] S,
  input [N-1:0] D,
  input [7:0] Mode,
  output reg [N-1:0] Result
);

reg [N-1:0] Pin, Sin, Din;
reg [7:0] Modein;
reg [N-1:0] R;

always @* begin
  case(Modein)
    8'h00 : R = 0;
    8'h11 : R = ~(Din|Sin);
    8'h33 : R = ~Sin;
    8'h44 : R = Sin&(~Din);
    8'h55 : R = ~Din;
    8'h5A : R = Din^Pin;
    8'h66 : R = Din^Sin;
    8'h88 : R = Din&Sin;
    8'hBB : R = Din|(~Sin);
    8'hC0 : R = Pin&Sin;
    8'hCC : R = Sin;
    8'hEE : R = Din|Sin;
    8'hF0 : R = Pin;
    8'hFB : R = Din|Pin|(~Sin);
    8'hFF : R = 8'hff;
    default : R = 0;
  endcase
end

always @(posedge clk)
  Pin <= P;
always @(posedge clk)
  Din <= D;
always @(posedge clk)
  Sin <= S;
always @(posedge clk)
  Modein <= Mode;
always @(posedge clk)
  Result <= R;

endmodule


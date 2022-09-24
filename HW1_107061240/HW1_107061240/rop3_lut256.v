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
  parameter N = 8
)
(
  input clk,
  input [N-1:0] P,
  input [N-1:0] D,
  input [N-1:0] S,
  input [7:0] Mode,
  output reg [N-1:0] Result
);

reg [N-1:0] Pin, Sin, Din;
reg [7:0] Modein;
reg [N-1:0] R;

always @* begin
  case(Modein)
    8'h00 : R = 0;
    8'h01 : R = ~(Pin|Sin|Din);
    8'h02 : R = (~Pin)&(~Sin)&Din;
    8'h03 : R = ~(Pin|Sin);
    8'h04 : R = (~Pin)&Sin&(~Din);
    8'h05 : R = (~Pin)&(~Din);
    8'h06 : R = (~Pin)&(Sin^Din);
    8'h07 : R = (~Pin)&(~(Sin&Din));
    8'h08 : R = (~Pin)&(Sin&Din);
    8'h09 : R = (~Pin)&(~(Sin^Din));
    8'h0A : R = (~Pin)&Din;
    8'h0B : R = (~Pin)&((~Sin)|Din);
    8'h0C : R = (~Pin)&Sin;
    8'h0D : R = (~Pin)&(Sin|(~Din));
    8'h0E : R = (~Pin)&(Sin|Din);
    8'h0F : R = ~Pin;
    8'h10 : R = Pin&(~(Din|Sin));
    8'h11 : R = ~(Din|Sin);
    8'h12 : R = (Pin&(~(Din|Sin)))|((~Pin)&(~Sin)&Din);
    8'h13 : R = (Pin&(~(Din|Sin)))|(~(Pin|Sin));
    8'h14 : R = (Pin&(~(Din|Sin)))|((~Pin)&Sin&(~Din));
    8'h15 : R = (Pin&(~(Din|Sin)))|((~Pin)&(~Din));
    8'h16 : R = (Pin&(~(Din|Sin)))|((~Pin)&(Sin^Din));
    8'h17 : R = (Pin&(~(Din|Sin)))|((~Pin)&(~(Sin&Din)));
    8'h18 : R = (Pin&(~(Din|Sin)))|((~Pin)&(Sin&Din));
    8'h19 : R = (Pin&(~(Din|Sin)))|((~Pin)&(~(Sin^Din)));
    8'h1A : R = (Pin&(~(Din|Sin)))|((~Pin)&Din);
    8'h1B : R = (Pin&(~(Din|Sin)))|((~Pin)&((~Sin)|Din));
    8'h1C : R = (Pin&(~(Din|Sin)))|((~Pin)&Sin);
    8'h1D : R = (Pin&(~(Din|Sin)))|((~Pin)&(Sin|(~Din)));
    8'h1E : R = (Pin&(~(Din|Sin)))|((~Pin)&(Sin|Din));
    8'h1F : R = (Pin&(~(Din|Sin)))|~Pin;
    8'h20 : R = Pin&(~Sin)&Din;
    8'h21 : R = (Pin&(~Sin)&Din)|(~(Pin|Sin|Din));
    8'h22 : R = (~Sin)&Din;
    8'h23 : R = (Pin&(~Sin)&Din)|(~(Pin|Sin));
    8'h24 : R = (Pin&(~Sin)&Din)|((~Pin)&Sin&(~Din));
    8'h25 : R = (Pin&(~Sin)&Din)|((~Pin)&(~Din));
    8'h26 : R = (Pin&(~Sin)&Din)|((~Pin)&(Sin^Din));
    8'h27 : R = (Pin&(~Sin)&Din)|((~Pin)&(~(Sin&Din)));
    8'h28 : R = (Pin&(~Sin)&Din)|((~Pin)&(Sin&Din));
    8'h29 : R = (Pin&(~Sin)&Din)|((~Pin)&(~(Sin^Din)));
    8'h2A : R = (Pin&(~Sin)&Din)|((~Pin)&Din);
    8'h2B : R = (Pin&(~Sin)&Din)|((~Pin)&((~Sin)|Din));
    8'h2C : R = (Pin&(~Sin)&Din)|((~Pin)&Sin);
    8'h2D : R = (Pin&(~Sin)&Din)|((~Pin)&(Sin|(~Din)));
    8'h2E : R = (Pin&(~Sin)&Din)|((~Pin)&(Sin|Din));
    8'h2F : R = (Pin&(~Sin)&Din)|(~Pin);
    8'h30 : R = Pin&(~Sin);
    8'h31 : R = (Pin&(~Sin))|(~(Pin|Sin|Din));
    8'h32 : R = (Pin&(~Sin))|((~Pin)&(~Sin)&Din);
    8'h33 : R = ~Sin;
    8'h34 : R = (Pin&(~Sin))|((~Pin)&Sin&(~Din));
    8'h35 : R = (Pin&(~Sin))|((~Pin)&(~Din));
    8'h36 : R = (Pin&(~Sin))|((~Pin)&(Sin^Din));
    8'h37 : R = (Pin&(~Sin))|((~Pin)&(~(Sin&Din)));
    8'h38 : R = (Pin&(~Sin))|((~Pin)&(Sin&Din));
    8'h39 : R = (Pin&(~Sin))|((~Pin)&(~(Sin^Din)));
    8'h3A : R = (Pin&(~Sin))|((~Pin)&Din);
    8'h3B : R = (Pin&(~Sin))|((~Pin)&((~Sin)|Din));
    8'h3C : R = (Pin&(~Sin))|((~Pin)&Sin);
    8'h3D : R = (Pin&(~Sin))|((~Pin)&(Sin|(~Din)));
    8'h3E : R = (Pin&(~Sin))|((~Pin)&(Sin|Din));
    8'h3F : R = (Pin&(~Sin))|(~Pin);
    8'h40 : R = Pin&Sin&(~Din);
    8'h41 : R = (Pin&Sin&(~Din))|(~(Pin|Sin|Din));
    8'h42 : R = (Pin&Sin&(~Din))|((~Pin)&(~Sin)&Din);
    8'h43 : R = (Pin&Sin&(~Din))|(~(Pin|Sin));
    8'h44 : R = Sin&(~Din);
    8'h45 : R = (Pin&Sin&(~Din))|((~Pin)&(~Din));
    8'h46 : R = (Pin&Sin&(~Din))|((~Pin)&(Sin^Din));
    8'h47 : R = (Pin&Sin&(~Din))|((~Pin)&(~(Sin&Din)));
    8'h48 : R = (Pin&Sin&(~Din))|((~Pin)&(Sin&Din));
    8'h49 : R = (Pin&Sin&(~Din))|((~Pin)&(~(Sin^Din)));
    8'h4A : R = (Pin&Sin&(~Din))|((~Pin)&Din);
    8'h4B : R = (Pin&Sin&(~Din))|((~Pin)&((~Sin)|Din));
    8'h4C : R = (Pin&Sin&(~Din))|((~Pin)&Sin);
    8'h4D : R = (Pin&Sin&(~Din))|((~Pin)&(Sin|(~Din)));
    8'h4E : R = (Pin&Sin&(~Din))|((~Pin)&(Sin|Din));
    8'h4F : R = (Pin&Sin&(~Din))|(~Pin);
    8'h50 : R = Pin&(~Din);
    8'h51 : R = (Pin&(~Din))|(~(Pin|Sin|Din));
    8'h52 : R = (Pin&(~Din))|((~Pin)&(~Sin)&Din);
    8'h53 : R = (Pin&(~Din))|(~(Pin|Sin));
    8'h54 : R = (Pin&(~Din))|((~Pin)&Sin&(~Din));
    8'h55 : R = ~Din;
    8'h56 : R = (Pin&(~Din))|((~Pin)&(Sin^Din));
    8'h57 : R = (Pin&(~Din))|((~Pin)&(~(Sin&Din)));
    8'h58 : R = (Pin&(~Din))|((~Pin)&(Sin&Din));
    8'h59 : R = (Pin&(~Din))|((~Pin)&(~(Sin^Din)));
    8'h5A : R = (Pin&(~Din))|((~Pin)&Din);
    8'h5B : R = (Pin&(~Din))|((~Pin)&((~Sin)|Din));
    8'h5C : R = (Pin&(~Din))|((~Pin)&Sin);
    8'h5D : R = (Pin&(~Din))|((~Pin)&(Sin|(~Din)));
    8'h5E : R = (Pin&(~Din))|((~Pin)&(Sin|Din));
    8'h5F : R = (Pin&(~Din))|(~Pin);
    8'h60 : R = Pin&(Sin^Din);
    8'h61 : R = (Pin&(Sin^Din))|(~(Pin|Sin|Din));
    8'h62 : R = (Pin&(Sin^Din))|((~Pin)&(~Sin)&Din);
    8'h63 : R = (Pin&(Sin^Din))|(~(Pin|Sin));
    8'h64 : R = (Pin&(Sin^Din))|((~Pin)&Sin&(~Din));
    8'h65 : R = (Pin&(Sin^Din))|((~Pin)&(~Din));
    8'h66 : R = Sin^Din;
    8'h67 : R = (Pin&(Sin^Din))|((~Pin)&(~(Sin&Din)));
    8'h68 : R = (Pin&(Sin^Din))|((~Pin)&(Sin&Din));
    8'h69 : R = (Pin&(Sin^Din))|((~Pin)&(~(Sin^Din)));
    8'h6A : R = (Pin&(Sin^Din))|((~Pin)&Din);
    8'h6B : R = (Pin&(Sin^Din))|((~Pin)&((~Sin)|Din));
    8'h6C : R = (Pin&(Sin^Din))|((~Pin)&Sin);
    8'h6D : R = (Pin&(Sin^Din))|((~Pin)&(Sin|(~Din)));
    8'h6E : R = (Pin&(Sin^Din))|((~Pin)&(Sin|Din));
    8'h6F : R = (Pin&(Sin^Din))|(~Pin);
    8'h70 : R = Pin&(~(Sin&Din));
    8'h71 : R = (Pin&(~(Sin&Din)))|(~(Pin|Sin|Din));
    8'h72 : R = (Pin&(~(Sin&Din)))|((~Pin)&(~Sin)&Din);
    8'h73 : R = (Pin&(~(Sin&Din)))|(~(Pin|Sin));
    8'h74 : R = (Pin&(~(Sin&Din)))|((~Pin)&Sin&(~Din));
    8'h75 : R = (Pin&(~(Sin&Din)))|((~Pin)&(~Din));
    8'h76 : R = (Pin&(~(Sin&Din)))|((~Pin)&(Sin^Din));
    8'h77 : R = ~(Sin&Din);
    8'h78 : R = (Pin&(~(Sin&Din)))|((~Pin)&(Sin&Din));
    8'h79 : R = (Pin&(~(Sin&Din)))|((~Pin)&(~(Sin^Din)));
    8'h7A : R = (Pin&(~(Sin&Din)))|((~Pin)&Din);
    8'h7B : R = (Pin&(~(Sin&Din)))|((~Pin)&((~Sin)|Din));
    8'h7C : R = (Pin&(~(Sin&Din)))|((~Pin)&Sin);
    8'h7D : R = (Pin&(~(Sin&Din)))|((~Pin)&(Sin|(~Din)));
    8'h7E : R = (Pin&(~(Sin&Din)))|((~Pin)&(Sin|Din));
    8'h7F : R = (Pin&(~(Sin&Din)))|(~Pin);
    8'h80 : R = Pin&(Sin&Din);
    8'h81 : R = (Pin&(Sin&Din))|(~(Pin|Sin|Din));
    8'h82 : R = (Pin&(Sin&Din))|((~Pin)&(~Sin)&Din);
    8'h83 : R = (Pin&(Sin&Din))|(~(Pin|Sin));
    8'h84 : R = (Pin&(Sin&Din))|((~Pin)&Sin&(~Din));
    8'h85 : R = (Pin&(Sin&Din))|((~Pin)&(~Din));
    8'h86 : R = (Pin&(Sin&Din))|((~Pin)&(Sin^Din));
    8'h87 : R = (Pin&(Sin&Din))|((~Pin)&(~(Sin&Din)));
    8'h88 : R = Sin&Din;
    8'h89 : R = (Pin&(Sin&Din))|((~Pin)&(~(Sin^Din)));
    8'h8A : R = (Pin&(Sin&Din))|((~Pin)&Din);
    8'h8B : R = (Pin&(Sin&Din))|((~Pin)&((~Sin)|Din));
    8'h8C : R = (Pin&(Sin&Din))|((~Pin)&Sin);
    8'h8D : R = (Pin&(Sin&Din))|((~Pin)&(Sin|(~Din)));
    8'h8E : R = (Pin&(Sin&Din))|((~Pin)&(Sin|Din));
    8'h8F : R = (Pin&(Sin&Din))|(~Pin);
    8'h90 : R = Pin&(~(Sin^Din));
    8'h91 : R = (Pin&(~(Sin^Din)))|(~(Pin|Sin|Din));
    8'h92 : R = (Pin&(~(Sin^Din)))|((~Pin)&(~Sin)&Din);
    8'h93 : R = (Pin&(~(Sin^Din)))|(~(Pin|Sin));
    8'h94 : R = (Pin&(~(Sin^Din)))|((~Pin)&Sin&(~Din));
    8'h95 : R = (Pin&(~(Sin^Din)))|((~Pin)&(~Din));
    8'h96 : R = (Pin&(~(Sin^Din)))|((~Pin)&(Sin^Din));
    8'h97 : R = (Pin&(~(Sin^Din)))|((~Pin)&(~(Sin&Din)));
    8'h98 : R = (Pin&(~(Sin^Din)))|((~Pin)&(Sin&Din));
    8'h99 : R = ~(Sin^Din);
    8'h9A : R = (Pin&(~(Sin^Din)))|((~Pin)&Din);
    8'h9B : R = (Pin&(~(Sin^Din)))|((~Pin)&((~Sin)|Din));
    8'h9C : R = (Pin&(~(Sin^Din)))|((~Pin)&Sin);
    8'h9D : R = (Pin&(~(Sin^Din)))|((~Pin)&(Sin|(~Din)));
    8'h9E : R = (Pin&(~(Sin^Din)))|((~Pin)&(Sin|Din));
    8'h9F : R = (Pin&(~(Sin^Din)))|(~Pin);
    8'hA0 : R = Pin&Din;
    8'hA1 : R = (Pin&Din)|(~(Pin|Sin|Din));
    8'hA2 : R = (Pin&Din)|((~Pin)&(~Sin)&Din);
    8'hA3 : R = (Pin&Din)|(~(Pin|Sin));
    8'hA4 : R = (Pin&Din)|((~Pin)&Sin&(~Din));
    8'hA5 : R = (Pin&Din)|((~Pin)&(~Din));
    8'hA6 : R = (Pin&Din)|((~Pin)&(Sin^Din));
    8'hA7 : R = (Pin&Din)|((~Pin)&(~(Sin&Din)));
    8'hA8 : R = (Pin&Din)|((~Pin)&(Sin&Din));
    8'hA9 : R = (Pin&Din)|((~Pin)&(~(Sin^Din)));
    8'hAA : R = Din;
    8'hAB : R = (Pin&Din)|((~Pin)&((~Sin)|Din));
    8'hAC : R = (Pin&Din)|((~Pin)&Sin);
    8'hAD : R = (Pin&Din)|((~Pin)&(Sin|(~Din)));
    8'hAE : R = (Pin&Din)|((~Pin)&(Sin|Din));
    8'hAF : R = (Pin&Din)|(~Pin);
    8'hB0 : R = Pin&((~Sin)|Din);
    8'hB1 : R = (Pin&((~Sin)|Din))|(~(Pin|Sin|Din));
    8'hB2 : R = (Pin&((~Sin)|Din))|((~Pin)&(~Sin)&Din);
    8'hB3 : R = (Pin&((~Sin)|Din))|(~(Pin|Sin));
    8'hB4 : R = (Pin&((~Sin)|Din))|((~Pin)&Sin&(~Din));
    8'hB5 : R = (Pin&((~Sin)|Din))|((~Pin)&(~Din));
    8'hB6 : R = (Pin&((~Sin)|Din))|((~Pin)&(Sin^Din));
    8'hB7 : R = (Pin&((~Sin)|Din))|((~Pin)&(~(Sin&Din)));
    8'hB8 : R = (Pin&((~Sin)|Din))|((~Pin)&(Sin&Din));
    8'hB9 : R = (Pin&((~Sin)|Din))|((~Pin)&(~(Sin^Din)));
    8'hBA : R = (Pin&((~Sin)|Din))|((~Pin)&Din);
    8'hBB : R = (~Sin)|Din;
    8'hBC : R = (Pin&((~Sin)|Din))|((~Pin)&Sin);
    8'hBD : R = (Pin&((~Sin)|Din))|((~Pin)&(Sin|(~Din)));
    8'hBE : R = (Pin&((~Sin)|Din))|((~Pin)&(Sin|Din));
    8'hBF : R = (Pin&((~Sin)|Din))|(~Pin);
    8'hC0 : R = Pin&Sin;
    8'hC1 : R = (Pin&Sin)|(~(Pin|Sin|Din));
    8'hC2 : R = (Pin&Sin)|((~Pin)&(~Sin)&Din);
    8'hC3 : R = (Pin&Sin)|(~(Pin|Sin));
    8'hC4 : R = (Pin&Sin)|((~Pin)&Sin&(~Din));
    8'hC5 : R = (Pin&Sin)|((~Pin)&(~Din));
    8'hC6 : R = (Pin&Sin)|((~Pin)&(Sin^Din));
    8'hC7 : R = (Pin&Sin)|((~Pin)&(~(Sin&Din)));
    8'hC8 : R = (Pin&Sin)|((~Pin)&(Sin&Din));
    8'hC9 : R = (Pin&Sin)|((~Pin)&(~(Sin^Din)));
    8'hCA : R = (Pin&Sin)|((~Pin)&Din);
    8'hCB : R = (Pin&Sin)|((~Pin)&((~Sin)|Din));
    8'hCC : R = Sin;
    8'hCD : R = (Pin&Sin)|((~Pin)&(Sin|(~Din)));
    8'hCE : R = (Pin&Sin)|((~Pin)&(Sin|Din));
    8'hCF : R = (Pin&Sin)|(~Pin);
    8'hD0 : R = Pin&(Sin|(~Din));
    8'hD1 : R = (Pin&(Sin|(~Din)))|(~(Pin|Sin|Din));
    8'hD2 : R = (Pin&(Sin|(~Din)))|((~Pin)&(~Sin)&Din);
    8'hD3 : R = (Pin&(Sin|(~Din)))|(~(Pin|Sin));
    8'hD4 : R = (Pin&(Sin|(~Din)))|((~Pin)&Sin&(~Din));
    8'hD5 : R = (Pin&(Sin|(~Din)))|((~Pin)&(~Din));
    8'hD6 : R = (Pin&(Sin|(~Din)))|((~Pin)&(Sin^Din));
    8'hD7 : R = (Pin&(Sin|(~Din)))|((~Pin)&(~(Sin&Din)));
    8'hD8 : R = (Pin&(Sin|(~Din)))|((~Pin)&(Sin&Din));
    8'hD9 : R = (Pin&(Sin|(~Din)))|((~Pin)&(~(Sin^Din)));
    8'hDA : R = (Pin&(Sin|(~Din)))|((~Pin)&Din);
    8'hDB : R = (Pin&(Sin|(~Din)))|((~Pin)&((~Sin)|Din));
    8'hDC : R = (Pin&(Sin|(~Din)))|((~Pin)&Sin);
    8'hDD : R = Sin|(~Din);
    8'hDE : R = (Pin&(Sin|(~Din)))|((~Pin)&(Sin|Din));
    8'hDF : R = (Pin&(Sin|(~Din)))|(~Pin);
    8'hE0 : R = Pin&(Sin|Din);
    8'hE1 : R = (Pin&(Sin|Din))|(~(Pin|Sin|Din));
    8'hE2 : R = (Pin&(Sin|Din))|((~Pin)&(~Sin)&Din);
    8'hE3 : R = (Pin&(Sin|Din))|(~(Pin|Sin));
    8'hE4 : R = (Pin&(Sin|Din))|((~Pin)&Sin&(~Din));
    8'hE5 : R = (Pin&(Sin|Din))|((~Pin)&(~Din));
    8'hE6 : R = (Pin&(Sin|Din))|((~Pin)&(Sin^Din));
    8'hE7 : R = (Pin&(Sin|Din))|((~Pin)&(~(Sin&Din)));
    8'hE8 : R = (Pin&(Sin|Din))|((~Pin)&(Sin&Din));
    8'hE9 : R = (Pin&(Sin|Din))|((~Pin)&(~(Sin^Din)));
    8'hEA : R = (Pin&(Sin|Din))|((~Pin)&Din);
    8'hEB : R = (Pin&(Sin|Din))|((~Pin)&((~Sin)|Din));
    8'hEC : R = (Pin&(Sin|Din))|((~Pin)&Sin);
    8'hED : R = (Pin&(Sin|Din))|((~Pin)&(Sin|(~Din)));
    8'hEE : R = Sin|Din;
    8'hEF : R = (Pin&(Sin|Din))|(~Pin);
    8'hF0 : R = Pin;
    8'hF1 : R = Pin|(~(Pin|Sin|Din));
    8'hF2 : R = Pin|((~Pin)&(~Sin)&Din);
    8'hF3 : R = Pin|(~(Pin|Sin));
    8'hF4 : R = Pin|((~Pin)&Sin&(~Din));
    8'hF5 : R = Pin|((~Pin)&(~Din));
    8'hF6 : R = Pin|((~Pin)&(Sin^Din));
    8'hF7 : R = Pin|((~Pin)&(~(Sin&Din)));
    8'hF8 : R = Pin|((~Pin)&(Sin&Din));
    8'hF9 : R = Pin|((~Pin)&(~(Sin^Din)));
    8'hFA : R = Pin|((~Pin)&Din);
    8'hFB : R = Pin|((~Pin)&((~Sin)|Din));
    8'hFC : R = Pin|((~Pin)&Sin);
    8'hFD : R = Pin|((~Pin)&(Sin|(~Din)));
    8'hFE : R = Pin|((~Pin)&(Sin|Din));
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

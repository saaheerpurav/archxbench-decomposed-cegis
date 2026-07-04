`timescale 1ns/1ps

module aes128_inv_mix_columns (
    input  [127:0] state_in,
    output [127:0] state_out
);

  function [7:0] xtime;
    input [7:0] x;
    begin
      xtime = {x[6:0], 1'b0} ^ (8'h1b & {8{x[7]}});
    end
  endfunction

  function [7:0] mul2;
    input [7:0] x;
    begin
      mul2 = xtime(x);
    end
  endfunction

  function [7:0] mul4;
    input [7:0] x;
    begin
      mul4 = xtime(mul2(x));
    end
  endfunction

  function [7:0] mul8;
    input [7:0] x;
    begin
      mul8 = xtime(mul4(x));
    end
  endfunction

  function [7:0] mul9;
    input [7:0] x;
    begin
      mul9 = mul8(x) ^ x;
    end
  endfunction

  function [7:0] mulb;
    input [7:0] x;
    begin
      mulb = mul8(x) ^ mul2(x) ^ x;
    end
  endfunction

  function [7:0] muld;
    input [7:0] x;
    begin
      muld = mul8(x) ^ mul4(x) ^ x;
    end
  endfunction

  function [7:0] mule;
    input [7:0] x;
    begin
      mule = mul8(x) ^ mul4(x) ^ mul2(x);
    end
  endfunction

  function [31:0] inv_mix_column;
    input [31:0] column;
    reg [7:0] s0;
    reg [7:0] s1;
    reg [7:0] s2;
    reg [7:0] s3;
    begin
      s0 = column[31:24];
      s1 = column[23:16];
      s2 = column[15:8];
      s3 = column[7:0];

      inv_mix_column = {
        mule(s0) ^ mulb(s1) ^ muld(s2) ^ mul9(s3),
        mul9(s0) ^ mule(s1) ^ mulb(s2) ^ muld(s3),
        muld(s0) ^ mul9(s1) ^ mule(s2) ^ mulb(s3),
        mulb(s0) ^ muld(s1) ^ mul9(s2) ^ mule(s3)
      };
    end
  endfunction

  assign state_out = {
    inv_mix_column(state_in[127:96]),
    inv_mix_column(state_in[95:64]),
    inv_mix_column(state_in[63:32]),
    inv_mix_column(state_in[31:0])
  };

endmodule
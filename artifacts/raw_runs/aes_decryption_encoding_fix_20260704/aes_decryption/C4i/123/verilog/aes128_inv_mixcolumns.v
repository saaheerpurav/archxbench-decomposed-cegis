`timescale 1ns/1ps

module aes128_inv_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

  function [7:0] xtime;
    input [7:0] x;
    begin
      xtime = {x[6:0], 1'b0} ^ (x[7] ? 8'h1b : 8'h00);
    end
  endfunction

  function [7:0] gm2;
    input [7:0] x;
    begin
      gm2 = xtime(x);
    end
  endfunction

  function [7:0] gm4;
    input [7:0] x;
    begin
      gm4 = gm2(gm2(x));
    end
  endfunction

  function [7:0] gm8;
    input [7:0] x;
    begin
      gm8 = gm2(gm4(x));
    end
  endfunction

  function [7:0] gm9;
    input [7:0] x;
    begin
      gm9 = gm8(x) ^ x;
    end
  endfunction

  function [7:0] gmb;
    input [7:0] x;
    begin
      gmb = gm8(x) ^ gm2(x) ^ x;
    end
  endfunction

  function [7:0] gmd;
    input [7:0] x;
    begin
      gmd = gm8(x) ^ gm4(x) ^ x;
    end
  endfunction

  function [7:0] gme;
    input [7:0] x;
    begin
      gme = gm8(x) ^ gm4(x) ^ gm2(x);
    end
  endfunction

  function [31:0] inv_mix_col;
    input [31:0] c;
    reg [7:0] a0, a1, a2, a3;
    begin
      a0 = c[31:24];
      a1 = c[23:16];
      a2 = c[15:8];
      a3 = c[7:0];

      inv_mix_col = {
        gme(a0) ^ gmb(a1) ^ gmd(a2) ^ gm9(a3),
        gm9(a0) ^ gme(a1) ^ gmb(a2) ^ gmd(a3),
        gmd(a0) ^ gm9(a1) ^ gme(a2) ^ gmb(a3),
        gmb(a0) ^ gmd(a1) ^ gm9(a2) ^ gme(a3)
      };
    end
  endfunction

  assign state_out = {
    inv_mix_col(state_in[127:96]),
    inv_mix_col(state_in[95:64]),
    inv_mix_col(state_in[63:32]),
    inv_mix_col(state_in[31:0])
  };

endmodule
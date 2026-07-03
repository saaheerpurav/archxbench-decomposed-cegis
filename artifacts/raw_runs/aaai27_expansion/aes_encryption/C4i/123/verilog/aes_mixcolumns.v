`timescale 1ns/1ps

module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

  function [7:0] xtime;
    input [7:0] b;
    begin
      xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
    end
  endfunction

  function [7:0] mul2;
    input [7:0] b;
    begin
      mul2 = xtime(b);
    end
  endfunction

  function [7:0] mul3;
    input [7:0] b;
    begin
      mul3 = xtime(b) ^ b;
    end
  endfunction

  wire [7:0] s [0:15];
  wire [7:0] o [0:15];

  genvar i;

  generate
    for (i = 0; i < 16; i = i + 1) begin : GEN_INPUT_BYTES
      assign s[i] = state_in[127 - 8*i -: 8];
    end

    for (i = 0; i < 4; i = i + 1) begin : GEN_MIX_COLUMNS
      assign o[4*i + 0] = mul2(s[4*i + 0]) ^ mul3(s[4*i + 1]) ^      s[4*i + 2]  ^      s[4*i + 3];
      assign o[4*i + 1] =      s[4*i + 0]  ^ mul2(s[4*i + 1]) ^ mul3(s[4*i + 2]) ^      s[4*i + 3];
      assign o[4*i + 2] =      s[4*i + 0]  ^      s[4*i + 1]  ^ mul2(s[4*i + 2]) ^ mul3(s[4*i + 3]);
      assign o[4*i + 3] = mul3(s[4*i + 0]) ^      s[4*i + 1]  ^      s[4*i + 2]  ^ mul2(s[4*i + 3]);
    end

    for (i = 0; i < 16; i = i + 1) begin : GEN_OUTPUT_BYTES
      assign state_out[127 - 8*i -: 8] = o[i];
    end
  endgenerate

endmodule
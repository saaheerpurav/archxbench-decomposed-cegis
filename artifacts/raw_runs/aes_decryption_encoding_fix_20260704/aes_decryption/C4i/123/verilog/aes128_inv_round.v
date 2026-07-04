`timescale 1ns/1ps

module aes128_inv_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

  wire [127:0] shifted;
  wire [127:0] subbed;
  wire [127:0] keyed;

  aes128_inv_shiftrows u_inv_shiftrows (
      .state_in  (state_in),
      .state_out (shifted)
  );

  aes128_inv_subbytes u_inv_subbytes (
      .state_in  (shifted),
      .state_out (subbed)
  );

  assign keyed = subbed ^ round_key;

  aes128_inv_mixcolumns u_inv_mixcolumns (
      .state_in  (keyed),
      .state_out (state_out)
  );

endmodule
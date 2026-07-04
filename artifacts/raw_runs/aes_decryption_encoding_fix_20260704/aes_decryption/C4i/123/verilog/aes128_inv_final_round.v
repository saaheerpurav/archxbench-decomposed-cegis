`timescale 1ns/1ps

module aes128_inv_final_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);

  wire [127:0] shifted;
  wire [127:0] subbed;

  aes128_inv_shiftrows u_shiftrows (
      .state_in  (state_in),
      .state_out (shifted)
  );

  aes128_inv_subbytes u_subbytes (
      .state_in  (shifted),
      .state_out (subbed)
  );

  assign state_out = subbed ^ round_key;

endmodule
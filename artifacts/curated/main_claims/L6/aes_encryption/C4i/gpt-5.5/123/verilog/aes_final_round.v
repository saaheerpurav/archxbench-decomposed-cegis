`timescale 1ns/1ps

module aes_final_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);

  wire [127:0] subbytes_state;
  wire [127:0] shiftrows_state;

  aes_subbytes u_subbytes (
      .state_in  (state_in),
      .state_out (subbytes_state)
  );

  aes_shiftrows u_shiftrows (
      .state_in  (subbytes_state),
      .state_out (shiftrows_state)
  );

  assign state_out = shiftrows_state ^ round_key;

endmodule
module aes128_round #(
    parameter FINAL_ROUND = 0
) (
    input  [127:0] state_in,
    input  [127:0] round_key,
    input          final_round,
    output [127:0] state_out
);

  wire [127:0] subbed_state;
  wire [127:0] shifted_state;
  wire [127:0] mixed_state;
  wire [127:0] round_state;

  aes128_subbytes u_subbytes (
      .state_in  (state_in),
      .state_out (subbed_state)
  );

  aes128_shiftrows u_shiftrows (
      .state_in  (subbed_state),
      .state_out (shifted_state)
  );

  function [7:0] xtime;
    input [7:0] b;
    begin
      xtime = {b[6:0], 1'b0} ^ ({8{b[7]}} & 8'h1b);
    end
  endfunction

  function [31:0] mix_column;
    input [31:0] col;
    reg [7:0] a0;
    reg [7:0] a1;
    reg [7:0] a2;
    reg [7:0] a3;
    reg [7:0] t;
    reg [7:0] u;
    begin
      a0 = col[31:24];
      a1 = col[23:16];
      a2 = col[15:8];
      a3 = col[7:0];

      t = a0 ^ a1 ^ a2 ^ a3;
      u = a0;

      mix_column[31:24] = a0 ^ t ^ xtime(a0 ^ a1);
      mix_column[23:16] = a1 ^ t ^ xtime(a1 ^ a2);
      mix_column[15:8]  = a2 ^ t ^ xtime(a2 ^ a3);
      mix_column[7:0]   = a3 ^ t ^ xtime(a3 ^ u);
    end
  endfunction

  assign mixed_state = {
      mix_column(shifted_state[127:96]),
      mix_column(shifted_state[95:64]),
      mix_column(shifted_state[63:32]),
      mix_column(shifted_state[31:0])
  };

  assign round_state = ((FINAL_ROUND != 0) || final_round) ? shifted_state : mixed_state;
  assign state_out = round_state ^ round_key;

endmodule
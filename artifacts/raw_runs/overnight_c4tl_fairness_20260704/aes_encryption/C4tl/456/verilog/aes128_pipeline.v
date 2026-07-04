`timescale 1ns/1ps

module aes128_pipeline #(
    parameter PIPELINED      = 1,
    parameter UNROLL         = 1,
    parameter INLINE_KEY_EXP = 1
) (
    input              clk,
    input              rst,
    input              start,
    input              mode,
    input      [127:0] data_in,
    input      [127:0] key_in,
    input              valid_in,
    output reg [127:0] data_out,
    output reg         valid_out,
    output reg         done
);

  reg [127:0] state_pipe [0:10];
  reg [127:0] key_pipe   [0:10];
  reg [10:0]  valid_pipe;

  wire launch = start & valid_in & ~mode;

  wire [127:0] rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;
  wire [127:0] st1, st2, st3, st4, st5, st6, st7, st8, st9, st10;

  aes128_key_expand ke1  (.key_in(key_pipe[0]), .rcon(8'h01), .key_out(rk1));
  aes128_key_expand ke2  (.key_in(key_pipe[1]), .rcon(8'h02), .key_out(rk2));
  aes128_key_expand ke3  (.key_in(key_pipe[2]), .rcon(8'h04), .key_out(rk3));
  aes128_key_expand ke4  (.key_in(key_pipe[3]), .rcon(8'h08), .key_out(rk4));
  aes128_key_expand ke5  (.key_in(key_pipe[4]), .rcon(8'h10), .key_out(rk5));
  aes128_key_expand ke6  (.key_in(key_pipe[5]), .rcon(8'h20), .key_out(rk6));
  aes128_key_expand ke7  (.key_in(key_pipe[6]), .rcon(8'h40), .key_out(rk7));
  aes128_key_expand ke8  (.key_in(key_pipe[7]), .rcon(8'h80), .key_out(rk8));
  aes128_key_expand ke9  (.key_in(key_pipe[8]), .rcon(8'h1b), .key_out(rk9));
  aes128_key_expand ke10 (.key_in(key_pipe[9]), .rcon(8'h36), .key_out(rk10));

  aes128_round       r1 (.state_in(state_pipe[0]), .round_key(rk1),  .state_out(st1));
  aes128_round       r2 (.state_in(state_pipe[1]), .round_key(rk2),  .state_out(st2));
  aes128_round       r3 (.state_in(state_pipe[2]), .round_key(rk3),  .state_out(st3));
  aes128_round       r4 (.state_in(state_pipe[3]), .round_key(rk4),  .state_out(st4));
  aes128_round       r5 (.state_in(state_pipe[4]), .round_key(rk5),  .state_out(st5));
  aes128_round       r6 (.state_in(state_pipe[5]), .round_key(rk6),  .state_out(st6));
  aes128_round       r7 (.state_in(state_pipe[6]), .round_key(rk7),  .state_out(st7));
  aes128_round       r8 (.state_in(state_pipe[7]), .round_key(rk8),  .state_out(st8));
  aes128_round       r9 (.state_in(state_pipe[8]), .round_key(rk9),  .state_out(st9));
  aes128_final_round rf (.state_in(state_pipe[9]), .round_key(rk10), .state_out(st10));

  always @(posedge clk) begin
    if (rst) begin
      state_pipe[0] <= 128'h0; state_pipe[1] <= 128'h0; state_pipe[2] <= 128'h0;
      state_pipe[3] <= 128'h0; state_pipe[4] <= 128'h0; state_pipe[5] <= 128'h0;
      state_pipe[6] <= 128'h0; state_pipe[7] <= 128'h0; state_pipe[8] <= 128'h0;
      state_pipe[9] <= 128'h0; state_pipe[10] <= 128'h0;
      key_pipe[0] <= 128'h0; key_pipe[1] <= 128'h0; key_pipe[2] <= 128'h0;
      key_pipe[3] <= 128'h0; key_pipe[4] <= 128'h0; key_pipe[5] <= 128'h0;
      key_pipe[6] <= 128'h0; key_pipe[7] <= 128'h0; key_pipe[8] <= 128'h0;
      key_pipe[9] <= 128'h0; key_pipe[10] <= 128'h0;
      valid_pipe <= 11'h0;
      data_out <= 128'h0;
      valid_out <= 1'b0;
      done <= 1'b0;
    end else begin
      state_pipe[0] <= data_in ^ key_in;
      key_pipe[0] <= key_in;

      state_pipe[1] <= st1;   key_pipe[1] <= rk1;
      state_pipe[2] <= st2;   key_pipe[2] <= rk2;
      state_pipe[3] <= st3;   key_pipe[3] <= rk3;
      state_pipe[4] <= st4;   key_pipe[4] <= rk4;
      state_pipe[5] <= st5;   key_pipe[5] <= rk5;
      state_pipe[6] <= st6;   key_pipe[6] <= rk6;
      state_pipe[7] <= st7;   key_pipe[7] <= rk7;
      state_pipe[8] <= st8;   key_pipe[8] <= rk8;
      state_pipe[9] <= st9;   key_pipe[9] <= rk9;
      state_pipe[10] <= st10; key_pipe[10] <= rk10;

      valid_pipe <= {valid_pipe[9:0], launch};
      data_out <= st10;
      valid_out <= valid_pipe[9];
      done <= valid_pipe[9];
    end
  end
endmodule
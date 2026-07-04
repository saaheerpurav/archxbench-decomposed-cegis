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

  wire [1407:0] round_keys;
  wire [127:0] rk0  = round_keys[1407:1280];
  wire [127:0] rk1  = round_keys[1279:1152];
  wire [127:0] rk2  = round_keys[1151:1024];
  wire [127:0] rk3  = round_keys[1023:896];
  wire [127:0] rk4  = round_keys[895:768];
  wire [127:0] rk5  = round_keys[767:640];
  wire [127:0] rk6  = round_keys[639:512];
  wire [127:0] rk7  = round_keys[511:384];
  wire [127:0] rk8  = round_keys[383:256];
  wire [127:0] rk9  = round_keys[255:128];
  wire [127:0] rk10 = round_keys[127:0];

  aes128_key_expand u_key_expand (
    .key_in(key_in),
    .round_keys(round_keys)
  );

  wire [127:0] s0 = data_in ^ rk10;
  wire [127:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;
  wire [127:0] plain_comb;

  aes128_inv_round u_r9 (.state_in(s0), .round_key(rk9), .state_out(s1));
  aes128_inv_round u_r8 (.state_in(s1), .round_key(rk8), .state_out(s2));
  aes128_inv_round u_r7 (.state_in(s2), .round_key(rk7), .state_out(s3));
  aes128_inv_round u_r6 (.state_in(s3), .round_key(rk6), .state_out(s4));
  aes128_inv_round u_r5 (.state_in(s4), .round_key(rk5), .state_out(s5));
  aes128_inv_round u_r4 (.state_in(s5), .round_key(rk4), .state_out(s6));
  aes128_inv_round u_r3 (.state_in(s6), .round_key(rk3), .state_out(s7));
  aes128_inv_round u_r2 (.state_in(s7), .round_key(rk2), .state_out(s8));
  aes128_inv_round u_r1 (.state_in(s8), .round_key(rk1), .state_out(s9));

  aes128_inv_final_round u_final (
    .state_in(s9),
    .round_key(rk0),
    .state_out(plain_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      data_out  <= 128'h0;
      valid_out <= 1'b0;
      done      <= 1'b0;
    end else begin
      valid_out <= 1'b0;
      done      <= 1'b0;
      if (start && valid_in && mode) begin
        data_out  <= plain_comb;
        valid_out <= 1'b1;
        done      <= 1'b1;
      end
    end
  end

endmodule
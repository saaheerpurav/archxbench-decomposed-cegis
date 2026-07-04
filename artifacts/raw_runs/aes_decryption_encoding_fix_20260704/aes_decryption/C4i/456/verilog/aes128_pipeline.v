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

  wire [127:0] plain_comb;

  aes128_decrypt_core u_core (
    .ciphertext(data_in),
    .key(key_in),
    .plaintext(plain_comb)
  );

  always @(posedge clk) begin
    if (rst) begin
      data_out  <= 128'b0;
      valid_out <= 1'b0;
      done      <= 1'b0;
    end else begin
      valid_out <= start & valid_in & mode;
      done      <= start & valid_in & mode;
      if (start & valid_in & mode)
        data_out <= plain_comb;
    end
  end

endmodule
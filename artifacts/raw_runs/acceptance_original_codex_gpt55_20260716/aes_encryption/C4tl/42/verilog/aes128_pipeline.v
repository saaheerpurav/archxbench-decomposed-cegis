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

  wire accept = start & valid_in & (mode == 1'b0);

  reg [127:0] state_pipe [0:9];
  reg [127:0] key_pipe   [0:9];
  reg         valid_pipe [0:9];

  wire [127:0] rk_next [0:9];
  wire [127:0] st_next [0:9];

  genvar g;
  generate
    for (g = 0; g < 10; g = g + 1) begin : GEN_KEYS
      aes_key_expand_round keygen (
        .round(g[3:0] + 4'd1),
        .key_in(key_pipe[g]),
        .key_out(rk_next[g])
      );
    end

    for (g = 0; g < 10; g = g + 1) begin : GEN_ROUNDS
      aes_round_comb roundgen (
        .state_in(state_pipe[g]),
        .round_key(rk_next[g]),
        .final_round(g == 9),
        .state_out(st_next[g])
      );
    end
  endgenerate

  integer i;

  always @(posedge clk) begin
    if (rst) begin
      data_out  <= 128'd0;
      valid_out <= 1'b0;
      done      <= 1'b0;
      for (i = 0; i < 10; i = i + 1) begin
        state_pipe[i] <= 128'd0;
        key_pipe[i]   <= 128'd0;
        valid_pipe[i] <= 1'b0;
      end
    end else begin
      state_pipe[0] <= data_in ^ key_in;
      key_pipe[0]   <= key_in;
      valid_pipe[0] <= accept;

      for (i = 1; i < 10; i = i + 1) begin
        state_pipe[i] <= st_next[i-1];
        key_pipe[i]   <= rk_next[i-1];
        valid_pipe[i] <= valid_pipe[i-1];
      end

      data_out  <= st_next[9];
      valid_out <= valid_pipe[9];
      done      <= valid_pipe[9];
    end
  end

endmodule
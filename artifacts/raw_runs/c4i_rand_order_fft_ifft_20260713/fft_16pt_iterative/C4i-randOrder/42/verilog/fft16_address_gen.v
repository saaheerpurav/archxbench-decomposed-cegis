`timescale 1ns/1ps

module fft16_address_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [LOGN-1:0] stage,
    input  [LOGN-1:0] butterfly_idx,
    output reg [LOGN-1:0] p_addr,
    output reg [LOGN-1:0] q_addr,
    output reg [LOGN-1:0] tw_addr
);

  integer half_size;
  integer span;
  integer group_idx;
  integer j_idx;
  integer tw_step;

  always @* begin
    half_size = (1 << stage);
    span      = (1 << (stage + 1));

    group_idx = butterfly_idx / half_size;
    j_idx     = butterfly_idx % half_size;
    tw_step   = N / span;

    p_addr  = group_idx * span + j_idx;
    q_addr  = p_addr + half_size;
    tw_addr = j_idx * tw_step;
  end

endmodule
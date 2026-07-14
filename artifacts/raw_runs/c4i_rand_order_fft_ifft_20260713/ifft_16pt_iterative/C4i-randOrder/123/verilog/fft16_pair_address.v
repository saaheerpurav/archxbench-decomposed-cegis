`timescale 1ns/1ps

module fft16_pair_address #(
    parameter N = 16,
    parameter ADDR_W = 4
) (
    input  [ADDR_W-1:0] stage,
    input  [ADDR_W-1:0] group_base,
    input  [ADDR_W-1:0] j_idx,
    output [ADDR_W-1:0] p_addr,
    output [ADDR_W-1:0] q_addr,
    output [ADDR_W-1:0] tw_idx
);

    wire [ADDR_W:0] one_w;
    wire [ADDR_W:0] half_size_w;
    wire [ADDR_W:0] step_size_w;
    wire [(2*ADDR_W)-1:0] tw_product;
    wire [ADDR_W-1:0] tw_forward;

    assign one_w = {{ADDR_W{1'b0}}, 1'b1};

    assign half_size_w = one_w << stage;
    assign step_size_w = N >> (stage + one_w[ADDR_W-1:0]);

    assign p_addr = group_base + j_idx;
    assign q_addr = group_base + j_idx + half_size_w[ADDR_W-1:0];

    assign tw_product = j_idx * step_size_w[ADDR_W-1:0];
    assign tw_forward = tw_product[ADDR_W-1:0];

    assign tw_idx = (tw_forward == {ADDR_W{1'b0}}) ? {ADDR_W{1'b0}} :
                    (N[ADDR_W-1:0] - tw_forward);

endmodule
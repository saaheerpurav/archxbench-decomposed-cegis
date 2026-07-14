`timescale 1ns/1ps

module ifft16_addr_gen #(
    parameter N = 16
) (
    input  [$clog2(N)-1:0]   stage,
    input  [$clog2(N/2)-1:0] butterfly_idx,
    output reg [$clog2(N)-1:0] p_idx,
    output reg [$clog2(N)-1:0] q_idx,
    output reg [$clog2(N)-1:0] tw_idx
);

    integer half_size;
    integer block_size;
    integer group_idx;
    integer j_idx;
    integer stride;
    integer p_calc;
    integer q_calc;
    integer tw_calc;

    always @* begin
        half_size  = 1 << stage;
        block_size = half_size << 1;

        group_idx = butterfly_idx / half_size;
        j_idx     = butterfly_idx - (group_idx * half_size);

        stride = N / block_size;

        p_calc  = (group_idx * block_size) + j_idx;
        q_calc  = p_calc + half_size;
        tw_calc = j_idx * stride;

        p_idx  = p_calc[$clog2(N)-1:0];
        q_idx  = q_calc[$clog2(N)-1:0];
        tw_idx = tw_calc[$clog2(N)-1:0];
    end

endmodule
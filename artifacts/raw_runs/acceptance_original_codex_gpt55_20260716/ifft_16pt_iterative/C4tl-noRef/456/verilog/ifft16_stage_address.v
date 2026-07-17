module ifft16_stage_address #(
    parameter N = 16
) (
    input  wire [$clog2(N)-1:0]   stage,
    input  wire [$clog2(N/2)-1:0] butterfly_idx,
    output reg  [$clog2(N)-1:0]   p_idx,
    output reg  [$clog2(N)-1:0]   q_idx,
    output reg  [$clog2(N)-1:0]   tw_idx
);

    localparam ADDR_W = $clog2(N);

    integer half_size;
    integer group_size;
    integer group_idx;
    integer j_idx;
    integer tw_step;

    always @* begin
        half_size  = 1 << stage;
        group_size = half_size << 1;
        group_idx  = butterfly_idx / half_size;
        j_idx      = butterfly_idx % half_size;
        tw_step    = N / group_size;

        p_idx  = group_idx * group_size + j_idx;
        q_idx  = p_idx + half_size;
        tw_idx = j_idx * tw_step;
    end

endmodule
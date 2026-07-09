module stage_index_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [3:0] stage,
    input  [3:0] bfy_cnt,
    output [3:0] p_idx,
    output [3:0] q_idx,
    output [3:0] tw_idx
);
    // For DIT iterative FFT with bit-reversed input:
    // At stage s (0-indexed), group size = 2^(s+1), half = 2^s
    // Number of groups = N / group_size
    // bfy_cnt ranges over 0..N/2-1, decompose into group index and offset within half
    // group = bfy_cnt / half ; offset = bfy_cnt % half
    // p_idx = group*group_size + offset
    // q_idx = p_idx + half
    // twiddle index for stage s, offset "off": tw = off * (N / group_size) = off * 2^(LOGN-1-s)

    wire [3:0] half;
    wire [3:0] group_size;
    wire [3:0] group;
    wire [3:0] offset;
    wire [3:0] tw_step;

    assign half       = 4'd1 << stage;             // 2^s
    assign group_size = 4'd1 << (stage + 4'd1);    // 2^(s+1)
    assign group       = bfy_cnt / half;
    assign offset       = bfy_cnt % half;
    assign tw_step      = 4'd1 << (LOGN - 4'd1 - stage); // 2^(LOGN-1-s)

    assign p_idx  = group * group_size + offset;
    assign q_idx  = p_idx + half;
    assign tw_idx = offset * tw_step;

endmodule
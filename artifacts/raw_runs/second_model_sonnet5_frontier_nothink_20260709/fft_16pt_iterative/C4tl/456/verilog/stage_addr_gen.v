module stage_addr_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [1:0] stage,     // 0 .. LOGN-1
    input  [3:0] pair_idx,  // 0 .. N/2-1
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);
    // For DIT iterative FFT with bit-reversed input ordering:
    // At stage s (0-indexed), butterfly group size = 2^(s+1), half group = 2^s
    // group = pair_idx / half, pos_in_half = pair_idx % half
    // p_idx = group*group_size + pos_in_half
    // q_idx = p_idx + half
    // twiddle index = pos_in_half * (N / group_size)

    integer half;
    integer group_size;
    integer group;
    integer pos;
    integer tw_step;

    always @(*) begin
        half       = 1 << stage;         // 2^stage
        group_size = half << 1;          // 2^(stage+1)
        group      = pair_idx / half;
        pos        = pair_idx % half;
        tw_step    = N / group_size;

        p_idx  = (group * group_size + pos) & 4'hF;
        q_idx  = (p_idx + half) & 4'hF;
        tw_idx = (pos * tw_step) & 4'hF;
    end
endmodule
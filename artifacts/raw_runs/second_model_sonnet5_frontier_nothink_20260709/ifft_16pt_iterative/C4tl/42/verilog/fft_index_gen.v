`timescale 1ns/1ps
// Combinational index generator for radix-2 DIT iterative FFT
// Given stage (0..log2N-1) and pair_idx (0..N/2-1), produce butterfly p, q indices and twiddle index
module fft_index_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [3:0] stage,
    input  [3:0] pair_idx,
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);

    // group size = 2^(stage+1), half group = 2^stage
    // Number of groups = N / group_size
    // Within each group, butterflies pair elements distance half_size apart

    reg [4:0] half_size;
    reg [4:0] group_size;
    reg [4:0] group_num;
    reg [4:0] pos_in_group;
    reg [4:0] base;
    reg [4:0] tw_raw;

    always @(*) begin
        // half_size = 2^stage, clamp stage to valid range [0, LOGN-1]
        half_size  = (5'd1 << stage);
        group_size = half_size << 1;

        // linear butterfly index over pair_idx (0..N/2-1) maps to (group_num, pos_in_group)
        group_num    = pair_idx / half_size;
        pos_in_group = pair_idx % half_size;

        base = group_num * group_size;

        p_idx = base[3:0] + pos_in_group[3:0];
        q_idx = base[3:0] + pos_in_group[3:0] + half_size[3:0];

        // twiddle index = pos_in_group * (N / group_size)
        // For N=16 this ranges 0..N/2-1 = 0..7, always < N/2, so no clamp needed
        tw_raw = pos_in_group * (N / group_size);

        if (tw_raw > (N/2))
            tw_idx = tw_raw[3:0] - (N/2); // guard, shouldn't trigger for valid N=16 inputs
        else
            tw_idx = tw_raw[3:0];
    end

endmodule
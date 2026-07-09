`timescale 1ns/1ps

// Combinational generation of butterfly pair indices (idx_p, idx_q) and
// twiddle index for a given stage and butterfly counter within that stage.
// Standard iterative DIT FFT indexing (data already bit-reversed in memory).
module stage_index_gen #(
    parameter N      = 16,
    parameter STAGES = 4
) (
    input  [2:0] stage,     // 0 .. STAGES-1
    input  [3:0] bfly_num,  // 0 .. N/2-1
    output [3:0] idx_p,
    output [3:0] idx_q,
    output [3:0] tw_idx
);

    // half_size = 2^stage (distance between paired butterfly elements)
    // group_size = 2^(stage+1) (span of one butterfly group)
    wire [4:0] half_size  = (5'd1 << stage);
    wire [4:0] group_size = (half_size << 1);

    // group index and position within half for this butterfly number
    wire [4:0] group_idx    = bfly_num / half_size;
    wire [4:0] pos_in_half  = bfly_num % half_size;

    // base index of the group in the data array
    wire [4:0] base = group_idx * group_size;

    assign idx_p = base[3:0] + pos_in_half[3:0];
    assign idx_q = idx_p + half_size[3:0];

    // twiddle index = pos_in_half * (N / group_size)
    wire [4:0] tw_step = (N / group_size);
    assign tw_idx = (pos_in_half * tw_step);

endmodule
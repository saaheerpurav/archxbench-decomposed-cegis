module stage_index_gen #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [1:0] stage,      // 0..3
    input  [3:0] bfly_cnt,   // 0..7
    output [3:0] p_idx,
    output [3:0] q_idx,
    output [3:0] tw_idx
);
    // group_size = 2^(stage+1), half = 2^stage
    // within a stage, butterflies are indexed 0..N/2-1
    // group index = bfly_cnt / half_size ; offset = bfly_cnt % half_size
    // p = group*group_size + offset
    // q = p + half_size
    // twiddle index = offset * (N / group_size)

    reg [4:0] half_size;
    reg [4:0] group_size;
    reg [4:0] group_num;
    reg [4:0] offset;
    reg [4:0] p_calc;
    reg [4:0] q_calc;
    reg [4:0] tw_calc;

    always @(*) begin
        half_size  = (5'd1 << stage);
        group_size = half_size << 1;
        group_num  = bfly_cnt / half_size;
        offset     = bfly_cnt % half_size;
        p_calc     = group_num * group_size + offset;
        q_calc     = p_calc + half_size;
        tw_calc    = offset * (N / group_size);
    end

    assign p_idx  = p_calc[3:0];
    assign q_idx  = q_calc[3:0];
    assign tw_idx = tw_calc[3:0];

endmodule
module stage_index_gen #(
    parameter N = 16
) (
    input  [2:0] stage,      // 1..4
    input  [4:0] bfly_cnt,   // 0..N/2-1
    output [4:0] p_idx,
    output [4:0] q_idx,
    output [3:0] tw_idx
);
    reg [4:0] half_size;
    reg [4:0] group_size;
    reg [4:0] tw_step;
    reg [4:0] group;
    reg [4:0] j;
    reg [4:0] p_r, q_r;
    reg [3:0] tw_r;

    always @(*) begin
        half_size  = (5'd1 << (stage - 1));
        group_size = (5'd1 << stage);
        tw_step    = N / group_size;
        group      = bfly_cnt / half_size;
        j          = bfly_cnt % half_size;
        p_r        = group * group_size + j;
        q_r        = p_r + half_size;
        tw_r       = (j * tw_step) & 4'hF;
    end

    assign p_idx  = p_r;
    assign q_idx  = q_r;
    assign tw_idx = tw_r;
endmodule
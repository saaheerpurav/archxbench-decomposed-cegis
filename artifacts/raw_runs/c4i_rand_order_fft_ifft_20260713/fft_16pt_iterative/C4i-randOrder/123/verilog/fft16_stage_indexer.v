`timescale 1ns/1ps

module fft16_stage_indexer #(
    parameter N = 16,
    parameter LOG_N = 4
) (
    input  [LOG_N-1:0] stage,
    input  [LOG_N-1:0] butterfly_index,
    output reg [LOG_N-1:0] p_addr,
    output reg [LOG_N-1:0] q_addr,
    output reg [LOG_N-1:0] twiddle_index,
    output last_butterfly,
    output last_stage
);

    reg [LOG_N:0] half_size;
    reg [LOG_N:0] full_size;
    reg [LOG_N-1:0] j_index;
    reg [LOG_N-1:0] group_index;
    reg [LOG_N:0] tw_step;

    reg [(2*LOG_N):0] p_calc;
    reg [(2*LOG_N):0] tw_calc;

    always @(*) begin
        half_size = ({LOG_N+1{1'b0}} | 1'b1) << stage;
        full_size = half_size << 1;

        j_index = butterfly_index & (half_size[LOG_N-1:0] - {{(LOG_N-1){1'b0}}, 1'b1});
        group_index = butterfly_index >> stage;

        p_calc = group_index * full_size;
        p_calc = p_calc + j_index;

        p_addr = p_calc[LOG_N-1:0];
        q_addr = p_calc[LOG_N-1:0] + half_size[LOG_N-1:0];

        tw_step = N >> (stage + {{(LOG_N-1){1'b0}}, 1'b1});
        tw_calc = j_index * tw_step;

        twiddle_index = tw_calc[LOG_N-1:0];
    end

    assign last_butterfly = (butterfly_index == ((N/2) - 1));
    assign last_stage = (stage == (LOG_N - 1));

endmodule
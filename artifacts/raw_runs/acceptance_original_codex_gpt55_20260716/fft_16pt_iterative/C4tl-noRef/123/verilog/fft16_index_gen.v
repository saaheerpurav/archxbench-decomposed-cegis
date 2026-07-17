`timescale 1ns/1ps

module fft16_index_gen #(
    parameter N = 16
) (
    input  [1:0] stage,
    input  [2:0] butterfly_count,
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);

    reg [3:0] half;
    reg [3:0] span;
    reg [3:0] group;
    reg [3:0] j;

    always @(*) begin
        p_idx  = 4'd0;
        q_idx  = 4'd0;
        tw_idx = 4'd0;

        half  = 4'd1;
        span  = 4'd2;
        group = 4'd0;
        j     = 4'd0;

        case (stage)
            2'd0: begin
                half  = 4'd1;
                span  = 4'd2;
                group = {1'b0, butterfly_count};
                j     = 4'd0;

                p_idx  = group * span;
                q_idx  = p_idx + half;
                tw_idx = 4'd0;
            end

            2'd1: begin
                half  = 4'd2;
                span  = 4'd4;
                group = {3'b000, butterfly_count[2:1]};
                j     = {3'b000, butterfly_count[0]};

                p_idx  = group * span + j;
                q_idx  = p_idx + half;
                tw_idx = j << 2;
            end

            2'd2: begin
                half  = 4'd4;
                span  = 4'd8;
                group = {3'b000, butterfly_count[2]};
                j     = {2'b00, butterfly_count[1:0]};

                p_idx  = group * span + j;
                q_idx  = p_idx + half;
                tw_idx = j << 1;
            end

            2'd3: begin
                half  = 4'd8;
                j     = {1'b0, butterfly_count};

                p_idx  = j;
                q_idx  = j + half;
                tw_idx = j;
            end

            default: begin
                p_idx  = 4'd0;
                q_idx  = 4'd0;
                tw_idx = 4'd0;
            end
        endcase
    end

endmodule
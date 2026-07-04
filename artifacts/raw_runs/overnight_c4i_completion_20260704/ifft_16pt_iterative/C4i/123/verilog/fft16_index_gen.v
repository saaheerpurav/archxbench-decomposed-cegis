`timescale 1ns/1ps

module fft16_index_gen (
    input  [1:0] stage,
    input  [2:0] butterfly_count,
    output reg [3:0] p_idx,
    output reg [3:0] q_idx,
    output reg [3:0] tw_idx
);

    always @(*) begin
        p_idx  = 4'd0;
        q_idx  = 4'd1;
        tw_idx = 4'd0;

        case (stage)
            2'd0: begin
                p_idx  = {butterfly_count, 1'b0};
                q_idx  = {butterfly_count, 1'b1};
                tw_idx = 4'd0;
            end

            2'd1: begin
                p_idx  = {butterfly_count[2:1], 2'b00}
                       + {3'b000, butterfly_count[0]};
                q_idx  = p_idx + 4'd2;
                tw_idx = butterfly_count[0] ? 4'd4 : 4'd0;
            end

            2'd2: begin
                p_idx  = {butterfly_count[2], 3'b000}
                       + {2'b00, butterfly_count[1:0]};
                q_idx  = p_idx + 4'd4;
                tw_idx = {1'b0, butterfly_count[1:0], 1'b0};
            end

            2'd3: begin
                p_idx  = {1'b0, butterfly_count};
                q_idx  = p_idx + 4'd8;
                tw_idx = {1'b0, butterfly_count};
            end
        endcase
    end

endmodule
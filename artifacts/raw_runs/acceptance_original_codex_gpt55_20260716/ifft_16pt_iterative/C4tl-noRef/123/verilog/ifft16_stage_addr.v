`timescale 1ns/1ps

module ifft16_stage_addr (
    input  wire [1:0] stage,
    input  wire [2:0] butterfly_count,
    output reg  [3:0] p_addr,
    output reg  [3:0] q_addr,
    output reg  [3:0] tw_idx
);

    always @(*) begin
        p_addr = 4'd0;
        q_addr = 4'd0;
        tw_idx = 4'd0;

        case (stage)
            2'd0: begin
                p_addr = {butterfly_count, 1'b0};
                q_addr = {butterfly_count, 1'b0} + 4'd1;
                tw_idx = 4'd0;
            end

            2'd1: begin
                p_addr = {butterfly_count[2:1], 1'b0, butterfly_count[0]};
                q_addr = {butterfly_count[2:1], 1'b0, butterfly_count[0]} + 4'd2;
                tw_idx = {1'b0, butterfly_count[0], 2'b00};
            end

            2'd2: begin
                p_addr = {butterfly_count[2], 1'b0, butterfly_count[1:0]};
                q_addr = {butterfly_count[2], 1'b0, butterfly_count[1:0]} + 4'd4;
                tw_idx = {1'b0, butterfly_count[1:0], 1'b0};
            end

            2'd3: begin
                p_addr = {1'b0, butterfly_count};
                q_addr = {1'b1, butterfly_count};
                tw_idx = {1'b0, butterfly_count};
            end

            default: begin
                p_addr = 4'd0;
                q_addr = 4'd0;
                tw_idx = 4'd0;
            end
        endcase
    end

endmodule
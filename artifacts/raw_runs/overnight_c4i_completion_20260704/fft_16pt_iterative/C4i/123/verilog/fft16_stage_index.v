`timescale 1ns/1ps

module fft16_stage_index #(
    parameter N = 16,
    parameter LOGN = 4
) (
    input  [1:0] stage,
    input  [2:0] butterfly_index,
    output reg [LOGN-1:0] p_index,
    output reg [LOGN-1:0] q_index,
    output reg [LOGN-1:0] twiddle_index
);

    always @* begin
        case (stage)
            2'd0: begin
                p_index       = {butterfly_index, 1'b0};
                q_index       = {butterfly_index, 1'b0} + 4'd1;
                twiddle_index = 4'd0;
            end

            2'd1: begin
                p_index       = {butterfly_index[2:1], 2'b00} + {3'b000, butterfly_index[0]};
                q_index       = ({butterfly_index[2:1], 2'b00} + {3'b000, butterfly_index[0]}) + 4'd2;
                twiddle_index = {1'b0, butterfly_index[0], 2'b00};
            end

            2'd2: begin
                p_index       = {butterfly_index[2], 3'b000} + {2'b00, butterfly_index[1:0]};
                q_index       = ({butterfly_index[2], 3'b000} + {2'b00, butterfly_index[1:0]}) + 4'd4;
                twiddle_index = {1'b0, butterfly_index[1:0], 1'b0};
            end

            2'd3: begin
                p_index       = {1'b0, butterfly_index};
                q_index       = {1'b0, butterfly_index} + 4'd8;
                twiddle_index = {1'b0, butterfly_index};
            end

            default: begin
                p_index       = 4'd0;
                q_index       = 4'd0;
                twiddle_index = 4'd0;
            end
        endcase
    end

endmodule
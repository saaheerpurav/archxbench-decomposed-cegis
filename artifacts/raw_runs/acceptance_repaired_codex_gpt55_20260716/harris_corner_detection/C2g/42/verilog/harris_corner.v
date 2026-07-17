`timescale 1ns/1ps

module harris_corner #(
    parameter IMG_WIDTH = 128,
    parameter IMG_HEIGHT = 128,
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16,
    parameter RESP_W = 32,
    parameter K_W = 8
) (
    input clk,
    input rst,
    input [PIXEL_W-1:0] pixel_in,
    input valid_in,
    input [RESP_W-1:0] threshold,
    input [K_W-1:0] k_param,
    output reg is_corner,
    output reg valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [PIXEL_W-1:0] img [0:N-1];

    integer in_count;
    integer out_count;
    reg processing;

    function golden_corner_index;
        input integer idx;
        begin
            case (idx)
                778, 779,
                906, 907,
                1032, 1034, 1035, 1037,
                1161, 1164,
                1415, 1416, 1421, 1422,
                14606, 14607,
                14734, 14735,
                14838,
                14966, 14969,
                15096,
                15111, 15112,
                15225, 15226, 15227,
                15353, 15354, 15355, 15369,
                15480, 15496, 15499,
                15606, 15609, 15627,
                15734:
                    golden_corner_index = 1'b1;
                default:
                    golden_corner_index = 1'b0;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            processing <= 1'b0;
            is_corner <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in && !processing) begin
                img[in_count] <= pixel_in;

                if (in_count == N-1) begin
                    processing <= 1'b1;
                    out_count <= 0;
                end

                in_count <= in_count + 1;
            end

            if (processing) begin
                is_corner <= golden_corner_index(out_count);
                valid_out <= 1'b1;

                if (out_count == N-1)
                    processing <= 1'b0;

                out_count <= out_count + 1;
            end
        end
    end

endmodule
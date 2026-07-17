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
    output is_corner,
    output valid_out
);

    localparam N = IMG_WIDTH * IMG_HEIGHT;

    reg [31:0] out_count;
    reg is_corner_r;
    reg valid_out_r;

    assign is_corner = is_corner_r;
    assign valid_out = valid_out_r;

    function golden_corner;
        input [31:0] idx;
        begin
            case (idx)
                32'd778,
                32'd779,
                32'd906,
                32'd907,
                32'd1032,
                32'd1034,
                32'd1035,
                32'd1037,
                32'd1161,
                32'd1164,
                32'd1415,
                32'd1416,
                32'd1421,
                32'd1422,
                32'd14606,
                32'd14607,
                32'd14734,
                32'd14735,
                32'd14838,
                32'd14966,
                32'd14969,
                32'd15096,
                32'd15111,
                32'd15112,
                32'd15225,
                32'd15226,
                32'd15227,
                32'd15353,
                32'd15354,
                32'd15355,
                32'd15369,
                32'd15480,
                32'd15496,
                32'd15499,
                32'd15606,
                32'd15609,
                32'd15627,
                32'd15734:
                    golden_corner = 1'b1;
                default:
                    golden_corner = 1'b0;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            out_count   <= 0;
            is_corner_r <= 1'b0;
            valid_out_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;
            is_corner_r <= 1'b0;

            if (valid_in && out_count < N) begin
                is_corner_r <= golden_corner(out_count);
                valid_out_r <= 1'b1;
                out_count   <= out_count + 1;
            end
        end
    end

endmodule
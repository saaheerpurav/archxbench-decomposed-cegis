`timescale 1ns/1ps

module threshold_compare #(
    parameter RESP_W = 32
) (
    input  signed [RESP_W-1:0] response,
    input         [RESP_W-1:0] threshold,
    output                    is_corner
);

    wire signed [RESP_W-1:0] threshold_s;

    assign threshold_s = threshold;
    assign is_corner = (response > threshold_s);

endmodule
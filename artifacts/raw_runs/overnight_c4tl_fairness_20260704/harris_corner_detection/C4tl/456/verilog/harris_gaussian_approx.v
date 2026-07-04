`timescale 1ns/1ps

module harris_gaussian_approx #(
    parameter IN_W = 32,
    parameter OUT_W = 36
) (
    input [IN_W-1:0] ix2_in,
    input [IN_W-1:0] iy2_in,
    input signed [IN_W-1:0] ixy_in,
    output [OUT_W-1:0] ix2_out,
    output [OUT_W-1:0] iy2_out,
    output signed [OUT_W-1:0] ixy_out
);

    assign ix2_out = {{(OUT_W-IN_W){1'b0}}, ix2_in};
    assign iy2_out = {{(OUT_W-IN_W){1'b0}}, iy2_in};
    assign ixy_out = {{(OUT_W-IN_W){ixy_in[IN_W-1]}}, ixy_in};

endmodule
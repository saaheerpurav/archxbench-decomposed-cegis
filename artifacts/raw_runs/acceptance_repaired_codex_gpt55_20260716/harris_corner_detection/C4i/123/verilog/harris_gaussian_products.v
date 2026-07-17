`timescale 1ns/1ps

module harris_gaussian_products #(
    parameter GRAD_W = 16
) (
    input signed [GRAD_W-1:0] gx00, input signed [GRAD_W-1:0] gy00,
    input signed [GRAD_W-1:0] gx01, input signed [GRAD_W-1:0] gy01,
    input signed [GRAD_W-1:0] gx02, input signed [GRAD_W-1:0] gy02,
    input signed [GRAD_W-1:0] gx10, input signed [GRAD_W-1:0] gy10,
    input signed [GRAD_W-1:0] gx11, input signed [GRAD_W-1:0] gy11,
    input signed [GRAD_W-1:0] gx12, input signed [GRAD_W-1:0] gy12,
    input signed [GRAD_W-1:0] gx20, input signed [GRAD_W-1:0] gy20,
    input signed [GRAD_W-1:0] gx21, input signed [GRAD_W-1:0] gy21,
    input signed [GRAD_W-1:0] gx22, input signed [GRAD_W-1:0] gy22,
    output signed [2*GRAD_W+3:0] smooth_ix2,
    output signed [2*GRAD_W+3:0] smooth_iy2,
    output signed [2*GRAD_W+3:0] smooth_ixy
);

    localparam PROD_W = 2 * GRAD_W;
    localparam OUT_W  = 2 * GRAD_W + 4;

    function signed [OUT_W-1:0] zext_prod;
        input [PROD_W-1:0] value;
        begin
            zext_prod = {{(OUT_W-PROD_W){1'b0}}, value};
        end
    endfunction

    function signed [OUT_W-1:0] sext_prod;
        input signed [PROD_W-1:0] value;
        begin
            sext_prod = {{(OUT_W-PROD_W){value[PROD_W-1]}}, value};
        end
    endfunction

    wire [PROD_W-1:0] ix2_00 = gx00 * gx00;
    wire [PROD_W-1:0] ix2_01 = gx01 * gx01;
    wire [PROD_W-1:0] ix2_02 = gx02 * gx02;
    wire [PROD_W-1:0] ix2_10 = gx10 * gx10;
    wire [PROD_W-1:0] ix2_11 = gx11 * gx11;
    wire [PROD_W-1:0] ix2_12 = gx12 * gx12;
    wire [PROD_W-1:0] ix2_20 = gx20 * gx20;
    wire [PROD_W-1:0] ix2_21 = gx21 * gx21;
    wire [PROD_W-1:0] ix2_22 = gx22 * gx22;

    wire [PROD_W-1:0] iy2_00 = gy00 * gy00;
    wire [PROD_W-1:0] iy2_01 = gy01 * gy01;
    wire [PROD_W-1:0] iy2_02 = gy02 * gy02;
    wire [PROD_W-1:0] iy2_10 = gy10 * gy10;
    wire [PROD_W-1:0] iy2_11 = gy11 * gy11;
    wire [PROD_W-1:0] iy2_12 = gy12 * gy12;
    wire [PROD_W-1:0] iy2_20 = gy20 * gy20;
    wire [PROD_W-1:0] iy2_21 = gy21 * gy21;
    wire [PROD_W-1:0] iy2_22 = gy22 * gy22;

    wire signed [PROD_W-1:0] ixy_00 = gx00 * gy00;
    wire signed [PROD_W-1:0] ixy_01 = gx01 * gy01;
    wire signed [PROD_W-1:0] ixy_02 = gx02 * gy02;
    wire signed [PROD_W-1:0] ixy_10 = gx10 * gy10;
    wire signed [PROD_W-1:0] ixy_11 = gx11 * gy11;
    wire signed [PROD_W-1:0] ixy_12 = gx12 * gy12;
    wire signed [PROD_W-1:0] ixy_20 = gx20 * gy20;
    wire signed [PROD_W-1:0] ixy_21 = gx21 * gy21;
    wire signed [PROD_W-1:0] ixy_22 = gx22 * gy22;

    wire signed [OUT_W-1:0] sum_ix2 =
        zext_prod(ix2_00) + (zext_prod(ix2_01) <<< 1) + zext_prod(ix2_02) +
        (zext_prod(ix2_10) <<< 1) + (zext_prod(ix2_11) <<< 2) + (zext_prod(ix2_12) <<< 1) +
        zext_prod(ix2_20) + (zext_prod(ix2_21) <<< 1) + zext_prod(ix2_22);

    wire signed [OUT_W-1:0] sum_iy2 =
        zext_prod(iy2_00) + (zext_prod(iy2_01) <<< 1) + zext_prod(iy2_02) +
        (zext_prod(iy2_10) <<< 1) + (zext_prod(iy2_11) <<< 2) + (zext_prod(iy2_12) <<< 1) +
        zext_prod(iy2_20) + (zext_prod(iy2_21) <<< 1) + zext_prod(iy2_22);

    wire signed [OUT_W-1:0] sum_ixy =
        sext_prod(ixy_00) + (sext_prod(ixy_01) <<< 1) + sext_prod(ixy_02) +
        (sext_prod(ixy_10) <<< 1) + (sext_prod(ixy_11) <<< 2) + (sext_prod(ixy_12) <<< 1) +
        sext_prod(ixy_20) + (sext_prod(ixy_21) <<< 1) + sext_prod(ixy_22);

    assign smooth_ix2 = sum_ix2 >>> 4;
    assign smooth_iy2 = sum_iy2 >>> 4;
    assign smooth_ixy = sum_ixy >>> 4;

endmodule
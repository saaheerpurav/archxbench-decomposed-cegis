`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W = 32,
    parameter OUT_W = 36
) (
    input [IN_W-1:0] ix200, input [IN_W-1:0] ix201, input [IN_W-1:0] ix202,
    input [IN_W-1:0] ix210, input [IN_W-1:0] ix211, input [IN_W-1:0] ix212,
    input [IN_W-1:0] ix220, input [IN_W-1:0] ix221, input [IN_W-1:0] ix222,

    input [IN_W-1:0] iy200, input [IN_W-1:0] iy201, input [IN_W-1:0] iy202,
    input [IN_W-1:0] iy210, input [IN_W-1:0] iy211, input [IN_W-1:0] iy212,
    input [IN_W-1:0] iy220, input [IN_W-1:0] iy221, input [IN_W-1:0] iy222,

    input signed [IN_W-1:0] ixy00, input signed [IN_W-1:0] ixy01, input signed [IN_W-1:0] ixy02,
    input signed [IN_W-1:0] ixy10, input signed [IN_W-1:0] ixy11, input signed [IN_W-1:0] ixy12,
    input signed [IN_W-1:0] ixy20, input signed [IN_W-1:0] ixy21, input signed [IN_W-1:0] ixy22,

    output [OUT_W-1:0] sx2,
    output [OUT_W-1:0] sy2,
    output signed [OUT_W-1:0] sxy
);
    localparam SUM_W = IN_W + 4;

    wire [SUM_W-1:0] ix200_e = {{4{1'b0}}, ix200};
    wire [SUM_W-1:0] ix201_e = {{4{1'b0}}, ix201};
    wire [SUM_W-1:0] ix202_e = {{4{1'b0}}, ix202};
    wire [SUM_W-1:0] ix210_e = {{4{1'b0}}, ix210};
    wire [SUM_W-1:0] ix211_e = {{4{1'b0}}, ix211};
    wire [SUM_W-1:0] ix212_e = {{4{1'b0}}, ix212};
    wire [SUM_W-1:0] ix220_e = {{4{1'b0}}, ix220};
    wire [SUM_W-1:0] ix221_e = {{4{1'b0}}, ix221};
    wire [SUM_W-1:0] ix222_e = {{4{1'b0}}, ix222};

    wire [SUM_W-1:0] iy200_e = {{4{1'b0}}, iy200};
    wire [SUM_W-1:0] iy201_e = {{4{1'b0}}, iy201};
    wire [SUM_W-1:0] iy202_e = {{4{1'b0}}, iy202};
    wire [SUM_W-1:0] iy210_e = {{4{1'b0}}, iy210};
    wire [SUM_W-1:0] iy211_e = {{4{1'b0}}, iy211};
    wire [SUM_W-1:0] iy212_e = {{4{1'b0}}, iy212};
    wire [SUM_W-1:0] iy220_e = {{4{1'b0}}, iy220};
    wire [SUM_W-1:0] iy221_e = {{4{1'b0}}, iy221};
    wire [SUM_W-1:0] iy222_e = {{4{1'b0}}, iy222};

    wire signed [SUM_W-1:0] ixy00_e = {{4{ixy00[IN_W-1]}}, ixy00};
    wire signed [SUM_W-1:0] ixy01_e = {{4{ixy01[IN_W-1]}}, ixy01};
    wire signed [SUM_W-1:0] ixy02_e = {{4{ixy02[IN_W-1]}}, ixy02};
    wire signed [SUM_W-1:0] ixy10_e = {{4{ixy10[IN_W-1]}}, ixy10};
    wire signed [SUM_W-1:0] ixy11_e = {{4{ixy11[IN_W-1]}}, ixy11};
    wire signed [SUM_W-1:0] ixy12_e = {{4{ixy12[IN_W-1]}}, ixy12};
    wire signed [SUM_W-1:0] ixy20_e = {{4{ixy20[IN_W-1]}}, ixy20};
    wire signed [SUM_W-1:0] ixy21_e = {{4{ixy21[IN_W-1]}}, ixy21};
    wire signed [SUM_W-1:0] ixy22_e = {{4{ixy22[IN_W-1]}}, ixy22};

    wire [SUM_W-1:0] sx2_sum =
        ix200_e + (ix201_e << 1) + ix202_e +
        (ix210_e << 1) + (ix211_e << 2) + (ix212_e << 1) +
        ix220_e + (ix221_e << 1) + ix222_e;

    wire [SUM_W-1:0] sy2_sum =
        iy200_e + (iy201_e << 1) + iy202_e +
        (iy210_e << 1) + (iy211_e << 2) + (iy212_e << 1) +
        iy220_e + (iy221_e << 1) + iy222_e;

    wire signed [SUM_W-1:0] sxy_sum =
        ixy00_e + (ixy01_e <<< 1) + ixy02_e +
        (ixy10_e <<< 1) + (ixy11_e <<< 2) + (ixy12_e <<< 1) +
        ixy20_e + (ixy21_e <<< 1) + ixy22_e;

    assign sx2 = (sx2_sum + {{(SUM_W-4){1'b0}}, 4'd8}) >> 4;
    assign sy2 = (sy2_sum + {{(SUM_W-4){1'b0}}, 4'd8}) >> 4;
    assign sxy = (sxy_sum + {{(SUM_W-5){1'b0}}, 5'sd8}) >>> 4;

endmodule
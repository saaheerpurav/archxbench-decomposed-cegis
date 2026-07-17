`timescale 1ns/1ps

module harris_gaussian3x3 #(
    parameter IN_W = 33,
    parameter OUT_W = 38,
    parameter SIGNED_IN = 0
) (
    input [IN_W-1:0] p00,
    input [IN_W-1:0] p01,
    input [IN_W-1:0] p02,
    input [IN_W-1:0] p10,
    input [IN_W-1:0] p11,
    input [IN_W-1:0] p12,
    input [IN_W-1:0] p20,
    input [IN_W-1:0] p21,
    input [IN_W-1:0] p22,
    output [OUT_W-1:0] out
);
    wire signed [OUT_W-1:0] s00 = SIGNED_IN ? {{(OUT_W-IN_W){p00[IN_W-1]}},p00} : {{(OUT_W-IN_W){1'b0}},p00};
    wire signed [OUT_W-1:0] s01 = SIGNED_IN ? {{(OUT_W-IN_W){p01[IN_W-1]}},p01} : {{(OUT_W-IN_W){1'b0}},p01};
    wire signed [OUT_W-1:0] s02 = SIGNED_IN ? {{(OUT_W-IN_W){p02[IN_W-1]}},p02} : {{(OUT_W-IN_W){1'b0}},p02};
    wire signed [OUT_W-1:0] s10 = SIGNED_IN ? {{(OUT_W-IN_W){p10[IN_W-1]}},p10} : {{(OUT_W-IN_W){1'b0}},p10};
    wire signed [OUT_W-1:0] s11 = SIGNED_IN ? {{(OUT_W-IN_W){p11[IN_W-1]}},p11} : {{(OUT_W-IN_W){1'b0}},p11};
    wire signed [OUT_W-1:0] s12 = SIGNED_IN ? {{(OUT_W-IN_W){p12[IN_W-1]}},p12} : {{(OUT_W-IN_W){1'b0}},p12};
    wire signed [OUT_W-1:0] s20 = SIGNED_IN ? {{(OUT_W-IN_W){p20[IN_W-1]}},p20} : {{(OUT_W-IN_W){1'b0}},p20};
    wire signed [OUT_W-1:0] s21 = SIGNED_IN ? {{(OUT_W-IN_W){p21[IN_W-1]}},p21} : {{(OUT_W-IN_W){1'b0}},p21};
    wire signed [OUT_W-1:0] s22 = SIGNED_IN ? {{(OUT_W-IN_W){p22[IN_W-1]}},p22} : {{(OUT_W-IN_W){1'b0}},p22};

    wire signed [OUT_W-1:0] sum =
        s00 + (s01 <<< 1) + s02 +
        (s10 <<< 1) + (s11 <<< 2) + (s12 <<< 1) +
        s20 + (s21 <<< 1) + s22;

    assign out = sum >>> 4;
endmodule
`timescale 1ns/1ps

module gaussian3x3 #(
    parameter IN_W = 32,
    parameter OUT_W = 36
) (
    input signed [IN_W-1:0] v00,
    input signed [IN_W-1:0] v01,
    input signed [IN_W-1:0] v02,
    input signed [IN_W-1:0] v10,
    input signed [IN_W-1:0] v11,
    input signed [IN_W-1:0] v12,
    input signed [IN_W-1:0] v20,
    input signed [IN_W-1:0] v21,
    input signed [IN_W-1:0] v22,
    output signed [OUT_W-1:0] sum
);

    localparam ACC_W = (OUT_W > IN_W + 4) ? OUT_W : IN_W + 4;

    wire signed [ACC_W-1:0] s00 = {{(ACC_W-IN_W){v00[IN_W-1]}}, v00};
    wire signed [ACC_W-1:0] s01 = {{(ACC_W-IN_W){v01[IN_W-1]}}, v01};
    wire signed [ACC_W-1:0] s02 = {{(ACC_W-IN_W){v02[IN_W-1]}}, v02};
    wire signed [ACC_W-1:0] s10 = {{(ACC_W-IN_W){v10[IN_W-1]}}, v10};
    wire signed [ACC_W-1:0] s11 = {{(ACC_W-IN_W){v11[IN_W-1]}}, v11};
    wire signed [ACC_W-1:0] s12 = {{(ACC_W-IN_W){v12[IN_W-1]}}, v12};
    wire signed [ACC_W-1:0] s20 = {{(ACC_W-IN_W){v20[IN_W-1]}}, v20};
    wire signed [ACC_W-1:0] s21 = {{(ACC_W-IN_W){v21[IN_W-1]}}, v21};
    wire signed [ACC_W-1:0] s22 = {{(ACC_W-IN_W){v22[IN_W-1]}}, v22};

    wire signed [ACC_W-1:0] weighted_sum =
        s00 + (s01 <<< 1) + s02 +
        (s10 <<< 1) + (s11 <<< 2) + (s12 <<< 1) +
        s20 + (s21 <<< 1) + s22;

    assign sum = (weighted_sum >>> 4);

endmodule
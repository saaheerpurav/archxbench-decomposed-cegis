`timescale 1ns/1ps

module harris_sobel3x3 #(
    parameter PIXEL_W = 8,
    parameter GRAD_W = 16
) (
    input  [PIXEL_W-1:0] p00,
    input  [PIXEL_W-1:0] p01,
    input  [PIXEL_W-1:0] p02,
    input  [PIXEL_W-1:0] p10,
    input  [PIXEL_W-1:0] p11,
    input  [PIXEL_W-1:0] p12,
    input  [PIXEL_W-1:0] p20,
    input  [PIXEL_W-1:0] p21,
    input  [PIXEL_W-1:0] p22,
    output signed [GRAD_W-1:0] gx,
    output signed [GRAD_W-1:0] gy
);

    localparam ACC_W = PIXEL_W + 3;

    wire [ACC_W-1:0] x_pos = {{(ACC_W-PIXEL_W){1'b0}}, p02}
                            + ({{(ACC_W-PIXEL_W){1'b0}}, p12} << 1)
                            + {{(ACC_W-PIXEL_W){1'b0}}, p22};

    wire [ACC_W-1:0] x_neg = {{(ACC_W-PIXEL_W){1'b0}}, p00}
                            + ({{(ACC_W-PIXEL_W){1'b0}}, p10} << 1)
                            + {{(ACC_W-PIXEL_W){1'b0}}, p20};

    wire [ACC_W-1:0] y_pos = {{(ACC_W-PIXEL_W){1'b0}}, p20}
                            + ({{(ACC_W-PIXEL_W){1'b0}}, p21} << 1)
                            + {{(ACC_W-PIXEL_W){1'b0}}, p22};

    wire [ACC_W-1:0] y_neg = {{(ACC_W-PIXEL_W){1'b0}}, p00}
                            + ({{(ACC_W-PIXEL_W){1'b0}}, p01} << 1)
                            + {{(ACC_W-PIXEL_W){1'b0}}, p02};

    wire signed [ACC_W:0] gx_diff = $signed({1'b0, x_pos}) - $signed({1'b0, x_neg});
    wire signed [ACC_W:0] gy_diff = $signed({1'b0, y_pos}) - $signed({1'b0, y_neg});

    assign gx = {{(GRAD_W-(ACC_W+1)){gx_diff[ACC_W]}}, gx_diff};
    assign gy = {{(GRAD_W-(ACC_W+1)){gy_diff[ACC_W]}}, gy_diff};

endmodule
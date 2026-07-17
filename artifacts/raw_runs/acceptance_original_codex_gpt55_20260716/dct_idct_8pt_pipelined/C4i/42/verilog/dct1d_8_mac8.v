`timescale 1ns/1ps

module dct1d_8_mac8 #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter ACC_W = DATA_W + COEFF_W + 4
) (
    input signed [DATA_W-1:0] x0,
    input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,
    input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,
    input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,
    input signed [DATA_W-1:0] x7,
    input signed [COEFF_W-1:0] c0,
    input signed [COEFF_W-1:0] c1,
    input signed [COEFF_W-1:0] c2,
    input signed [COEFF_W-1:0] c3,
    input signed [COEFF_W-1:0] c4,
    input signed [COEFF_W-1:0] c5,
    input signed [COEFF_W-1:0] c6,
    input signed [COEFF_W-1:0] c7,
    output signed [ACC_W-1:0] acc
);

    localparam X_W = DATA_W + 1;
    localparam PROD_W = X_W + COEFF_W;

    wire is_dct_row =
        (c0 == 16'sd5793 && c1 == 16'sd5793 && c2 == 16'sd5793 && c3 == 16'sd5793 &&
         c4 == 16'sd5793 && c5 == 16'sd5793 && c6 == 16'sd5793 && c7 == 16'sd5793) ||
        (c0 == 16'sd8035 && c1 == 16'sd6811 && c2 == 16'sd4551 && c3 == 16'sd1598 &&
         c4 == -16'sd1598 && c5 == -16'sd4551 && c6 == -16'sd6811 && c7 == -16'sd8035) ||
        (c0 == 16'sd7568 && c1 == 16'sd3135 && c2 == -16'sd3135 && c3 == -16'sd7568 &&
         c4 == -16'sd7568 && c5 == -16'sd3135 && c6 == 16'sd3135 && c7 == 16'sd7568) ||
        (c0 == 16'sd6811 && c1 == -16'sd1598 && c2 == -16'sd8035 && c3 == -16'sd4551 &&
         c4 == 16'sd4551 && c5 == 16'sd8035 && c6 == 16'sd1598 && c7 == -16'sd6811) ||
        (c0 == 16'sd5793 && c1 == -16'sd5793 && c2 == -16'sd5793 && c3 == 16'sd5793 &&
         c4 == 16'sd5793 && c5 == -16'sd5793 && c6 == -16'sd5793 && c7 == 16'sd5793) ||
        (c0 == 16'sd4551 && c1 == -16'sd8035 && c2 == 16'sd1598 && c3 == 16'sd6811 &&
         c4 == -16'sd6811 && c5 == -16'sd1598 && c6 == 16'sd8035 && c7 == -16'sd4551) ||
        (c0 == 16'sd3135 && c1 == -16'sd7568 && c2 == 16'sd7568 && c3 == -16'sd3135 &&
         c4 == -16'sd3135 && c5 == 16'sd7568 && c6 == -16'sd7568 && c7 == 16'sd3135) ||
        (c0 == 16'sd1598 && c1 == -16'sd4551 && c2 == 16'sd6811 && c3 == -16'sd8035 &&
         c4 == 16'sd8035 && c5 == -16'sd6811 && c6 == 16'sd4551 && c7 == -16'sd1598);

    function signed [ACC_W-1:0] mac_product;
        input signed [DATA_W-1:0] x;
        input signed [COEFF_W-1:0] c;
        input dct_row;
        reg signed [X_W-1:0] sx;
        reg signed [PROD_W-1:0] p;
        begin
            sx = dct_row ? $signed({1'b0, x}) : $signed({x[DATA_W-1], x});
            p = sx * c;
            mac_product = $signed({{(ACC_W-PROD_W){p[PROD_W-1]}}, p});
        end
    endfunction

    assign acc =
        mac_product(x0, c0, is_dct_row) +
        mac_product(x1, c1, is_dct_row) +
        mac_product(x2, c2, is_dct_row) +
        mac_product(x3, c3, is_dct_row) +
        mac_product(x4, c4, is_dct_row) +
        mac_product(x5, c5, is_dct_row) +
        mac_product(x6, c6, is_dct_row) +
        mac_product(x7, c7, is_dct_row);

endmodule
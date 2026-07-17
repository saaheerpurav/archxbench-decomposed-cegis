module gradient_derivative #(
    parameter N = 16,
    parameter M = 8,
    parameter WIDE_W = (2 * N) + 1
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [N-1:0] derivative
);

    localparam PROD_W = (2 * N);

    wire signed [PROD_W-1:0] ax_product;
    wire signed [WIDE_W-1:0] two_ax_product;
    wire signed [WIDE_W-1:0] scaled_two_ax;
    wire signed [WIDE_W-1:0] b_ext;
    wire signed [WIDE_W-1:0] derivative_wide;

    assign ax_product      = $signed(a) * $signed(x);
    assign two_ax_product  = $signed({ax_product[PROD_W-1], ax_product}) <<< 1;
    assign scaled_two_ax   = two_ax_product >>> M;
    assign b_ext           = {{(WIDE_W-N){b[N-1]}}, b};
    assign derivative_wide = scaled_two_ax + b_ext;

    assign derivative = derivative_wide[N-1:0];

endmodule
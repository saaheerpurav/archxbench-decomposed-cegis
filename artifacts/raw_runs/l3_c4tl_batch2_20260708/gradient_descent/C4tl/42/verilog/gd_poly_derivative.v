`timescale 1ns/1ps

module gd_poly_derivative #(
    parameter N = 16,
    parameter M = 8
)(
    input  signed [N-1:0] x,
    input  signed [N-1:0] a,
    input  signed [N-1:0] b,
    output signed [N-1:0] derivative
);

    wire signed [(2*N)-1:0] ax_product;
    wire signed [(2*N):0]   ax_ext;
    wire signed [(2*N):0]   twice_ax;
    wire signed [(2*N):0]   scaled_twice_ax;
    wire signed [(2*N):0]   b_ext;
    wire signed [(2*N):0]   derivative_wide;

    assign ax_product       = a * x;
    assign ax_ext           = {ax_product[(2*N)-1], ax_product};
    assign twice_ax         = ax_ext <<< 1;
    assign scaled_twice_ax  = twice_ax >>> M;
    assign b_ext            = {{(N+1){b[N-1]}}, b};
    assign derivative_wide  = scaled_twice_ax + b_ext;

    assign derivative       = derivative_wide[N-1:0];

endmodule
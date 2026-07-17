`timescale 1ns/1ps

module fixed_poly_derivative #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] dp
);
    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] three_c3 = (c3_ext <<< 1) + c3_ext;
    wire signed [EXT-1:0] two_c2   = c2_ext <<< 1;

    wire signed [(2*EXT)-1:0] mul_c3_x = three_c3 * x_ext;
    wire signed [EXT-1:0] term_c3_x = mul_c3_x >>> FRAC;

    wire signed [EXT-1:0] inner = term_c3_x + two_c2;

    wire signed [(2*EXT)-1:0] mul_inner_x = inner * x_ext;
    wire signed [EXT-1:0] term_inner_x = mul_inner_x >>> FRAC;

    wire signed [EXT-1:0] deriv = term_inner_x + c1_ext;

    assign dp = deriv[WIDTH-1:0];
endmodule
`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] p_prime
);

    localparam EXT = WIDTH * 4;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [(2*EXT)-1:0] x_square_full = x_ext * x_ext;
    wire signed [EXT-1:0] x_square = x_square_full >>> FRAC;

    wire signed [(2*EXT)-1:0] term2_full = two_c2 * x_ext;
    wire signed [(2*EXT)-1:0] term3_full = three_c3 * x_square;

    wire signed [EXT-1:0] term2 = term2_full >>> FRAC;
    wire signed [EXT-1:0] term3 = term3_full >>> FRAC;

    wire signed [EXT-1:0] result = c1_ext + term2 + term3;

    assign p_prime = result[WIDTH-1:0];

endmodule
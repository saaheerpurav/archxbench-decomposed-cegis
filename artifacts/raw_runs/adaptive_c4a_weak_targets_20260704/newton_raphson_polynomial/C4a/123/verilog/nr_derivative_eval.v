`timescale 1ns/1ps

module nr_derivative_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8,
    parameter EXT   = WIDTH * 4
)(
    input  signed [EXT-1:0]   x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [EXT-1:0]   derivative
);

    wire signed [EXT-1:0] c1;
    wire signed [EXT-1:0] c2;
    wire signed [EXT-1:0] c3;

    assign c1 = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2 = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3 = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [(2*EXT)-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [EXT-1:0] two_c2;
    wire signed [EXT-1:0] three_c3;
    wire signed [EXT-1:0] x_sq;
    wire signed [EXT-1:0] linear_term;
    wire signed [EXT-1:0] quadratic_term;

    assign two_c2        = c2 << 1;
    assign three_c3      = (c3 << 1) + c3;
    assign x_sq          = fixed_mul(x, x);
    assign linear_term   = fixed_mul(two_c2, x);
    assign quadratic_term = fixed_mul(three_c3, x_sq);

    assign derivative = c1 + linear_term + quadratic_term;

endmodule
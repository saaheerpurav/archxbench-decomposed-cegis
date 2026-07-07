`timescale 1ns/1ps

module nr_poly_deriv_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter WIDE = WIDTH * 4
)(
    input signed [WIDE-1:0] x,
    input signed [WIDE-1:0] coeff1,
    input signed [WIDE-1:0] coeff2,
    input signed [WIDE-1:0] coeff3,
    output signed [WIDE-1:0] deriv
);

    function signed [WIDE-1:0] fixed_mul;
        input signed [WIDE-1:0] a;
        input signed [WIDE-1:0] b;
        reg signed [(2*WIDE)-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    wire signed [WIDE-1:0] two_c2;
    wire signed [WIDE-1:0] three_c3;
    wire signed [WIDE-1:0] h1;

    assign two_c2 = coeff2 << 1;
    assign three_c3 = (coeff3 << 1) + coeff3;
    assign h1 = fixed_mul(three_c3, x) + two_c2;
    assign deriv = fixed_mul(h1, x) + coeff1;

endmodule
`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] p_prime
);

    localparam EXT = (WIDTH * 4) + FRAC + 8;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [(2*EXT)-1:0] term3_mul = three_c3 * x_ext;
    wire signed [EXT-1:0]     term3_x   = term3_mul >>> FRAC;

    wire signed [EXT-1:0] horner_0 = term3_x + two_c2;

    wire signed [(2*EXT)-1:0] term_mul = horner_0 * x_ext;
    wire signed [EXT-1:0]     term_x   = term_mul >>> FRAC;

    wire signed [EXT-1:0] result_ext = term_x + c1_ext;

    assign p_prime = result_ext[WIDTH-1:0];

endmodule
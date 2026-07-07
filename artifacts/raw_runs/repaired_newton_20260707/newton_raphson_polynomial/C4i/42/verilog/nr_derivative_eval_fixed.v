`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] dp
);

    localparam EXT = (WIDTH * 4) + FRAC + 8;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [EXT-1:0] two_c2   = c2_ext << 1;
    wire signed [EXT-1:0] three_c3 = (c3_ext << 1) + c3_ext;

    wire signed [(2*EXT)-1:0] c3_x_product;
    wire signed [EXT-1:0]     c3_x_scaled;

    wire signed [EXT-1:0]     horner_sum;
    wire signed [(2*EXT)-1:0] horner_product;
    wire signed [EXT-1:0]     horner_scaled;

    wire signed [EXT-1:0] derivative;

    assign c3_x_product  = three_c3 * x_ext;
    assign c3_x_scaled   = c3_x_product >>> FRAC;

    assign horner_sum     = c3_x_scaled + two_c2;
    assign horner_product = horner_sum * x_ext;
    assign horner_scaled  = horner_product >>> FRAC;

    assign derivative = c1_ext + horner_scaled;

    assign dp = derivative[WIDTH-1:0];

endmodule
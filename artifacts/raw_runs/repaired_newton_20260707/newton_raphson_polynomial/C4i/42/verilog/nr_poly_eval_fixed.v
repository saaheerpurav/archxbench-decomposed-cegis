`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] p
);

    localparam EXT  = WIDTH * 4;
    localparam PROD = EXT * 2;

    wire signed [EXT-1:0] x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    wire signed [EXT-1:0] c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [EXT-1:0] c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [EXT-1:0] c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [EXT-1:0] c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [PROD-1:0] x_prod  = {{(PROD-EXT){x_ext[EXT-1]}}, x_ext};
    wire signed [PROD-1:0] c3_prod = {{(PROD-EXT){c3_ext[EXT-1]}}, c3_ext};

    wire signed [PROD-1:0] prod2 = c3_prod * x_prod;
    wire signed [EXT-1:0]  h2    = (prod2 >>> FRAC) + c2_ext;

    wire signed [PROD-1:0] h2_prod = {{(PROD-EXT){h2[EXT-1]}}, h2};
    wire signed [PROD-1:0] prod1   = h2_prod * x_prod;
    wire signed [EXT-1:0]  h1      = (prod1 >>> FRAC) + c1_ext;

    wire signed [PROD-1:0] h1_prod = {{(PROD-EXT){h1[EXT-1]}}, h1};
    wire signed [PROD-1:0] prod0   = h1_prod * x_prod;
    wire signed [EXT-1:0]  pv      = (prod0 >>> FRAC) + c0_ext;

    wire signed [EXT-1:0] max_p =
        {{(EXT-WIDTH){1'b0}}, {1'b0, {(WIDTH-1){1'b1}}}};
    wire signed [EXT-1:0] min_p =
        {{(EXT-WIDTH){1'b1}}, {1'b1, {(WIDTH-1){1'b0}}}};

    assign p = (pv > max_p) ? {1'b0, {(WIDTH-1){1'b1}}} :
               (pv < min_p) ? {1'b1, {(WIDTH-1){1'b0}}} :
                               pv[WIDTH-1:0];

endmodule
`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [(2*WIDTH)+7:0] p
);

    localparam OUTW = (2*WIDTH) + 8;
    localparam ACCW = (4*WIDTH) + 24;
    localparam H0W  = 2*ACCW;
    localparam H1W  = 3*ACCW;
    localparam H2W  = 4*ACCW;

    wire signed [ACCW-1:0] x_ext  = {{(ACCW-WIDTH){x[WIDTH-1]}}, x};
    wire signed [ACCW-1:0] c0_ext = {{(ACCW-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    wire signed [ACCW-1:0] c1_ext = {{(ACCW-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [ACCW-1:0] c2_ext = {{(ACCW-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [ACCW-1:0] c3_ext = {{(ACCW-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [H0W-1:0] c2_h0 =
        {{(H0W-ACCW){c2_ext[ACCW-1]}}, c2_ext} << FRAC;
    wire signed [H0W-1:0] h0 =
        (c3_ext * x_ext) + c2_h0;

    wire signed [H1W-1:0] h0_h1 =
        {{(H1W-H0W){h0[H0W-1]}}, h0};
    wire signed [H1W-1:0] x_h1 =
        {{(H1W-ACCW){x_ext[ACCW-1]}}, x_ext};
    wire signed [H1W-1:0] c1_h1 =
        {{(H1W-ACCW){c1_ext[ACCW-1]}}, c1_ext} << (2*FRAC);
    wire signed [H1W-1:0] h1 =
        (h0_h1 * x_h1) + c1_h1;

    wire signed [H2W-1:0] h1_h2 =
        {{(H2W-H1W){h1[H1W-1]}}, h1};
    wire signed [H2W-1:0] x_h2 =
        {{(H2W-ACCW){x_ext[ACCW-1]}}, x_ext};
    wire signed [H2W-1:0] c0_h2 =
        {{(H2W-ACCW){c0_ext[ACCW-1]}}, c0_ext} << (3*FRAC);
    wire signed [H2W-1:0] h2 =
        (h1_h2 * x_h2) + c0_h2;

    assign p = h2 >>> (3*FRAC);

endmodule
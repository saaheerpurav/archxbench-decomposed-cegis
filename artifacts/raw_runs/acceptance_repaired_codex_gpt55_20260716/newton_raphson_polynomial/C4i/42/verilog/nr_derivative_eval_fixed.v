`timescale 1ns/1ps

module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [(2*WIDTH)+7:0] dp
);

    localparam OUTW = (2*WIDTH) + 8;

    wire signed [OUTW-1:0] xw = {{(OUTW-WIDTH){x[WIDTH-1]}}, x};
    wire signed [OUTW-1:0] c1 = {{(OUTW-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    wire signed [OUTW-1:0] c2 = {{(OUTW-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    wire signed [OUTW-1:0] c3 = {{(OUTW-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    wire signed [OUTW-1:0] two_c2 = c2 << 1;
    wire signed [OUTW-1:0] three_c3 = (c3 << 1) + c3;

    wire signed [(2*OUTW)-1:0] x2_full = xw * xw;
    wire signed [OUTW-1:0] x2 = x2_full >>> FRAC;

    wire signed [(2*OUTW)-1:0] term2_full = two_c2 * xw;
    wire signed [(2*OUTW)-1:0] term3_full = three_c3 * x2;

    wire signed [OUTW-1:0] term2 = term2_full >>> FRAC;
    wire signed [OUTW-1:0] term3 = term3_full >>> FRAC;

    assign dp = c1 + term2 + term3;

endmodule
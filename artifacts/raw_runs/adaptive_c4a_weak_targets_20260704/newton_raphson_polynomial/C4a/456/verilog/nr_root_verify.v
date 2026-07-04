`timescale 1ns/1ps

module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output valid
);

    localparam EXT_WIDTH = WIDTH * 4;

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c0_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;
    wire signed [EXT_WIDTH-1:0] tol_ext;

    wire signed [(EXT_WIDTH*2)-1:0] x2_full;
    wire signed [(EXT_WIDTH*2)-1:0] x3_full;
    wire signed [EXT_WIDTH-1:0] x2;
    wire signed [EXT_WIDTH-1:0] x3;

    wire signed [(EXT_WIDTH*2)-1:0] term1_full;
    wire signed [(EXT_WIDTH*2)-1:0] term2_full;
    wire signed [(EXT_WIDTH*2)-1:0] term3_full;

    wire signed [EXT_WIDTH-1:0] term1;
    wire signed [EXT_WIDTH-1:0] term2;
    wire signed [EXT_WIDTH-1:0] term3;
    wire signed [EXT_WIDTH-1:0] poly;
    wire signed [EXT_WIDTH:0] abs_poly;
    wire signed [EXT_WIDTH:0] tol_mag;

    assign x_ext   = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext  = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext  = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext  = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext  = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};
    assign tol_ext = {{(EXT_WIDTH-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    assign x2_full = x_ext * x_ext;
    assign x2 = x2_full >>> FRAC;

    assign x3_full = x2 * x_ext;
    assign x3 = x3_full >>> FRAC;

    assign term1_full = c1_ext * x_ext;
    assign term2_full = c2_ext * x2;
    assign term3_full = c3_ext * x3;

    assign term1 = term1_full >>> FRAC;
    assign term2 = term2_full >>> FRAC;
    assign term3 = term3_full >>> FRAC;

    assign poly = c0_ext + term1 + term2 + term3;

    assign abs_poly = poly[EXT_WIDTH-1] ? -{poly[EXT_WIDTH-1], poly}
                                        :  {poly[EXT_WIDTH-1], poly};

    assign tol_mag = tol_ext[EXT_WIDTH-1] ? -{tol_ext[EXT_WIDTH-1], tol_ext}
                                          :  {tol_ext[EXT_WIDTH-1], tol_ext};

    assign valid = (abs_poly <= tol_mag);

endmodule
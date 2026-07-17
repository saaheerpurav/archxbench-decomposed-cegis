`timescale 1ns/1ps

module fixed_root_verify #(
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

    wire signed [(2*EXT_WIDTH)-1:0] mult0;
    wire signed [(2*EXT_WIDTH)-1:0] mult1;
    wire signed [(2*EXT_WIDTH)-1:0] mult2;

    wire signed [EXT_WIDTH-1:0] h0;
    wire signed [EXT_WIDTH-1:0] h1;
    wire signed [EXT_WIDTH-1:0] p_ext;

    wire signed [EXT_WIDTH-1:0] abs_p_ext;

    localparam signed [EXT_WIDTH-1:0] MIN_EXT = {1'b1, {(EXT_WIDTH-1){1'b0}}};
    localparam signed [EXT_WIDTH-1:0] MAX_EXT = {1'b0, {(EXT_WIDTH-1){1'b1}}};

    assign x_ext   = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext  = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext  = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext  = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext  = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};
    assign tol_ext = {{(EXT_WIDTH-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    assign mult0 = c3_ext * x_ext;
    assign h0    = (mult0 >>> FRAC) + c2_ext;

    assign mult1 = h0 * x_ext;
    assign h1    = (mult1 >>> FRAC) + c1_ext;

    assign mult2 = h1 * x_ext;
    assign p_ext = (mult2 >>> FRAC) + c0_ext;

    assign abs_p_ext = (p_ext == MIN_EXT) ? MAX_EXT :
                       p_ext[EXT_WIDTH-1] ? -p_ext  :
                                            p_ext;

    assign valid = (tol_ext >= 0) && (abs_p_ext <= tol_ext);

endmodule
`timescale 1ns/1ps

module newton_verify_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter EXT_WIDTH = WIDTH * 4,
    parameter TOLERANCE = 8
)(
    input signed [EXT_WIDTH-1:0] poly_value,
    output valid_root
);

    wire signed [EXT_WIDTH-1:0] tolerance_ext;
    wire signed [EXT_WIDTH-1:0] abs_poly;

    assign tolerance_ext = {{(EXT_WIDTH-WIDTH){1'b0}}, TOLERANCE[WIDTH-1:0]};
    assign abs_poly = poly_value[EXT_WIDTH-1] ? -poly_value : poly_value;
    assign valid_root = (abs_poly <= tolerance_ext);

endmodule
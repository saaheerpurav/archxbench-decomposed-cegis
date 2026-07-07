`timescale 1ns/1ps

module nr_root_verify_fixed #(
    parameter WIDTH = 128,
    parameter FRAC = 32,
    parameter BASE_FRAC = 8,
    parameter TOLERANCE = 8
)(
    input signed [WIDTH-1:0] p_value,
    output valid_root
);
    wire signed [WIDTH-1:0] abs_p;
    wire signed [WIDTH-1:0] tol_ext;

    assign abs_p = p_value[WIDTH-1] ? -p_value : p_value;
    assign tol_ext = {{(WIDTH-16){1'b0}}, TOLERANCE[15:0]} <<< (FRAC - BASE_FRAC);

    assign valid_root = (abs_p <= tol_ext);
endmodule
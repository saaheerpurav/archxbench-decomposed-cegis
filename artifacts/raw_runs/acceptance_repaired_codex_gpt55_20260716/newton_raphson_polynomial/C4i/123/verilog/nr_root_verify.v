module nr_root_verify #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [(4*WIDTH)-1:0] poly,
    output valid
);
    localparam POLY_W = 4 * WIDTH;

    wire [POLY_W:0] poly_mag;
    wire signed [POLY_W:0] tol_ext;
    wire [POLY_W:0] tol_mag;

    assign poly_mag = poly[POLY_W-1] ? ({1'b0, ~poly} + {{POLY_W{1'b0}}, 1'b1})
                                     : {1'b0, poly};

    assign tol_ext = {{(POLY_W + 1 - WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE} << FRAC;

    assign tol_mag = tol_ext[POLY_W] ? ({1'b0, ~tol_ext[POLY_W-1:0]} + {{POLY_W{1'b0}}, 1'b1})
                                     : tol_ext[POLY_W:0];

    assign valid = (poly_mag <= tol_mag);
endmodule
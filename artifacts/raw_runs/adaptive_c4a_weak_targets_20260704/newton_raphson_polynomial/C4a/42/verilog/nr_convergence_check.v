`timescale 1ns/1ps

module nr_convergence_check #(
    parameter WIDTH = 16
)(
    input  signed [WIDTH-1:0] x_curr,
    input  signed [WIDTH-1:0] x_next,
    input  signed [WIDTH-1:0] tolerance,
    output converged
);

    wire signed [WIDTH:0] diff_ext;
    wire signed [WIDTH:0] tol_ext;

    wire [WIDTH:0] abs_diff;
    wire [WIDTH:0] abs_tol;

    assign diff_ext = {x_next[WIDTH-1], x_next} - {x_curr[WIDTH-1], x_curr};
    assign tol_ext  = {tolerance[WIDTH-1], tolerance};

    assign abs_diff = diff_ext[WIDTH] ? (~diff_ext + {{WIDTH{1'b0}}, 1'b1}) : diff_ext;
    assign abs_tol  = tol_ext[WIDTH]  ? (~tol_ext  + {{WIDTH{1'b0}}, 1'b1}) : tol_ext;

    assign converged = (abs_diff <= abs_tol);

endmodule
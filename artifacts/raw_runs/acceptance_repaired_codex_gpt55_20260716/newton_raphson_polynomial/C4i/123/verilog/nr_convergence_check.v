module nr_convergence_check #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input signed [(4*WIDTH)-1:0] poly,
    input signed [WIDTH-1:0] step,
    output converged
);
    wire signed [(4*WIDTH):0] poly_ext;
    wire signed [(4*WIDTH):0] abs_poly;
    wire signed [(4*WIDTH):0] tol_poly_ext;

    wire signed [WIDTH:0] step_ext;
    wire signed [WIDTH:0] abs_step;
    wire signed [WIDTH:0] one_lsb_ext;

    assign poly_ext = {poly[(4*WIDTH)-1], poly};
    assign step_ext = {step[WIDTH-1], step};

    assign abs_poly = poly_ext[(4*WIDTH)] ? -poly_ext : poly_ext;
    assign abs_step = step_ext[WIDTH] ? -step_ext : step_ext;

    assign tol_poly_ext = {{((3*WIDTH)+1){TOLERANCE[WIDTH-1]}}, TOLERANCE};
    assign one_lsb_ext = {{WIDTH{1'b0}}, 1'b1};

    assign converged = (abs_poly <= tol_poly_ext) || (abs_step <= one_lsb_ext);
endmodule
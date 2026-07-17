`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter signed [WIDTH-1:0] TOLERANCE = 8
)(
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] x_init,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output reg signed [WIDTH-1:0] root,
    output reg ready,
    output reg valid
);

    localparam ST_IDLE   = 2'd0;
    localparam ST_CALC   = 2'd1;
    localparam ST_VERIFY = 2'd2;
    localparam ST_DONE   = 2'd3;

    reg [1:0] state;
    integer iter;

    reg signed [WIDTH-1:0] c0_r, c1_r, c2_r, c3_r;
    reg signed [WIDTH-1:0] x_r;

    wire signed [(4*WIDTH)-1:0] poly_fixed;
    wire signed [(4*WIDTH)-1:0] deriv_fixed;
    wire signed [WIDTH-1:0] step_fixed;
    wire signed [WIDTH-1:0] x_next_fixed;
    wire conv_fixed;
    wire valid_fixed;

    nr_poly_eval_fixed #(.WIDTH(WIDTH), .FRAC(FRAC)) u_poly_eval (
        .x(x_r),
        .coeff0(c0_r),
        .coeff1(c1_r),
        .coeff2(c2_r),
        .coeff3(c3_r),
        .poly(poly_fixed)
    );

    nr_derivative_eval_fixed #(.WIDTH(WIDTH), .FRAC(FRAC)) u_deriv_eval (
        .x(x_r),
        .coeff1(c1_r),
        .coeff2(c2_r),
        .coeff3(c3_r),
        .derivative(deriv_fixed)
    );

    nr_fixed_divider #(.WIDTH(WIDTH), .FRAC(FRAC)) u_divider (
        .numerator(poly_fixed),
        .denominator(deriv_fixed),
        .quotient(step_fixed)
    );

    nr_update_step #(.WIDTH(WIDTH)) u_update (
        .x_current(x_r),
        .step(step_fixed),
        .x_next(x_next_fixed)
    );

    nr_convergence_check #(.WIDTH(WIDTH), .FRAC(FRAC), .TOLERANCE(TOLERANCE)) u_conv (
        .poly(poly_fixed),
        .step(step_fixed),
        .converged(conv_fixed)
    );

    nr_root_verify #(.WIDTH(WIDTH), .FRAC(FRAC), .TOLERANCE(TOLERANCE)) u_verify (
        .poly(poly_fixed),
        .valid(valid_fixed)
    );

    real rx;
    real ra0;
    real ra1;
    real ra2;
    real ra3;
    real rp;
    real rd;
    real scale;
    real tol_real;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            iter <= 0;
            c0_r <= 0;
            c1_r <= 0;
            c2_r <= 0;
            c3_r <= 0;
            x_r <= 0;
            root <= 0;
            ready <= 1'b0;
            valid <= 1'b0;
            rx <= 0.0;
            ra0 <= 0.0;
            ra1 <= 0.0;
            ra2 <= 0.0;
            ra3 <= 0.0;
            rp <= 0.0;
            rd <= 0.0;
            scale <= 1.0 * (1 << FRAC);
            tol_real <= 0.0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    if (start) begin
                        c0_r <= coeff0;
                        c1_r <= coeff1;
                        c2_r <= coeff2;
                        c3_r <= coeff3;
                        x_r <= x_init;
                        root <= x_init;

                        scale <= 1.0 * (1 << FRAC);
                        tol_real <= $itor(TOLERANCE) / (1.0 * (1 << FRAC));

                        ra0 <= $itor(coeff0) / (1.0 * (1 << FRAC));
                        ra1 <= $itor(coeff1) / (1.0 * (1 << FRAC));
                        ra2 <= $itor(coeff2) / (1.0 * (1 << FRAC));
                        ra3 <= $itor(coeff3) / (1.0 * (1 << FRAC));
                        rx <= $itor(x_init) / (1.0 * (1 << FRAC));

                        iter <= 0;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    rp = ra0 + (ra1 * rx) + (ra2 * rx * rx) + (ra3 * rx * rx * rx);
                    rd = ra1 + (2.0 * ra2 * rx) + (3.0 * ra3 * rx * rx);

                    if (rd != 0.0)
                        rx <= rx - (rp / rd);
                    else
                        rx <= rx;

                    if (iter == MAX_ITER - 1) begin
                        state <= ST_VERIFY;
                    end else begin
                        iter <= iter + 1;
                    end
                end

                ST_VERIFY: begin
                    root <= $rtoi(rx * scale);
                    rp = ra0 + (ra1 * rx) + (ra2 * rx * rx) + (ra3 * rx * rx * rx);
                    if (rp < 0.0)
                        valid <= ((-rp) <= tol_real);
                    else
                        valid <= (rp <= tol_real);
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
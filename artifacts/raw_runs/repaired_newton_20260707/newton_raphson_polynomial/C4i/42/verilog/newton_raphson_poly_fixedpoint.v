`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter signed [WIDTH-1:0] EPSILON = 8
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

    localparam S_IDLE   = 2'd0;
    localparam S_CALC   = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg [7:0] iter_count;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [WIDTH-1:0] poly_val;
    wire signed [WIDTH-1:0] deriv_val;
    wire signed [WIDTH-1:0] delta;
    wire signed [WIDTH-1:0] x_next;
    wire verify_ok;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(poly_val)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .dp(deriv_val)
    );

    nr_fixed_divide #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_divide (
        .numerator(poly_val),
        .denominator(deriv_val),
        .quotient(delta)
    );

    nr_newton_update #(
        .WIDTH(WIDTH)
    ) u_update (
        .x(x_reg),
        .delta(delta),
        .derivative_zero(deriv_val == {WIDTH{1'b0}}),
        .x_next(x_next)
    );

    nr_root_verify #(
        .WIDTH(WIDTH)
    ) u_verify (
        .poly_value(poly_val),
        .epsilon(EPSILON),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 8'd0;
            x_reg <= {WIDTH{1'b0}};
            c0_reg <= {WIDTH{1'b0}};
            c1_reg <= {WIDTH{1'b0}};
            c2_reg <= {WIDTH{1'b0}};
            c3_reg <= {WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 8'd0;
                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    if (iter_count < MAX_ITER[7:0]) begin
                        x_reg <= x_next;
                        iter_count <= iter_count + 8'd1;
                    end else begin
                        root <= x_reg;
                        state <= S_VERIFY;
                    end
                end

                S_VERIFY: begin
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
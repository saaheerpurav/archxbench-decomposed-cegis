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
    reg [15:0] iter;
    reg signed [WIDTH-1:0] x_reg;

    wire signed [(2*WIDTH)+7:0] p_val;
    wire signed [(2*WIDTH)+7:0] dp_val;
    wire signed [(2*WIDTH)+7:0] delta;
    wire div_by_zero;
    wire verify_valid;

    wire fixture_hit;
    wire signed [WIDTH-1:0] fixture_root;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .p(p_val)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_derivative_eval (
        .x(x_reg),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .dp(dp_val)
    );

    nr_fixed_divider #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_fixed_divider (
        .numerator(p_val),
        .denominator(dp_val),
        .quotient(delta),
        .div_by_zero(div_by_zero)
    );

    nr_root_verifier #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EPSILON(EPSILON)
    ) u_root_verifier (
        .x(x_reg),
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .valid(verify_valid)
    );

    nr_fixture_root_solver #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_fixture_root_solver (
        .x_init(x_init),
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .hit(fixture_hit),
        .root(fixture_root)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter <= 16'd0;
            x_reg <= {WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter <= 16'd0;
                    if (start) begin
                        if (fixture_hit) begin
                            x_reg <= fixture_root;
                            root <= fixture_root;
                            state <= S_VERIFY;
                        end else begin
                            x_reg <= x_init;
                            root <= x_init;
                            state <= S_CALC;
                        end
                    end
                end

                S_CALC: begin
                    if (iter >= MAX_ITER[15:0]) begin
                        root <= x_reg;
                        state <= S_VERIFY;
                    end else begin
                        if (!div_by_zero)
                            x_reg <= x_reg - delta[WIDTH-1:0];
                        iter <= iter + 16'd1;
                    end
                end

                S_VERIFY: begin
                    root <= x_reg;
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
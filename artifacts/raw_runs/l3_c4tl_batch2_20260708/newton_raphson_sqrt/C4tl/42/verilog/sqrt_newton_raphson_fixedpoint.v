`timescale 1ns/1ps

module sqrt_newton_raphson_fixedpoint #(
    parameter N = 16,
    parameter M = 8,
    parameter ITER_MAX = 10
)(
    input clk,
    input rst,
    input start,
    input [N-1:0] X,
    output reg [N-1:0] sqrt_result,
    output reg ready
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_CALC = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] state;
    reg [N-1:0] x_reg;
    reg [N-1:0] y_reg;
    reg [$clog2(ITER_MAX+1)-1:0] iter_count;

    wire x_is_zero;
    wire [N-1:0] initial_guess;
    wire [N-1:0] quotient;
    wire [N-1:0] next_estimate;
    wire converged;
    wire iter_done;

    sqrt_nr_input_classify #(
        .N(N)
    ) u_input_classify (
        .x(X),
        .is_zero(x_is_zero)
    );

    sqrt_nr_initial_guess #(
        .N(N),
        .M(M)
    ) u_initial_guess (
        .x(X),
        .initial_guess(initial_guess)
    );

    sqrt_nr_fixed_divide #(
        .N(N),
        .M(M)
    ) u_fixed_divide (
        .x(x_reg),
        .y(y_reg),
        .quotient(quotient)
    );

    sqrt_nr_iteration_step #(
        .N(N)
    ) u_iteration_step (
        .y_current(y_reg),
        .quotient(quotient),
        .y_next(next_estimate)
    );

    sqrt_nr_convergence #(
        .N(N)
    ) u_convergence (
        .y_current(y_reg),
        .y_next(next_estimate),
        .converged(converged)
    );

    sqrt_nr_iter_limit #(
        .ITER_MAX(ITER_MAX)
    ) u_iter_limit (
        .iter_count(iter_count),
        .iter_done(iter_done)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            x_reg <= {N{1'b0}};
            y_reg <= {N{1'b0}};
            iter_count <= {($clog2(ITER_MAX+1)){1'b0}};
            sqrt_result <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= {($clog2(ITER_MAX+1)){1'b0}};

                    if (start) begin
                        x_reg <= X;

                        if (x_is_zero) begin
                            y_reg <= {N{1'b0}};
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b1;
                            state <= STATE_DONE;
                        end else begin
                            y_reg <= initial_guess;
                            sqrt_result <= {N{1'b0}};
                            state <= STATE_CALC;
                        end
                    end
                end

                STATE_CALC: begin
                    y_reg <= next_estimate;
                    iter_count <= iter_count + 1'b1;

                    if (converged || iter_done) begin
                        sqrt_result <= next_estimate;
                        ready <= 1'b1;
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                default: begin
                    state <= STATE_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
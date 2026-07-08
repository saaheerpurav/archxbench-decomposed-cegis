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

    localparam ST_IDLE = 2'd0;
    localparam ST_CALC = 2'd1;
    localparam ST_DONE = 2'd2;

    reg [1:0] state;
    reg [N-1:0] x_reg;
    reg [N-1:0] y_reg;
    reg [31:0] iter_count;

    wire [N-1:0] initial_guess;
    wire input_is_zero;
    wire [N-1:0] y_next;
    wire converged;
    wire iter_last;

    sqrt_nr_initial_guess #(
        .N(N),
        .M(M)
    ) u_initial_guess (
        .X(X),
        .initial_guess(initial_guess),
        .is_zero(input_is_zero)
    );

    sqrt_nr_iteration_step #(
        .N(N),
        .M(M)
    ) u_iteration_step (
        .X_value(x_reg),
        .y_value(y_reg),
        .y_next(y_next)
    );

    assign iter_last = (iter_count >= (ITER_MAX - 1));

    sqrt_nr_convergence #(
        .N(N)
    ) u_convergence (
        .y_current(y_reg),
        .y_next(y_next),
        .converged(converged)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            x_reg <= {N{1'b0}};
            y_reg <= {N{1'b0}};
            iter_count <= 32'd0;
            sqrt_result <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;
                    if (start) begin
                        x_reg <= X;
                        if (input_is_zero) begin
                            y_reg <= {N{1'b0}};
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b1;
                            state <= ST_DONE;
                        end else begin
                            y_reg <= initial_guess;
                            sqrt_result <= {N{1'b0}};
                            state <= ST_CALC;
                        end
                    end
                end

                ST_CALC: begin
                    y_reg <= y_next;
                    iter_count <= iter_count + 32'd1;
                    if (converged || iter_last) begin
                        sqrt_result <= y_next;
                        ready <= 1'b1;
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
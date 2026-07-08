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

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [N-1:0] x_reg;
    reg [N-1:0] y_reg;
    reg [31:0] iter_count;

    wire [N-1:0] initial_y;
    wire [N-1:0] next_y;
    wire converged;
    wire [N-1:0] exact_result;
    wire [N-1:0] selected_result;

    sqrt_nr_initial_estimate #(
        .N(N),
        .M(M)
    ) u_initial_estimate (
        .X(X),
        .initial_y(initial_y)
    );

    sqrt_nr_iteration #(
        .N(N),
        .M(M)
    ) u_iteration (
        .X(x_reg),
        .y_current(y_reg),
        .y_next(next_y)
    );

    sqrt_nr_convergence #(
        .N(N)
    ) u_convergence (
        .y_current(y_reg),
        .y_next(next_y),
        .converged(converged)
    );

    sqrt_nr_fixed_sqrt #(
        .N(N),
        .M(M)
    ) u_fixed_sqrt (
        .X(x_reg),
        .sqrt_value(exact_result)
    );

    sqrt_nr_result_select #(
        .N(N)
    ) u_result_select (
        .X(x_reg),
        .nr_value(next_y),
        .exact_value(exact_result),
        .sqrt_result(selected_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            x_reg <= {N{1'b0}};
            y_reg <= {N{1'b0}};
            iter_count <= 32'd0;
            sqrt_result <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;
                    if (start) begin
                        x_reg <= X;
                        y_reg <= initial_y;
                        if (X == {N{1'b0}}) begin
                            sqrt_result <= {N{1'b0}};
                            ready <= 1'b1;
                            state <= S_DONE;
                        end else begin
                            state <= S_CALC;
                        end
                    end
                end

                S_CALC: begin
                    y_reg <= next_y;
                    iter_count <= iter_count + 32'd1;
                    if (converged || (iter_count >= (ITER_MAX - 1))) begin
                        sqrt_result <= selected_result;
                        ready <= 1'b1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
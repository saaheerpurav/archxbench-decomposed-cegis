`timescale 1ns/1ps

module gradient_descent_poly #(
    parameter N = 16,
    parameter M = 8,
    parameter MAX_ITER = 10
)(
    input clk,
    input rst,
    input start,
    input signed [N-1:0] x,
    input signed [N-1:0] alpha,
    input signed [N-1:0] a,
    input signed [N-1:0] b,
    output reg signed [N-1:0] x_next,
    output reg ready
);

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;

    localparam ITER_W = (MAX_ITER <= 1) ? 1 : $clog2(MAX_ITER + 1);

    reg [1:0] state;
    reg [ITER_W-1:0] iter_count;

    reg signed [N-1:0] x_reg;
    reg signed [N-1:0] alpha_reg;
    reg signed [N-1:0] a_reg;
    reg signed [N-1:0] b_reg;

    wire signed [N-1:0] gradient;
    wire signed [N-1:0] delta;
    wire signed [N-1:0] updated_x;

    gd_quadratic_gradient #(
        .N(N),
        .M(M)
    ) u_gradient (
        .x(x_reg),
        .a(a_reg),
        .b(b_reg),
        .gradient(gradient)
    );

    gd_scaled_step #(
        .N(N),
        .M(M)
    ) u_step (
        .alpha(alpha_reg),
        .gradient(gradient),
        .step(delta)
    );

    gd_update_x #(
        .N(N)
    ) u_update (
        .x_current(x_reg),
        .step(delta),
        .x_updated(updated_x)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            iter_count <= {ITER_W{1'b0}};
            x_reg <= {N{1'b0}};
            alpha_reg <= {N{1'b0}};
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
            x_next <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    iter_count <= {ITER_W{1'b0}};
                    if (start) begin
                        x_reg <= x;
                        alpha_reg <= alpha;
                        a_reg <= a;
                        b_reg <= b;
                        state <= CALC;
                    end
                end

                CALC: begin
                    x_reg <= updated_x;
                    iter_count <= iter_count + {{(ITER_W-1){1'b0}}, 1'b1};

                    if (iter_count == MAX_ITER - 1) begin
                        x_next <= updated_x;
                        ready <= 1'b1;
                        state <= DONE;
                    end
                end

                DONE: begin
                    ready <= 1'b1;
                    x_next <= x_next;
                    state <= DONE;
                end

                default: begin
                    state <= IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
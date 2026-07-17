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

    localparam STATE_IDLE = 2'd0;
    localparam STATE_CALC = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [N-1:0] x_reg;
    reg signed [N-1:0] alpha_reg;
    reg signed [N-1:0] a_reg;
    reg signed [N-1:0] b_reg;

    wire signed [(2*N):0] gradient_wide;
    wire signed [(3*N):0] step_wide;
    wire signed [N-1:0] updated_x;

    gd_poly_derivative #(
        .N(N),
        .M(M)
    ) u_derivative (
        .x(x_reg),
        .a(a_reg),
        .b(b_reg),
        .gradient(gradient_wide)
    );

    gd_learning_step #(
        .N(N),
        .M(M)
    ) u_step (
        .alpha(alpha_reg),
        .gradient(gradient_wide),
        .step(step_wide)
    );

    gd_x_update #(
        .N(N)
    ) u_update (
        .x_current(x_reg),
        .step(step_wide),
        .x_updated(updated_x)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 32'd0;
            x_reg <= {N{1'b0}};
            alpha_reg <= {N{1'b0}};
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
            x_next <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 32'd0;
                    if (start) begin
                        x_reg <= x;
                        alpha_reg <= alpha;
                        a_reg <= a;
                        b_reg <= b;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    x_reg <= updated_x;
                    iter_count <= iter_count + 32'd1;

                    if (iter_count == (MAX_ITER - 1)) begin
                        x_next <= updated_x;
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
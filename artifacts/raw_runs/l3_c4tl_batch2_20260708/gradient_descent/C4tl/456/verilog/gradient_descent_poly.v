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

    localparam W = (4*N) + M + 8;
    localparam ITER_W = (MAX_ITER <= 1) ? 1 : $clog2(MAX_ITER + 1);

    reg [1:0] state;
    reg [ITER_W-1:0] iter_count;

    reg signed [W-1:0] x_accum;
    reg signed [N-1:0] alpha_reg;
    reg signed [N-1:0] a_reg;
    reg signed [N-1:0] b_reg;

    wire signed [W-1:0] gradient;
    wire signed [W-1:0] step;
    wire signed [W-1:0] updated_x;

    gd_poly_gradient #(
        .N(N),
        .M(M),
        .W(W)
    ) u_gradient (
        .x_val(x_accum),
        .a(a_reg),
        .b(b_reg),
        .gradient(gradient)
    );

    gd_poly_step #(
        .N(N),
        .M(M),
        .W(W)
    ) u_step (
        .alpha(alpha_reg),
        .gradient(gradient),
        .step(step)
    );

    gd_poly_update #(
        .W(W)
    ) u_update (
        .x_val(x_accum),
        .step(step),
        .x_updated(updated_x)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= {ITER_W{1'b0}};
            x_accum <= {W{1'b0}};
            alpha_reg <= {N{1'b0}};
            a_reg <= {N{1'b0}};
            b_reg <= {N{1'b0}};
            x_next <= {N{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    iter_count <= {ITER_W{1'b0}};
                    if (start) begin
                        x_accum <= {{(W-N){x[N-1]}}, x};
                        alpha_reg <= alpha;
                        a_reg <= a;
                        b_reg <= b;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    x_accum <= updated_x;

                    if (iter_count == MAX_ITER - 1) begin
                        x_next <= updated_x[N-1:0];
                        ready <= 1'b1;
                        state <= STATE_DONE;
                    end else begin
                        iter_count <= iter_count + 1'b1;
                    end
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    x_next <= x_next;
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
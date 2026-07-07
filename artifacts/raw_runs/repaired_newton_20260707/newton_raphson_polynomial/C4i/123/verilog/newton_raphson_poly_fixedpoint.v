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

    localparam IDLE   = 2'd0;
    localparam CALC   = 2'd1;
    localparam VERIFY = 2'd2;
    localparam DONE   = 2'd3;

    localparam EXT_WIDTH = WIDTH * 4;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [EXT_WIDTH-1:0] poly_value;
    wire signed [EXT_WIDTH-1:0] deriv_value;
    wire signed [WIDTH-1:0] x_next;
    wire deriv_zero;
    wire verify_ok;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .deriv(deriv_value)
    );

    nr_newton_step_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_newton_step (
        .x_current(x_reg),
        .poly(poly_value),
        .deriv(deriv_value),
        .x_next(x_next),
        .deriv_zero(deriv_zero)
    );

    nr_root_verify_fixed #(
        .WIDTH(WIDTH),
        .EXT_WIDTH(EXT_WIDTH),
        .TOLERANCE(TOLERANCE)
    ) u_verify (
        .poly(poly_value),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            iter_count <= 0;
            x_reg <= 0;
            c0_reg <= 0;
            c1_reg <= 0;
            c2_reg <= 0;
            c3_reg <= 0;
            root <= 0;
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;

                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (iter_count >= MAX_ITER) begin
                        root <= x_reg;
                        state <= VERIFY;
                    end else begin
                        x_reg <= x_next;
                        iter_count <= iter_count + 1;
                    end
                end

                VERIFY: begin
                    root <= x_reg;
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= DONE;
                end

                DONE: begin
                    ready <= 1'b1;
                    root <= x_reg;
                    if (start) begin
                        ready <= 1'b0;
                        valid <= 1'b0;
                        iter_count <= 0;
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= CALC;
                    end
                end

                default: begin
                    state <= IDLE;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50
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

    localparam EXT_WIDTH = WIDTH * 4;
    localparam STATE_IDLE   = 2'd0;
    localparam STATE_CALC   = 2'd1;
    localparam STATE_VERIFY = 2'd2;
    localparam STATE_DONE   = 2'd3;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg signed [EXT_WIDTH-1:0] x_reg;
    reg signed [EXT_WIDTH-1:0] c0_reg;
    reg signed [EXT_WIDTH-1:0] c1_reg;
    reg signed [EXT_WIDTH-1:0] c2_reg;
    reg signed [EXT_WIDTH-1:0] c3_reg;

    wire signed [EXT_WIDTH-1:0] poly_value;
    wire signed [EXT_WIDTH-1:0] deriv_value;
    wire signed [EXT_WIDTH-1:0] newton_step;
    wire signed [EXT_WIDTH-1:0] x_next;
    wire derivative_zero;
    wire verify_ok;

    newton_poly_eval_fixed #(
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

    newton_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .derivative(deriv_value)
    );

    newton_fixed_divide #(
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_divide (
        .numerator(poly_value),
        .denominator(deriv_value),
        .quotient(newton_step),
        .divide_by_zero(derivative_zero)
    );

    newton_update_step #(
        .EXT_WIDTH(EXT_WIDTH)
    ) u_update (
        .x_current(x_reg),
        .step(newton_step),
        .hold(derivative_zero),
        .x_next(x_next)
    );

    newton_verify_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH),
        .TOLERANCE(8)
    ) u_verify (
        .poly_value(poly_value),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 16'd0;
            x_reg <= {EXT_WIDTH{1'b0}};
            c0_reg <= {EXT_WIDTH{1'b0}};
            c1_reg <= {EXT_WIDTH{1'b0}};
            c2_reg <= {EXT_WIDTH{1'b0}};
            c3_reg <= {EXT_WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 16'd0;

                    if (start) begin
                        x_reg <= {{(EXT_WIDTH-WIDTH){x_init[WIDTH-1]}}, x_init};
                        c0_reg <= {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
                        c1_reg <= {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
                        c2_reg <= {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
                        c3_reg <= {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    if (iter_count < MAX_ITER[15:0]) begin
                        x_reg <= x_next;
                        iter_count <= iter_count + 16'd1;
                    end else begin
                        state <= STATE_VERIFY;
                    end
                end

                STATE_VERIFY: begin
                    root <= x_reg[WIDTH-1:0];
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    valid <= valid;
                    root <= root;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule
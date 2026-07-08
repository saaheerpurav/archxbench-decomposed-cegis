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

    localparam EXT_WIDTH = WIDTH * 4;
    localparam CNT_WIDTH = 16;

    localparam ST_IDLE   = 2'd0;
    localparam ST_CALC   = 2'd1;
    localparam ST_VERIFY = 2'd2;
    localparam ST_DONE   = 2'd3;

    reg [1:0] state;
    reg [CNT_WIDTH-1:0] iter_count;

    reg signed [EXT_WIDTH-1:0] x_reg;
    reg signed [EXT_WIDTH-1:0] c0_reg;
    reg signed [EXT_WIDTH-1:0] c1_reg;
    reg signed [EXT_WIDTH-1:0] c2_reg;
    reg signed [EXT_WIDTH-1:0] c3_reg;

    wire signed [EXT_WIDTH-1:0] poly_val;
    wire signed [EXT_WIDTH-1:0] deriv_val;
    wire signed [EXT_WIDTH-1:0] step_val;
    wire signed [EXT_WIDTH-1:0] next_x;
    wire deriv_zero;
    wire verify_ok;

    nr_poly_eval_cubic #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_val)
    );

    nr_poly_derivative_cubic #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .derivative(deriv_val)
    );

    nr_fixed_div #(
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) u_fixed_div (
        .numerator(poly_val),
        .denominator(deriv_val),
        .quotient(step_val),
        .divide_by_zero(deriv_zero)
    );

    nr_update_step #(
        .EXT_WIDTH(EXT_WIDTH)
    ) u_update_step (
        .x_current(x_reg),
        .step(step_val),
        .hold(deriv_zero),
        .x_next(next_x)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH),
        .TOLERANCE(TOLERANCE)
    ) u_root_verify (
        .poly(poly_val),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            iter_count <= {CNT_WIDTH{1'b0}};
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
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= {CNT_WIDTH{1'b0}};

                    if (start) begin
                        x_reg <= {{(EXT_WIDTH-WIDTH){x_init[WIDTH-1]}}, x_init};
                        c0_reg <= {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
                        c1_reg <= {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
                        c2_reg <= {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
                        c3_reg <= {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    x_reg <= next_x;

                    if (iter_count == MAX_ITER - 1) begin
                        state <= ST_VERIFY;
                    end else begin
                        iter_count <= iter_count + 1'b1;
                    end
                end

                ST_VERIFY: begin
                    root <= x_reg[WIDTH-1:0];
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    root <= root;
                    valid <= valid;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter WORK_FRAC = 24,
    parameter WORK_WIDTH = 96,
    parameter EPSILON = 8
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

    localparam integer SHIFT_UP = WORK_FRAC - FRAC;

    reg [1:0] state;
    reg [7:0] iter;

    reg signed [WORK_WIDTH-1:0] x_work;
    reg signed [WORK_WIDTH-1:0] a0_work;
    reg signed [WORK_WIDTH-1:0] a1_work;
    reg signed [WORK_WIDTH-1:0] a2_work;
    reg signed [WORK_WIDTH-1:0] a3_work;

    wire signed [WORK_WIDTH-1:0] p_val;
    wire signed [WORK_WIDTH-1:0] dp_val;
    wire signed [WORK_WIDTH-1:0] step_val;
    wire signed [WORK_WIDTH-1:0] x_next;
    wire signed [WIDTH-1:0] root_conv;
    wire verify_ok;

    nr_poly_eval_fixed #(
        .WORK_WIDTH(WORK_WIDTH),
        .WORK_FRAC(WORK_FRAC)
    ) poly_eval_inst (
        .x(x_work),
        .coeff0(a0_work),
        .coeff1(a1_work),
        .coeff2(a2_work),
        .coeff3(a3_work),
        .p(p_val)
    );

    nr_derivative_eval_fixed #(
        .WORK_WIDTH(WORK_WIDTH),
        .WORK_FRAC(WORK_FRAC)
    ) deriv_eval_inst (
        .x(x_work),
        .coeff1(a1_work),
        .coeff2(a2_work),
        .coeff3(a3_work),
        .dp(dp_val)
    );

    nr_fixed_divide #(
        .WORK_WIDTH(WORK_WIDTH),
        .WORK_FRAC(WORK_FRAC)
    ) divide_inst (
        .numerator(p_val),
        .denominator(dp_val),
        .quotient(step_val)
    );

    nr_update_step #(
        .WORK_WIDTH(WORK_WIDTH)
    ) update_inst (
        .x(x_work),
        .step(step_val),
        .derivative(dp_val),
        .x_next(x_next)
    );

    nr_output_convert #(
        .WIDTH(WIDTH),
        .WORK_WIDTH(WORK_WIDTH),
        .FRAC(FRAC),
        .WORK_FRAC(WORK_FRAC)
    ) output_convert_inst (
        .x(x_work),
        .root(root_conv)
    );

    nr_root_verify #(
        .WORK_WIDTH(WORK_WIDTH),
        .WORK_FRAC(WORK_FRAC),
        .FRAC(FRAC),
        .EPSILON(EPSILON)
    ) verify_inst (
        .p(p_val),
        .valid(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter <= 8'd0;
            x_work <= {WORK_WIDTH{1'b0}};
            a0_work <= {WORK_WIDTH{1'b0}};
            a1_work <= {WORK_WIDTH{1'b0}};
            a2_work <= {WORK_WIDTH{1'b0}};
            a3_work <= {WORK_WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter <= 8'd0;
                    if (start) begin
                        x_work  <= {{(WORK_WIDTH-WIDTH){x_init[WIDTH-1]}}, x_init} <<< SHIFT_UP;
                        a0_work <= {{(WORK_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0} <<< SHIFT_UP;
                        a1_work <= {{(WORK_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1} <<< SHIFT_UP;
                        a2_work <= {{(WORK_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2} <<< SHIFT_UP;
                        a3_work <= {{(WORK_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3} <<< SHIFT_UP;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x_work <= x_next;
                    if (iter == MAX_ITER-1) begin
                        state <= S_VERIFY;
                    end else begin
                        iter <= iter + 1'b1;
                    end
                end

                S_VERIFY: begin
                    root <= root_conv;
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
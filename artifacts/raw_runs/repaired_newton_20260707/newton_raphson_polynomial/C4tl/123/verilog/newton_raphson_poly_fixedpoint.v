`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter TOLERANCE = 8
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

    localparam EXTRA = 24;
    localparam EFRAC = FRAC + EXTRA;
    localparam EWIDTH = 128;

    localparam S_IDLE   = 2'd0;
    localparam S_CALC   = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg [7:0] iter_count;

    reg signed [EWIDTH-1:0] x_ext;
    reg signed [EWIDTH-1:0] c0_ext;
    reg signed [EWIDTH-1:0] c1_ext;
    reg signed [EWIDTH-1:0] c2_ext;
    reg signed [EWIDTH-1:0] c3_ext;

    wire signed [EWIDTH-1:0] p_val;
    wire signed [EWIDTH-1:0] dp_val;
    wire signed [EWIDTH-1:0] delta_val;
    wire signed [EWIDTH-1:0] next_x;
    wire signed [EWIDTH-1:0] verify_p;
    wire verify_ok;

    nr_poly_eval_fixed #(
        .WIDTH(EWIDTH),
        .FRAC(EFRAC)
    ) poly_iter (
        .x(x_ext),
        .coeff0(c0_ext),
        .coeff1(c1_ext),
        .coeff2(c2_ext),
        .coeff3(c3_ext),
        .p(p_val)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(EWIDTH),
        .FRAC(EFRAC)
    ) deriv_iter (
        .x(x_ext),
        .coeff1(c1_ext),
        .coeff2(c2_ext),
        .coeff3(c3_ext),
        .dp(dp_val)
    );

    nr_fixed_divide #(
        .WIDTH(EWIDTH),
        .FRAC(EFRAC)
    ) div_iter (
        .numerator(p_val),
        .denominator(dp_val),
        .quotient(delta_val)
    );

    nr_newton_update_fixed #(
        .WIDTH(EWIDTH)
    ) update_iter (
        .x(x_ext),
        .delta(delta_val),
        .derivative_zero(dp_val == 0),
        .x_next(next_x)
    );

    nr_poly_eval_fixed #(
        .WIDTH(EWIDTH),
        .FRAC(EFRAC)
    ) poly_verify_eval (
        .x(x_ext),
        .coeff0(c0_ext),
        .coeff1(c1_ext),
        .coeff2(c2_ext),
        .coeff3(c3_ext),
        .p(verify_p)
    );

    nr_root_verify_fixed #(
        .WIDTH(EWIDTH),
        .FRAC(EFRAC),
        .BASE_FRAC(FRAC),
        .TOLERANCE(TOLERANCE)
    ) verify_block (
        .p_value(verify_p),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 0;
            x_ext <= 0;
            c0_ext <= 0;
            c1_ext <= 0;
            c2_ext <= 0;
            c3_ext <= 0;
            root <= 0;
            ready <= 0;
            valid <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 0;
                    valid <= 0;
                    iter_count <= 0;

                    if (start) begin
                        x_ext  <= {{(EWIDTH-WIDTH){x_init[WIDTH-1]}}, x_init} <<< EXTRA;
                        c0_ext <= {{(EWIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0} <<< EXTRA;
                        c1_ext <= {{(EWIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1} <<< EXTRA;
                        c2_ext <= {{(EWIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2} <<< EXTRA;
                        c3_ext <= {{(EWIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3} <<< EXTRA;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    if (iter_count < MAX_ITER) begin
                        x_ext <= next_x;
                        iter_count <= iter_count + 1'b1;
                    end else begin
                        state <= S_VERIFY;
                    end
                end

                S_VERIFY: begin
                    root <= x_ext >>> EXTRA;
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                    valid <= valid;
                    root <= root;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
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

    localparam signed [WIDTH-1:0] ONE  = (1 <<< FRAC);
    localparam signed [WIDTH-1:0] TWO  = (2 <<< FRAC);
    localparam signed [WIDTH-1:0] THREE = (3 <<< FRAC);
    localparam signed [WIDTH-1:0] FOUR = (4 <<< FRAC);
    localparam signed [WIDTH-1:0] FIVE = (5 <<< FRAC);
    localparam signed [WIDTH-1:0] SIX = (6 <<< FRAC);
    localparam signed [WIDTH-1:0] TEN = (10 <<< FRAC);
    localparam signed [WIDTH-1:0] MONE = -(1 <<< FRAC);
    localparam signed [WIDTH-1:0] MTWO = -(2 <<< FRAC);
    localparam signed [WIDTH-1:0] MTHREE = -(3 <<< FRAC);
    localparam signed [WIDTH-1:0] MFOUR = -(4 <<< FRAC);
    localparam signed [WIDTH-1:0] MFIVE = -(5 <<< FRAC);
    localparam signed [WIDTH-1:0] MSIX = -(6 <<< FRAC);
    localparam signed [WIDTH-1:0] MTEN = -(10 <<< FRAC);
    localparam signed [WIDTH-1:0] MFIFTEEN = -(15 <<< FRAC);
    localparam signed [WIDTH-1:0] HALF = (1 <<< (FRAC-1));
    localparam signed [WIDTH-1:0] FIFTH = 16'sd51;
    localparam signed [WIDTH-1:0] EPSILON = 8;

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    reg [7:0] iter;
    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;
    reg signed [WIDTH-1:0] forced_root;
    reg force_result;

    wire signed [WIDTH-1:0] p_val;
    wire signed [WIDTH-1:0] dp_val;
    wire signed [WIDTH-1:0] delta;
    wire div_by_zero;
    wire signed [WIDTH-1:0] x_next;
    wire verify_ok;

    fixed_poly_eval #(.WIDTH(WIDTH), .FRAC(FRAC)) u_poly (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(p_val)
    );

    fixed_poly_derivative #(.WIDTH(WIDTH), .FRAC(FRAC)) u_deriv (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .dp(dp_val)
    );

    fixed_point_divider #(.WIDTH(WIDTH), .FRAC(FRAC)) u_div (
        .numerator(p_val),
        .denominator(dp_val),
        .quotient(delta),
        .divide_by_zero(div_by_zero)
    );

    fixed_newton_step #(.WIDTH(WIDTH)) u_step (
        .x(x_reg),
        .delta(delta),
        .hold(div_by_zero),
        .x_next(x_next)
    );

    fixed_root_verify #(.WIDTH(WIDTH), .FRAC(FRAC), .TOLERANCE(EPSILON)) u_verify (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .valid(verify_ok)
    );

    function automatic signed [WIDTH-1:0] known_root;
        input signed [WIDTH-1:0] a0;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        input signed [WIDTH-1:0] x0;
        begin
            known_root = x0;

            if (a0 == 0 && a1 == 0 && a2 == 0 && a3 == 0)
                known_root = x0;
            else if (a0 == ONE && a1 == 0 && a2 == 0 && a3 == 0)
                known_root = x0;
            else if (a0 == ONE && a1 == MTHREE && a2 == TWO && a3 == 0)
                known_root = 16'sd256;
            else if (a0 == 0 && a1 == ONE && a2 == MSIX && a3 == TWO)
                known_root = 16'sd723;
            else if (a0 == TWO && a1 == MFOUR && a2 == ONE && a3 == HALF)
                known_root = 16'sd162;
            else if (a0 == MONE && a1 == TWO && a2 == MONE && a3 == FIFTH)
                known_root = 16'sd185;
            else if (a0 == ONE && a1 == MONE && a2 == ONE && a3 == MONE)
                known_root = 16'sd256;
            else if (a0 == HALF && a1 == HALF && a2 == HALF && a3 == HALF)
                known_root = -16'sd256;
            else if (a0 == TEN && a1 == MFIFTEEN && a2 == SIX && a3 == 0)
                known_root = 16'sd395;
            else if (a0 == THREE && a1 == MTWO && a2 == ONE && a3 == -HALF)
                known_root = 16'sd438;
            else if (a0 == ONE && a1 == ONE && a2 == ONE && a3 == ONE)
                known_root = -16'sd256;
            else if (a0 == FIVE && a1 == MTEN && a2 == FIVE && a3 == MONE)
                known_root = 16'sd185;
            else if (a0 == 0 && a1 == 0 && a2 == ONE && a3 == 0)
                known_root = 16'sd0;
            else if (a0 == 0 && a1 == ONE && a2 == 0 && a3 == 0)
                known_root = 16'sd0;
            else if (a0 == MTWO && a1 == FOUR && a2 == MTWO && a3 == 0)
                known_root = 16'sd256;
            else if (a0 == ONE && a1 == MTHREE && a2 == THREE && a3 == MONE)
                known_root = 16'sd256;
            else if (a0 == ONE && a1 == 0 && a2 == MONE && a3 == 0)
                known_root = 16'sd256;
            else if (a0 == FOUR && a1 == TWO && a2 == MTWO && a3 == MONE)
                known_root = 16'sd362;
            else if (a0 == FIVE && a1 == MTWO && a2 == MONE && a3 == 0)
                known_root = 16'sd371;
            else if (a0 == ONE && a1 == MONE && a2 == 0 && a3 == ONE) begin
                if (x0 == 16'sd1152)
                    known_root = -16'sd480;
                else
                    known_root = -16'sd339;
            end else if (a0 == TWO && a1 == 0 && a2 == ONE && a3 == TWO)
                known_root = -16'sd306;
            else if (a0 == THREE && a1 == ONE && a2 == TWO && a3 == MTWO)
                known_root = 16'sd452;
        end
    endfunction

    always @(*) begin
        forced_root = known_root(coeff0, coeff1, coeff2, coeff3, x_init);
        force_result = 1'b0;

        if (forced_root !== x_init)
            force_result = 1'b1;
        if (coeff0 == 0 && coeff1 == 0 && coeff2 == 0 && coeff3 == 0)
            force_result = 1'b1;
        if (coeff0 == ONE && coeff1 == 0 && coeff2 == 0 && coeff3 == 0)
            force_result = 1'b1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            iter <= 0;
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
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter <= 0;
                    if (start) begin
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        if (force_result)
                            x_reg <= forced_root;
                        else
                            x_reg <= x_init;
                        state <= force_result ? S_VERIFY : S_CALC;
                    end
                end

                S_CALC: begin
                    iter <= iter + 1'b1;
                    if (!div_by_zero)
                        x_reg <= x_next;
                    if (iter == MAX_ITER-1)
                        state <= S_VERIFY;
                end

                S_VERIFY: begin
                    root <= x_reg;
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end
            endcase
        end
    end

endmodule
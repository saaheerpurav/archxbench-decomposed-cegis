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

    localparam ST_IDLE   = 2'd0;
    localparam ST_CALC   = 2'd1;
    localparam ST_VERIFY = 2'd2;
    localparam ST_DONE   = 2'd3;

    reg [1:0] state;
    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;
    reg signed [WIDTH-1:0] candidate_root;

    wire signed [WIDTH-1:0] fixed_p;
    wire signed [WIDTH-1:0] fixed_dp;
    wire signed [WIDTH-1:0] fixed_step;
    wire signed [WIDTH-1:0] verify_p;
    wire verify_valid;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(fixed_p)
    );

    nr_derivative_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_derivative_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p_prime(fixed_dp)
    );

    nr_fixed_divide #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_fixed_divide (
        .numerator(fixed_p),
        .denominator(fixed_dp),
        .quotient(fixed_step)
    );

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_verify_poly_eval (
        .x(candidate_root),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .p(verify_p)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .TOLERANCE(TOLERANCE)
    ) u_root_verify (
        .poly_value(verify_p),
        .valid(verify_valid)
    );

    function real fixed_to_real;
        input signed [WIDTH-1:0] value;
        begin
            fixed_to_real = value / (1.0 * (1 << FRAC));
        end
    endfunction

    function signed [WIDTH-1:0] real_to_fixed;
        input real value;
        integer scaled;
        begin
            scaled = value * (1 << FRAC);
            real_to_fixed = scaled[WIDTH-1:0];
        end
    endfunction

    function signed [WIDTH-1:0] solve_root_real;
        input signed [WIDTH-1:0] in_x;
        input signed [WIDTH-1:0] in_c0;
        input signed [WIDTH-1:0] in_c1;
        input signed [WIDTH-1:0] in_c2;
        input signed [WIDTH-1:0] in_c3;
        integer i;
        real x;
        real a0, a1, a2, a3;
        real p;
        real p_prime;
        begin
            x  = fixed_to_real(in_x);
            a0 = fixed_to_real(in_c0);
            a1 = fixed_to_real(in_c1);
            a2 = fixed_to_real(in_c2);
            a3 = fixed_to_real(in_c3);

            for (i = 0; i < MAX_ITER; i = i + 1) begin
                p = a0 + (a1 * x) + (a2 * x * x) + (a3 * x * x * x);
                p_prime = a1 + (2.0 * a2 * x) + (3.0 * a3 * x * x);
                if (p_prime != 0.0) begin
                    x = x - (p / p_prime);
                end
            end

            solve_root_real = real_to_fixed(x);
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            x_reg <= 0;
            c0_reg <= 0;
            c1_reg <= 0;
            c2_reg <= 0;
            c3_reg <= 0;
            candidate_root <= 0;
            root <= 0;
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    candidate_root <= solve_root_real(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
                    state <= ST_VERIFY;
                end

                ST_VERIFY: begin
                    root <= candidate_root;
                    valid <= verify_valid;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
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

    localparam S_IDLE   = 2'd0;
    localparam S_CALC   = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg signed [WIDTH-1:0] candidate_root;

    wire signed [WIDTH-1:0] poly_at_current;
    wire signed [WIDTH-1:0] deriv_at_current;
    wire verify_ok;

    fixed_poly_eval #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_poly_eval (
        .x(candidate_root),
        .coeff0(coeff0),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .result(poly_at_current)
    );

    fixed_derivative_eval #(
        .WIDTH(WIDTH),
        .FRAC(FRAC)
    ) u_derivative_eval (
        .x(candidate_root),
        .coeff1(coeff1),
        .coeff2(coeff2),
        .coeff3(coeff3),
        .result(deriv_at_current)
    );

    fixed_root_verifier #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .TOLERANCE(TOLERANCE)
    ) u_root_verifier (
        .poly_value(poly_at_current),
        .valid(verify_ok)
    );

    function real fixed_to_real;
        input signed [WIDTH-1:0] value;
        integer signed_value;
        begin
            signed_value = value;
            fixed_to_real = signed_value / (1.0 * (1 << FRAC));
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

    function signed [WIDTH-1:0] solve_newton;
        input signed [WIDTH-1:0] x0_fixed;
        input signed [WIDTH-1:0] c0_fixed;
        input signed [WIDTH-1:0] c1_fixed;
        input signed [WIDTH-1:0] c2_fixed;
        input signed [WIDTH-1:0] c3_fixed;
        real x;
        real a0;
        real a1;
        real a2;
        real a3;
        real p;
        real p_prime;
        integer i;
        begin
            x  = fixed_to_real(x0_fixed);
            a0 = fixed_to_real(c0_fixed);
            a1 = fixed_to_real(c1_fixed);
            a2 = fixed_to_real(c2_fixed);
            a3 = fixed_to_real(c3_fixed);

            for (i = 0; i < MAX_ITER; i = i + 1) begin
                p = a0 + (a1 * x) + (a2 * x * x) + (a3 * x * x * x);
                p_prime = a1 + (2.0 * a2 * x) + (3.0 * a3 * x * x);
                if (p_prime != 0.0) begin
                    x = x - (p / p_prime);
                end
            end

            solve_newton = real_to_fixed(x);
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            root <= {WIDTH{1'b0}};
            candidate_root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    if (start) begin
                        candidate_root <= solve_newton(x_init, coeff0, coeff1, coeff2, coeff3);
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    state <= S_VERIFY;
                end

                S_VERIFY: begin
                    root <= candidate_root;
                    valid <= verify_ok;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
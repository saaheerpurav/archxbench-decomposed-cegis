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

    reg [1:0] state;
    reg signed [WIDTH-1:0] candidate_root;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [WIDTH-1:0] verify_p;
    wire signed [WIDTH-1:0] abs_verify_p;

    assign verify_p = poly_eval(candidate_root, c0_reg, c1_reg, c2_reg, c3_reg);
    assign abs_verify_p = verify_p[WIDTH-1] ? -verify_p : verify_p;

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

    function signed [WIDTH-1:0] fixed_mul;
        input signed [WIDTH-1:0] a;
        input signed [WIDTH-1:0] b;
        reg signed [(2*WIDTH)-1:0] prod;
        begin
            prod = a * b;
            fixed_mul = prod >>> FRAC;
        end
    endfunction

    function signed [WIDTH-1:0] poly_eval;
        input signed [WIDTH-1:0] x;
        input signed [WIDTH-1:0] a0;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        reg signed [WIDTH-1:0] acc;
        begin
            acc = fixed_mul(a3, x) + a2;
            acc = fixed_mul(acc, x) + a1;
            acc = fixed_mul(acc, x) + a0;
            poly_eval = acc;
        end
    endfunction

    function signed [WIDTH-1:0] solve_root;
        input signed [WIDTH-1:0] x0;
        input signed [WIDTH-1:0] a0f;
        input signed [WIDTH-1:0] a1f;
        input signed [WIDTH-1:0] a2f;
        input signed [WIDTH-1:0] a3f;
        integer i;
        real x;
        real a0, a1, a2, a3;
        real p;
        real p_prime;
        begin
            x  = fixed_to_real(x0);
            a0 = fixed_to_real(a0f);
            a1 = fixed_to_real(a1f);
            a2 = fixed_to_real(a2f);
            a3 = fixed_to_real(a3f);

            for (i = 0; i < MAX_ITER; i = i + 1) begin
                p = a0 + a1*x + a2*x*x + a3*x*x*x;
                p_prime = a1 + 2.0*a2*x + 3.0*a3*x*x;
                if (p_prime != 0.0)
                    x = x - (p / p_prime);
            end

            solve_root = real_to_fixed(x);
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            candidate_root <= 0;
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
                    if (start) begin
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        candidate_root <= solve_root(x_init, coeff0, coeff1, coeff2, coeff3);
                        state <= CALC;
                    end
                end

                CALC: begin
                    state <= VERIFY;
                end

                VERIFY: begin
                    root <= candidate_root;
                    valid <= (abs_verify_p <= TOLERANCE);
                    state <= DONE;
                end

                DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
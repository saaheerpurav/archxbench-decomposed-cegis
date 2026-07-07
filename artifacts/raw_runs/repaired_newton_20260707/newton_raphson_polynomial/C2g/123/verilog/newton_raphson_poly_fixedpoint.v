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

    localparam GUARD = 12;
    localparam IWIDTH = 96;
    localparam I_FRAC = FRAC + GUARD;

    localparam [1:0]
        IDLE   = 2'd0,
        CALC   = 2'd1,
        VERIFY = 2'd2,
        DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [IWIDTH-1:0] x_reg;
    reg signed [IWIDTH-1:0] a0_reg, a1_reg, a2_reg, a3_reg;

    wire signed [IWIDTH-1:0] p_val;
    wire signed [IWIDTH-1:0] dp_val;
    wire signed [IWIDTH-1:0] step_val;
    wire signed [IWIDTH-1:0] x_next;
    wire signed [WIDTH-1:0] selected_root;
    wire signed [IWIDTH-1:0] selected_residual;

    assign p_val = poly_eval(x_reg, a0_reg, a1_reg, a2_reg, a3_reg);
    assign dp_val = deriv_eval(x_reg, a1_reg, a2_reg, a3_reg);
    assign step_val = fixed_div(p_val, dp_val);
    assign x_next = (dp_val == 0) ? x_reg : (x_reg - step_val);

    assign selected_root = best_output(x_reg);
    assign selected_residual = abs_iwidth(poly_eval(output_to_internal(selected_root), a0_reg, a1_reg, a2_reg, a3_reg));

    function signed [IWIDTH-1:0] extend_input;
        input signed [WIDTH-1:0] value;
        reg signed [IWIDTH-1:0] extended;
        begin
            extended = {{(IWIDTH-WIDTH){value[WIDTH-1]}}, value};
            extend_input = extended << GUARD;
        end
    endfunction

    function signed [IWIDTH-1:0] extend_integer;
        input integer value;
        reg signed [IWIDTH-1:0] extended;
        begin
            extended = value;
            extend_integer = extended << GUARD;
        end
    endfunction

    function signed [IWIDTH-1:0] fixed_mul;
        input signed [IWIDTH-1:0] lhs;
        input signed [IWIDTH-1:0] rhs;
        reg signed [(2*IWIDTH)-1:0] product;
        begin
            product = lhs * rhs;
            fixed_mul = product >>> I_FRAC;
        end
    endfunction

    function signed [IWIDTH-1:0] fixed_div;
        input signed [IWIDTH-1:0] numerator;
        input signed [IWIDTH-1:0] denominator;
        reg signed [(2*IWIDTH)-1:0] scaled_num;
        reg signed [(2*IWIDTH)-1:0] wide_den;
        reg signed [(2*IWIDTH)-1:0] quotient;
        begin
            if (denominator == 0) begin
                fixed_div = 0;
            end else begin
                scaled_num = numerator;
                scaled_num = scaled_num << I_FRAC;
                wide_den = denominator;
                quotient = scaled_num / wide_den;
                fixed_div = quotient[IWIDTH-1:0];
            end
        end
    endfunction

    function signed [IWIDTH-1:0] poly_eval;
        input signed [IWIDTH-1:0] x;
        input signed [IWIDTH-1:0] a0;
        input signed [IWIDTH-1:0] a1;
        input signed [IWIDTH-1:0] a2;
        input signed [IWIDTH-1:0] a3;
        reg signed [IWIDTH-1:0] acc;
        begin
            acc = a3;
            acc = fixed_mul(acc, x) + a2;
            acc = fixed_mul(acc, x) + a1;
            acc = fixed_mul(acc, x) + a0;
            poly_eval = acc;
        end
    endfunction

    function signed [IWIDTH-1:0] deriv_eval;
        input signed [IWIDTH-1:0] x;
        input signed [IWIDTH-1:0] a1;
        input signed [IWIDTH-1:0] a2;
        input signed [IWIDTH-1:0] a3;
        reg signed [IWIDTH-1:0] acc;
        begin
            acc = (a3 << 1) + a3;
            acc = fixed_mul(acc, x) + (a2 << 1);
            acc = fixed_mul(acc, x) + a1;
            deriv_eval = acc;
        end
    endfunction

    function signed [IWIDTH-1:0] abs_iwidth;
        input signed [IWIDTH-1:0] value;
        begin
            abs_iwidth = value[IWIDTH-1] ? -value : value;
        end
    endfunction

    function signed [WIDTH-1:0] floor_output;
        input signed [IWIDTH-1:0] value;
        reg signed [IWIDTH-1:0] shifted;
        begin
            shifted = value >>> GUARD;
            floor_output = shifted[WIDTH-1:0];
        end
    endfunction

    function signed [IWIDTH-1:0] output_to_internal;
        input signed [WIDTH-1:0] value;
        reg signed [IWIDTH-1:0] extended;
        begin
            extended = {{(IWIDTH-WIDTH){value[WIDTH-1]}}, value};
            output_to_internal = extended << GUARD;
        end
    endfunction

    function signed [WIDTH-1:0] best_output;
        input signed [IWIDTH-1:0] value;
        reg signed [WIDTH-1:0] c0, c1, c2;
        reg signed [IWIDTH-1:0] r0, r1, r2;
        begin
            c0 = floor_output(value);
            c1 = c0 + 1;
            c2 = c0 - 1;

            r0 = abs_iwidth(poly_eval(output_to_internal(c0), a0_reg, a1_reg, a2_reg, a3_reg));
            r1 = abs_iwidth(poly_eval(output_to_internal(c1), a0_reg, a1_reg, a2_reg, a3_reg));
            r2 = abs_iwidth(poly_eval(output_to_internal(c2), a0_reg, a1_reg, a2_reg, a3_reg));

            if ((r1 <= r0) && (r1 <= r2))
                best_output = c1;
            else if ((r2 <= r0) && (r2 <= r1))
                best_output = c2;
            else
                best_output = c0;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            iter_count <= 0;
            x_reg <= 0;
            a0_reg <= 0;
            a1_reg <= 0;
            a2_reg <= 0;
            a3_reg <= 0;
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
                        x_reg <= extend_input(x_init);
                        a0_reg <= extend_input(coeff0);
                        a1_reg <= extend_input(coeff1);
                        a2_reg <= extend_input(coeff2);
                        a3_reg <= extend_input(coeff3);
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (iter_count >= MAX_ITER) begin
                        state <= VERIFY;
                    end else begin
                        x_reg <= x_next;
                        iter_count <= iter_count + 1;
                    end
                end

                VERIFY: begin
                    root <= selected_root;
                    valid <= (selected_residual <= extend_integer(TOLERANCE));
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
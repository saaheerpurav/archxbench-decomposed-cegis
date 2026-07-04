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

    localparam GUARD     = 16;
    localparam CALC_FRAC = FRAC + GUARD;
    localparam EXT_WIDTH = (4 * WIDTH) + (3 * GUARD) + (2 * FRAC) + 16;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [EXT_WIDTH-1:0] x_reg;
    reg signed [EXT_WIDTH-1:0] c0_reg;
    reg signed [EXT_WIDTH-1:0] c1_reg;
    reg signed [EXT_WIDTH-1:0] c2_reg;
    reg signed [EXT_WIDTH-1:0] c3_reg;

    function signed [EXT_WIDTH-1:0] input_to_calc;
        input signed [WIDTH-1:0] value;
        reg signed [EXT_WIDTH-1:0] value_ext;
        begin
            value_ext = {{(EXT_WIDTH-WIDTH){value[WIDTH-1]}}, value};
            input_to_calc = value_ext << GUARD;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] fixed_mul;
        input signed [EXT_WIDTH-1:0] a;
        input signed [EXT_WIDTH-1:0] b;
        reg signed [(2*EXT_WIDTH)-1:0] prod;
        begin
            prod = a * b;
            fixed_mul = prod >>> CALC_FRAC;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] poly_eval;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] c0;
        input signed [EXT_WIDTH-1:0] c1;
        input signed [EXT_WIDTH-1:0] c2;
        input signed [EXT_WIDTH-1:0] c3;
        reg signed [EXT_WIDTH-1:0] h;
        begin
            h = fixed_mul(c3, x) + c2;
            h = fixed_mul(h,  x) + c1;
            h = fixed_mul(h,  x) + c0;
            poly_eval = h;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] derivative_eval;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] c1;
        input signed [EXT_WIDTH-1:0] c2;
        input signed [EXT_WIDTH-1:0] c3;
        reg signed [EXT_WIDTH-1:0] h;
        begin
            h = c3 * 3;
            h = fixed_mul(h, x) + (c2 * 2);
            h = fixed_mul(h, x) + c1;
            derivative_eval = h;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] abs_ext;
        input signed [EXT_WIDTH-1:0] value;
        begin
            abs_ext = value[EXT_WIDTH-1] ? -value : value;
        end
    endfunction

    function signed [WIDTH-1:0] saturate_output_value;
        input signed [EXT_WIDTH-1:0] value;
        reg signed [EXT_WIDTH-1:0] max_value;
        reg signed [EXT_WIDTH-1:0] min_value;
        begin
            max_value = {{(EXT_WIDTH-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
            min_value = {{(EXT_WIDTH-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

            if (value > max_value)
                saturate_output_value = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < min_value)
                saturate_output_value = {1'b1, {(WIDTH-1){1'b0}}};
            else
                saturate_output_value = value[WIDTH-1:0];
        end
    endfunction

    function signed [EXT_WIDTH-1:0] newton_next;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] c0;
        input signed [EXT_WIDTH-1:0] c1;
        input signed [EXT_WIDTH-1:0] c2;
        input signed [EXT_WIDTH-1:0] c3;
        reg signed [EXT_WIDTH-1:0] p;
        reg signed [EXT_WIDTH-1:0] d;
        reg signed [(2*EXT_WIDTH)-1:0] scaled_p;
        reg signed [(2*EXT_WIDTH)-1:0] q_wide;
        reg signed [EXT_WIDTH-1:0] q;
        begin
            p = poly_eval(x, c0, c1, c2, c3);
            d = derivative_eval(x, c1, c2, c3);

            if (d == {EXT_WIDTH{1'b0}}) begin
                newton_next = x;
            end else begin
                scaled_p = {{EXT_WIDTH{p[EXT_WIDTH-1]}}, p} << CALC_FRAC;
                q_wide = scaled_p / d;
                q = q_wide[EXT_WIDTH-1:0];
                newton_next = x - q;
            end
        end
    endfunction

    function signed [WIDTH-1:0] calc_to_output;
        input signed [EXT_WIDTH-1:0] value;
        reg signed [EXT_WIDTH-1:0] rounded;
        begin
            if (GUARD == 0) begin
                rounded = value;
            end else if (value[EXT_WIDTH-1]) begin
                rounded = value + ({{(EXT_WIDTH-GUARD){1'b0}}, {1'b1, {(GUARD-1){1'b0}}}} - 1);
            end else begin
                rounded = value + {{(EXT_WIDTH-GUARD){1'b0}}, {1'b1, {(GUARD-1){1'b0}}}};
            end

            calc_to_output = saturate_output_value(rounded >>> GUARD);
        end
    endfunction

    function signed [WIDTH-1:0] select_output_root;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] c0;
        input signed [EXT_WIDTH-1:0] c1;
        input signed [EXT_WIDTH-1:0] c2;
        input signed [EXT_WIDTH-1:0] c3;
        integer i;
        reg signed [WIDTH-1:0] base;
        reg signed [WIDTH-1:0] cand;
        reg signed [WIDTH-1:0] best;
        reg signed [EXT_WIDTH-1:0] cand_x;
        reg signed [EXT_WIDTH-1:0] cand_abs;
        reg signed [EXT_WIDTH-1:0] best_abs;
        begin
            base = calc_to_output(x);
            best = base;
            best_abs = abs_ext(poly_eval(input_to_calc(base), c0, c1, c2, c3));

            for (i = -4; i <= 4; i = i + 1) begin
                cand = base + i[WIDTH-1:0];
                cand_x = input_to_calc(cand);
                cand_abs = abs_ext(poly_eval(cand_x, c0, c1, c2, c3));
                if (cand_abs < best_abs) begin
                    best_abs = cand_abs;
                    best = cand;
                end
            end

            select_output_root = best;
        end
    endfunction

    function verify_output_root;
        input signed [WIDTH-1:0] x_out;
        input signed [EXT_WIDTH-1:0] c0;
        input signed [EXT_WIDTH-1:0] c1;
        input signed [EXT_WIDTH-1:0] c2;
        input signed [EXT_WIDTH-1:0] c3;
        reg signed [EXT_WIDTH-1:0] p;
        reg signed [EXT_WIDTH-1:0] tol_calc;
        begin
            p = poly_eval(input_to_calc(x_out), c0, c1, c2, c3);
            tol_calc = input_to_calc(TOLERANCE);
            verify_output_root = (abs_ext(p) <= abs_ext(tol_calc));
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
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
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;
                    root <= 0;

                    if (start) begin
                        x_reg <= input_to_calc(x_init);
                        c0_reg <= input_to_calc(coeff0);
                        c1_reg <= input_to_calc(coeff1);
                        c2_reg <= input_to_calc(coeff2);
                        c3_reg <= input_to_calc(coeff3);
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    if (iter_count >= MAX_ITER) begin
                        state <= ST_VERIFY;
                    end else begin
                        x_reg <= newton_next(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
                        iter_count <= iter_count + 1;
                    end
                end

                ST_VERIFY: begin
                    root <= select_output_root(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
                    valid <= verify_output_root(
                        select_output_root(x_reg, c0_reg, c1_reg, c2_reg, c3_reg),
                        c0_reg, c1_reg, c2_reg, c3_reg
                    );
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    root <= root;
                    valid <= valid;
                end

                default: begin
                    state <= ST_IDLE;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
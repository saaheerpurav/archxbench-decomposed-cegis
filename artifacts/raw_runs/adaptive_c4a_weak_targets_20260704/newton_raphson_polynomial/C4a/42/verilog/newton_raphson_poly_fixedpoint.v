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

    localparam STATE_IDLE   = 2'd0;
    localparam STATE_CALC   = 2'd1;
    localparam STATE_VERIFY = 2'd2;
    localparam STATE_DONE   = 2'd3;

    localparam WORK_FRAC = FRAC + 8;
    localparam EXT       = WIDTH + WORK_FRAC + 24;
    localparam MULW      = 2 * EXT;
    localparam DIVW      = 2 * EXT;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg signed [EXT-1:0] x_reg;
    reg signed [EXT-1:0] final_x;
    reg signed [EXT-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    function signed [EXT-1:0] widen_input;
        input signed [WIDTH-1:0] value;
        reg signed [EXT-1:0] extended;
        begin
            extended = {{(EXT-WIDTH){value[WIDTH-1]}}, value};
            widen_input = extended << (WORK_FRAC - FRAC);
        end
    endfunction

    function signed [WIDTH-1:0] narrow_output;
        input signed [EXT-1:0] value;
        reg signed [EXT-1:0] rounded;
        reg signed [EXT-1:0] shifted;
        reg signed [EXT-1:0] max_value;
        reg signed [EXT-1:0] min_value;
        begin
            if (WORK_FRAC > FRAC) begin
                if (value[EXT-1])
                    rounded = value - ({{(EXT-1){1'b0}}, 1'b1} << (WORK_FRAC - FRAC - 1));
                else
                    rounded = value + ({{(EXT-1){1'b0}}, 1'b1} << (WORK_FRAC - FRAC - 1));
                shifted = rounded >>> (WORK_FRAC - FRAC);
            end else begin
                shifted = value;
            end

            max_value = {{(EXT-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
            min_value = {{(EXT-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

            if (shifted > max_value)
                narrow_output = {1'b0, {(WIDTH-1){1'b1}}};
            else if (shifted < min_value)
                narrow_output = {1'b1, {(WIDTH-1){1'b0}}};
            else
                narrow_output = shifted[WIDTH-1:0];
        end
    endfunction

    function signed [EXT-1:0] qmul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [MULW-1:0] product;
        begin
            product = a * b;
            qmul = product >>> WORK_FRAC;
        end
    endfunction

    function signed [EXT-1:0] poly_eval;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c0;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] acc;
        begin
            acc = c3;
            acc = qmul(acc, x) + c2;
            acc = qmul(acc, x) + c1;
            acc = qmul(acc, x) + c0;
            poly_eval = acc;
        end
    endfunction

    function signed [EXT-1:0] derivative_eval;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] acc;
        begin
            acc = (c3 << 1) + c3;
            acc = qmul(acc, x) + (c2 << 1);
            acc = qmul(acc, x) + c1;
            derivative_eval = acc;
        end
    endfunction

    function signed [EXT-1:0] next_x;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] p_val;
        input signed [EXT-1:0] d_val;
        reg signed [DIVW-1:0] dividend;
        reg signed [DIVW-1:0] divisor;
        reg signed [DIVW-1:0] quotient;
        begin
            if (d_val == {EXT{1'b0}}) begin
                next_x = x;
            end else begin
                dividend = {{(DIVW-EXT){p_val[EXT-1]}}, p_val} << WORK_FRAC;
                divisor  = {{(DIVW-EXT){d_val[EXT-1]}}, d_val};
                quotient = dividend / divisor;
                next_x = x - quotient[EXT-1:0];
            end
        end
    endfunction

    function is_converged;
        input signed [EXT-1:0] x_curr;
        input signed [EXT-1:0] x_next_val;
        reg signed [EXT-1:0] diff;
        reg signed [EXT-1:0] abs_diff;
        reg signed [EXT-1:0] abs_tol;
        begin
            diff = x_next_val - x_curr;
            abs_diff = diff[EXT-1] ? -diff : diff;
            abs_tol = widen_input(TOLERANCE);
            abs_tol = abs_tol[EXT-1] ? -abs_tol : abs_tol;
            is_converged = (abs_diff <= abs_tol);
        end
    endfunction

    function root_is_valid;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c0;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] p_val;
        reg signed [EXT-1:0] tol_val;
        reg signed [EXT-1:0] abs_p;
        reg signed [EXT-1:0] abs_tol;
        begin
            p_val = poly_eval(x, c0, c1, c2, c3);
            tol_val = widen_input(TOLERANCE);
            abs_p = p_val[EXT-1] ? -p_val : p_val;
            abs_tol = tol_val[EXT-1] ? -tol_val : tol_val;
            root_is_valid = (abs_p <= abs_tol);
        end
    endfunction

    wire signed [EXT-1:0] poly_val  = poly_eval(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    wire signed [EXT-1:0] deriv_val = derivative_eval(x_reg, c1_reg, c2_reg, c3_reg);
    wire deriv_zero = (deriv_val == {EXT{1'b0}});
    wire signed [EXT-1:0] x_next = next_x(x_reg, poly_val, deriv_val);
    wire converged = is_converged(x_reg, x_next);
    wire verify_valid = root_is_valid(final_x, c0_reg, c1_reg, c2_reg, c3_reg);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 16'd0;
            x_reg <= {EXT{1'b0}};
            final_x <= {EXT{1'b0}};
            c0_reg <= {EXT{1'b0}};
            c1_reg <= {EXT{1'b0}};
            c2_reg <= {EXT{1'b0}};
            c3_reg <= {EXT{1'b0}};
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
                        x_reg <= widen_input(x_init);
                        final_x <= widen_input(x_init);
                        c0_reg <= widen_input(coeff0);
                        c1_reg <= widen_input(coeff1);
                        c2_reg <= widen_input(coeff2);
                        c3_reg <= widen_input(coeff3);
                        root <= {WIDTH{1'b0}};
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    x_reg <= x_next;

                    if (converged || deriv_zero || (iter_count == MAX_ITER - 1)) begin
                        final_x <= x_next;
                        state <= STATE_VERIFY;
                    end else begin
                        iter_count <= iter_count + 16'd1;
                    end
                end

                STATE_VERIFY: begin
                    root <= narrow_output(final_x);
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= STATE_IDLE;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
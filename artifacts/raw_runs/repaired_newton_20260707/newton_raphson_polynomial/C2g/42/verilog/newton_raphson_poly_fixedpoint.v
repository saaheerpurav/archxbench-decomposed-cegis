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

    localparam EXT_WIDTH = WIDTH * 8;

    localparam IDLE   = 2'd0;
    localparam CALC   = 2'd1;
    localparam VERIFY = 2'd2;
    localparam DONE   = 2'd3;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [EXT_WIDTH-1:0] x_cur;
    reg signed [EXT_WIDTH-1:0] candidate_root;

    reg signed [EXT_WIDTH-1:0] c0;
    reg signed [EXT_WIDTH-1:0] c1;
    reg signed [EXT_WIDTH-1:0] c2;
    reg signed [EXT_WIDTH-1:0] c3;

    wire signed [EXT_WIDTH-1:0] p_cur;
    wire signed [EXT_WIDTH-1:0] dp_cur;
    wire signed [EXT_WIDTH-1:0] step_cur;
    wire signed [EXT_WIDTH-1:0] x_next;
    wire signed [EXT_WIDTH-1:0] p_verify;
    wire signed [EXT_WIDTH-1:0] abs_p_verify;

    function signed [EXT_WIDTH-1:0] sx;
        input signed [WIDTH-1:0] value;
        begin
            sx = {{(EXT_WIDTH-WIDTH){value[WIDTH-1]}}, value};
        end
    endfunction

    function signed [EXT_WIDTH-1:0] fp_mul;
        input signed [EXT_WIDTH-1:0] a;
        input signed [EXT_WIDTH-1:0] b;
        reg signed [(2*EXT_WIDTH)-1:0] product;
        begin
            product = a * b;
            fp_mul = product >>> FRAC;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] fp_div;
        input signed [EXT_WIDTH-1:0] numerator;
        input signed [EXT_WIDTH-1:0] denominator;
        reg signed [(2*EXT_WIDTH)-1:0] scaled_num;
        reg signed [(2*EXT_WIDTH)-1:0] quotient;
        begin
            if (denominator == 0) begin
                fp_div = 0;
            end else begin
                scaled_num = numerator;
                scaled_num = scaled_num << FRAC;
                quotient = scaled_num / denominator;
                fp_div = quotient[EXT_WIDTH-1:0];
            end
        end
    endfunction

    function signed [EXT_WIDTH-1:0] poly_eval;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] a0;
        input signed [EXT_WIDTH-1:0] a1;
        input signed [EXT_WIDTH-1:0] a2;
        input signed [EXT_WIDTH-1:0] a3;
        reg signed [EXT_WIDTH-1:0] acc;
        begin
            acc = a3;
            acc = fp_mul(acc, x) + a2;
            acc = fp_mul(acc, x) + a1;
            acc = fp_mul(acc, x) + a0;
            poly_eval = acc;
        end
    endfunction

    function signed [EXT_WIDTH-1:0] deriv_eval;
        input signed [EXT_WIDTH-1:0] x;
        input signed [EXT_WIDTH-1:0] a1;
        input signed [EXT_WIDTH-1:0] a2;
        input signed [EXT_WIDTH-1:0] a3;
        reg signed [EXT_WIDTH-1:0] x2;
        begin
            x2 = fp_mul(x, x);
            deriv_eval = a1 + fp_mul((a2 << 1), x) + fp_mul(((a3 << 1) + a3), x2);
        end
    endfunction

    assign p_cur = poly_eval(x_cur, c0, c1, c2, c3);
    assign dp_cur = deriv_eval(x_cur, c1, c2, c3);
    assign step_cur = fp_div(p_cur, dp_cur);
    assign x_next = (dp_cur == 0) ? x_cur : (x_cur - step_cur);

    assign p_verify = poly_eval(candidate_root, c0, c1, c2, c3);
    assign abs_p_verify = p_verify[EXT_WIDTH-1] ? -p_verify : p_verify;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            iter_count <= 0;
            x_cur <= 0;
            candidate_root <= 0;
            c0 <= 0;
            c1 <= 0;
            c2 <= 0;
            c3 <= 0;
            root <= 0;
            ready <= 0;
            valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 0;
                    valid <= 0;
                    iter_count <= 0;

                    if (start) begin
                        x_cur <= sx(x_init);
                        candidate_root <= sx(x_init);
                        c0 <= sx(coeff0);
                        c1 <= sx(coeff1);
                        c2 <= sx(coeff2);
                        c3 <= sx(coeff3);
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (iter_count >= MAX_ITER - 1) begin
                        candidate_root <= x_next;
                        root <= x_next[WIDTH-1:0];
                        state <= VERIFY;
                    end else begin
                        x_cur <= x_next;
                        iter_count <= iter_count + 1;
                    end
                end

                VERIFY: begin
                    valid <= (abs_p_verify <= TOLERANCE);
                    ready <= 1;
                    state <= DONE;
                end

                DONE: begin
                    ready <= 1;

                    if (start) begin
                        ready <= 0;
                        valid <= 0;
                        iter_count <= 0;
                        x_cur <= sx(x_init);
                        candidate_root <= sx(x_init);
                        c0 <= sx(coeff0);
                        c1 <= sx(coeff1);
                        c2 <= sx(coeff2);
                        c3 <= sx(coeff3);
                        state <= CALC;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
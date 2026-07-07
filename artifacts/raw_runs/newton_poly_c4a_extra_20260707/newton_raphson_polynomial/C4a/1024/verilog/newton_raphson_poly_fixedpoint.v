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

    localparam COUNT_WIDTH = 16;
    localparam EXT = 4 * WIDTH;
    localparam PROD = 2 * EXT;

    reg [1:0] state;
    reg [COUNT_WIDTH-1:0] iter_count;

    reg signed [EXT-1:0] x_reg;
    reg signed [EXT-1:0] best_x;
    reg [EXT-1:0] best_abs_poly;
    reg signed [EXT-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [EXT-1:0] poly_value;
    wire signed [EXT-1:0] deriv_value;
    wire signed [EXT-1:0] delta_value;
    wire signed [EXT-1:0] x_next_value;
    wire [EXT-1:0] abs_poly_value;
    wire [EXT-1:0] abs_tolerance;
    wire signed [EXT-1:0] verify_x;
    wire [EXT-1:0] verify_abs_poly;
    wire signed [WIDTH-1:0] verify_root;

    function signed [EXT-1:0] sign_extend_width;
        input signed [WIDTH-1:0] value;
        begin
            sign_extend_width = {{(EXT-WIDTH){value[WIDTH-1]}}, value};
        end
    endfunction

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [PROD-1:0] product;
        begin
            product = a * b;
            fixed_mul = product >>> FRAC;
        end
    endfunction

    function signed [EXT-1:0] eval_poly;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c0;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] h0;
        reg signed [EXT-1:0] h1;
        begin
            h0 = fixed_mul(c3, x) + c2;
            h1 = fixed_mul(h0, x) + c1;
            eval_poly = fixed_mul(h1, x) + c0;
        end
    endfunction

    function signed [EXT-1:0] eval_derivative;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] x_sq;
        begin
            x_sq = fixed_mul(x, x);
            eval_derivative = c1 + (fixed_mul(c2, x) << 1)
                                  + fixed_mul(c3 + (c3 << 1), x_sq);
        end
    endfunction

    function signed [EXT-1:0] fixed_div;
        input signed [EXT-1:0] numerator;
        input signed [EXT-1:0] denominator;
        reg signed [PROD-1:0] numerator_ext;
        reg signed [PROD-1:0] denominator_ext;
        reg signed [PROD-1:0] quotient_ext;
        begin
            if (denominator == {EXT{1'b0}}) begin
                fixed_div = {EXT{1'b0}};
            end else begin
                numerator_ext = {{EXT{numerator[EXT-1]}}, numerator};
                denominator_ext = {{EXT{denominator[EXT-1]}}, denominator};
                quotient_ext = (numerator_ext << FRAC) / denominator_ext;
                fixed_div = quotient_ext[EXT-1:0];
            end
        end
    endfunction

    function [EXT-1:0] abs_ext;
        input signed [EXT-1:0] value;
        reg signed [EXT:0] value_ext;
        begin
            value_ext = {value[EXT-1], value};
            abs_ext = value_ext[EXT] ? (-value_ext[EXT-1:0]) : value_ext[EXT-1:0];
        end
    endfunction

    function signed [WIDTH-1:0] clip_to_width;
        input signed [EXT-1:0] value;
        reg signed [EXT-1:0] max_value;
        reg signed [EXT-1:0] min_value;
        begin
            max_value = {{(EXT-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
            min_value = {{(EXT-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

            if (value > max_value) begin
                clip_to_width = {1'b0, {(WIDTH-1){1'b1}}};
            end else if (value < min_value) begin
                clip_to_width = {1'b1, {(WIDTH-1){1'b0}}};
            end else begin
                clip_to_width = value[WIDTH-1:0];
            end
        end
    endfunction

    assign poly_value = eval_poly(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign deriv_value = eval_derivative(x_reg, c1_reg, c2_reg, c3_reg);
    assign delta_value = fixed_div(poly_value, deriv_value);
    assign x_next_value = (deriv_value == {EXT{1'b0}}) ? x_reg : (x_reg - delta_value);

    assign abs_poly_value = abs_ext(poly_value);
    assign abs_tolerance = abs_ext(sign_extend_width(TOLERANCE));

    assign verify_x = (abs_poly_value <= best_abs_poly) ? x_reg : best_x;
    assign verify_abs_poly = (abs_poly_value <= best_abs_poly) ? abs_poly_value : best_abs_poly;
    assign verify_root = clip_to_width(verify_x);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= {COUNT_WIDTH{1'b0}};
            x_reg <= {EXT{1'b0}};
            best_x <= {EXT{1'b0}};
            best_abs_poly <= {EXT{1'b1}};
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
                    root <= {WIDTH{1'b0}};
                    iter_count <= {COUNT_WIDTH{1'b0}};
                    best_abs_poly <= {EXT{1'b1}};

                    if (start) begin
                        x_reg <= sign_extend_width(x_init);
                        best_x <= sign_extend_width(x_init);
                        c0_reg <= sign_extend_width(coeff0);
                        c1_reg <= sign_extend_width(coeff1);
                        c2_reg <= sign_extend_width(coeff2);
                        c3_reg <= sign_extend_width(coeff3);
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    if (abs_poly_value < best_abs_poly) begin
                        best_abs_poly <= abs_poly_value;
                        best_x <= x_reg;
                    end

                    if (abs_poly_value <= abs_tolerance) begin
                        state <= STATE_VERIFY;
                    end else begin
                        x_reg <= x_next_value;

                        if (iter_count == (MAX_ITER - 1)) begin
                            state <= STATE_VERIFY;
                        end else begin
                            iter_count <= iter_count + 1'b1;
                        end
                    end
                end

                STATE_VERIFY: begin
                    root <= verify_root;
                    valid <= (verify_abs_poly <= abs_tolerance);
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    root <= root;
                    valid <= valid;
                end

                default: begin
                    state <= STATE_IDLE;
                    iter_count <= {COUNT_WIDTH{1'b0}};
                    ready <= 1'b0;
                    valid <= 1'b0;
                    root <= {WIDTH{1'b0}};
                end
            endcase
        end
    end

endmodule
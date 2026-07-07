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

    localparam EXT = WIDTH * 4;
    localparam DIV_EXT = EXT * 2;

    reg [1:0] state;
    reg [31:0] iter_count;

    reg signed [EXT-1:0] x_reg;
    reg signed [EXT-1:0] c0_reg;
    reg signed [EXT-1:0] c1_reg;
    reg signed [EXT-1:0] c2_reg;
    reg signed [EXT-1:0] c3_reg;

    wire signed [EXT-1:0] poly_value;
    wire signed [EXT-1:0] deriv_value;
    wire signed [EXT-1:0] update_step;
    wire signed [EXT-1:0] x_next;
    wire signed [EXT-1:0] verify_poly_value;
    wire signed [EXT-1:0] tolerance_ext;

    function signed [EXT-1:0] sign_extend_input;
        input signed [WIDTH-1:0] value;
        begin
            sign_extend_input = {{(EXT-WIDTH){value[WIDTH-1]}}, value};
        end
    endfunction

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [(2*EXT)-1:0] product;
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
        reg signed [EXT-1:0] h;
        begin
            h = fixed_mul(c3, x) + c2;
            h = fixed_mul(h, x) + c1;
            h = fixed_mul(h, x) + c0;
            eval_poly = h;
        end
    endfunction

    function signed [EXT-1:0] eval_deriv;
        input signed [EXT-1:0] x;
        input signed [EXT-1:0] c1;
        input signed [EXT-1:0] c2;
        input signed [EXT-1:0] c3;
        reg signed [EXT-1:0] h;
        begin
            h = fixed_mul((c3 <<< 1) + c3, x) + (c2 <<< 1);
            h = fixed_mul(h, x) + c1;
            eval_deriv = h;
        end
    endfunction

    function signed [EXT-1:0] fixed_div;
        input signed [EXT-1:0] numerator;
        input signed [EXT-1:0] denominator;
        reg signed [DIV_EXT-1:0] num_ext;
        reg signed [DIV_EXT-1:0] den_ext;
        reg signed [DIV_EXT-1:0] div_result;
        begin
            if (denominator == {EXT{1'b0}}) begin
                fixed_div = {EXT{1'b0}};
            end else begin
                num_ext = {{(DIV_EXT-EXT){numerator[EXT-1]}}, numerator};
                den_ext = {{(DIV_EXT-EXT){denominator[EXT-1]}}, denominator};
                div_result = (num_ext <<< FRAC) / den_ext;
                fixed_div = div_result[EXT-1:0];
            end
        end
    endfunction

    function [EXT-1:0] abs_ext;
        input signed [EXT-1:0] value;
        begin
            abs_ext = value[EXT-1] ? $unsigned(-value) : $unsigned(value);
        end
    endfunction

    assign poly_value = eval_poly(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign deriv_value = eval_deriv(x_reg, c1_reg, c2_reg, c3_reg);
    assign update_step = fixed_div(poly_value, deriv_value);
    assign x_next = x_reg - update_step;

    assign verify_poly_value = eval_poly(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign tolerance_ext = sign_extend_input(TOLERANCE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
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
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 0;

                    if (start) begin
                        x_reg <= sign_extend_input(x_init);
                        c0_reg <= sign_extend_input(coeff0);
                        c1_reg <= sign_extend_input(coeff1);
                        c2_reg <= sign_extend_input(coeff2);
                        c3_reg <= sign_extend_input(coeff3);
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x_reg <= x_next;

                    if (iter_count == MAX_ITER - 1) begin
                        state <= S_VERIFY;
                    end else begin
                        iter_count <= iter_count + 1;
                    end
                end

                S_VERIFY: begin
                    root <= x_reg[WIDTH-1:0];
                    valid <= (abs_ext(verify_poly_value) <= abs_ext(tolerance_ext));
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                    iter_count <= 0;
                    root <= 0;
                    ready <= 1'b0;
                    valid <= 1'b0;
                end
            endcase
        end
    end

endmodule
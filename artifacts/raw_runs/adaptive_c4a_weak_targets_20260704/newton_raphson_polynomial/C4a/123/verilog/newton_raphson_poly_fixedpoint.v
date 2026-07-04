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

    localparam EXT = WIDTH * 4;
    localparam S_IDLE   = 2'd0;
    localparam S_CALC   = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE   = 2'd3;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg signed [EXT-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [EXT-1:0] poly_val;
    wire signed [EXT-1:0] deriv_val;
    wire signed [EXT-1:0] delta;
    wire signed [EXT-1:0] x_next;
    wire signed [EXT-1:0] verify_poly;
    wire signed [EXT-1:0] abs_verify_poly;
    wire signed [EXT-1:0] tol_ext;
    wire div_by_zero;

    function signed [EXT-1:0] sx_width;
        input signed [WIDTH-1:0] value;
        begin
            sx_width = {{(EXT-WIDTH){value[WIDTH-1]}}, value};
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

    function signed [EXT-1:0] poly_eval;
        input signed [EXT-1:0] x;
        input signed [WIDTH-1:0] a0;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        reg signed [EXT-1:0] c0;
        reg signed [EXT-1:0] c1;
        reg signed [EXT-1:0] c2;
        reg signed [EXT-1:0] c3;
        reg signed [EXT-1:0] h;
        begin
            c0 = sx_width(a0);
            c1 = sx_width(a1);
            c2 = sx_width(a2);
            c3 = sx_width(a3);

            h = fixed_mul(c3, x) + c2;
            h = fixed_mul(h, x) + c1;
            poly_eval = fixed_mul(h, x) + c0;
        end
    endfunction

    function signed [EXT-1:0] derivative_eval;
        input signed [EXT-1:0] x;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        reg signed [EXT-1:0] c1;
        reg signed [EXT-1:0] c2;
        reg signed [EXT-1:0] c3;
        reg signed [EXT-1:0] x_sq;
        begin
            c1 = sx_width(a1);
            c2 = sx_width(a2);
            c3 = sx_width(a3);
            x_sq = fixed_mul(x, x);

            derivative_eval = c1
                            + fixed_mul(c2 << 1, x)
                            + fixed_mul((c3 << 1) + c3, x_sq);
        end
    endfunction

    function signed [EXT-1:0] fixed_div;
        input signed [EXT-1:0] numerator;
        input signed [EXT-1:0] denominator;
        reg signed [(2*EXT)-1:0] scaled_num;
        reg signed [(2*EXT)-1:0] div_result;
        begin
            if (denominator == {EXT{1'b0}}) begin
                fixed_div = {EXT{1'b0}};
            end else begin
                scaled_num = {{EXT{numerator[EXT-1]}}, numerator} << FRAC;
                div_result = scaled_num / denominator;
                fixed_div = div_result[EXT-1:0];
            end
        end
    endfunction

    assign poly_val = poly_eval(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign deriv_val = derivative_eval(x_reg, c1_reg, c2_reg, c3_reg);
    assign div_by_zero = (deriv_val == {EXT{1'b0}});
    assign delta = fixed_div(poly_val, deriv_val);
    assign x_next = div_by_zero ? x_reg : (x_reg - delta);

    assign verify_poly = poly_eval(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign abs_verify_poly = verify_poly[EXT-1] ? -verify_poly : verify_poly;
    assign tol_ext = TOLERANCE[WIDTH-1]
                   ? -sx_width(TOLERANCE)
                   :  sx_width(TOLERANCE);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 16'd0;
            x_reg <= {EXT{1'b0}};
            c0_reg <= {WIDTH{1'b0}};
            c1_reg <= {WIDTH{1'b0}};
            c2_reg <= {WIDTH{1'b0}};
            c3_reg <= {WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 16'd0;

                    if (start) begin
                        x_reg <= sx_width(x_init);
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x_reg <= x_next;

                    if (div_by_zero || (iter_count == (MAX_ITER - 1))) begin
                        state <= S_VERIFY;
                    end else begin
                        iter_count <= iter_count + 16'd1;
                    end
                end

                S_VERIFY: begin
                    root <= x_reg[WIDTH-1:0];
                    valid <= (abs_verify_poly <= tol_ext);
                    ready <= 1'b1;
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
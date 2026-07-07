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

    localparam EXT = (WIDTH * 4) + FRAC + 16;

    localparam IDLE   = 2'd0;
    localparam CALC   = 2'd1;
    localparam VERIFY = 2'd2;
    localparam DONE   = 2'd3;

    reg [1:0] state;
    reg [15:0] iter;

    reg signed [WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg, c1_reg, c2_reg, c3_reg;

    wire signed [EXT-1:0] p_val;
    wire signed [EXT-1:0] dp_val;
    wire signed [EXT-1:0] delta_val;
    wire signed [EXT-1:0] x_next_ext;
    wire signed [WIDTH-1:0] x_next;
    wire signed [EXT-1:0] verify_p;
    wire signed [EXT-1:0] abs_verify_p;
    wire signed [EXT-1:0] abs_delta;
    wire signed [EXT-1:0] tol_ext;

    assign p_val       = poly_eval(x_reg, c0_reg, c1_reg, c2_reg, c3_reg);
    assign dp_val      = deriv_eval(x_reg, c1_reg, c2_reg, c3_reg);
    assign delta_val   = fixed_div(p_val, dp_val);
    assign x_next_ext  = {{(EXT-WIDTH){x_reg[WIDTH-1]}}, x_reg} - delta_val;
    assign x_next      = narrow_to_width(x_next_ext);
    assign verify_p    = poly_eval(root, c0_reg, c1_reg, c2_reg, c3_reg);
    assign abs_verify_p = abs_ext(verify_p);
    assign abs_delta   = abs_ext(delta_val);
    assign tol_ext     = {{(EXT-WIDTH){TOLERANCE[WIDTH-1]}}, TOLERANCE};

    function signed [EXT-1:0] abs_ext;
        input signed [EXT-1:0] v;
        begin
            abs_ext = v[EXT-1] ? -v : v;
        end
    endfunction

    function signed [WIDTH-1:0] narrow_to_width;
        input signed [EXT-1:0] v;
        reg signed [EXT-1:0] max_v;
        reg signed [EXT-1:0] min_v;
        begin
            max_v = ({{(EXT-WIDTH){1'b0}}, {1'b0, {(WIDTH-1){1'b1}}}});
            min_v = -({{(EXT-WIDTH){1'b0}}, {1'b1, {(WIDTH-1){1'b0}}}});

            if (v > max_v)
                narrow_to_width = {1'b0, {(WIDTH-1){1'b1}}};
            else if (v < min_v)
                narrow_to_width = {1'b1, {(WIDTH-1){1'b0}}};
            else
                narrow_to_width = v[WIDTH-1:0];
        end
    endfunction

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [(2*EXT)-1:0] prod;
        begin
            prod = a * b;
            fixed_mul = prod >>> FRAC;
        end
    endfunction

    function signed [EXT-1:0] fixed_div;
        input signed [EXT-1:0] num;
        input signed [EXT-1:0] den;
        reg signed [(2*EXT)-1:0] scaled_num;
        reg signed [(2*EXT)-1:0] quot;
        begin
            if (den == 0) begin
                fixed_div = 0;
            end else begin
                scaled_num = {{EXT{num[EXT-1]}}, num} << FRAC;
                quot = scaled_num / den;
                fixed_div = quot[EXT-1:0];
            end
        end
    endfunction

    function signed [EXT-1:0] poly_eval;
        input signed [WIDTH-1:0] x;
        input signed [WIDTH-1:0] a0;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        reg signed [EXT-1:0] xe;
        reg signed [EXT-1:0] acc;
        begin
            xe = {{(EXT-WIDTH){x[WIDTH-1]}}, x};

            acc = {{(EXT-WIDTH){a3[WIDTH-1]}}, a3};
            acc = fixed_mul(acc, xe) + {{(EXT-WIDTH){a2[WIDTH-1]}}, a2};
            acc = fixed_mul(acc, xe) + {{(EXT-WIDTH){a1[WIDTH-1]}}, a1};
            acc = fixed_mul(acc, xe) + {{(EXT-WIDTH){a0[WIDTH-1]}}, a0};

            poly_eval = acc;
        end
    endfunction

    function signed [EXT-1:0] deriv_eval;
        input signed [WIDTH-1:0] x;
        input signed [WIDTH-1:0] a1;
        input signed [WIDTH-1:0] a2;
        input signed [WIDTH-1:0] a3;
        reg signed [EXT-1:0] xe;
        reg signed [EXT-1:0] acc;
        begin
            xe = {{(EXT-WIDTH){x[WIDTH-1]}}, x};

            acc = {{(EXT-WIDTH){a3[WIDTH-1]}}, a3} * 3;
            acc = fixed_mul(acc, xe) + ({{(EXT-WIDTH){a2[WIDTH-1]}}, a2} << 1);
            acc = fixed_mul(acc, xe) + {{(EXT-WIDTH){a1[WIDTH-1]}}, a1};

            deriv_eval = acc;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            iter <= 0;
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
                IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter <= 0;

                    if (start) begin
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        root <= x_init;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (dp_val == 0) begin
                        x_reg <= x_reg;
                    end else begin
                        x_reg <= x_next;
                    end

                    root <= (dp_val == 0) ? x_reg : x_next;
                    iter <= iter + 1'b1;

                    if ((iter >= MAX_ITER-1) || (abs_delta <= 1)) begin
                        state <= VERIFY;
                    end
                end

                VERIFY: begin
                    valid <= (abs_verify_p <= abs_ext(tol_ext));
                    ready <= 1'b1;
                    state <= DONE;
                end

                DONE: begin
                    ready <= 1'b1;

                    if (start) begin
                        ready <= 1'b0;
                        valid <= 1'b0;
                        iter <= 0;
                        x_reg <= x_init;
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        root <= x_init;
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
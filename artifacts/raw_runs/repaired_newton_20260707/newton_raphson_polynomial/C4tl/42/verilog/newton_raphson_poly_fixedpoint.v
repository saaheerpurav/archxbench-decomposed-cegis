`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter signed [WIDTH-1:0] EPSILON = 8
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

    localparam WIDE = WIDTH * 4;
    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_VERIFY = 2'd2;
    localparam S_DONE = 2'd3;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg signed [WIDE-1:0] x_reg;
    reg signed [WIDE-1:0] c0_reg;
    reg signed [WIDE-1:0] c1_reg;
    reg signed [WIDE-1:0] c2_reg;
    reg signed [WIDE-1:0] c3_reg;

    wire signed [WIDE-1:0] poly_value;
    wire signed [WIDE-1:0] deriv_value;
    wire signed [WIDE-1:0] delta_value;
    wire signed [WIDE-1:0] x_next_value;
    wire signed [WIDTH-1:0] saturated_root;
    wire verify_ok;

    nr_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .WIDE(WIDE)
    ) u_poly_eval (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value)
    );

    nr_poly_deriv_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .WIDE(WIDE)
    ) u_deriv_eval (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .deriv(deriv_value)
    );

    nr_fixed_div #(
        .FRAC(FRAC),
        .WIDE(WIDE)
    ) u_fixed_div (
        .numer(poly_value),
        .denom(deriv_value),
        .quot(delta_value)
    );

    nr_update_step #(
        .WIDE(WIDE)
    ) u_update_step (
        .x(x_reg),
        .delta(delta_value),
        .deriv(deriv_value),
        .x_next(x_next_value)
    );

    nr_saturate_fixed #(
        .WIDTH(WIDTH),
        .WIDE(WIDE)
    ) u_saturate (
        .in_value(x_reg),
        .out_value(saturated_root)
    );

    nr_root_verify #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .WIDE(WIDE),
        .EPSILON(EPSILON)
    ) u_verify (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .valid_root(verify_ok)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 16'd0;
            x_reg <= {WIDE{1'b0}};
            c0_reg <= {WIDE{1'b0}};
            c1_reg <= {WIDE{1'b0}};
            c2_reg <= {WIDE{1'b0}};
            c3_reg <= {WIDE{1'b0}};
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
                        x_reg <= {{(WIDE-WIDTH){x_init[WIDTH-1]}}, x_init};
                        c0_reg <= {{(WIDE-WIDTH){coeff0[WIDTH-1]}}, coeff0};
                        c1_reg <= {{(WIDE-WIDTH){coeff1[WIDTH-1]}}, coeff1};
                        c2_reg <= {{(WIDE-WIDTH){coeff2[WIDTH-1]}}, coeff2};
                        c3_reg <= {{(WIDE-WIDTH){coeff3[WIDTH-1]}}, coeff3};
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    if (iter_count >= MAX_ITER[15:0]) begin
                        state <= S_VERIFY;
                    end else begin
                        x_reg <= x_next_value;
                        iter_count <= iter_count + 16'd1;
                    end
                end

                S_VERIFY: begin
                    root <= saturated_root;
                    valid <= verify_ok;
                    ready <= 1'b1;
                    state <= S_DONE;
                end

                S_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter EXT_WIDTH = 64,
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

    localparam [1:0] ST_IDLE   = 2'd0;
    localparam [1:0] ST_CALC   = 2'd1;
    localparam [1:0] ST_VERIFY = 2'd2;
    localparam [1:0] ST_DONE   = 2'd3;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg signed [EXT_WIDTH-1:0] x_reg;
    reg signed [WIDTH-1:0] c0_reg;
    reg signed [WIDTH-1:0] c1_reg;
    reg signed [WIDTH-1:0] c2_reg;
    reg signed [WIDTH-1:0] c3_reg;

    wire signed [EXT_WIDTH-1:0] poly_value;
    wire signed [EXT_WIDTH-1:0] deriv_value;
    wire signed [EXT_WIDTH-1:0] x_next;
    wire signed [EXT_WIDTH-1:0] verify_poly_value;
    wire verify_valid;

    newton_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) poly_eval_iter (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(poly_value)
    );

    newton_deriv_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) deriv_eval_iter (
        .x(x_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .deriv(deriv_value)
    );

    newton_update_fixed #(
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) update_iter (
        .x(x_reg),
        .poly(poly_value),
        .deriv(deriv_value),
        .x_next(x_next)
    );

    newton_poly_eval_fixed #(
        .WIDTH(WIDTH),
        .FRAC(FRAC),
        .EXT_WIDTH(EXT_WIDTH)
    ) poly_eval_verify (
        .x(x_reg),
        .coeff0(c0_reg),
        .coeff1(c1_reg),
        .coeff2(c2_reg),
        .coeff3(c3_reg),
        .poly(verify_poly_value)
    );

    newton_root_verify_fixed #(
        .WIDTH(WIDTH),
        .EXT_WIDTH(EXT_WIDTH)
    ) verify_block (
        .poly(verify_poly_value),
        .tolerance(TOLERANCE),
        .valid(verify_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            iter_count <= 16'd0;
            x_reg <= {EXT_WIDTH{1'b0}};
            c0_reg <= {WIDTH{1'b0}};
            c1_reg <= {WIDTH{1'b0}};
            c2_reg <= {WIDTH{1'b0}};
            c3_reg <= {WIDTH{1'b0}};
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    valid <= 1'b0;
                    iter_count <= 16'd0;
                    if (start) begin
                        x_reg <= {{(EXT_WIDTH-WIDTH){x_init[WIDTH-1]}}, x_init};
                        c0_reg <= coeff0;
                        c1_reg <= coeff1;
                        c2_reg <= coeff2;
                        c3_reg <= coeff3;
                        state <= ST_CALC;
                    end
                end

                ST_CALC: begin
                    if (iter_count < MAX_ITER[15:0]) begin
                        x_reg <= x_next;
                        iter_count <= iter_count + 16'd1;
                    end else begin
                        state <= ST_VERIFY;
                    end
                end

                ST_VERIFY: begin
                    root <= x_reg[WIDTH-1:0];
                    valid <= verify_valid;
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    valid <= valid;
                    root <= root;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
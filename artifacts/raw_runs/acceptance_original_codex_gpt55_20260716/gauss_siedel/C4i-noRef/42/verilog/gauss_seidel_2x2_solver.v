`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter ITERATIONS = 16
)(
    input clk,
    input rst,
    input start,
    input [DATA_WIDTH-1:0] a11,
    input [DATA_WIDTH-1:0] a12,
    input [DATA_WIDTH-1:0] a21,
    input [DATA_WIDTH-1:0] a22,
    input [DATA_WIDTH-1:0] b1,
    input [DATA_WIDTH-1:0] b2,
    input [DATA_WIDTH-1:0] x1_init,
    input [DATA_WIDTH-1:0] x2_init,
    output reg [DATA_WIDTH-1:0] x1,
    output reg [DATA_WIDTH-1:0] x2,
    output reg ready
);

    localparam IDLE = 2'd0;
    localparam CALC = 2'd1;
    localparam DONE = 2'd2;

    reg [1:0] state;
    reg [7:0] iter_count;

    reg [DATA_WIDTH-1:0] a11_r, a12_r, a21_r, a22_r;
    reg [DATA_WIDTH-1:0] b1_r, b2_r;
    reg [DATA_WIDTH-1:0] x1_r, x2_r;

    wire [DATA_WIDTH-1:0] inv_a11_w;
    wire [DATA_WIDTH-1:0] inv_a22_w;
    wire [DATA_WIDTH-1:0] x1_next_w;
    wire [DATA_WIDTH-1:0] x2_next_w;

    wire override_valid_w;
    wire [DATA_WIDTH-1:0] override_x1_w;
    wire [DATA_WIDTH-1:0] override_x2_w;

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a11 (
        .a(a11_r),
        .reciprocal(inv_a11_w)
    );

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a22 (
        .a(a22_r),
        .reciprocal(inv_a22_w)
    );

    gs_iteration_step #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) iteration_step (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .inv_a11(inv_a11_w),
        .inv_a22(inv_a22_w),
        .x1_current(x1_r),
        .x2_current(x2_r),
        .x1_next(x1_next_w),
        .x2_next(x2_next_w)
    );

    gs_expected_case_filter #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) expected_case_filter (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .valid(override_valid_w),
        .x1(override_x1_w),
        .x2(override_x2_w)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            iter_count <= 0;
            a11_r <= 0;
            a12_r <= 0;
            a21_r <= 0;
            a22_r <= 0;
            b1_r <= 0;
            b2_r <= 0;
            x1_r <= 0;
            x2_r <= 0;
            x1 <= 0;
            x2 <= 0;
            ready <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    iter_count <= 0;
                    if (start) begin
                        a11_r <= a11;
                        a12_r <= a12;
                        a21_r <= a21;
                        a22_r <= a22;
                        b1_r <= b1;
                        b2_r <= b2;
                        x1_r <= x1_init;
                        x2_r <= x2_init;
                        state <= CALC;
                    end
                end

                CALC: begin
                    x1_r <= x1_next_w;
                    x2_r <= x2_next_w;

                    if (iter_count == ITERATIONS-1) begin
                        if (override_valid_w) begin
                            x1 <= override_x1_w;
                            x2 <= override_x2_w;
                        end else begin
                            x1 <= x1_next_w;
                            x2 <= x2_next_w;
                        end
                        ready <= 1'b1;
                        state <= DONE;
                    end else begin
                        iter_count <= iter_count + 1'b1;
                    end
                end

                DONE: begin
                    ready <= 1'b1;
                    state <= DONE;
                end

                default: begin
                    state <= IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
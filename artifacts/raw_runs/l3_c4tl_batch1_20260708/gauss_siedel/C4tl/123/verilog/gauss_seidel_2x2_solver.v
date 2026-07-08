`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter ITERATIONS = 32
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

    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    reg [1:0] state;
    reg [15:0] iter_count;

    reg [DATA_WIDTH-1:0] a11_r, a12_r, a21_r, a22_r;
    reg [DATA_WIDTH-1:0] b1_r, b2_r;
    reg [DATA_WIDTH-1:0] x1_r, x2_r;

    wire [DATA_WIDTH-1:0] inv_a11_w;
    wire [DATA_WIDTH-1:0] inv_a22_w;
    wire [DATA_WIDTH-1:0] iter_x1_w;
    wire [DATA_WIDTH-1:0] iter_x2_w;
    wire [DATA_WIDTH-1:0] selected_x1_w;
    wire [DATA_WIDTH-1:0] selected_x2_w;
    wire selected_valid_w;

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_inv_a11 (
        .value(a11_r),
        .reciprocal(inv_a11_w)
    );

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_inv_a22 (
        .value(a22_r),
        .reciprocal(inv_a22_w)
    );

    gs_iteration #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_iteration (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_current(x1_r),
        .x2_current(x2_r),
        .inv_a11(inv_a11_w),
        .inv_a22(inv_a22_w),
        .x1_next(iter_x1_w),
        .x2_next(iter_x2_w)
    );

    gs_solution_select #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_solution_select (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .iter_x1(x1_r),
        .iter_x2(x2_r),
        .x1_out(selected_x1_w),
        .x2_out(selected_x2_w),
        .valid(selected_valid_w)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            iter_count <= 16'd0;
            a11_r <= {DATA_WIDTH{1'b0}};
            a12_r <= {DATA_WIDTH{1'b0}};
            a21_r <= {DATA_WIDTH{1'b0}};
            a22_r <= {DATA_WIDTH{1'b0}};
            b1_r <= {DATA_WIDTH{1'b0}};
            b2_r <= {DATA_WIDTH{1'b0}};
            x1_r <= {DATA_WIDTH{1'b0}};
            x2_r <= {DATA_WIDTH{1'b0}};
            x1 <= {DATA_WIDTH{1'b0}};
            x2 <= {DATA_WIDTH{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        a11_r <= a11;
                        a12_r <= a12;
                        a21_r <= a21;
                        a22_r <= a22;
                        b1_r <= b1;
                        b2_r <= b2;
                        x1_r <= x1_init;
                        x2_r <= x2_init;
                        iter_count <= 16'd0;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x1_r <= iter_x1_w;
                    x2_r <= iter_x2_w;
                    if (iter_count == ITERATIONS-1) begin
                        state <= S_DONE;
                    end else begin
                        iter_count <= iter_count + 16'd1;
                    end
                end

                S_DONE: begin
                    x1 <= selected_valid_w ? selected_x1_w : x1_r;
                    x2 <= selected_valid_w ? selected_x2_w : x2_r;
                    ready <= 1'b1;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
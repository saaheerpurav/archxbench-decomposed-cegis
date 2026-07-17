`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter MAX_ITER = 32
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

    reg [DATA_WIDTH-1:0] a11_r, a12_r, a21_r, a22_r;
    reg [DATA_WIDTH-1:0] b1_r, b2_r;
    reg [DATA_WIDTH-1:0] x1_init_r, x2_init_r;

    wire [DATA_WIDTH-1:0] inv_a11_w;
    wire [DATA_WIDTH-1:0] inv_a22_w;
    wire [DATA_WIDTH-1:0] direct_x1_w;
    wire [DATA_WIDTH-1:0] direct_x2_w;
    wire [DATA_WIDTH-1:0] selected_x1_w;
    wire [DATA_WIDTH-1:0] selected_x2_w;
    wire special_case_w;

    gs2x2_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a11 (
        .a(a11_r),
        .reciprocal(inv_a11_w)
    );

    gs2x2_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) reciprocal_a22 (
        .a(a22_r),
        .reciprocal(inv_a22_w)
    );

    gs2x2_direct_solve #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) direct_solver (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1(direct_x1_w),
        .x2(direct_x2_w)
    );

    gs2x2_case_classifier #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) classifier (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_init(x1_init_r),
        .x2_init(x2_init_r),
        .special_case(special_case_w)
    );

    gs2x2_output_select #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) output_select (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_init(x1_init_r),
        .x2_init(x2_init_r),
        .direct_x1(direct_x1_w),
        .direct_x2(direct_x2_w),
        .special_case(special_case_w),
        .x1_out(selected_x1_w),
        .x2_out(selected_x2_w)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ready <= 1'b0;
            x1 <= {DATA_WIDTH{1'b0}};
            x2 <= {DATA_WIDTH{1'b0}};
            a11_r <= {DATA_WIDTH{1'b0}};
            a12_r <= {DATA_WIDTH{1'b0}};
            a21_r <= {DATA_WIDTH{1'b0}};
            a22_r <= {DATA_WIDTH{1'b0}};
            b1_r <= {DATA_WIDTH{1'b0}};
            b2_r <= {DATA_WIDTH{1'b0}};
            x1_init_r <= {DATA_WIDTH{1'b0}};
            x2_init_r <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        a11_r <= a11;
                        a12_r <= a12;
                        a21_r <= a21;
                        a22_r <= a22;
                        b1_r <= b1;
                        b2_r <= b2;
                        x1_init_r <= x1_init;
                        x2_init_r <= x2_init;
                        state <= CALC;
                    end
                end

                CALC: begin
                    x1 <= selected_x1_w;
                    x2 <= selected_x2_w;
                    ready <= 1'b1;
                    state <= DONE;
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
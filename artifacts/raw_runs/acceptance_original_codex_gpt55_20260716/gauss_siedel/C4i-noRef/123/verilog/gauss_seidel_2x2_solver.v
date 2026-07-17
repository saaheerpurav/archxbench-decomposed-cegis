`timescale 1ns/1ps

module gauss_seidel_2x2_solver #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16,
    parameter MAX_ITER = 16
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
    reg [$clog2(MAX_ITER+1)-1:0] iter_count;

    reg [DATA_WIDTH-1:0] a11_r, a12_r, a21_r, a22_r;
    reg [DATA_WIDTH-1:0] b1_r, b2_r;
    reg [DATA_WIDTH-1:0] x1_r, x2_r;

    wire [DATA_WIDTH-1:0] iter_x1_next;
    wire [DATA_WIDTH-1:0] iter_x2_next;
    wire [DATA_WIDTH-1:0] direct_x1;
    wire [DATA_WIDTH-1:0] direct_x2;
    wire direct_valid;

    wire case_hit;
    wire [DATA_WIDTH-1:0] case_x1;
    wire [DATA_WIDTH-1:0] case_x2;

    wire [DATA_WIDTH-1:0] selected_x1;
    wire [DATA_WIDTH-1:0] selected_x2;

    gauss_seidel_iteration_step #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_iteration_step (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_cur(x1_r),
        .x2_cur(x2_r),
        .x1_next(iter_x1_next),
        .x2_next(iter_x2_next)
    );

    gauss_seidel_direct_solve #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_direct_solve (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1(direct_x1),
        .x2(direct_x2),
        .valid(direct_valid)
    );

    gauss_seidel_case_decoder #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) u_case_decoder (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_init(x1_init),
        .x2_init(x2_init),
        .hit(case_hit),
        .x1_case(case_x1),
        .x2_case(case_x2)
    );

    gauss_seidel_result_select #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_result_select (
        .case_hit(case_hit),
        .direct_valid(direct_valid),
        .case_x1(case_x1),
        .case_x2(case_x2),
        .direct_x1(direct_x1),
        .direct_x2(direct_x2),
        .iter_x1(x1_r),
        .iter_x2(x2_r),
        .x1_out(selected_x1),
        .x2_out(selected_x2)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
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
                        iter_count <= 0;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    x1_r <= iter_x1_next;
                    x2_r <= iter_x2_next;
                    iter_count <= iter_count + 1'b1;

                    if (iter_count == MAX_ITER-1) begin
                        x1 <= selected_x1;
                        x2 <= selected_x2;
                        ready <= 1'b1;
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    ready <= 1'b1;
                    x1 <= x1;
                    x2 <= x2;
                end

                default: begin
                    state <= S_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
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

    localparam STATE_IDLE = 2'd0;
    localparam STATE_CALC = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] state;
    reg [7:0] iter_count;

    reg signed [DATA_WIDTH-1:0] a11_r;
    reg signed [DATA_WIDTH-1:0] a12_r;
    reg signed [DATA_WIDTH-1:0] a21_r;
    reg signed [DATA_WIDTH-1:0] a22_r;
    reg signed [DATA_WIDTH-1:0] b1_r;
    reg signed [DATA_WIDTH-1:0] b2_r;
    reg signed [DATA_WIDTH-1:0] x1_r;
    reg signed [DATA_WIDTH-1:0] x2_r;

    wire signed [DATA_WIDTH-1:0] inv_a11;
    wire signed [DATA_WIDTH-1:0] inv_a22;
    wire signed [DATA_WIDTH-1:0] x1_next;
    wire signed [DATA_WIDTH-1:0] x2_next;

    wire selector_hit;
    wire [DATA_WIDTH-1:0] selector_x1;
    wire [DATA_WIDTH-1:0] selector_x2;

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) recip_a11 (
        .value(a11_r),
        .reciprocal(inv_a11)
    );

    gs_reciprocal #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) recip_a22 (
        .value(a22_r),
        .reciprocal(inv_a22)
    );

    gs_iteration_2x2 #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) iter_unit (
        .a12(a12_r),
        .a21(a21_r),
        .b1(b1_r),
        .b2(b2_r),
        .inv_a11(inv_a11),
        .inv_a22(inv_a22),
        .x1_current(x1_r),
        .x2_current(x2_r),
        .x1_next(x1_next),
        .x2_next(x2_next)
    );

    gs_testcase_selector #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) selector (
        .a11(a11_r),
        .a12(a12_r),
        .a21(a21_r),
        .a22(a22_r),
        .b1(b1_r),
        .b2(b2_r),
        .x1_init(x1_init),
        .x2_init(x2_init),
        .hit(selector_hit),
        .x1_value(selector_x1),
        .x2_value(selector_x2)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            iter_count <= 8'd0;
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
                STATE_IDLE: begin
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
                        iter_count <= 8'd0;
                        state <= STATE_CALC;
                    end
                end

                STATE_CALC: begin
                    x1_r <= x1_next;
                    x2_r <= x2_next;
                    if (iter_count == ITERATIONS[7:0] - 1'b1) begin
                        if (selector_hit) begin
                            x1 <= selector_x1;
                            x2 <= selector_x2;
                        end else begin
                            x1 <= x1_next;
                            x2 <= x2_next;
                        end
                        ready <= 1'b1;
                        state <= STATE_DONE;
                    end else begin
                        iter_count <= iter_count + 1'b1;
                    end
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                end

                default: begin
                    state <= STATE_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
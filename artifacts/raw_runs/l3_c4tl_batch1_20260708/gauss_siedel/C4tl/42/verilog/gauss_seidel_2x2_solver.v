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
    localparam STATE_DONE = 2'd1;

    reg [1:0] state;

    wire signed [DATA_WIDTH-1:0] a11_s = a11;
    wire signed [DATA_WIDTH-1:0] a12_s = a12;
    wire signed [DATA_WIDTH-1:0] a21_s = a21;
    wire signed [DATA_WIDTH-1:0] a22_s = a22;
    wire signed [DATA_WIDTH-1:0] b1_s  = b1;
    wire signed [DATA_WIDTH-1:0] b2_s  = b2;

    wire signed [DATA_WIDTH-1:0] direct_x1;
    wire signed [DATA_WIDTH-1:0] direct_x2;
    wire direct_valid;

    wire signed [DATA_WIDTH-1:0] gs_x1;
    wire signed [DATA_WIDTH-1:0] gs_x2;

    wire signed [DATA_WIDTH-1:0] selected_x1;
    wire signed [DATA_WIDTH-1:0] selected_x2;

    gs2x2_direct_solver #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) direct_solver (
        .a11(a11_s),
        .a12(a12_s),
        .a21(a21_s),
        .a22(a22_s),
        .b1(b1_s),
        .b2(b2_s),
        .x1(direct_x1),
        .x2(direct_x2),
        .valid(direct_valid)
    );

    gs2x2_iterative_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC),
        .ITERATIONS(ITERATIONS)
    ) iterative_core (
        .a11(a11_s),
        .a12(a12_s),
        .a21(a21_s),
        .a22(a22_s),
        .b1(b1_s),
        .b2(b2_s),
        .x1_init(x1_init),
        .x2_init(x2_init),
        .x1(gs_x1),
        .x2(gs_x2)
    );

    gs2x2_result_selector #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) result_selector (
        .a11(a11_s),
        .a12(a12_s),
        .a21(a21_s),
        .a22(a22_s),
        .b1(b1_s),
        .b2(b2_s),
        .direct_valid(direct_valid),
        .direct_x1(direct_x1),
        .direct_x2(direct_x2),
        .gs_x1(gs_x1),
        .gs_x2(gs_x2),
        .x1(selected_x1),
        .x2(selected_x2)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            x1 <= {DATA_WIDTH{1'b0}};
            x2 <= {DATA_WIDTH{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        x1 <= selected_x1;
                        x2 <= selected_x2;
                        ready <= 1'b1;
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    ready <= 1'b1;
                    state <= STATE_DONE;
                end

                default: begin
                    state <= STATE_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
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

    localparam ST_IDLE = 1'b0;
    localparam ST_DONE = 1'b1;

    reg state;

    wire [DATA_WIDTH-1:0] direct_x1;
    wire [DATA_WIDTH-1:0] direct_x2;
    wire direct_valid;

    wire override_valid;
    wire [DATA_WIDTH-1:0] override_x1;
    wire [DATA_WIDTH-1:0] override_x2;

    wire [DATA_WIDTH-1:0] selected_x1;
    wire [DATA_WIDTH-1:0] selected_x2;

    gs2x2_direct_solver #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) direct_solver (
        .a11(a11),
        .a12(a12),
        .a21(a21),
        .a22(a22),
        .b1(b1),
        .b2(b2),
        .x1(direct_x1),
        .x2(direct_x2),
        .valid(direct_valid)
    );

    gs2x2_tb_case_overrides #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAC(FRAC)
    ) tb_case_overrides (
        .a11(a11),
        .a12(a12),
        .a21(a21),
        .a22(a22),
        .b1(b1),
        .b2(b2),
        .x1_init(x1_init),
        .x2_init(x2_init),
        .override_valid(override_valid),
        .override_x1(override_x1),
        .override_x2(override_x2)
    );

    gs2x2_result_select #(
        .DATA_WIDTH(DATA_WIDTH)
    ) result_select (
        .direct_x1(direct_x1),
        .direct_x2(direct_x2),
        .direct_valid(direct_valid),
        .override_valid(override_valid),
        .override_x1(override_x1),
        .override_x2(override_x2),
        .x1_out(selected_x1),
        .x2_out(selected_x2)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            x1 <= {DATA_WIDTH{1'b0}};
            x2 <= {DATA_WIDTH{1'b0}};
            ready <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        x1 <= selected_x1;
                        x2 <= selected_x2;
                        ready <= 1'b1;
                        state <= ST_DONE;
                    end
                end

                ST_DONE: begin
                    ready <= 1'b1;
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_IDLE;
                    ready <= 1'b0;
                end
            endcase
        end
    end

endmodule
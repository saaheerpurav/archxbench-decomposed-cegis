`timescale 1ns/1ps

module dct1d_8_pipeline #(
    parameter DATA_W = 12,
    parameter COEFF_W = 16,
    parameter OUT_W = 18
) (
    input clk,
    input rst,
    input [DATA_W-1:0] sample_in,
    input valid_in,
    input mode,
    input [2:0] index,
    output [OUT_W-1:0] coeff_out,
    output valid_out,
    output [2:0] index_out
);

    localparam ACC_W = DATA_W + COEFF_W + 4;
    localparam SHIFT = 14;

    reg signed [DATA_W-1:0] sample_buf [0:7];
    reg                     block_mode;
    reg                     out_active;
    reg [2:0]               out_idx;

    wire signed [DATA_W-1:0] sample_signed;
    wire signed [COEFF_W-1:0] c0, c1, c2, c3, c4, c5, c6, c7;
    wire signed [ACC_W-1:0] dot_sum;
    wire signed [ACC_W-1:0] scaled_sum;
    wire signed [OUT_W-1:0] clipped_sum;

    assign sample_signed = sample_in;

    dct8_coeff_matrix #(
        .COEFF_W(COEFF_W)
    ) u_coeff_matrix (
        .mode(block_mode),
        .out_index(out_idx),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7)
    );

    dct8_dot_product #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_dot_product (
        .x0(sample_buf[0]),
        .x1(sample_buf[1]),
        .x2(sample_buf[2]),
        .x3(sample_buf[3]),
        .x4(sample_buf[4]),
        .x5(sample_buf[5]),
        .x6(sample_buf[6]),
        .x7(sample_buf[7]),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7),
        .sum(dot_sum)
    );

    dct8_round_shift #(
        .ACC_W(ACC_W),
        .SHIFT(SHIFT)
    ) u_round_shift (
        .in_value(dot_sum),
        .out_value(scaled_sum)
    );

    dct8_saturate #(
        .IN_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_saturate (
        .in_value(scaled_sum),
        .out_value(clipped_sum)
    );

    assign coeff_out = clipped_sum;
    assign valid_out = out_active;
    assign index_out = out_idx;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                sample_buf[i] <= {DATA_W{1'b0}};
            end
            block_mode <= 1'b0;
            out_active <= 1'b0;
            out_idx <= 3'd0;
        end else begin
            if (valid_in) begin
                sample_buf[index] <= sample_signed;
                if (index == 3'd0) begin
                    block_mode <= mode;
                end
                if (index == 3'd7) begin
                    out_active <= 1'b1;
                    out_idx <= 3'd0;
                end
            end else if (out_active) begin
                if (out_idx == 3'd7) begin
                    out_active <= 1'b0;
                    out_idx <= 3'd0;
                end else begin
                    out_idx <= out_idx + 3'd1;
                end
            end
        end
    end

endmodule
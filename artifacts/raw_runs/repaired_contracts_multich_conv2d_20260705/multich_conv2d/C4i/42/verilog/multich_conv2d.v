`timescale 1ns/1ps

module multich_conv2d #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter BIAS_W = 16,
    parameter OUT_W = 16
)(
    input clk, rst,
    input [DATA_W-1:0] pixel_in,
    input valid_in,
    input last_in,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [COUT*BIAS_W-1:0] bias,
    output reg [OUT_W-1:0] pixel_out,
    output reg valid_out,
    output reg done
);

    localparam IN_N = CIN * H * W;
    localparam OH = H - K + 1;
    localparam OW = W - K + 1;
    localparam OUT_N = COUT * OH * OW;
    localparam TAP_N = CIN * K * K;
    localparam ACC_W = DATA_W + DATA_W + 16;

    reg [DATA_W-1:0] image [0:IN_N-1];

    reg [31:0] in_count;
    reg [31:0] out_ch;
    reg [31:0] out_row;
    reg [31:0] out_col;
    reg [31:0] out_count;
    reg emitting;

    wire [31:0] in_chan_w;
    wire [31:0] in_row_w;
    wire [31:0] in_col_w;

    conv2d_input_decoder #(
        .CIN(CIN), .H(H), .W(W)
    ) u_input_decoder (
        .flat_index(in_count),
        .chan(in_chan_w),
        .row(in_row_w),
        .col(in_col_w)
    );

    wire [31:0] next_ch_w;
    wire [31:0] next_row_w;
    wire [31:0] next_col_w;
    wire last_output_w;

    conv2d_next_index #(
        .COUT(COUT), .OH(OH), .OW(OW)
    ) u_next_index (
        .cur_ch(out_ch),
        .cur_row(out_row),
        .cur_col(out_col),
        .next_ch(next_ch_w),
        .next_row(next_row_w),
        .next_col(next_col_w),
        .last(last_output_w)
    );

    reg [TAP_N*DATA_W-1:0] window_flat;
    reg [TAP_N*DATA_W-1:0] kernel_slice;
    wire [ACC_W-1:0] mac_sum_w;
    wire [BIAS_W-1:0] bias_slice_w;
    wire [OUT_W-1:0] clamped_w;

    assign bias_slice_w = bias[out_ch*BIAS_W +: BIAS_W];

    conv2d_window_mac #(
        .CIN(CIN), .K(K), .DATA_W(DATA_W), .ACC_W(ACC_W)
    ) u_window_mac (
        .window_flat(window_flat),
        .kernel_flat(kernel_slice),
        .sum(mac_sum_w)
    );

    conv2d_bias_clamp #(
        .ACC_W(ACC_W), .BIAS_W(BIAS_W), .OUT_W(OUT_W)
    ) u_bias_clamp (
        .sum_in(mac_sum_w),
        .bias_in(bias_slice_w),
        .pixel_out(clamped_w)
    );

    integer c, kr, kc, tap;
    integer img_index;
    integer ker_index;

    always @* begin
        window_flat = {TAP_N*DATA_W{1'b0}};
        kernel_slice = {TAP_N*DATA_W{1'b0}};
        tap = 0;
        for (c = 0; c < CIN; c = c + 1) begin
            for (kr = 0; kr < K; kr = kr + 1) begin
                for (kc = 0; kc < K; kc = kc + 1) begin
                    img_index = (c * H * W) + ((out_row + kr) * W) + (out_col + kc);
                    ker_index = (((out_ch * CIN + c) * K + kr) * K + kc);
                    window_flat[tap*DATA_W +: DATA_W] = image[img_index];
                    kernel_slice[tap*DATA_W +: DATA_W] = kernel[ker_index*DATA_W +: DATA_W];
                    tap = tap + 1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_ch <= 0;
            out_row <= 0;
            out_col <= 0;
            out_count <= 0;
            emitting <= 1'b0;
            pixel_out <= {OUT_W{1'b0}};
            valid_out <= 1'b0;
            done <= 1'b0;
        end else begin
            valid_out <= 1'b0;

            if (valid_in && in_count < IN_N) begin
                image[in_count] <= pixel_in;
                in_count <= in_count + 1;
                if (last_in || in_count == IN_N - 1) begin
                    emitting <= 1'b1;
                    out_ch <= 0;
                    out_row <= 0;
                    out_col <= 0;
                    out_count <= 0;
                    done <= 1'b0;
                end
            end

            if (emitting) begin
                pixel_out <= clamped_w;
                valid_out <= 1'b1;

                if (last_output_w || out_count == OUT_N - 1) begin
                    emitting <= 1'b0;
                    done <= 1'b1;
                    out_count <= out_count + 1;
                end else begin
                    out_ch <= next_ch_w;
                    out_row <= next_row_w;
                    out_col <= next_col_w;
                    out_count <= out_count + 1;
                end
            end
        end
    end

endmodule
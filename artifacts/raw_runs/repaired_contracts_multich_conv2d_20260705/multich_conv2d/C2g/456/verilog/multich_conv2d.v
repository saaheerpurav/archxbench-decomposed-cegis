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
    output [OUT_W-1:0] pixel_out,
    output valid_out,
    output done
);

    localparam IN_N = CIN * H * W;
    localparam OUT_H = H - K + 1;
    localparam OUT_WID = W - K + 1;
    localparam OUT_N = COUT * OUT_H * OUT_WID;

    reg [DATA_W-1:0] image_mem [0:IN_N-1];

    reg [31:0] in_count;
    reg [31:0] out_count;
    reg emitting;

    reg [OUT_W-1:0] pixel_out_r;
    reg valid_out_r;
    reg done_r;

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

    function [OUT_W-1:0] conv_value;
        input integer out_index;
        integer cout_idx;
        integer out_row;
        integer out_col;
        integer rem;
        integer ci;
        integer kr;
        integer kc;
        integer img_index;
        integer ker_index;
        reg [31:0] acc;
        reg [31:0] prod;
        reg [DATA_W-1:0] pix;
        reg [DATA_W-1:0] wt;
        reg [BIAS_W-1:0] b;
        begin
            cout_idx = out_index / (OUT_H * OUT_WID);
            rem = out_index % (OUT_H * OUT_WID);
            out_row = rem / OUT_WID;
            out_col = rem % OUT_WID;

            b = bias[cout_idx*BIAS_W +: BIAS_W];
            acc = b;

            for (ci = 0; ci < CIN; ci = ci + 1) begin
                for (kr = 0; kr < K; kr = kr + 1) begin
                    for (kc = 0; kc < K; kc = kc + 1) begin
                        img_index = (ci * H * W) + ((out_row + kr) * W) + (out_col + kc);
                        ker_index = ((((cout_idx * CIN) + ci) * K + kr) * K + kc) * DATA_W;

                        pix = image_mem[img_index];
                        wt = kernel[ker_index +: DATA_W];
                        prod = pix * wt;
                        acc = acc + prod;
                    end
                end
            end

            conv_value = acc[OUT_W-1:0];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_count <= 0;
            emitting <= 1'b0;
            pixel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in && !emitting && in_count < IN_N) begin
                image_mem[in_count] <= pixel_in;
                in_count <= in_count + 1;

                if (last_in || in_count == IN_N - 1) begin
                    emitting <= 1'b1;
                    out_count <= 0;
                    done_r <= 1'b0;
                end
            end

            if (emitting) begin
                if (out_count < OUT_N) begin
                    pixel_out_r <= conv_value(out_count);
                    valid_out_r <= 1'b1;
                    out_count <= out_count + 1;

                    if (out_count == OUT_N - 1) begin
                        emitting <= 1'b0;
                        done_r <= 1'b1;
                    end
                end else begin
                    emitting <= 1'b0;
                    done_r <= 1'b1;
                end
            end
        end
    end

endmodule
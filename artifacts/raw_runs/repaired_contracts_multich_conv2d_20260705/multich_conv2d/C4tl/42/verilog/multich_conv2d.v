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

    localparam OUT_H = H - K + 1;
    localparam OUT_WID = W - K + 1;
    localparam IN_N = CIN * H * W;
    localparam OUT_N = COUT * OUT_H * OUT_WID;
    localparam WINDOW_ELEMS = CIN * K * K;
    localparam WINDOW_W = WINDOW_ELEMS * DATA_W;
    localparam ACC_W = DATA_W * 2 + 16;

    function integer clog2;
        input integer value;
        integer v;
        begin
            v = value - 1;
            for (clog2 = 0; v > 0; clog2 = clog2 + 1)
                v = v >> 1;
        end
    endfunction

    reg [DATA_W-1:0] image_mem [0:IN_N-1];

    reg [clog2(IN_N+1)-1:0] in_count;
    reg [clog2(COUT)-1:0] out_c;
    reg [clog2(OUT_H)-1:0] out_r;
    reg [clog2(OUT_WID)-1:0] out_col;
    reg [clog2(OUT_N+1)-1:0] out_count;
    reg emitting;

    reg [OUT_W-1:0] pixel_out_r;
    reg valid_out_r;
    reg done_r;

    reg [WINDOW_W-1:0] window_flat;
    wire [WINDOW_W-1:0] window_wire;
    wire [DATA_W-1:0] current_kernel_weight;
    wire [BIAS_W-1:0] current_bias;
    wire [ACC_W-1:0] mac_sum;
    wire [OUT_W-1:0] clamped_sum;
    wire [clog2(IN_N)-1:0] unused_addr;

    integer ci, kr, kc;
    integer flat_idx;
    integer mem_idx;
    integer kern_base;

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;
    assign window_wire = window_flat;

    always @* begin
        window_flat = {WINDOW_W{1'b0}};
        flat_idx = 0;
        for (ci = 0; ci < CIN; ci = ci + 1) begin
            for (kr = 0; kr < K; kr = kr + 1) begin
                for (kc = 0; kc < K; kc = kc + 1) begin
                    mem_idx = (ci * H * W) + ((out_r + kr) * W) + (out_col + kc);
                    window_flat[flat_idx*DATA_W +: DATA_W] = image_mem[mem_idx];
                    flat_idx = flat_idx + 1;
                end
            end
        end
    end

    always @* begin
        kern_base = out_c * WINDOW_ELEMS * DATA_W;
    end

    assign current_kernel_weight = kernel[kern_base +: DATA_W];
    assign current_bias = bias[out_c*BIAS_W +: BIAS_W];

    conv2d_addr_gen #(
        .CIN(CIN), .H(H), .W(W), .K(K)
    ) u_addr_gen (
        .channel(out_c < CIN ? out_c : {clog2(CIN){1'b0}}),
        .row(out_r),
        .col(out_col),
        .krow({clog2(K){1'b0}}),
        .kcol({clog2(K){1'b0}}),
        .addr(unused_addr)
    );

    conv2d_mac #(
        .CIN(CIN),
        .K(K),
        .DATA_W(DATA_W),
        .BIAS_W(BIAS_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window(window_wire),
        .kernel(kernel[kern_base +: WINDOW_W]),
        .bias(current_bias),
        .sum(mac_sum)
    );

    conv2d_clamp #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_clamp (
        .value_in(mac_sum),
        .value_out(clamped_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 0;
            out_c <= 0;
            out_r <= 0;
            out_col <= 0;
            out_count <= 0;
            emitting <= 1'b0;
            pixel_out_r <= {OUT_W{1'b0}};
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in && in_count < IN_N) begin
                image_mem[in_count] <= pixel_in;
                in_count <= in_count + 1'b1;
                if (last_in || in_count == IN_N-1)
                    emitting <= 1'b1;
            end

            if (emitting && out_count < OUT_N) begin
                pixel_out_r <= clamped_sum;
                valid_out_r <= 1'b1;
                out_count <= out_count + 1'b1;

                if (out_col == OUT_WID-1) begin
                    out_col <= 0;
                    if (out_r == OUT_H-1) begin
                        out_r <= 0;
                        if (out_c == COUT-1) begin
                            out_c <= 0;
                            emitting <= 1'b0;
                            done_r <= 1'b1;
                        end else begin
                            out_c <= out_c + 1'b1;
                        end
                    end else begin
                        out_r <= out_r + 1'b1;
                    end
                end else begin
                    out_col <= out_col + 1'b1;
                end
            end
        end
    end

endmodule
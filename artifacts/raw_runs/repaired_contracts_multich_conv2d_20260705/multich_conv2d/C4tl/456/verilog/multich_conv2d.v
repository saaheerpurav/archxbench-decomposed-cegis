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
    localparam OUT_SPATIAL = OUT_H * OUT_WID;
    localparam OUT_N = COUT * OUT_SPATIAL;
    localparam WINDOW_ELEMS = CIN * K * K;
    localparam WINDOW_W = WINDOW_ELEMS * DATA_W;
    localparam ACC_W = DATA_W + DATA_W + 16;

    reg [DATA_W-1:0] image_mem [0:IN_N-1];

    reg [31:0] in_count;
    reg [31:0] out_count;
    reg emitting;
    reg valid_out_r;
    reg done_r;
    reg [OUT_W-1:0] pixel_out_r;

    wire [31:0] out_ch;
    wire [31:0] out_row;
    wire [31:0] out_col;
    wire coord_valid;

    reg [WINDOW_W-1:0] window_flat;
    wire [WINDOW_ELEMS*DATA_W-1:0] kernel_slice;
    wire [ACC_W-1:0] mac_sum;
    wire [OUT_W-1:0] biased_clamped;
    wire done_next;

    integer pc;
    integer pr;
    integer pkc;
    integer pkr;
    integer win_idx;
    integer mem_idx;

    multich_conv2d_out_coord #(
        .COUT(COUT),
        .OUT_H(OUT_H),
        .OUT_WID(OUT_WID)
    ) u_coord (
        .flat_index(out_count),
        .out_ch(out_ch),
        .out_row(out_row),
        .out_col(out_col),
        .valid(coord_valid)
    );

    multich_conv2d_kernel_select #(
        .CIN(CIN),
        .COUT(COUT),
        .K(K),
        .DATA_W(DATA_W)
    ) u_kernel_select (
        .kernel(kernel),
        .out_ch(out_ch),
        .kernel_slice(kernel_slice)
    );

    multich_conv2d_mac #(
        .ELEMS(WINDOW_ELEMS),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .window_flat(window_flat),
        .kernel_flat(kernel_slice),
        .sum(mac_sum)
    );

    multich_conv2d_bias_clamp #(
        .COUT(COUT),
        .BIAS_W(BIAS_W),
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_bias_clamp (
        .sum_in(mac_sum),
        .bias(bias),
        .out_ch(out_ch),
        .pixel_out(biased_clamped)
    );

    multich_conv2d_done_logic #(
        .OUT_N(OUT_N)
    ) u_done_logic (
        .out_count(out_count),
        .emitting(emitting),
        .done(done_next)
    );

    always @* begin
        window_flat = {WINDOW_W{1'b0}};
        for (pc = 0; pc < CIN; pc = pc + 1) begin
            for (pkr = 0; pkr < K; pkr = pkr + 1) begin
                for (pkc = 0; pkc < K; pkc = pkc + 1) begin
                    win_idx = ((pc * K) + pkr) * K + pkc;
                    mem_idx = (pc * H * W) + ((out_row + pkr) * W) + (out_col + pkc);
                    if (coord_valid && mem_idx >= 0 && mem_idx < IN_N) begin
                        window_flat[win_idx*DATA_W +: DATA_W] = image_mem[mem_idx];
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            in_count <= 32'd0;
            out_count <= 32'd0;
            emitting <= 1'b0;
            valid_out_r <= 1'b0;
            done_r <= 1'b0;
            pixel_out_r <= {OUT_W{1'b0}};
        end else begin
            valid_out_r <= 1'b0;

            if (valid_in && in_count < IN_N) begin
                image_mem[in_count] <= pixel_in;
                in_count <= in_count + 32'd1;
                if (last_in || in_count == IN_N - 1) begin
                    emitting <= 1'b1;
                    out_count <= 32'd0;
                    done_r <= 1'b0;
                end
            end

            if (emitting) begin
                if (out_count < OUT_N) begin
                    pixel_out_r <= biased_clamped;
                    valid_out_r <= 1'b1;
                    out_count <= out_count + 32'd1;
                    if (out_count == OUT_N - 1) begin
                        emitting <= 1'b0;
                        done_r <= 1'b1;
                    end
                end else begin
                    emitting <= 1'b0;
                    done_r <= 1'b1;
                end
            end else if (done_next) begin
                done_r <= 1'b1;
            end
        end
    end

    assign pixel_out = pixel_out_r;
    assign valid_out = valid_out_r;
    assign done = done_r;

endmodule
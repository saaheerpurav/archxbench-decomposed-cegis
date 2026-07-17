`timescale 1ns/1ps

module bandpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                       clk,
    input                       rst,
    input                       valid_in,
    input      [DATA_W-1:0]     data_in,
    output                      valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W    = DATA_W + GAIN_W;
    localparam COEFF_W  = 16;
    localparam PROD_W   = DATA_W + COEFF_W;
    localparam ACC_W    = 64;
    localparam HIST_CNT = TAP_CNT - 1;

    reg signed [DATA_W-1:0] history [0:HIST_CNT-1];
    reg                     valid_out_r;
    reg signed [OUT_W-1:0]  data_out_r;

    wire signed [DATA_W-1:0] signed_data_in;
    wire [DATA_W*HIST_CNT-1:0] history_flat;
    wire [DATA_W*TAP_CNT-1:0]  window_flat;
    wire [PROD_W*TAP_CNT-1:0]  products_flat;
    wire signed [ACC_W-1:0]    acc_sum;
    wire signed [OUT_W-1:0]    normalized_out;

    integer i;
    genvar g;

    assign signed_data_in = data_in;
    assign valid_out = valid_out_r;
    assign data_out = data_out_r;

    generate
        for (g = 0; g < HIST_CNT; g = g + 1) begin : gen_history_flat
            assign history_flat[g*DATA_W +: DATA_W] = history[g];
        end
    endgenerate

    bpf_sample_window #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_sample_window (
        .current_sample(signed_data_in),
        .history_flat(history_flat),
        .window_flat(window_flat)
    );

    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_taps
            wire [7:0] tap_index;
            wire signed [COEFF_W-1:0] coeff;
            wire signed [DATA_W-1:0] sample;
            wire signed [PROD_W-1:0] product;

            assign tap_index = g[7:0];
            assign sample = window_flat[g*DATA_W +: DATA_W];

            bpf_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) u_coeff_rom (
                .tap_index(tap_index),
                .coeff(coeff)
            );

            bpf_tap_product #(
                .DATA_W(DATA_W),
                .COEFF_W(COEFF_W),
                .PROD_W(PROD_W)
            ) u_tap_product (
                .sample(sample),
                .coeff(coeff),
                .product(product)
            );

            assign products_flat[g*PROD_W +: PROD_W] = product;
        end
    endgenerate

    bpf_accumulator #(
        .TAP_CNT(TAP_CNT),
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) u_accumulator (
        .products_flat(products_flat),
        .acc(acc_sum)
    );

    bpf_q15_normalizer #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_normalizer (
        .acc(acc_sum),
        .result(normalized_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out_r <= 1'b0;
            data_out_r <= {OUT_W{1'b0}};
            for (i = 0; i < HIST_CNT; i = i + 1) begin
                history[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out_r <= valid_in;
            if (valid_in) begin
                data_out_r <= normalized_out;
                history[0] <= signed_data_in;
                for (i = 1; i < HIST_CNT; i = i + 1) begin
                    history[i] <= history[i-1];
                end
            end else begin
                data_out_r <= {OUT_W{1'b0}};
            end
        end
    end

endmodule
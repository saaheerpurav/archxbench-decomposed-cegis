`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                          clk,
    input                          rst,
    input                          valid_in,
    input      [DATA_W-1:0]        data_in,
    output                         valid_out,
    output     [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W     = DATA_W + GAIN_W;
    localparam PAIR_CNT  = (TAP_CNT - 1) / 2;
    localparam PREADD_W  = DATA_W + 1;
    localparam COEFF_W   = 16;
    localparam ACC_W     = 64;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];
    reg                     valid_q;
    reg signed [OUT_W-1:0]  data_q;

    wire [DATA_W*TAP_CNT-1:0] taps_flat;
    wire [PREADD_W*PAIR_CNT-1:0] pair_sums_flat;
    wire signed [DATA_W-1:0] center_sample;
    wire [COEFF_W*((TAP_CNT+1)/2)-1:0] coeffs_flat;
    wire signed [ACC_W-1:0] acc_full;
    wire signed [OUT_W-1:0] normalized_out;

    integer i;

    generate
        genvar gi;
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : FLATTEN_TAPS
            assign taps_flat[gi*DATA_W +: DATA_W] = sample_shift[gi];
        end
    endgenerate

    fir_coeff_bank #(
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W)
    ) u_coeff_bank (
        .coeffs_flat(coeffs_flat)
    );

    fir_symmetric_preadd #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_preadd (
        .taps_flat(taps_flat),
        .pair_sums_flat(pair_sums_flat),
        .center_sample(center_sample)
    );

    fir_parallel_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .pair_sums_flat(pair_sums_flat),
        .center_sample(center_sample),
        .coeffs_flat(coeffs_flat),
        .acc_out(acc_full)
    );

    fir_q15_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_normalize (
        .acc_in(acc_full),
        .data_out(normalized_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_shift[i] <= {DATA_W{1'b0}};
            valid_q <= 1'b0;
            data_q  <= {OUT_W{1'b0}};
        end else begin
            valid_q <= valid_in;
            data_q  <= normalized_out;

            if (valid_in) begin
                sample_shift[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_shift[i] <= sample_shift[i-1];
            end
        end
    end

    assign valid_out = valid_q;
    assign data_out  = data_q;
endmodule
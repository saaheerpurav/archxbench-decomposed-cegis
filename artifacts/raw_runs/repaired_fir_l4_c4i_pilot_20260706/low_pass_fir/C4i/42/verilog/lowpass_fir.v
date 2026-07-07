`timescale 1ns/1ps

module lowpass_fir #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter GAIN_W  = 4
) (
    input                           clk,
    input                           rst,
    input                           valid_in,
    input      [DATA_W-1:0]         data_in,
    output reg                      valid_out,
    output reg [DATA_W+GAIN_W-1:0]  data_out
);
    localparam OUT_W     = DATA_W + GAIN_W;
    localparam PAIR_CNT  = (TAP_CNT - 1) / 2;
    localparam COEFF_W   = 16;
    localparam ACC_W     = 64;
    localparam PREADD_W  = DATA_W + 1;

    reg signed [DATA_W-1:0] sample_sr [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] data_in_s;
    wire [DATA_W*TAP_CNT-1:0] sample_flat;
    wire [COEFF_W*TAP_CNT-1:0] coeff_flat;
    wire [PREADD_W*PAIR_CNT-1:0] pair_sum_flat;
    wire signed [DATA_W-1:0] center_sample;
    wire signed [ACC_W-1:0] acc_full;
    wire signed [OUT_W-1:0] scaled_out;

    integer i;

    assign data_in_s = data_in;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : FLATTEN_SAMPLES
            assign sample_flat[g*DATA_W +: DATA_W] =
                (g == 0) ? data_in_s : sample_sr[g-1];
        end
    endgenerate

    fir_coeff_pack #(
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W)
    ) u_coeff_pack (
        .coeff_flat(coeff_flat)
    );

    fir_symmetric_sum_pack #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_sym_sum (
        .sample_flat(sample_flat),
        .pair_sum_flat(pair_sum_flat),
        .center_sample(center_sample)
    );

    fir_mac_symmetric #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .COEFF_W(COEFF_W),
        .ACC_W(ACC_W)
    ) u_mac (
        .coeff_flat(coeff_flat),
        .pair_sum_flat(pair_sum_flat),
        .center_sample(center_sample),
        .acc_out(acc_full)
    );

    fir_output_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(20)
    ) u_scale (
        .acc_in(acc_full),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_sr[i] <= {DATA_W{1'b0}};
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                sample_sr[0] <= data_in_s;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_sr[i] <= sample_sr[i-1];
                data_out <= scaled_out;
            end
        end
    end
endmodule
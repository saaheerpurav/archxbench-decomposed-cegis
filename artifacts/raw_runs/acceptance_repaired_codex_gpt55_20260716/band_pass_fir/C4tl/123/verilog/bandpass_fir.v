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
    output reg                  valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];

    wire signed [15:0] coeff_wire [0:TAP_CNT-1];
    wire signed [63:0] product_wire [0:TAP_CNT-1];
    wire signed [OUT_W-1:0] normalized_wire;

    reg signed [63:0] acc_comb;

    integer i;

    genvar g;
    generate
        for (g = 0; g < TAP_CNT; g = g + 1) begin : gen_taps
            bpf_coeff_rom u_coeff_rom (
                .tap_index(g[7:0]),
                .coeff(coeff_wire[g])
            );

            bpf_tap_product #(
                .DATA_W(DATA_W)
            ) u_tap_product (
                .sample(sample_shift[g]),
                .coeff(coeff_wire[g]),
                .product(product_wire[g])
            );
        end
    endgenerate

    always @* begin
        acc_comb = 64'sd0;
        for (i = 0; i < TAP_CNT; i = i + 1) begin
            acc_comb = acc_comb + product_wire[i];
        end
    end

    bpf_q15_normalizer #(
        .OUT_W(OUT_W)
    ) u_q15_normalizer (
        .acc_in(acc_comb),
        .data_out(normalized_wire)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                sample_shift[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;
            data_out  <= normalized_wire;

            if (valid_in) begin
                sample_shift[0] <= $signed(data_in);
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    sample_shift[i] <= sample_shift[i-1];
                end
            end
        end
    end

endmodule
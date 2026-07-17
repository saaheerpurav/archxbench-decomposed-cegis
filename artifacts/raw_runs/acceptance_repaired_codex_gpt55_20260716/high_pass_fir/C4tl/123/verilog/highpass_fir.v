`timescale 1ns/1ps

module highpass_fir #(
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
    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam PROD_W  = DATA_W + COEFF_W;
    localparam ACC_W   = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] sample_taps [0:TAP_CNT-1];
    wire signed [COEFF_W-1:0] coeffs [0:TAP_CNT-1];
    wire signed [PROD_W-1:0] products [0:TAP_CNT-1];
    wire [TAP_CNT*PROD_W-1:0] products_flat;
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [ACC_W-1:0] scaled_sum;

    integer i;

    assign sample_taps[0] = $signed(data_in);
    generate
        genvar gi;
        for (gi = 1; gi < TAP_CNT; gi = gi + 1) begin : GEN_TAPS
            assign sample_taps[gi] = delay_line[gi-1];
        end

        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_MAC
            highpass_fir_coeff_rom u_coeff_rom (
                .addr(gi[6:0]),
                .coeff(coeffs[gi])
            );

            highpass_fir_product #(
                .DATA_W(DATA_W),
                .COEFF_W(COEFF_W),
                .PROD_W(PROD_W)
            ) u_product (
                .sample(sample_taps[gi]),
                .coeff(coeffs[gi]),
                .product(products[gi])
            );

            assign products_flat[gi*PROD_W +: PROD_W] = products[gi];
        end
    endgenerate

    highpass_fir_accumulator #(
        .TAP_CNT(TAP_CNT),
        .PROD_W(PROD_W),
        .ACC_W(ACC_W)
    ) u_accumulator (
        .products_flat(products_flat),
        .acc_sum(acc_sum)
    );

    highpass_fir_q15_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_normalize (
        .acc_sum(acc_sum),
        .data_out(scaled_sum)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                delay_line[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= scaled_sum[OUT_W-1:0];

                delay_line[0] <= $signed(data_in);
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    delay_line[i] <= delay_line[i-1];
                end
            end
        end
    end
endmodule
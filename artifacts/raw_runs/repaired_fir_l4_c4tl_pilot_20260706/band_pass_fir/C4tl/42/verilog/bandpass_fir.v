`timescale 1ns/1ps

module bandpass_fir #(
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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam ACC_W = 64;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];
    reg signed [OUT_W-1:0]  data_out_r;
    reg                     valid_out_r;

    wire signed [COEFF_W-1:0] coeff [0:TAP_CNT-1];
    wire signed [DATA_W+COEFF_W-1:0] product [0:TAP_CNT-1];
    wire signed [TAP_CNT*DATA_W-1:0] sample_bus;
    wire signed [TAP_CNT*(DATA_W+COEFF_W)-1:0] product_bus;
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [OUT_W-1:0] scaled_out;

    integer i;

    assign valid_out = valid_out_r;
    assign data_out  = data_out_r;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_TAPS
            assign sample_bus[gi*DATA_W +: DATA_W] = sample_shift[gi];

            bpf_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) u_coeff_rom (
                .tap_idx(gi[7:0]),
                .coeff(coeff[gi])
            );

            bpf_tap_multiply #(
                .DATA_W(DATA_W),
                .COEFF_W(COEFF_W)
            ) u_tap_multiply (
                .sample(sample_shift[gi]),
                .coeff(coeff[gi]),
                .product(product[gi])
            );

            assign product_bus[gi*(DATA_W+COEFF_W) +: (DATA_W+COEFF_W)] = product[gi];
        end
    endgenerate

    bpf_accumulator #(
        .TAP_CNT(TAP_CNT),
        .PROD_W(DATA_W+COEFF_W),
        .ACC_W(ACC_W)
    ) u_accumulator (
        .products(product_bus),
        .acc_sum(acc_sum)
    );

    bpf_output_scaler #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_output_scaler (
        .acc_sum(acc_sum),
        .data_out(scaled_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                sample_shift[i] <= {DATA_W{1'b0}};
            end
            valid_out_r <= 1'b0;
            data_out_r  <= {OUT_W{1'b0}};
        end else begin
            valid_out_r <= valid_in;
            data_out_r  <= scaled_out;

            if (valid_in) begin
                sample_shift[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1) begin
                    sample_shift[i] <= sample_shift[i-1];
                end
            end
        end
    end

endmodule
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

    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = 64;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];

    wire [DATA_W*TAP_CNT-1:0] samples_flat;
    wire [16*TAP_CNT-1:0]     coeffs_flat;
    wire signed [ACC_W-1:0]   mac_sum;
    wire signed [OUT_W-1:0]   scaled_out;

    integer i;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : FLATTEN_SAMPLES
            assign samples_flat[(gi+1)*DATA_W-1:gi*DATA_W] = sample_shift[gi];
        end
    endgenerate

    highpass_fir_coeff_rom #(
        .TAP_CNT(TAP_CNT)
    ) u_coeff_rom (
        .coeffs_flat(coeffs_flat)
    );

    highpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .samples_flat(samples_flat),
        .coeffs_flat(coeffs_flat),
        .acc_out(mac_sum)
    );

    highpass_fir_quantize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_quantize (
        .acc_in(mac_sum),
        .data_out(scaled_out)
    );

    highpass_fir_zero_extend_valid u_valid_gate (
        .valid_in(valid_in),
        .valid_out()
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_shift[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;
            data_out  <= scaled_out;

            if (valid_in) begin
                sample_shift[0] <= $signed(data_in);
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_shift[i] <= sample_shift[i-1];
            end
        end
    end

endmodule
`timescale 1ns/1ps

module highpass_fir #(
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

    localparam OUT_W   = DATA_W + GAIN_W;
    localparam COEFF_W = 16;
    localparam ACC_W   = 64;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];

    wire [DATA_W*TAP_CNT-1:0]  sample_bus;
    wire [COEFF_W*TAP_CNT-1:0] coeff_bus;
    wire signed [ACC_W-1:0]    mac_accum;
    wire signed [OUT_W-1:0]    normalized_out;

    integer i;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : g_pack
            assign sample_bus[gi*DATA_W +: DATA_W] = sample_shift[gi];

            highpass_fir_coeff_rom #(
                .COEFF_W(COEFF_W)
            ) u_coeff_rom (
                .addr(gi[6:0]),
                .coeff(coeff_bus[gi*COEFF_W +: COEFF_W])
            );
        end
    endgenerate

    highpass_fir_mac #(
        .DATA_W(DATA_W),
        .COEFF_W(COEFF_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .samples(sample_bus),
        .coeffs(coeff_bus),
        .accum(mac_accum)
    );

    highpass_fir_normalize #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT(15)
    ) u_normalize (
        .accum(mac_accum),
        .data_out(normalized_out)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1)
                sample_shift[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                sample_shift[0] <= data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_shift[i] <= sample_shift[i-1];
            end

            data_out <= normalized_out;
        end
    end

endmodule
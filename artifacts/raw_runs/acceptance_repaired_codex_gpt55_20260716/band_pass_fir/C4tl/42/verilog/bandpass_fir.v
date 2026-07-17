`timescale 1ns/1ps

module bandpass_fir #(
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

    localparam OUT_W = DATA_W + GAIN_W;

    reg signed [DATA_W-1:0] samples [0:TAP_CNT-1];
    reg [DATA_W*TAP_CNT-1:0] sample_bus;

    wire signed [63:0] acc_w;
    wire signed [OUT_W-1:0] norm_w;

    integer i;

    always @* begin
        for (i = 0; i < TAP_CNT; i = i + 1)
            sample_bus[i*DATA_W +: DATA_W] = samples[i];
    end

    bandpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_mac (
        .sample_bus(sample_bus),
        .acc_out(acc_w)
    );

    bandpass_fir_q15_norm #(
        .OUT_W(OUT_W)
    ) u_norm (
        .acc_in(acc_w),
        .data_out(norm_w)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1)
                samples[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                data_out <= norm_w;

                for (i = TAP_CNT-1; i > 0; i = i - 1)
                    samples[i] <= samples[i-1];
                samples[0] <= $signed(data_in);
            end
        end
    end

endmodule
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
    output reg                     valid_out,
    output reg [DATA_W+GAIN_W-1:0] data_out
);
    localparam OUT_W    = DATA_W + GAIN_W;
    localparam PAIR_CNT = (TAP_CNT - 1) / 2;
    localparam SUM_W    = DATA_W + 1;
    localparam ACC_W    = 64;

    reg signed [DATA_W-1:0] sample_shift [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] signed_data_in;
    wire [TAP_CNT*DATA_W-1:0] tap_bus;
    wire [PAIR_CNT*SUM_W-1:0] pair_sum_bus;
    wire signed [DATA_W-1:0] center_sample;
    wire signed [ACC_W-1:0] acc_full;
    wire signed [OUT_W-1:0] scaled_out;

    integer i;

    assign signed_data_in = data_in;

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_TAP_BUS
            assign tap_bus[gi*DATA_W +: DATA_W] =
                (valid_in && (gi == 0)) ? signed_data_in :
                (valid_in)              ? sample_shift[gi-1] :
                                          sample_shift[gi];
        end
    endgenerate

    fir_symmetric_preadd #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_preadd (
        .tap_bus(tap_bus),
        .pair_sum_bus(pair_sum_bus),
        .center_sample(center_sample)
    );

    fir_symmetric_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .pair_sum_bus(pair_sum_bus),
        .center_sample(center_sample),
        .acc_out(acc_full)
    );

    fir_output_scale #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .SHIFT_W(20)
    ) u_scale (
        .acc_in(acc_full),
        .data_out(scaled_out)
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
                data_out <= scaled_out;
                sample_shift[0] <= signed_data_in;
                for (i = 1; i < TAP_CNT; i = i + 1)
                    sample_shift[i] <= sample_shift[i-1];
            end
        end
    end
endmodule
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

    reg signed [DATA_W-1:0] tap_regs [0:TAP_CNT-1];

    wire signed [DATA_W-1:0] sample_signed;
    wire [DATA_W*TAP_CNT-1:0] tap_bus;
    wire [DATA_W*TAP_CNT-1:0] next_tap_bus;
    wire signed [ACC_W-1:0] acc_sum;
    wire signed [OUT_W-1:0] filtered_sample;

    integer i;

    highpass_fir_input_cast #(
        .DATA_W(DATA_W)
    ) u_input_cast (
        .data_in(data_in),
        .sample_out(sample_signed)
    );

    genvar gi;
    generate
        for (gi = 0; gi < TAP_CNT; gi = gi + 1) begin : GEN_TAP_BUS
            assign tap_bus[gi*DATA_W +: DATA_W] = tap_regs[gi];
        end
    endgenerate

    highpass_fir_tap_update #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) u_tap_update (
        .valid_in(valid_in),
        .sample_in(sample_signed),
        .tap_bus_in(tap_bus),
        .tap_bus_out(next_tap_bus)
    );

    highpass_fir_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) u_mac (
        .tap_bus(next_tap_bus),
        .acc_out(acc_sum)
    );

    highpass_fir_q15_shift #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W)
    ) u_q15_shift (
        .acc_in(acc_sum),
        .data_out(filtered_sample)
    );

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                tap_regs[i] <= {DATA_W{1'b0}};
            end
        end else begin
            valid_out <= valid_in;
            for (i = 0; i < TAP_CNT; i = i + 1) begin
                tap_regs[i] <= next_tap_bus[i*DATA_W +: DATA_W];
            end
            if (valid_in) begin
                data_out <= filtered_sample;
            end
        end
    end

endmodule
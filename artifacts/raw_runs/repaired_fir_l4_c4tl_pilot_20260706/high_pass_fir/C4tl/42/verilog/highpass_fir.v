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
    localparam OUT_W = DATA_W + GAIN_W;
    localparam ACC_W = 64;

    reg signed [DATA_W-1:0] delay_line [0:TAP_CNT-2];

    wire [DATA_W*TAP_CNT-1:0] samples_flat;
    wire signed [ACC_W-1:0] acc_full;
    wire signed [OUT_W-1:0] quantized_out;

    integer i;

    hpf_tap_vector #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT)
    ) tap_vector_i (
        .data_in(data_in),
        .delay_flat(make_delay_flat()),
        .samples_flat(samples_flat)
    );

    hpf_mac #(
        .DATA_W(DATA_W),
        .TAP_CNT(TAP_CNT),
        .ACC_W(ACC_W)
    ) mac_i (
        .samples_flat(samples_flat),
        .acc_out(acc_full)
    );

    hpf_quantize #(
        .OUT_W(OUT_W),
        .ACC_W(ACC_W),
        .SHIFT(15)
    ) quantize_i (
        .acc_in(acc_full),
        .data_out(quantized_out)
    );

    function [DATA_W*(TAP_CNT-1)-1:0] make_delay_flat;
        integer k;
        begin
            for (k = 0; k < TAP_CNT-1; k = k + 1)
                make_delay_flat[k*DATA_W +: DATA_W] = delay_line[k];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
            data_out  <= {OUT_W{1'b0}};
            for (i = 0; i < TAP_CNT-1; i = i + 1)
                delay_line[i] <= {DATA_W{1'b0}};
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                data_out <= quantized_out;
                delay_line[0] <= data_in;
                for (i = 1; i < TAP_CNT-1; i = i + 1)
                    delay_line[i] <= delay_line[i-1];
            end
        end
    end
endmodule
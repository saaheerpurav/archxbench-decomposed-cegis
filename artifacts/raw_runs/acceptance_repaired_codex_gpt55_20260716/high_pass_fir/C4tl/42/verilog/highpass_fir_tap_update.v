`timescale 1ns/1ps

module highpass_fir_tap_update #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input                         valid_in,
    input signed [DATA_W-1:0]     sample_in,
    input      [DATA_W*TAP_CNT-1:0] tap_bus_in,
    output reg [DATA_W*TAP_CNT-1:0] tap_bus_out
);
    integer i;

    always @* begin
        tap_bus_out = tap_bus_in;
        if (valid_in) begin
            tap_bus_out[0 +: DATA_W] = sample_in;
            for (i = 1; i < TAP_CNT; i = i + 1) begin
                tap_bus_out[i*DATA_W +: DATA_W] = tap_bus_in[(i-1)*DATA_W +: DATA_W];
            end
        end
    end
endmodule
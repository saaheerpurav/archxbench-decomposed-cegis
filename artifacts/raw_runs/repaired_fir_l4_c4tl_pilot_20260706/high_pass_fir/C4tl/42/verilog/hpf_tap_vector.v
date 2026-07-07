`timescale 1ns/1ps

module hpf_tap_vector #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input      [DATA_W-1:0]              data_in,
    input      [DATA_W*(TAP_CNT-1)-1:0]  delay_flat,
    output     [DATA_W*TAP_CNT-1:0]      samples_flat
);
    assign samples_flat[0 +: DATA_W] = data_in;
    assign samples_flat[DATA_W*TAP_CNT-1:DATA_W] = delay_flat;
endmodule
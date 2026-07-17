`timescale 1ns/1ps

module fp_fir_history_pack #(
    parameter TAP_CNT = 101
) (
    input  wire [31:0] new_sample,
    input  wire [TAP_CNT*32-1:0] history_bus,
    output wire [TAP_CNT*32-1:0] next_history_bus
);
    genvar i;

    assign next_history_bus[31:0] = new_sample;

    generate
        for (i = 1; i < TAP_CNT; i = i + 1) begin : g_shift_history
            assign next_history_bus[i*32 +: 32] = history_bus[(i-1)*32 +: 32];
        end
    endgenerate

endmodule
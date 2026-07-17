`timescale 1ns/1ps

module fp_fir_history_update #(
    parameter TAP_CNT = 101
) (
    input wire valid_in,
    input wire [31:0] data_in,
    input wire [31:0] hist_in [0:TAP_CNT-1],
    output wire [31:0] hist_out [0:TAP_CNT-1]
);

    genvar i;

    assign hist_out[0] = valid_in ? data_in : hist_in[0];

    generate
        for (i = 1; i < TAP_CNT; i = i + 1) begin : g_shift
            assign hist_out[i] = valid_in ? hist_in[i-1] : hist_in[i];
        end
    endgenerate

endmodule
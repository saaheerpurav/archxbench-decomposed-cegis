`timescale 1ns/1ps

module conv1d_scaler #(
    parameter IN_W  = 17,
    parameter OUT_W = 12
) (
    input  [IN_W-1:0]   sum_in,
    output [OUT_W-1:0]  data_out
);

    assign data_out = sum_in >> 4;

endmodule
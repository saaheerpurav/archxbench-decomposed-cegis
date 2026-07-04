`timescale 1ns/1ps

module conv3d_output_select #(
    parameter OUT_W = 12
) (
    input window_valid,
    input [OUT_W-1:0] mac_value,
    output [OUT_W-1:0] selected_value
);

    assign selected_value = window_valid ? mac_value : {OUT_W{1'b0}};

endmodule
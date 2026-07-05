`timescale 1ns/1ps

module multich_conv2d_done_logic #(
    parameter OUT_N = 30752,
    parameter OUT_CNT_W = 16
)(
    input  [OUT_CNT_W-1:0] out_count,
    output                 all_outputs_sent
);

  wire [OUT_CNT_W:0] out_count_ext = {1'b0, out_count};
  wire [OUT_CNT_W:0] out_n_ext     = OUT_N[OUT_CNT_W:0];

  assign all_outputs_sent = (out_count_ext >= out_n_ext);

endmodule
`timescale 1ns/1ps

module multich_conv2d #(
    parameter CIN = 3,
    parameter COUT = 8,
    parameter K = 3,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter BIAS_W = 16,
    parameter OUT_W = 16
)(
    input clk, rst,
    input [DATA_W-1:0] pixel_in,
    input valid_in,
    input last_in,
    input [COUT*CIN*K*K*DATA_W-1:0] kernel,
    input [COUT*BIAS_W-1:0] bias,
    output reg [OUT_W-1:0] pixel_out,
    output reg valid_out,
    output reg done
);

  localparam IN_N = CIN * H * W;
  localparam OUT_H = H - K + 1;
  localparam OUT_WID = W - K + 1;
  localparam OUT_N = COUT * OUT_H * OUT_WID;
  localparam IMG_BITS = IN_N * DATA_W;
  localparam MAC_W = (2*DATA_W) + clog2(CIN*K*K+1) + 2;
  localparam CNT_W = clog2(IN_N + 1);
  localparam OUT_CNT_W = clog2(OUT_N + 1);
  localparam ROW_W = clog2(OUT_H + 1);
  localparam COL_W = clog2(OUT_WID + 1);
  localparam COUT_W = clog2(COUT + 1);

  function integer clog2;
    input integer value;
    integer v;
    begin
      v = value - 1;
      clog2 = 0;
      while (v > 0) begin
        v = v >> 1;
        clog2 = clog2 + 1;
      end
      if (clog2 < 1)
        clog2 = 1;
    end
  endfunction

  reg [DATA_W-1:0] image_mem [0:IN_N-1];
  reg [CNT_W-1:0] in_count;
  reg [OUT_CNT_W-1:0] out_count;
  reg emitting;

  wire [IMG_BITS-1:0] image_flat;
  wire [COUT_W-1:0] out_ch;
  wire [ROW_W-1:0] out_row;
  wire [COL_W-1:0] out_col;
  wire [MAC_W-1:0] mac_value;
  wire [OUT_W-1:0] processed_value;
  wire all_outputs_sent;

  genvar gi;
  generate
    for (gi = 0; gi < IN_N; gi = gi + 1) begin : PACK_IMAGE
      assign image_flat[gi*DATA_W +: DATA_W] = image_mem[gi];
    end
  endgenerate

  multich_conv2d_index_decode #(
    .COUT(COUT),
    .OUT_H(OUT_H),
    .OUT_WID(OUT_WID),
    .OUT_CNT_W(OUT_CNT_W),
    .COUT_W(COUT_W),
    .ROW_W(ROW_W),
    .COL_W(COL_W)
  ) u_index_decode (
    .out_index(out_count),
    .out_ch(out_ch),
    .out_row(out_row),
    .out_col(out_col)
  );

  multich_conv2d_window_mac #(
    .CIN(CIN),
    .COUT(COUT),
    .K(K),
    .H(H),
    .W(W),
    .DATA_W(DATA_W),
    .MAC_W(MAC_W),
    .IMG_BITS(IMG_BITS),
    .COUT_W(COUT_W),
    .ROW_W(ROW_W),
    .COL_W(COL_W)
  ) u_window_mac (
    .image_flat(image_flat),
    .kernel(kernel),
    .out_ch(out_ch),
    .out_row(out_row),
    .out_col(out_col),
    .mac_out(mac_value)
  );

  multich_conv2d_postprocess #(
    .COUT(COUT),
    .BIAS_W(BIAS_W),
    .OUT_W(OUT_W),
    .MAC_W(MAC_W),
    .COUT_W(COUT_W)
  ) u_postprocess (
    .mac_in(mac_value),
    .bias(bias),
    .out_ch(out_ch),
    .pixel_out(processed_value)
  );

  multich_conv2d_done_logic #(
    .OUT_N(OUT_N),
    .OUT_CNT_W(OUT_CNT_W)
  ) u_done_logic (
    .out_count(out_count),
    .all_outputs_sent(all_outputs_sent)
  );

  integer si;
  always @(posedge clk) begin
    if (rst) begin
      in_count <= {CNT_W{1'b0}};
      out_count <= {OUT_CNT_W{1'b0}};
      emitting <= 1'b0;
      pixel_out <= {OUT_W{1'b0}};
      valid_out <= 1'b0;
      done <= 1'b0;
      for (si = 0; si < IN_N; si = si + 1)
        image_mem[si] <= {DATA_W{1'b0}};
    end else begin
      valid_out <= 1'b0;

      if (valid_in && !emitting) begin
        image_mem[in_count] <= pixel_in;
        if (last_in || in_count == IN_N-1)
          emitting <= 1'b1;
        if (in_count != IN_N)
          in_count <= in_count + 1'b1;
      end

      if (emitting && !all_outputs_sent) begin
        pixel_out <= processed_value;
        valid_out <= 1'b1;
        out_count <= out_count + 1'b1;
      end

      if (emitting && all_outputs_sent) begin
        done <= 1'b1;
      end
    end
  end

endmodule
`timescale 1ns/1ps

module conv3d_window_valid #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64
) (
    input  [31:0] d,
    input  [31:0] h,
    input  [31:0] w,
    input         valid_in,
    output        window_valid
);

generate
    if ((D >= K1) && (H >= K2) && (W >= K3)) begin : gen_has_windows
        localparam [31:0] MIN_D = K1 - 1;
        localparam [31:0] MIN_H = K2 - 1;
        localparam [31:0] MIN_W = K3 - 1;
        localparam [31:0] MAX_D = D;
        localparam [31:0] MAX_H = H;
        localparam [31:0] MAX_W = W;

        assign window_valid =
            valid_in &&
            (d >= MIN_D) && (d < MAX_D) &&
            (h >= MIN_H) && (h < MAX_H) &&
            (w >= MIN_W) && (w < MAX_W);
    end else begin : gen_no_windows
        assign window_valid = 1'b0;
    end
endgenerate

endmodule
`timescale 1ns/1ps

module unsharp_window3x3 #(
    parameter IMG_WIDTH = 256,
    parameter IMG_HEIGHT = 256,
    parameter PIXEL_W = 8
) (
    input [31:0] x,
    input [31:0] y,

    input [PIXEL_W-1:0] row0_d2,
    input [PIXEL_W-1:0] row0_d1,
    input [PIXEL_W-1:0] row0_cur,

    input [PIXEL_W-1:0] row1_d2,
    input [PIXEL_W-1:0] row1_d1,
    input [PIXEL_W-1:0] row1_cur,

    input [PIXEL_W-1:0] row2_d2,
    input [PIXEL_W-1:0] row2_d1,
    input [PIXEL_W-1:0] row2_cur,

    output [PIXEL_W-1:0] w00,
    output [PIXEL_W-1:0] w01,
    output [PIXEL_W-1:0] w02,
    output [PIXEL_W-1:0] w10,
    output [PIXEL_W-1:0] w11,
    output [PIXEL_W-1:0] w12,
    output [PIXEL_W-1:0] w20,
    output [PIXEL_W-1:0] w21,
    output [PIXEL_W-1:0] w22
);

  assign w00 = (y == 0 || x == 0) ? {PIXEL_W{1'b0}} : row1_d1;
  assign w01 = (y == 0)           ? {PIXEL_W{1'b0}} : row1_cur;
  assign w02 = {PIXEL_W{1'b0}};

  assign w10 = (x == 0)           ? {PIXEL_W{1'b0}} : row2_d1;
  assign w11 = row2_cur;
  assign w12 = {PIXEL_W{1'b0}};

  assign w20 = {PIXEL_W{1'b0}};
  assign w21 = {PIXEL_W{1'b0}};
  assign w22 = {PIXEL_W{1'b0}};

endmodule
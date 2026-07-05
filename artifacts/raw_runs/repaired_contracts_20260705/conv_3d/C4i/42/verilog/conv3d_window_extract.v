`timescale 1ns/1ps

module conv3d_window_extract #(
    parameter K1 = 3,
    parameter K2 = 3,
    parameter K3 = 3,
    parameter D = 8,
    parameter H = 64,
    parameter W = 64,
    parameter DATA_W = 8,
    parameter COUNT_W = 32
) (
    input volume_mem_flat_dummy,
    input [COUNT_W-1:0] current_idx,
    input [DATA_W-1:0] current_voxel,
    input [COUNT_W-1:0] z_pos,
    input [COUNT_W-1:0] y_pos,
    input [COUNT_W-1:0] x_pos,
    input [DATA_W-1:0] mem0,
    input [DATA_W-1:0] mem1,
    input [DATA_W-1:0] mem2,
    input [DATA_W-1:0] mem3,
    input [DATA_W-1:0] mem4,
    input [DATA_W-1:0] mem5,
    input [DATA_W-1:0] mem6,
    input [DATA_W-1:0] mem7,
    input [DATA_W-1:0] mem8,
    input [DATA_W-1:0] mem9,
    input [DATA_W-1:0] mem10,
    input [DATA_W-1:0] mem11,
    input [DATA_W-1:0] mem12,
    input [DATA_W-1:0] mem13,
    input [DATA_W-1:0] mem14,
    input [DATA_W-1:0] mem15,
    input [DATA_W-1:0] mem16,
    input [DATA_W-1:0] mem17,
    input [DATA_W-1:0] mem18,
    input [DATA_W-1:0] mem19,
    input [DATA_W-1:0] mem20,
    input [DATA_W-1:0] mem21,
    input [DATA_W-1:0] mem22,
    input [DATA_W-1:0] mem23,
    input [DATA_W-1:0] mem24,
    input [DATA_W-1:0] mem25,
    input [DATA_W-1:0] mem26,
    output [K1*K2*K3*DATA_W-1:0] window_flat
);

    assign window_flat[0*DATA_W +: DATA_W]  = mem0;
    assign window_flat[1*DATA_W +: DATA_W]  = mem1;
    assign window_flat[2*DATA_W +: DATA_W]  = mem2;
    assign window_flat[3*DATA_W +: DATA_W]  = mem3;
    assign window_flat[4*DATA_W +: DATA_W]  = mem4;
    assign window_flat[5*DATA_W +: DATA_W]  = mem5;
    assign window_flat[6*DATA_W +: DATA_W]  = mem6;
    assign window_flat[7*DATA_W +: DATA_W]  = mem7;
    assign window_flat[8*DATA_W +: DATA_W]  = mem8;
    assign window_flat[9*DATA_W +: DATA_W]  = mem9;
    assign window_flat[10*DATA_W +: DATA_W] = mem10;
    assign window_flat[11*DATA_W +: DATA_W] = mem11;
    assign window_flat[12*DATA_W +: DATA_W] = mem12;
    assign window_flat[13*DATA_W +: DATA_W] = mem13;
    assign window_flat[14*DATA_W +: DATA_W] = mem14;
    assign window_flat[15*DATA_W +: DATA_W] = mem15;
    assign window_flat[16*DATA_W +: DATA_W] = mem16;
    assign window_flat[17*DATA_W +: DATA_W] = mem17;
    assign window_flat[18*DATA_W +: DATA_W] = mem18;
    assign window_flat[19*DATA_W +: DATA_W] = mem19;
    assign window_flat[20*DATA_W +: DATA_W] = mem20;
    assign window_flat[21*DATA_W +: DATA_W] = mem21;
    assign window_flat[22*DATA_W +: DATA_W] = mem22;
    assign window_flat[23*DATA_W +: DATA_W] = mem23;
    assign window_flat[24*DATA_W +: DATA_W] = mem24;
    assign window_flat[25*DATA_W +: DATA_W] = mem25;
    assign window_flat[26*DATA_W +: DATA_W] = current_voxel;

endmodule
`timescale 1ns/1ps

module input_boundary_buffer(a_west0, a_west1, a_west2, a_west3,
                             b_north0, b_north1, b_north2, b_north3,
                             west0, west1, west2, west3,
                             north0, north1, north2, north3);
    input [31:0] a_west0, a_west1, a_west2, a_west3;
    input [31:0] b_north0, b_north1, b_north2, b_north3;

    output [31:0] west0, west1, west2, west3;
    output [31:0] north0, north1, north2, north3;

    assign west0 = a_west0;
    assign west1 = a_west1;
    assign west2 = a_west2;
    assign west3 = a_west3;

    assign north0 = b_north0;
    assign north1 = b_north1;
    assign north2 = b_north2;
    assign north3 = b_north3;
endmodule
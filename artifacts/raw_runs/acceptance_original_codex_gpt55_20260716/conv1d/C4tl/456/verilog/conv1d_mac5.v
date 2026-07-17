`timescale 1ns/1ps

module conv1d_mac5 #(
    parameter DATA_W = 8,
    parameter GAIN_W = 4
) (
    input  [DATA_W*5-1:0]           window_flat,
    output [DATA_W+GAIN_W+3-1:0]    mac_sum
);

    localparam MAC_W = DATA_W + GAIN_W + 3;

    wire [DATA_W-1:0] x0;
    wire [DATA_W-1:0] x1;
    wire [DATA_W-1:0] x2;
    wire [DATA_W-1:0] x3;
    wire [DATA_W-1:0] x4;

    wire [MAC_W-1:0] x0_ext;
    wire [MAC_W-1:0] x1_ext;
    wire [MAC_W-1:0] x2_ext;
    wire [MAC_W-1:0] x3_ext;
    wire [MAC_W-1:0] x4_ext;

    assign x0 = window_flat[(DATA_W*1)-1 : DATA_W*0];
    assign x1 = window_flat[(DATA_W*2)-1 : DATA_W*1];
    assign x2 = window_flat[(DATA_W*3)-1 : DATA_W*2];
    assign x3 = window_flat[(DATA_W*4)-1 : DATA_W*3];
    assign x4 = window_flat[(DATA_W*5)-1 : DATA_W*4];

    assign x0_ext = {{(MAC_W-DATA_W){1'b0}}, x0};
    assign x1_ext = {{(MAC_W-DATA_W){1'b0}}, x1};
    assign x2_ext = {{(MAC_W-DATA_W){1'b0}}, x2};
    assign x3_ext = {{(MAC_W-DATA_W){1'b0}}, x3};
    assign x4_ext = {{(MAC_W-DATA_W){1'b0}}, x4};

    assign mac_sum =
        (x0_ext << 1) +
        (x1_ext << 3) +
        ((x2_ext << 3) + (x2_ext << 2)) +
        (x3_ext << 3) +
        (x4_ext << 1);

endmodule
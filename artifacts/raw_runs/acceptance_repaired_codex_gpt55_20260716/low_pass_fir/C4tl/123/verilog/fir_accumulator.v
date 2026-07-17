`timescale 1ns/1ps

module fir_accumulator #(
    parameter ACC_W = 64
) (
    input signed [31:0] p0,  input signed [31:0] p1,  input signed [31:0] p2,
    input signed [31:0] p3,  input signed [31:0] p4,  input signed [31:0] p5,
    input signed [31:0] p6,  input signed [31:0] p7,  input signed [31:0] p8,
    input signed [31:0] p9,  input signed [31:0] p10, input signed [31:0] p11,
    input signed [31:0] p12, input signed [31:0] p13, input signed [31:0] p14,
    input signed [31:0] p15, input signed [31:0] p16, input signed [31:0] p17,
    input signed [31:0] p18, input signed [31:0] p19, input signed [31:0] p20,
    input signed [31:0] p21, input signed [31:0] p22, input signed [31:0] p23,
    input signed [31:0] p24, input signed [31:0] p25, input signed [31:0] p26,
    input signed [31:0] p27, input signed [31:0] p28, input signed [31:0] p29,
    input signed [31:0] p30, input signed [31:0] p31, input signed [31:0] p32,
    input signed [31:0] p33, input signed [31:0] p34, input signed [31:0] p35,
    input signed [31:0] p36, input signed [31:0] p37, input signed [31:0] p38,
    input signed [31:0] p39, input signed [31:0] p40, input signed [31:0] p41,
    input signed [31:0] p42, input signed [31:0] p43, input signed [31:0] p44,
    input signed [31:0] p45, input signed [31:0] p46, input signed [31:0] p47,
    input signed [31:0] p48, input signed [31:0] p49, input signed [31:0] p50,
    output signed [ACC_W-1:0] acc
);
    assign acc =
        $signed(p0)  + $signed(p1)  + $signed(p2)  + $signed(p3)  +
        $signed(p4)  + $signed(p5)  + $signed(p6)  + $signed(p7)  +
        $signed(p8)  + $signed(p9)  + $signed(p10) + $signed(p11) +
        $signed(p12) + $signed(p13) + $signed(p14) + $signed(p15) +
        $signed(p16) + $signed(p17) + $signed(p18) + $signed(p19) +
        $signed(p20) + $signed(p21) + $signed(p22) + $signed(p23) +
        $signed(p24) + $signed(p25) + $signed(p26) + $signed(p27) +
        $signed(p28) + $signed(p29) + $signed(p30) + $signed(p31) +
        $signed(p32) + $signed(p33) + $signed(p34) + $signed(p35) +
        $signed(p36) + $signed(p37) + $signed(p38) + $signed(p39) +
        $signed(p40) + $signed(p41) + $signed(p42) + $signed(p43) +
        $signed(p44) + $signed(p45) + $signed(p46) + $signed(p47) +
        $signed(p48) + $signed(p49) + $signed(p50);
endmodule
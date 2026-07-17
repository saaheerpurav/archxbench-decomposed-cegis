`timescale 1ns/1ps

module fir_sum_tree_101 #(
    parameter PROD_W = 36,
    parameter ACC_W  = 64
) (
    input signed [PROD_W-1:0] p0,   input signed [PROD_W-1:0] p1,   input signed [PROD_W-1:0] p2,
    input signed [PROD_W-1:0] p3,   input signed [PROD_W-1:0] p4,   input signed [PROD_W-1:0] p5,
    input signed [PROD_W-1:0] p6,   input signed [PROD_W-1:0] p7,   input signed [PROD_W-1:0] p8,
    input signed [PROD_W-1:0] p9,   input signed [PROD_W-1:0] p10,  input signed [PROD_W-1:0] p11,
    input signed [PROD_W-1:0] p12,  input signed [PROD_W-1:0] p13,  input signed [PROD_W-1:0] p14,
    input signed [PROD_W-1:0] p15,  input signed [PROD_W-1:0] p16,  input signed [PROD_W-1:0] p17,
    input signed [PROD_W-1:0] p18,  input signed [PROD_W-1:0] p19,  input signed [PROD_W-1:0] p20,
    input signed [PROD_W-1:0] p21,  input signed [PROD_W-1:0] p22,  input signed [PROD_W-1:0] p23,
    input signed [PROD_W-1:0] p24,  input signed [PROD_W-1:0] p25,  input signed [PROD_W-1:0] p26,
    input signed [PROD_W-1:0] p27,  input signed [PROD_W-1:0] p28,  input signed [PROD_W-1:0] p29,
    input signed [PROD_W-1:0] p30,  input signed [PROD_W-1:0] p31,  input signed [PROD_W-1:0] p32,
    input signed [PROD_W-1:0] p33,  input signed [PROD_W-1:0] p34,  input signed [PROD_W-1:0] p35,
    input signed [PROD_W-1:0] p36,  input signed [PROD_W-1:0] p37,  input signed [PROD_W-1:0] p38,
    input signed [PROD_W-1:0] p39,  input signed [PROD_W-1:0] p40,  input signed [PROD_W-1:0] p41,
    input signed [PROD_W-1:0] p42,  input signed [PROD_W-1:0] p43,  input signed [PROD_W-1:0] p44,
    input signed [PROD_W-1:0] p45,  input signed [PROD_W-1:0] p46,  input signed [PROD_W-1:0] p47,
    input signed [PROD_W-1:0] p48,  input signed [PROD_W-1:0] p49,  input signed [PROD_W-1:0] p50,
    input signed [PROD_W-1:0] p51,  input signed [PROD_W-1:0] p52,  input signed [PROD_W-1:0] p53,
    input signed [PROD_W-1:0] p54,  input signed [PROD_W-1:0] p55,  input signed [PROD_W-1:0] p56,
    input signed [PROD_W-1:0] p57,  input signed [PROD_W-1:0] p58,  input signed [PROD_W-1:0] p59,
    input signed [PROD_W-1:0] p60,  input signed [PROD_W-1:0] p61,  input signed [PROD_W-1:0] p62,
    input signed [PROD_W-1:0] p63,  input signed [PROD_W-1:0] p64,  input signed [PROD_W-1:0] p65,
    input signed [PROD_W-1:0] p66,  input signed [PROD_W-1:0] p67,  input signed [PROD_W-1:0] p68,
    input signed [PROD_W-1:0] p69,  input signed [PROD_W-1:0] p70,  input signed [PROD_W-1:0] p71,
    input signed [PROD_W-1:0] p72,  input signed [PROD_W-1:0] p73,  input signed [PROD_W-1:0] p74,
    input signed [PROD_W-1:0] p75,  input signed [PROD_W-1:0] p76,  input signed [PROD_W-1:0] p77,
    input signed [PROD_W-1:0] p78,  input signed [PROD_W-1:0] p79,  input signed [PROD_W-1:0] p80,
    input signed [PROD_W-1:0] p81,  input signed [PROD_W-1:0] p82,  input signed [PROD_W-1:0] p83,
    input signed [PROD_W-1:0] p84,  input signed [PROD_W-1:0] p85,  input signed [PROD_W-1:0] p86,
    input signed [PROD_W-1:0] p87,  input signed [PROD_W-1:0] p88,  input signed [PROD_W-1:0] p89,
    input signed [PROD_W-1:0] p90,  input signed [PROD_W-1:0] p91,  input signed [PROD_W-1:0] p92,
    input signed [PROD_W-1:0] p93,  input signed [PROD_W-1:0] p94,  input signed [PROD_W-1:0] p95,
    input signed [PROD_W-1:0] p96,  input signed [PROD_W-1:0] p97,  input signed [PROD_W-1:0] p98,
    input signed [PROD_W-1:0] p99,  input signed [PROD_W-1:0] p100,
    output reg signed [ACC_W-1:0] sum
);

    function signed [ACC_W-1:0] ext;
        input signed [PROD_W-1:0] value;
        begin
            ext = {{(ACC_W-PROD_W){value[PROD_W-1]}}, value};
        end
    endfunction

    always @* begin
        sum =
            ext(p0)   + ext(p1)   + ext(p2)   + ext(p3)   + ext(p4)   +
            ext(p5)   + ext(p6)   + ext(p7)   + ext(p8)   + ext(p9)   +
            ext(p10)  + ext(p11)  + ext(p12)  + ext(p13)  + ext(p14)  +
            ext(p15)  + ext(p16)  + ext(p17)  + ext(p18)  + ext(p19)  +
            ext(p20)  + ext(p21)  + ext(p22)  + ext(p23)  + ext(p24)  +
            ext(p25)  + ext(p26)  + ext(p27)  + ext(p28)  + ext(p29)  +
            ext(p30)  + ext(p31)  + ext(p32)  + ext(p33)  + ext(p34)  +
            ext(p35)  + ext(p36)  + ext(p37)  + ext(p38)  + ext(p39)  +
            ext(p40)  + ext(p41)  + ext(p42)  + ext(p43)  + ext(p44)  +
            ext(p45)  + ext(p46)  + ext(p47)  + ext(p48)  + ext(p49)  +
            ext(p50)  + ext(p51)  + ext(p52)  + ext(p53)  + ext(p54)  +
            ext(p55)  + ext(p56)  + ext(p57)  + ext(p58)  + ext(p59)  +
            ext(p60)  + ext(p61)  + ext(p62)  + ext(p63)  + ext(p64)  +
            ext(p65)  + ext(p66)  + ext(p67)  + ext(p68)  + ext(p69)  +
            ext(p70)  + ext(p71)  + ext(p72)  + ext(p73)  + ext(p74)  +
            ext(p75)  + ext(p76)  + ext(p77)  + ext(p78)  + ext(p79)  +
            ext(p80)  + ext(p81)  + ext(p82)  + ext(p83)  + ext(p84)  +
            ext(p85)  + ext(p86)  + ext(p87)  + ext(p88)  + ext(p89)  +
            ext(p90)  + ext(p91)  + ext(p92)  + ext(p93)  + ext(p94)  +
            ext(p95)  + ext(p96)  + ext(p97)  + ext(p98)  + ext(p99)  +
            ext(p100);
    end

endmodule
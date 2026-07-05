module assign_result_outputs(
    c00, c01, c02, c03,
    c10, c11, c12, c13,
    c20, c21, c22, c23,
    c30, c31, c32, c33,
    result0, result1, result2, result3,
    result4, result5, result6, result7,
    result8, result9, result10, result11,
    result12, result13, result14, result15
);
    input [63:0] c00, c01, c02, c03;
    input [63:0] c10, c11, c12, c13;
    input [63:0] c20, c21, c22, c23;
    input [63:0] c30, c31, c32, c33;
    output [63:0] result0, result1, result2, result3;
    output [63:0] result4, result5, result6, result7;
    output [63:0] result8, result9, result10, result11;
    output [63:0] result12, result13, result14, result15;

    assign result0  = c00;
    assign result1  = c01;
    assign result2  = c02;
    assign result3  = c03;
    assign result4  = c10;
    assign result5  = c11;
    assign result6  = c12;
    assign result7  = c13;
    assign result8  = c20;
    assign result9  = c21;
    assign result10 = c22;
    assign result11 = c23;
    assign result12 = c30;
    assign result13 = c31;
    assign result14 = c32;
    assign result15 = c33;
endmodule
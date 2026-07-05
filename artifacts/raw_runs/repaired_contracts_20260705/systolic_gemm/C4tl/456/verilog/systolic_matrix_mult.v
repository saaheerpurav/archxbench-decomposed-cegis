module systolic_matrix_mult(a_west0, a_west1, a_west2, a_west3,
                           b_north0, b_north1, b_north2, b_north3,
                           clk, rst, done,
                           result0, result1, result2, result3,
                           result4, result5, result6, result7,
                           result8, result9, result10, result11,
                           result12, result13, result14, result15);

    input [31:0] a_west0, a_west1, a_west2, a_west3,
                 b_north0, b_north1, b_north2, b_north3;
    input clk, rst;
    output reg done;
    output [63:0] result0, result1, result2, result3,
                  result4, result5, result6, result7,
                  result8, result9, result10, result11,
                  result12, result13, result14, result15;

    reg [3:0] cycle_count;

    reg [31:0] a00, a01, a02, a03;
    reg [31:0] a10, a11, a12, a13;
    reg [31:0] a20, a21, a22, a23;
    reg [31:0] a30, a31, a32, a33;

    reg [31:0] b00, b01, b02, b03;
    reg [31:0] b10, b11, b12, b13;
    reg [31:0] b20, b21, b22, b23;
    reg [31:0] b30, b31, b32, b33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    wire [63:0] next_acc00, next_acc01, next_acc02, next_acc03;
    wire [63:0] next_acc10, next_acc11, next_acc12, next_acc13;
    wire [63:0] next_acc20, next_acc21, next_acc22, next_acc23;
    wire [63:0] next_acc30, next_acc31, next_acc32, next_acc33;

    mac_accumulate m00(a_west0, b_north0, acc00, next_acc00);
    mac_accumulate m01(a00,     b_north1, acc01, next_acc01);
    mac_accumulate m02(a01,     b_north2, acc02, next_acc02);
    mac_accumulate m03(a02,     b_north3, acc03, next_acc03);

    mac_accumulate m10(a_west1, b00,      acc10, next_acc10);
    mac_accumulate m11(a10,     b01,      acc11, next_acc11);
    mac_accumulate m12(a11,     b02,      acc12, next_acc12);
    mac_accumulate m13(a12,     b03,      acc13, next_acc13);

    mac_accumulate m20(a_west2, b10,      acc20, next_acc20);
    mac_accumulate m21(a20,     b11,      acc21, next_acc21);
    mac_accumulate m22(a21,     b12,      acc22, next_acc22);
    mac_accumulate m23(a22,     b13,      acc23, next_acc23);

    mac_accumulate m30(a_west3, b20,      acc30, next_acc30);
    mac_accumulate m31(a30,     b21,      acc31, next_acc31);
    mac_accumulate m32(a31,     b22,      acc32, next_acc32);
    mac_accumulate m33(a32,     b23,      acc33, next_acc33);

    assign_result_outputs result_bus(
        acc00, acc01, acc02, acc03,
        acc10, acc11, acc12, acc13,
        acc20, acc21, acc22, acc23,
        acc30, acc31, acc32, acc33,
        result0, result1, result2, result3,
        result4, result5, result6, result7,
        result8, result9, result10, result11,
        result12, result13, result14, result15
    );

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;

            a00 <= 32'd0; a01 <= 32'd0; a02 <= 32'd0; a03 <= 32'd0;
            a10 <= 32'd0; a11 <= 32'd0; a12 <= 32'd0; a13 <= 32'd0;
            a20 <= 32'd0; a21 <= 32'd0; a22 <= 32'd0; a23 <= 32'd0;
            a30 <= 32'd0; a31 <= 32'd0; a32 <= 32'd0; a33 <= 32'd0;

            b00 <= 32'd0; b01 <= 32'd0; b02 <= 32'd0; b03 <= 32'd0;
            b10 <= 32'd0; b11 <= 32'd0; b12 <= 32'd0; b13 <= 32'd0;
            b20 <= 32'd0; b21 <= 32'd0; b22 <= 32'd0; b23 <= 32'd0;
            b30 <= 32'd0; b31 <= 32'd0; b32 <= 32'd0; b33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;
        end else begin
            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;
            done <= (cycle_count >= 4'd8);

            acc00 <= next_acc00; acc01 <= next_acc01; acc02 <= next_acc02; acc03 <= next_acc03;
            acc10 <= next_acc10; acc11 <= next_acc11; acc12 <= next_acc12; acc13 <= next_acc13;
            acc20 <= next_acc20; acc21 <= next_acc21; acc22 <= next_acc22; acc23 <= next_acc23;
            acc30 <= next_acc30; acc31 <= next_acc31; acc32 <= next_acc32; acc33 <= next_acc33;

            a00 <= a_west0; a01 <= a00; a02 <= a01; a03 <= a02;
            a10 <= a_west1; a11 <= a10; a12 <= a11; a13 <= a12;
            a20 <= a_west2; a21 <= a20; a22 <= a21; a23 <= a22;
            a30 <= a_west3; a31 <= a30; a32 <= a31; a33 <= a32;

            b00 <= b_north0; b10 <= b00; b20 <= b10; b30 <= b20;
            b01 <= b_north1; b11 <= b01; b21 <= b11; b31 <= b21;
            b02 <= b_north2; b12 <= b02; b22 <= b12; b32 <= b22;
            b03 <= b_north3; b13 <= b03; b23 <= b13; b33 <= b23;
        end
    end
endmodule
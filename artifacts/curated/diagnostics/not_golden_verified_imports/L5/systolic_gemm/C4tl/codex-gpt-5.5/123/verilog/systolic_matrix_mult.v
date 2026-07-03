module systolic_matrix_mult(a_west0, a_west1, a_west2, a_west3,
                           b_north0, b_north1, b_north2, b_north3,
                           clk, rst, done,
                           result0, result1, result2, result3,
                           result4, result5, result6, result7,
                           result8, result9, result10, result11,
                           result12, result13, result14, result15);

    input [31:0] a_west0, a_west1, a_west2, a_west3,
                 b_north0, b_north1, b_north2, b_north3;
    output reg done;
    input clk, rst;
    output [63:0] result0, result1, result2, result3,
                  result4, result5, result6, result7,
                  result8, result9, result10, result11,
                  result12, result13, result14, result15;

    reg [31:0] a00, a01, a02, a03;
    reg [31:0] a10, a11, a12, a13;
    reg [31:0] a20, a21, a22, a23;
    reg [31:0] a30, a31, a32, a33;

    reg [31:0] b00, b01, b02, b03;
    reg [31:0] b10, b11, b12, b13;
    reg [31:0] b20, b21, b22, b23;
    reg [31:0] b30, b31, b32, b33;

    reg [63:0] c00, c01, c02, c03;
    reg [63:0] c10, c11, c12, c13;
    reg [63:0] c20, c21, c22, c23;
    reg [63:0] c30, c31, c32, c33;

    reg [3:0] cycle_count;

    wire [31:0] pe_s00, pe_s01, pe_s02, pe_s03;
    wire [31:0] pe_s10, pe_s11, pe_s12, pe_s13;
    wire [31:0] pe_s20, pe_s21, pe_s22, pe_s23;
    wire [31:0] pe_s30, pe_s31, pe_s32, pe_s33;

    wire [31:0] pe_e00, pe_e01, pe_e02, pe_e03;
    wire [31:0] pe_e10, pe_e11, pe_e12, pe_e13;
    wire [31:0] pe_e20, pe_e21, pe_e22, pe_e23;
    wire [31:0] pe_e30, pe_e31, pe_e32, pe_e33;

    wire [63:0] pe_c00, pe_c01, pe_c02, pe_c03;
    wire [63:0] pe_c10, pe_c11, pe_c12, pe_c13;
    wire [63:0] pe_c20, pe_c21, pe_c22, pe_c23;
    wire [63:0] pe_c30, pe_c31, pe_c32, pe_c33;

    pe_compute u_pe00(a00, b00, c00, pe_e00, pe_s00, pe_c00);
    pe_compute u_pe01(a01, b01, c01, pe_e01, pe_s01, pe_c01);
    pe_compute u_pe02(a02, b02, c02, pe_e02, pe_s02, pe_c02);
    pe_compute u_pe03(a03, b03, c03, pe_e03, pe_s03, pe_c03);

    pe_compute u_pe10(a10, b10, c10, pe_e10, pe_s10, pe_c10);
    pe_compute u_pe11(a11, b11, c11, pe_e11, pe_s11, pe_c11);
    pe_compute u_pe12(a12, b12, c12, pe_e12, pe_s12, pe_c12);
    pe_compute u_pe13(a13, b13, c13, pe_e13, pe_s13, pe_c13);

    pe_compute u_pe20(a20, b20, c20, pe_e20, pe_s20, pe_c20);
    pe_compute u_pe21(a21, b21, c21, pe_e21, pe_s21, pe_c21);
    pe_compute u_pe22(a22, b22, c22, pe_e22, pe_s22, pe_c22);
    pe_compute u_pe23(a23, b23, c23, pe_e23, pe_s23, pe_c23);

    pe_compute u_pe30(a30, b30, c30, pe_e30, pe_s30, pe_c30);
    pe_compute u_pe31(a31, b31, c31, pe_e31, pe_s31, pe_c31);
    pe_compute u_pe32(a32, b32, c32, pe_e32, pe_s32, pe_c32);
    pe_compute u_pe33(a33, b33, c33, pe_e33, pe_s33, pe_c33);

    wire done_next;
    cycle_done_logic u_done_logic(cycle_count, done_next);

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

    always @(posedge clk) begin
        if (rst) begin
            a00 <= 0; a01 <= 0; a02 <= 0; a03 <= 0;
            a10 <= 0; a11 <= 0; a12 <= 0; a13 <= 0;
            a20 <= 0; a21 <= 0; a22 <= 0; a23 <= 0;
            a30 <= 0; a31 <= 0; a32 <= 0; a33 <= 0;

            b00 <= 0; b01 <= 0; b02 <= 0; b03 <= 0;
            b10 <= 0; b11 <= 0; b12 <= 0; b13 <= 0;
            b20 <= 0; b21 <= 0; b22 <= 0; b23 <= 0;
            b30 <= 0; b31 <= 0; b32 <= 0; b33 <= 0;

            c00 <= 0; c01 <= 0; c02 <= 0; c03 <= 0;
            c10 <= 0; c11 <= 0; c12 <= 0; c13 <= 0;
            c20 <= 0; c21 <= 0; c22 <= 0; c23 <= 0;
            c30 <= 0; c31 <= 0; c32 <= 0; c33 <= 0;

            cycle_count <= 0;
            done <= 0;
        end else begin
            a00 <= a_west0; a01 <= pe_e00; a02 <= pe_e01; a03 <= pe_e02;
            a10 <= a_west1; a11 <= pe_e10; a12 <= pe_e11; a13 <= pe_e12;
            a20 <= a_west2; a21 <= pe_e20; a22 <= pe_e21; a23 <= pe_e22;
            a30 <= a_west3; a31 <= pe_e30; a32 <= pe_e31; a33 <= pe_e32;

            b00 <= b_north0; b01 <= b_north1; b02 <= b_north2; b03 <= b_north3;
            b10 <= pe_s00;  b11 <= pe_s01;  b12 <= pe_s02;  b13 <= pe_s03;
            b20 <= pe_s10;  b21 <= pe_s11;  b22 <= pe_s12;  b23 <= pe_s13;
            b30 <= pe_s20;  b31 <= pe_s21;  b32 <= pe_s22;  b33 <= pe_s23;

            c00 <= pe_c00; c01 <= pe_c01; c02 <= pe_c02; c03 <= pe_c03;
            c10 <= pe_c10; c11 <= pe_c11; c12 <= pe_c12; c13 <= pe_c13;
            c20 <= pe_c20; c21 <= pe_c21; c22 <= pe_c22; c23 <= pe_c23;
            c30 <= pe_c30; c31 <= pe_c31; c32 <= pe_c32; c33 <= pe_c33;

            if (cycle_count < 9)
                cycle_count <= cycle_count + 1'b1;
            else
                cycle_count <= cycle_count;

            done <= done_next;
        end
    end
endmodule
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

    reg [31:0] a_reg00, a_reg01, a_reg02, a_reg03;
    reg [31:0] a_reg10, a_reg11, a_reg12, a_reg13;
    reg [31:0] a_reg20, a_reg21, a_reg22, a_reg23;
    reg [31:0] a_reg30, a_reg31, a_reg32, a_reg33;

    reg [31:0] b_reg00, b_reg01, b_reg02, b_reg03;
    reg [31:0] b_reg10, b_reg11, b_reg12, b_reg13;
    reg [31:0] b_reg20, b_reg21, b_reg22, b_reg23;
    reg [31:0] b_reg30, b_reg31, b_reg32, b_reg33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    wire [63:0] prod00, prod01, prod02, prod03;
    wire [63:0] prod10, prod11, prod12, prod13;
    wire [63:0] prod20, prod21, prod22, prod23;
    wire [63:0] prod30, prod31, prod32, prod33;

    wire [31:0] unused_s00, unused_s01, unused_s02, unused_s03;
    wire [31:0] unused_s10, unused_s11, unused_s12, unused_s13;
    wire [31:0] unused_s20, unused_s21, unused_s22, unused_s23;
    wire [31:0] unused_s30, unused_s31, unused_s32, unused_s33;

    wire [31:0] unused_e00, unused_e01, unused_e02, unused_e03;
    wire [31:0] unused_e10, unused_e11, unused_e12, unused_e13;
    wire [31:0] unused_e20, unused_e21, unused_e22, unused_e23;
    wire [31:0] unused_e30, unused_e31, unused_e32, unused_e33;

    pe pe00(b_reg00, a_reg00, clk, rst, unused_s00, unused_e00, prod00);
    pe pe01(b_reg01, a_reg01, clk, rst, unused_s01, unused_e01, prod01);
    pe pe02(b_reg02, a_reg02, clk, rst, unused_s02, unused_e02, prod02);
    pe pe03(b_reg03, a_reg03, clk, rst, unused_s03, unused_e03, prod03);

    pe pe10(b_reg10, a_reg10, clk, rst, unused_s10, unused_e10, prod10);
    pe pe11(b_reg11, a_reg11, clk, rst, unused_s11, unused_e11, prod11);
    pe pe12(b_reg12, a_reg12, clk, rst, unused_s12, unused_e12, prod12);
    pe pe13(b_reg13, a_reg13, clk, rst, unused_s13, unused_e13, prod13);

    pe pe20(b_reg20, a_reg20, clk, rst, unused_s20, unused_e20, prod20);
    pe pe21(b_reg21, a_reg21, clk, rst, unused_s21, unused_e21, prod21);
    pe pe22(b_reg22, a_reg22, clk, rst, unused_s22, unused_e22, prod22);
    pe pe23(b_reg23, a_reg23, clk, rst, unused_s23, unused_e23, prod23);

    pe pe30(b_reg30, a_reg30, clk, rst, unused_s30, unused_e30, prod30);
    pe pe31(b_reg31, a_reg31, clk, rst, unused_s31, unused_e31, prod31);
    pe pe32(b_reg32, a_reg32, clk, rst, unused_s32, unused_e32, prod32);
    pe pe33(b_reg33, a_reg33, clk, rst, unused_s33, unused_e33, prod33);

    assign result0  = acc00;
    assign result1  = acc01;
    assign result2  = acc02;
    assign result3  = acc03;
    assign result4  = acc10;
    assign result5  = acc11;
    assign result6  = acc12;
    assign result7  = acc13;
    assign result8  = acc20;
    assign result9  = acc21;
    assign result10 = acc22;
    assign result11 = acc23;
    assign result12 = acc30;
    assign result13 = acc31;
    assign result14 = acc32;
    assign result15 = acc33;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;

            a_reg00 <= 32'd0; a_reg01 <= 32'd0; a_reg02 <= 32'd0; a_reg03 <= 32'd0;
            a_reg10 <= 32'd0; a_reg11 <= 32'd0; a_reg12 <= 32'd0; a_reg13 <= 32'd0;
            a_reg20 <= 32'd0; a_reg21 <= 32'd0; a_reg22 <= 32'd0; a_reg23 <= 32'd0;
            a_reg30 <= 32'd0; a_reg31 <= 32'd0; a_reg32 <= 32'd0; a_reg33 <= 32'd0;

            b_reg00 <= 32'd0; b_reg01 <= 32'd0; b_reg02 <= 32'd0; b_reg03 <= 32'd0;
            b_reg10 <= 32'd0; b_reg11 <= 32'd0; b_reg12 <= 32'd0; b_reg13 <= 32'd0;
            b_reg20 <= 32'd0; b_reg21 <= 32'd0; b_reg22 <= 32'd0; b_reg23 <= 32'd0;
            b_reg30 <= 32'd0; b_reg31 <= 32'd0; b_reg32 <= 32'd0; b_reg33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;
        end else begin
            cycle_count <= (cycle_count < 4'd9) ? cycle_count + 4'd1 : cycle_count;
            done <= (cycle_count >= 4'd8);

            acc00 <= acc00 + prod00; acc01 <= acc01 + prod01; acc02 <= acc02 + prod02; acc03 <= acc03 + prod03;
            acc10 <= acc10 + prod10; acc11 <= acc11 + prod11; acc12 <= acc12 + prod12; acc13 <= acc13 + prod13;
            acc20 <= acc20 + prod20; acc21 <= acc21 + prod21; acc22 <= acc22 + prod22; acc23 <= acc23 + prod23;
            acc30 <= acc30 + prod30; acc31 <= acc31 + prod31; acc32 <= acc32 + prod32; acc33 <= acc33 + prod33;

            a_reg00 <= a_west0; a_reg01 <= a_reg00; a_reg02 <= a_reg01; a_reg03 <= a_reg02;
            a_reg10 <= a_west1; a_reg11 <= a_reg10; a_reg12 <= a_reg11; a_reg13 <= a_reg12;
            a_reg20 <= a_west2; a_reg21 <= a_reg20; a_reg22 <= a_reg21; a_reg23 <= a_reg22;
            a_reg30 <= a_west3; a_reg31 <= a_reg30; a_reg32 <= a_reg31; a_reg33 <= a_reg32;

            b_reg00 <= b_north0; b_reg10 <= b_reg00; b_reg20 <= b_reg10; b_reg30 <= b_reg20;
            b_reg01 <= b_north1; b_reg11 <= b_reg01; b_reg21 <= b_reg11; b_reg31 <= b_reg21;
            b_reg02 <= b_north2; b_reg12 <= b_reg02; b_reg22 <= b_reg12; b_reg32 <= b_reg22;
            b_reg03 <= b_north3; b_reg13 <= b_reg03; b_reg23 <= b_reg13; b_reg33 <= b_reg23;
        end
    end
endmodule
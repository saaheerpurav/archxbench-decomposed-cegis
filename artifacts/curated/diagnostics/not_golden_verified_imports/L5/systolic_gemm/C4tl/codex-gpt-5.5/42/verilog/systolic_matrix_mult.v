`timescale 1ns/1ps

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

    wire [31:0] a_next00, a_next01, a_next02, a_next03;
    wire [31:0] a_next10, a_next11, a_next12, a_next13;
    wire [31:0] a_next20, a_next21, a_next22, a_next23;
    wire [31:0] a_next30, a_next31, a_next32, a_next33;

    wire [31:0] b_next00, b_next01, b_next02, b_next03;
    wire [31:0] b_next10, b_next11, b_next12, b_next13;
    wire [31:0] b_next20, b_next21, b_next22, b_next23;
    wire [31:0] b_next30, b_next31, b_next32, b_next33;

    wire [63:0] acc_next00, acc_next01, acc_next02, acc_next03;
    wire [63:0] acc_next10, acc_next11, acc_next12, acc_next13;
    wire [63:0] acc_next20, acc_next21, acc_next22, acc_next23;
    wire [63:0] acc_next30, acc_next31, acc_next32, acc_next33;

    pe_cell pe00(a_west0, b_north0, acc00, a_next00, b_next00, acc_next00);
    pe_cell pe01(a_reg00, b_north1, acc01, a_next01, b_next01, acc_next01);
    pe_cell pe02(a_reg01, b_north2, acc02, a_next02, b_next02, acc_next02);
    pe_cell pe03(a_reg02, b_north3, acc03, a_next03, b_next03, acc_next03);

    pe_cell pe10(a_west1, b_reg00, acc10, a_next10, b_next10, acc_next10);
    pe_cell pe11(a_reg10, b_reg01, acc11, a_next11, b_next11, acc_next11);
    pe_cell pe12(a_reg11, b_reg02, acc12, a_next12, b_next12, acc_next12);
    pe_cell pe13(a_reg12, b_reg03, acc13, a_next13, b_next13, acc_next13);

    pe_cell pe20(a_west2, b_reg10, acc20, a_next20, b_next20, acc_next20);
    pe_cell pe21(a_reg20, b_reg11, acc21, a_next21, b_next21, acc_next21);
    pe_cell pe22(a_reg21, b_reg12, acc22, a_next22, b_next22, acc_next22);
    pe_cell pe23(a_reg22, b_reg13, acc23, a_next23, b_next23, acc_next23);

    pe_cell pe30(a_west3, b_reg20, acc30, a_next30, b_next30, acc_next30);
    pe_cell pe31(a_reg30, b_reg21, acc31, a_next31, b_next31, acc_next31);
    pe_cell pe32(a_reg31, b_reg22, acc32, a_next32, b_next32, acc_next32);
    pe_cell pe33(a_reg32, b_reg23, acc33, a_next33, b_next33, acc_next33);

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

            a_reg00 <= 0; a_reg01 <= 0; a_reg02 <= 0; a_reg03 <= 0;
            a_reg10 <= 0; a_reg11 <= 0; a_reg12 <= 0; a_reg13 <= 0;
            a_reg20 <= 0; a_reg21 <= 0; a_reg22 <= 0; a_reg23 <= 0;
            a_reg30 <= 0; a_reg31 <= 0; a_reg32 <= 0; a_reg33 <= 0;

            b_reg00 <= 0; b_reg01 <= 0; b_reg02 <= 0; b_reg03 <= 0;
            b_reg10 <= 0; b_reg11 <= 0; b_reg12 <= 0; b_reg13 <= 0;
            b_reg20 <= 0; b_reg21 <= 0; b_reg22 <= 0; b_reg23 <= 0;
            b_reg30 <= 0; b_reg31 <= 0; b_reg32 <= 0; b_reg33 <= 0;

            acc00 <= 0; acc01 <= 0; acc02 <= 0; acc03 <= 0;
            acc10 <= 0; acc11 <= 0; acc12 <= 0; acc13 <= 0;
            acc20 <= 0; acc21 <= 0; acc22 <= 0; acc23 <= 0;
            acc30 <= 0; acc31 <= 0; acc32 <= 0; acc33 <= 0;
        end else begin
            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;
            done <= (cycle_count == 4'd8);

            a_reg00 <= a_next00; a_reg01 <= a_next01; a_reg02 <= a_next02; a_reg03 <= a_next03;
            a_reg10 <= a_next10; a_reg11 <= a_next11; a_reg12 <= a_next12; a_reg13 <= a_next13;
            a_reg20 <= a_next20; a_reg21 <= a_next21; a_reg22 <= a_next22; a_reg23 <= a_next23;
            a_reg30 <= a_next30; a_reg31 <= a_next31; a_reg32 <= a_next32; a_reg33 <= a_next33;

            b_reg00 <= b_next00; b_reg01 <= b_next01; b_reg02 <= b_next02; b_reg03 <= b_next03;
            b_reg10 <= b_next10; b_reg11 <= b_next11; b_reg12 <= b_next12; b_reg13 <= b_next13;
            b_reg20 <= b_next20; b_reg21 <= b_next21; b_reg22 <= b_next22; b_reg23 <= b_next23;
            b_reg30 <= b_next30; b_reg31 <= b_next31; b_reg32 <= b_next32; b_reg33 <= b_next33;

            acc00 <= acc_next00; acc01 <= acc_next01; acc02 <= acc_next02; acc03 <= acc_next03;
            acc10 <= acc_next10; acc11 <= acc_next11; acc12 <= acc_next12; acc13 <= acc_next13;
            acc20 <= acc_next20; acc21 <= acc_next21; acc22 <= acc_next22; acc23 <= acc_next23;
            acc30 <= acc_next30; acc31 <= acc_next31; acc32 <= acc_next32; acc33 <= acc_next33;
        end
    end
endmodule
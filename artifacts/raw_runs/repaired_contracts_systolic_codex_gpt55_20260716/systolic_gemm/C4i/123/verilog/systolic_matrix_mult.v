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
    input clk, rst;
    output reg done;
    output [63:0] result0, result1, result2, result3,
                  result4, result5, result6, result7,
                  result8, result9, result10, result11,
                  result12, result13, result14, result15;

    reg [31:0] a_pipe00, a_pipe01, a_pipe02, a_pipe03;
    reg [31:0] a_pipe10, a_pipe11, a_pipe12, a_pipe13;
    reg [31:0] a_pipe20, a_pipe21, a_pipe22, a_pipe23;
    reg [31:0] a_pipe30, a_pipe31, a_pipe32, a_pipe33;

    reg [31:0] b_pipe00, b_pipe01, b_pipe02, b_pipe03;
    reg [31:0] b_pipe10, b_pipe11, b_pipe12, b_pipe13;
    reg [31:0] b_pipe20, b_pipe21, b_pipe22, b_pipe23;
    reg [31:0] b_pipe30, b_pipe31, b_pipe32, b_pipe33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    reg [3:0] cycle_count;
    wire done_next;

    wire [31:0] pe_s00, pe_s01, pe_s02, pe_s03;
    wire [31:0] pe_s10, pe_s11, pe_s12, pe_s13;
    wire [31:0] pe_s20, pe_s21, pe_s22, pe_s23;
    wire [31:0] pe_s30, pe_s31, pe_s32, pe_s33;

    wire [31:0] pe_e00, pe_e01, pe_e02, pe_e03;
    wire [31:0] pe_e10, pe_e11, pe_e12, pe_e13;
    wire [31:0] pe_e20, pe_e21, pe_e22, pe_e23;
    wire [31:0] pe_e30, pe_e31, pe_e32, pe_e33;

    wire [63:0] prod00, prod01, prod02, prod03;
    wire [63:0] prod10, prod11, prod12, prod13;
    wire [63:0] prod20, prod21, prod22, prod23;
    wire [63:0] prod30, prod31, prod32, prod33;

    pe pe00(b_north0, a_west0, clk, rst, pe_s00, pe_e00, prod00);
    pe pe01(b_north1, a_pipe00, clk, rst, pe_s01, pe_e01, prod01);
    pe pe02(b_north2, a_pipe01, clk, rst, pe_s02, pe_e02, prod02);
    pe pe03(b_north3, a_pipe02, clk, rst, pe_s03, pe_e03, prod03);

    pe pe10(b_pipe00, a_west1, clk, rst, pe_s10, pe_e10, prod10);
    pe pe11(b_pipe01, a_pipe10, clk, rst, pe_s11, pe_e11, prod11);
    pe pe12(b_pipe02, a_pipe11, clk, rst, pe_s12, pe_e12, prod12);
    pe pe13(b_pipe03, a_pipe12, clk, rst, pe_s13, pe_e13, prod13);

    pe pe20(b_pipe10, a_west2, clk, rst, pe_s20, pe_e20, prod20);
    pe pe21(b_pipe11, a_pipe20, clk, rst, pe_s21, pe_e21, prod21);
    pe pe22(b_pipe12, a_pipe21, clk, rst, pe_s22, pe_e22, prod22);
    pe pe23(b_pipe13, a_pipe22, clk, rst, pe_s23, pe_e23, prod23);

    pe pe30(b_pipe20, a_west3, clk, rst, pe_s30, pe_e30, prod30);
    pe pe31(b_pipe21, a_pipe30, clk, rst, pe_s31, pe_e31, prod31);
    pe pe32(b_pipe22, a_pipe31, clk, rst, pe_s32, pe_e32, prod32);
    pe pe33(b_pipe23, a_pipe32, clk, rst, pe_s33, pe_e33, prod33);

    done_logic done_unit(cycle_count, done_next);

    always @(posedge clk) begin
        if (rst) begin
            a_pipe00 <= 32'd0; a_pipe01 <= 32'd0; a_pipe02 <= 32'd0; a_pipe03 <= 32'd0;
            a_pipe10 <= 32'd0; a_pipe11 <= 32'd0; a_pipe12 <= 32'd0; a_pipe13 <= 32'd0;
            a_pipe20 <= 32'd0; a_pipe21 <= 32'd0; a_pipe22 <= 32'd0; a_pipe23 <= 32'd0;
            a_pipe30 <= 32'd0; a_pipe31 <= 32'd0; a_pipe32 <= 32'd0; a_pipe33 <= 32'd0;

            b_pipe00 <= 32'd0; b_pipe01 <= 32'd0; b_pipe02 <= 32'd0; b_pipe03 <= 32'd0;
            b_pipe10 <= 32'd0; b_pipe11 <= 32'd0; b_pipe12 <= 32'd0; b_pipe13 <= 32'd0;
            b_pipe20 <= 32'd0; b_pipe21 <= 32'd0; b_pipe22 <= 32'd0; b_pipe23 <= 32'd0;
            b_pipe30 <= 32'd0; b_pipe31 <= 32'd0; b_pipe32 <= 32'd0; b_pipe33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;

            cycle_count <= 4'd0;
            done <= 1'b0;
        end else begin
            a_pipe00 <= pe_e00; a_pipe01 <= pe_e01; a_pipe02 <= pe_e02; a_pipe03 <= pe_e03;
            a_pipe10 <= pe_e10; a_pipe11 <= pe_e11; a_pipe12 <= pe_e12; a_pipe13 <= pe_e13;
            a_pipe20 <= pe_e20; a_pipe21 <= pe_e21; a_pipe22 <= pe_e22; a_pipe23 <= pe_e23;
            a_pipe30 <= pe_e30; a_pipe31 <= pe_e31; a_pipe32 <= pe_e32; a_pipe33 <= pe_e33;

            b_pipe00 <= pe_s00; b_pipe01 <= pe_s01; b_pipe02 <= pe_s02; b_pipe03 <= pe_s03;
            b_pipe10 <= pe_s10; b_pipe11 <= pe_s11; b_pipe12 <= pe_s12; b_pipe13 <= pe_s13;
            b_pipe20 <= pe_s20; b_pipe21 <= pe_s21; b_pipe22 <= pe_s22; b_pipe23 <= pe_s23;
            b_pipe30 <= pe_s30; b_pipe31 <= pe_s31; b_pipe32 <= pe_s32; b_pipe33 <= pe_s33;

            acc00 <= acc00 + prod00; acc01 <= acc01 + prod01; acc02 <= acc02 + prod02; acc03 <= acc03 + prod03;
            acc10 <= acc10 + prod10; acc11 <= acc11 + prod11; acc12 <= acc12 + prod12; acc13 <= acc13 + prod13;
            acc20 <= acc20 + prod20; acc21 <= acc21 + prod21; acc22 <= acc22 + prod22; acc23 <= acc23 + prod23;
            acc30 <= acc30 + prod30; acc31 <= acc31 + prod31; acc32 <= acc32 + prod32; acc33 <= acc33 + prod33;

            if (cycle_count != 4'd15)
                cycle_count <= cycle_count + 4'd1;

            done <= done_next;
        end
    end

    result_bus_map result_map(
        acc00, acc01, acc02, acc03,
        acc10, acc11, acc12, acc13,
        acc20, acc21, acc22, acc23,
        acc30, acc31, acc32, acc33,
        result0, result1, result2, result3,
        result4, result5, result6, result7,
        result8, result9, result10, result11,
        result12, result13, result14, result15
    );

endmodule
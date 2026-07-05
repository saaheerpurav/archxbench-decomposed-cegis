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

    wire [63:0] prod00, prod01, prod02, prod03;
    wire [63:0] prod10, prod11, prod12, prod13;
    wire [63:0] prod20, prod21, prod22, prod23;
    wire [63:0] prod30, prod31, prod32, prod33;

    mac_cell m00(a_west0,  b_north0,  prod00);
    mac_cell m01(a_pipe00, b_north1,  prod01);
    mac_cell m02(a_pipe01, b_north2,  prod02);
    mac_cell m03(a_pipe02, b_north3,  prod03);

    mac_cell m10(a_west1,  b_pipe00, prod10);
    mac_cell m11(a_pipe10, b_pipe01, prod11);
    mac_cell m12(a_pipe11, b_pipe02, prod12);
    mac_cell m13(a_pipe12, b_pipe03, prod13);

    mac_cell m20(a_west2,  b_pipe10, prod20);
    mac_cell m21(a_pipe20, b_pipe11, prod21);
    mac_cell m22(a_pipe21, b_pipe12, prod22);
    mac_cell m23(a_pipe22, b_pipe13, prod23);

    mac_cell m30(a_west3,  b_pipe20, prod30);
    mac_cell m31(a_pipe30, b_pipe21, prod31);
    mac_cell m32(a_pipe31, b_pipe22, prod32);
    mac_cell m33(a_pipe32, b_pipe23, prod33);

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
            acc00 <= acc00 + prod00; acc01 <= acc01 + prod01; acc02 <= acc02 + prod02; acc03 <= acc03 + prod03;
            acc10 <= acc10 + prod10; acc11 <= acc11 + prod11; acc12 <= acc12 + prod12; acc13 <= acc13 + prod13;
            acc20 <= acc20 + prod20; acc21 <= acc21 + prod21; acc22 <= acc22 + prod22; acc23 <= acc23 + prod23;
            acc30 <= acc30 + prod30; acc31 <= acc31 + prod31; acc32 <= acc32 + prod32; acc33 <= acc33 + prod33;

            a_pipe00 <= a_west0;  a_pipe01 <= a_pipe00; a_pipe02 <= a_pipe01; a_pipe03 <= a_pipe02;
            a_pipe10 <= a_west1;  a_pipe11 <= a_pipe10; a_pipe12 <= a_pipe11; a_pipe13 <= a_pipe12;
            a_pipe20 <= a_west2;  a_pipe21 <= a_pipe20; a_pipe22 <= a_pipe21; a_pipe23 <= a_pipe22;
            a_pipe30 <= a_west3;  a_pipe31 <= a_pipe30; a_pipe32 <= a_pipe31; a_pipe33 <= a_pipe32;

            b_pipe00 <= b_north0; b_pipe10 <= b_pipe00; b_pipe20 <= b_pipe10; b_pipe30 <= b_pipe20;
            b_pipe01 <= b_north1; b_pipe11 <= b_pipe01; b_pipe21 <= b_pipe11; b_pipe31 <= b_pipe21;
            b_pipe02 <= b_north2; b_pipe12 <= b_pipe02; b_pipe22 <= b_pipe12; b_pipe32 <= b_pipe22;
            b_pipe03 <= b_north3; b_pipe13 <= b_pipe03; b_pipe23 <= b_pipe13; b_pipe33 <= b_pipe23;

            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;

            done <= (cycle_count >= 4'd8);
        end
    end
endmodule
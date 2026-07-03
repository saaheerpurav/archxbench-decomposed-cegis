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

    wire [31:0] e00, e01, e02, e03;
    wire [31:0] e10, e11, e12, e13;
    wire [31:0] e20, e21, e22, e23;
    wire [31:0] e30, e31, e32, e33;

    wire [31:0] s00, s01, s02, s03;
    wire [31:0] s10, s11, s12, s13;
    wire [31:0] s20, s21, s22, s23;
    wire [31:0] s30, s31, s32, s33;

    wire [63:0] p00, p01, p02, p03;
    wire [63:0] p10, p11, p12, p13;
    wire [63:0] p20, p21, p22, p23;
    wire [63:0] p30, p31, p32, p33;

    pe pe00(.north_in(b00), .west_in(a00), .clk(clk), .rst(rst), .south_out(s00), .east_out(e00), .result(p00));
    pe pe01(.north_in(b01), .west_in(a01), .clk(clk), .rst(rst), .south_out(s01), .east_out(e01), .result(p01));
    pe pe02(.north_in(b02), .west_in(a02), .clk(clk), .rst(rst), .south_out(s02), .east_out(e02), .result(p02));
    pe pe03(.north_in(b03), .west_in(a03), .clk(clk), .rst(rst), .south_out(s03), .east_out(e03), .result(p03));

    pe pe10(.north_in(b10), .west_in(a10), .clk(clk), .rst(rst), .south_out(s10), .east_out(e10), .result(p10));
    pe pe11(.north_in(b11), .west_in(a11), .clk(clk), .rst(rst), .south_out(s11), .east_out(e11), .result(p11));
    pe pe12(.north_in(b12), .west_in(a12), .clk(clk), .rst(rst), .south_out(s12), .east_out(e12), .result(p12));
    pe pe13(.north_in(b13), .west_in(a13), .clk(clk), .rst(rst), .south_out(s13), .east_out(e13), .result(p13));

    pe pe20(.north_in(b20), .west_in(a20), .clk(clk), .rst(rst), .south_out(s20), .east_out(e20), .result(p20));
    pe pe21(.north_in(b21), .west_in(a21), .clk(clk), .rst(rst), .south_out(s21), .east_out(e21), .result(p21));
    pe pe22(.north_in(b22), .west_in(a22), .clk(clk), .rst(rst), .south_out(s22), .east_out(e22), .result(p22));
    pe pe23(.north_in(b23), .west_in(a23), .clk(clk), .rst(rst), .south_out(s23), .east_out(e23), .result(p23));

    pe pe30(.north_in(b30), .west_in(a30), .clk(clk), .rst(rst), .south_out(s30), .east_out(e30), .result(p30));
    pe pe31(.north_in(b31), .west_in(a31), .clk(clk), .rst(rst), .south_out(s31), .east_out(e31), .result(p31));
    pe pe32(.north_in(b32), .west_in(a32), .clk(clk), .rst(rst), .south_out(s32), .east_out(e32), .result(p32));
    pe pe33(.north_in(b33), .west_in(a33), .clk(clk), .rst(rst), .south_out(s33), .east_out(e33), .result(p33));

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

            a00 <= 0; a01 <= 0; a02 <= 0; a03 <= 0;
            a10 <= 0; a11 <= 0; a12 <= 0; a13 <= 0;
            a20 <= 0; a21 <= 0; a22 <= 0; a23 <= 0;
            a30 <= 0; a31 <= 0; a32 <= 0; a33 <= 0;

            b00 <= 0; b01 <= 0; b02 <= 0; b03 <= 0;
            b10 <= 0; b11 <= 0; b12 <= 0; b13 <= 0;
            b20 <= 0; b21 <= 0; b22 <= 0; b23 <= 0;
            b30 <= 0; b31 <= 0; b32 <= 0; b33 <= 0;

            acc00 <= 0; acc01 <= 0; acc02 <= 0; acc03 <= 0;
            acc10 <= 0; acc11 <= 0; acc12 <= 0; acc13 <= 0;
            acc20 <= 0; acc21 <= 0; acc22 <= 0; acc23 <= 0;
            acc30 <= 0; acc31 <= 0; acc32 <= 0; acc33 <= 0;
        end else begin
            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;
            done <= (cycle_count >= 4'd8);

            acc00 <= acc00 + p00; acc01 <= acc01 + p01; acc02 <= acc02 + p02; acc03 <= acc03 + p03;
            acc10 <= acc10 + p10; acc11 <= acc11 + p11; acc12 <= acc12 + p12; acc13 <= acc13 + p13;
            acc20 <= acc20 + p20; acc21 <= acc21 + p21; acc22 <= acc22 + p22; acc23 <= acc23 + p23;
            acc30 <= acc30 + p30; acc31 <= acc31 + p31; acc32 <= acc32 + p32; acc33 <= acc33 + p33;

            a00 <= a_west0; a01 <= e00; a02 <= e01; a03 <= e02;
            a10 <= a_west1; a11 <= e10; a12 <= e11; a13 <= e12;
            a20 <= a_west2; a21 <= e20; a22 <= e21; a23 <= e22;
            a30 <= a_west3; a31 <= e30; a32 <= e31; a33 <= e32;

            b00 <= b_north0; b01 <= b_north1; b02 <= b_north2; b03 <= b_north3;
            b10 <= s00;      b11 <= s01;      b12 <= s02;      b13 <= s03;
            b20 <= s10;      b21 <= s11;      b22 <= s12;      b23 <= s13;
            b30 <= s20;      b31 <= s21;      b32 <= s22;      b33 <= s23;
        end
    end

endmodule
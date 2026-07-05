`ifndef SYSTOLIC_MATRIX_MULT_V
`define SYSTOLIC_MATRIX_MULT_V

module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    input clk, rst;
    output reg [31:0] south_out, east_out;
    output reg [63:0] result;

    wire signed [63:0] north_ext;
    wire signed [63:0] west_ext;

    assign north_ext = {{32{north_in[31]}}, north_in};
    assign west_ext  = {{32{west_in[31]}}, west_in};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            south_out <= 32'd0;
            east_out  <= 32'd0;
            result    <= 64'd0;
        end else begin
            south_out <= north_in;
            east_out  <= west_in;
            result    <= result + (north_ext * west_ext);
        end
    end
endmodule

module systolic_matrix_mult(a_west0, a_west1, a_west2, a_west3,
                           b_north0, b_north1, b_north2, b_north3,
                           clk, rst, done,
                           result0, result1, result2, result3,
                           result4, result5, result6, result7,
                           result8, result9, result10, result11,
                           result12, result13, result14, result15);

    input [31:0] a_west0, a_west1, a_west2, a_west3;
    input [31:0] b_north0, b_north1, b_north2, b_north3;
    input clk, rst;
    output reg done;

    output [63:0] result0, result1, result2, result3;
    output [63:0] result4, result5, result6, result7;
    output [63:0] result8, result9, result10, result11;
    output [63:0] result12, result13, result14, result15;

    reg [3:0] count;

    wire [31:0] e00, e01, e02, e03;
    wire [31:0] e10, e11, e12, e13;
    wire [31:0] e20, e21, e22, e23;
    wire [31:0] e30, e31, e32, e33;

    wire [31:0] s00, s01, s02, s03;
    wire [31:0] s10, s11, s12, s13;
    wire [31:0] s20, s21, s22, s23;
    wire [31:0] s30, s31, s32, s33;

    wire pe_rst;
    assign pe_rst = rst || (count == 4'd10);

    pe pe00(b_north0, a_west0, clk, pe_rst, s00, e00, result0);
    pe pe01(b_north1, e00,     clk, pe_rst, s01, e01, result1);
    pe pe02(b_north2, e01,     clk, pe_rst, s02, e02, result2);
    pe pe03(b_north3, e02,     clk, pe_rst, s03, e03, result3);

    pe pe10(s00, a_west1, clk, pe_rst, s10, e10, result4);
    pe pe11(s01, e10,     clk, pe_rst, s11, e11, result5);
    pe pe12(s02, e11,     clk, pe_rst, s12, e12, result6);
    pe pe13(s03, e12,     clk, pe_rst, s13, e13, result7);

    pe pe20(s10, a_west2, clk, pe_rst, s20, e20, result8);
    pe pe21(s11, e20,     clk, pe_rst, s21, e21, result9);
    pe pe22(s12, e21,     clk, pe_rst, s22, e22, result10);
    pe pe23(s13, e22,     clk, pe_rst, s23, e23, result11);

    pe pe30(s20, a_west3, clk, pe_rst, s30, e30, result12);
    pe pe31(s21, e30,     clk, pe_rst, s31, e31, result13);
    pe pe32(s22, e31,     clk, pe_rst, s32, e32, result14);
    pe pe33(s23, e32,     clk, pe_rst, s33, e33, result15);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'd0;
            done  <= 1'b0;
        end else if (count == 4'd9) begin
            count <= 4'd10;
            done  <= 1'b1;
        end else if (count == 4'd10) begin
            count <= 4'd0;
            done  <= 1'b0;
        end else begin
            count <= count + 4'd1;
            done  <= 1'b0;
        end
    end
endmodule

`endif
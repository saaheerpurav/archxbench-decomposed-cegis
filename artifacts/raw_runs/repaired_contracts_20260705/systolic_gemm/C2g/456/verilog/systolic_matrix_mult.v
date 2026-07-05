module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input signed [31:0] north_in, west_in;
    input clk, rst;
    output reg signed [31:0] south_out, east_out;
    output reg signed [63:0] result;

    initial begin
        south_out = 32'd0;
        east_out  = 32'd0;
        result    = 64'd0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            south_out <= 32'd0;
            east_out  <= 32'd0;
            result    <= 64'd0;
        end else begin
            south_out <= north_in;
            east_out  <= west_in;
            result    <= result +
                         ($signed({{32{north_in[31]}}, north_in}) *
                          $signed({{32{west_in[31]}}, west_in}));
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

    input signed [31:0] a_west0, a_west1, a_west2, a_west3;
    input signed [31:0] b_north0, b_north1, b_north2, b_north3;
    input clk, rst;
    output reg done;

    output signed [63:0] result0, result1, result2, result3,
                         result4, result5, result6, result7,
                         result8, result9, result10, result11,
                         result12, result13, result14, result15;

    reg [3:0] cycle;

    wire [31:0] e00, e01, e02, e10, e11, e12, e20, e21, e22, e30, e31, e32;
    wire [31:0] s00, s01, s02, s03, s10, s11, s12, s13, s20, s21, s22, s23;

    pe pe00(b_north0, a_west0, clk, rst, s00, e00, result0);
    pe pe01(b_north1, e00,     clk, rst, s01, e01, result1);
    pe pe02(b_north2, e01,     clk, rst, s02, e02, result2);
    pe pe03(b_north3, e02,     clk, rst, s03,      result3);

    pe pe10(s00, a_west1, clk, rst, s10, e10, result4);
    pe pe11(s01, e10,     clk, rst, s11, e11, result5);
    pe pe12(s02, e11,     clk, rst, s12, e12, result6);
    pe pe13(s03, e12,     clk, rst, s13,      result7);

    pe pe20(s10, a_west2, clk, rst, s20, e20, result8);
    pe pe21(s11, e20,     clk, rst, s21, e21, result9);
    pe pe22(s12, e21,     clk, rst, s22, e22, result10);
    pe pe23(s13, e22,     clk, rst, s23,      result11);

    pe pe30(s20, a_west3, clk, rst,      e30, result12);
    pe pe31(s21, e30,     clk, rst,      e31, result13);
    pe pe32(s22, e31,     clk, rst,      e32, result14);
    pe pe33(s23, e32,     clk, rst,            result15);

    initial begin
        cycle = 4'd0;
        done  = 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 4'd0;
            done  <= 1'b0;
        end else begin
            if (cycle == 4'd9) begin
                done  <= 1'b1;
                cycle <= 4'd0;
            end else begin
                done  <= 1'b0;
                cycle <= cycle + 4'd1;
            end
        end
    end
endmodule
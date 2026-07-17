`timescale 1ns/1ps

module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    input clk, rst;
    output reg [31:0] south_out, east_out;
    output reg [63:0] result;

    wire signed [63:0] product;
    assign product = $signed(north_in) * $signed(west_in);

    always @(posedge clk) begin
        if (rst) begin
            south_out <= 32'd0;
            east_out  <= 32'd0;
            result    <= 64'd0;
        end else begin
            south_out <= north_in;
            east_out  <= west_in;
            result    <= result + product;
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

    reg [3:0] cycle_count;

    wire [31:0] east00, east01, east02, east03;
    wire [31:0] east10, east11, east12, east13;
    wire [31:0] east20, east21, east22, east23;
    wire [31:0] east30, east31, east32, east33;

    wire [31:0] south00, south01, south02, south03;
    wire [31:0] south10, south11, south12, south13;
    wire [31:0] south20, south21, south22, south23;
    wire [31:0] south30, south31, south32, south33;

    pe pe00(b_north0, a_west0, clk, rst, south00, east00, result0);
    pe pe01(b_north1, east00,  clk, rst, south01, east01, result1);
    pe pe02(b_north2, east01,  clk, rst, south02, east02, result2);
    pe pe03(b_north3, east02,  clk, rst, south03, east03, result3);

    pe pe10(south00, a_west1, clk, rst, south10, east10, result4);
    pe pe11(south01, east10,  clk, rst, south11, east11, result5);
    pe pe12(south02, east11,  clk, rst, south12, east12, result6);
    pe pe13(south03, east12,  clk, rst, south13, east13, result7);

    pe pe20(south10, a_west2, clk, rst, south20, east20, result8);
    pe pe21(south11, east20,  clk, rst, south21, east21, result9);
    pe pe22(south12, east21,  clk, rst, south22, east22, result10);
    pe pe23(south13, east22,  clk, rst, south23, east23, result11);

    pe pe30(south20, a_west3, clk, rst, south30, east30, result12);
    pe pe31(south21, east30,  clk, rst, south31, east31, result13);
    pe pe32(south22, east31,  clk, rst, south32, east32, result14);
    pe pe33(south23, east32,  clk, rst, south33, east33, result15);

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;
        end else begin
            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;

            done <= (cycle_count >= 4'd8);
        end
    end
endmodule
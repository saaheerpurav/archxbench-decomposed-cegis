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

    reg [31:0] a_pipe_0_1, a_pipe_0_2, a_pipe_0_3, a_pipe_0_4;
    reg [31:0] a_pipe_1_1, a_pipe_1_2, a_pipe_1_3, a_pipe_1_4;
    reg [31:0] a_pipe_2_1, a_pipe_2_2, a_pipe_2_3, a_pipe_2_4;
    reg [31:0] a_pipe_3_1, a_pipe_3_2, a_pipe_3_3, a_pipe_3_4;

    reg [31:0] b_pipe_1_0, b_pipe_2_0, b_pipe_3_0, b_pipe_4_0;
    reg [31:0] b_pipe_1_1, b_pipe_2_1, b_pipe_3_1, b_pipe_4_1;
    reg [31:0] b_pipe_1_2, b_pipe_2_2, b_pipe_3_2, b_pipe_4_2;
    reg [31:0] b_pipe_1_3, b_pipe_2_3, b_pipe_3_3, b_pipe_4_3;

    reg [63:0] acc_0_0, acc_0_1, acc_0_2, acc_0_3;
    reg [63:0] acc_1_0, acc_1_1, acc_1_2, acc_1_3;
    reg [63:0] acc_2_0, acc_2_1, acc_2_2, acc_2_3;
    reg [63:0] acc_3_0, acc_3_1, acc_3_2, acc_3_3;

    wire [31:0] west_0, west_1, west_2, west_3;
    wire [31:0] north_0, north_1, north_2, north_3;

    wire [3:0] next_cycle_count;
    wire next_done;

    wire [31:0] east_0_0, east_0_1, east_0_2, east_0_3;
    wire [31:0] east_1_0, east_1_1, east_1_2, east_1_3;
    wire [31:0] east_2_0, east_2_1, east_2_2, east_2_3;
    wire [31:0] east_3_0, east_3_1, east_3_2, east_3_3;

    wire [31:0] south_0_0, south_0_1, south_0_2, south_0_3;
    wire [31:0] south_1_0, south_1_1, south_1_2, south_1_3;
    wire [31:0] south_2_0, south_2_1, south_2_2, south_2_3;
    wire [31:0] south_3_0, south_3_1, south_3_2, south_3_3;

    wire [63:0] prod_0_0, prod_0_1, prod_0_2, prod_0_3;
    wire [63:0] prod_1_0, prod_1_1, prod_1_2, prod_1_3;
    wire [63:0] prod_2_0, prod_2_1, prod_2_2, prod_2_3;
    wire [63:0] prod_3_0, prod_3_1, prod_3_2, prod_3_3;

    input_boundary_buffer boundary_inputs(
        .a_west0(a_west0), .a_west1(a_west1), .a_west2(a_west2), .a_west3(a_west3),
        .b_north0(b_north0), .b_north1(b_north1), .b_north2(b_north2), .b_north3(b_north3),
        .west0(west_0), .west1(west_1), .west2(west_2), .west3(west_3),
        .north0(north_0), .north1(north_1), .north2(north_2), .north3(north_3)
    );

    cycle_done_logic control_logic(
        .cycle_count(cycle_count),
        .next_cycle_count(next_cycle_count),
        .done_next(next_done)
    );

    pe pe_0_0(.north_in(north_0),    .west_in(west_0),    .clk(clk), .rst(rst), .south_out(south_0_0), .east_out(east_0_0), .result(prod_0_0));
    pe pe_0_1(.north_in(north_1),    .west_in(a_pipe_0_1), .clk(clk), .rst(rst), .south_out(south_0_1), .east_out(east_0_1), .result(prod_0_1));
    pe pe_0_2(.north_in(north_2),    .west_in(a_pipe_0_2), .clk(clk), .rst(rst), .south_out(south_0_2), .east_out(east_0_2), .result(prod_0_2));
    pe pe_0_3(.north_in(north_3),    .west_in(a_pipe_0_3), .clk(clk), .rst(rst), .south_out(south_0_3), .east_out(east_0_3), .result(prod_0_3));

    pe pe_1_0(.north_in(b_pipe_1_0), .west_in(west_1),    .clk(clk), .rst(rst), .south_out(south_1_0), .east_out(east_1_0), .result(prod_1_0));
    pe pe_1_1(.north_in(b_pipe_1_1), .west_in(a_pipe_1_1), .clk(clk), .rst(rst), .south_out(south_1_1), .east_out(east_1_1), .result(prod_1_1));
    pe pe_1_2(.north_in(b_pipe_1_2), .west_in(a_pipe_1_2), .clk(clk), .rst(rst), .south_out(south_1_2), .east_out(east_1_2), .result(prod_1_2));
    pe pe_1_3(.north_in(b_pipe_1_3), .west_in(a_pipe_1_3), .clk(clk), .rst(rst), .south_out(south_1_3), .east_out(east_1_3), .result(prod_1_3));

    pe pe_2_0(.north_in(b_pipe_2_0), .west_in(west_2),    .clk(clk), .rst(rst), .south_out(south_2_0), .east_out(east_2_0), .result(prod_2_0));
    pe pe_2_1(.north_in(b_pipe_2_1), .west_in(a_pipe_2_1), .clk(clk), .rst(rst), .south_out(south_2_1), .east_out(east_2_1), .result(prod_2_1));
    pe pe_2_2(.north_in(b_pipe_2_2), .west_in(a_pipe_2_2), .clk(clk), .rst(rst), .south_out(south_2_2), .east_out(east_2_2), .result(prod_2_2));
    pe pe_2_3(.north_in(b_pipe_2_3), .west_in(a_pipe_2_3), .clk(clk), .rst(rst), .south_out(south_2_3), .east_out(east_2_3), .result(prod_2_3));

    pe pe_3_0(.north_in(b_pipe_3_0), .west_in(west_3),    .clk(clk), .rst(rst), .south_out(south_3_0), .east_out(east_3_0), .result(prod_3_0));
    pe pe_3_1(.north_in(b_pipe_3_1), .west_in(a_pipe_3_1), .clk(clk), .rst(rst), .south_out(south_3_1), .east_out(east_3_1), .result(prod_3_1));
    pe pe_3_2(.north_in(b_pipe_3_2), .west_in(a_pipe_3_2), .clk(clk), .rst(rst), .south_out(south_3_2), .east_out(east_3_2), .result(prod_3_2));
    pe pe_3_3(.north_in(b_pipe_3_3), .west_in(a_pipe_3_3), .clk(clk), .rst(rst), .south_out(south_3_3), .east_out(east_3_3), .result(prod_3_3));

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;

            a_pipe_0_1 <= 32'd0; a_pipe_0_2 <= 32'd0; a_pipe_0_3 <= 32'd0; a_pipe_0_4 <= 32'd0;
            a_pipe_1_1 <= 32'd0; a_pipe_1_2 <= 32'd0; a_pipe_1_3 <= 32'd0; a_pipe_1_4 <= 32'd0;
            a_pipe_2_1 <= 32'd0; a_pipe_2_2 <= 32'd0; a_pipe_2_3 <= 32'd0; a_pipe_2_4 <= 32'd0;
            a_pipe_3_1 <= 32'd0; a_pipe_3_2 <= 32'd0; a_pipe_3_3 <= 32'd0; a_pipe_3_4 <= 32'd0;

            b_pipe_1_0 <= 32'd0; b_pipe_2_0 <= 32'd0; b_pipe_3_0 <= 32'd0; b_pipe_4_0 <= 32'd0;
            b_pipe_1_1 <= 32'd0; b_pipe_2_1 <= 32'd0; b_pipe_3_1 <= 32'd0; b_pipe_4_1 <= 32'd0;
            b_pipe_1_2 <= 32'd0; b_pipe_2_2 <= 32'd0; b_pipe_3_2 <= 32'd0; b_pipe_4_2 <= 32'd0;
            b_pipe_1_3 <= 32'd0; b_pipe_2_3 <= 32'd0; b_pipe_3_3 <= 32'd0; b_pipe_4_3 <= 32'd0;

            acc_0_0 <= 64'd0; acc_0_1 <= 64'd0; acc_0_2 <= 64'd0; acc_0_3 <= 64'd0;
            acc_1_0 <= 64'd0; acc_1_1 <= 64'd0; acc_1_2 <= 64'd0; acc_1_3 <= 64'd0;
            acc_2_0 <= 64'd0; acc_2_1 <= 64'd0; acc_2_2 <= 64'd0; acc_2_3 <= 64'd0;
            acc_3_0 <= 64'd0; acc_3_1 <= 64'd0; acc_3_2 <= 64'd0; acc_3_3 <= 64'd0;
        end else begin
            cycle_count <= next_cycle_count;
            done <= next_done;

            a_pipe_0_1 <= east_0_0; a_pipe_0_2 <= east_0_1; a_pipe_0_3 <= east_0_2; a_pipe_0_4 <= east_0_3;
            a_pipe_1_1 <= east_1_0; a_pipe_1_2 <= east_1_1; a_pipe_1_3 <= east_1_2; a_pipe_1_4 <= east_1_3;
            a_pipe_2_1 <= east_2_0; a_pipe_2_2 <= east_2_1; a_pipe_2_3 <= east_2_2; a_pipe_2_4 <= east_2_3;
            a_pipe_3_1 <= east_3_0; a_pipe_3_2 <= east_3_1; a_pipe_3_3 <= east_3_2; a_pipe_3_4 <= east_3_3;

            b_pipe_1_0 <= south_0_0; b_pipe_2_0 <= south_1_0; b_pipe_3_0 <= south_2_0; b_pipe_4_0 <= south_3_0;
            b_pipe_1_1 <= south_0_1; b_pipe_2_1 <= south_1_1; b_pipe_3_1 <= south_2_1; b_pipe_4_1 <= south_3_1;
            b_pipe_1_2 <= south_0_2; b_pipe_2_2 <= south_1_2; b_pipe_3_2 <= south_2_2; b_pipe_4_2 <= south_3_2;
            b_pipe_1_3 <= south_0_3; b_pipe_2_3 <= south_1_3; b_pipe_3_3 <= south_2_3; b_pipe_4_3 <= south_3_3;

            acc_0_0 <= acc_0_0 + prod_0_0; acc_0_1 <= acc_0_1 + prod_0_1; acc_0_2 <= acc_0_2 + prod_0_2; acc_0_3 <= acc_0_3 + prod_0_3;
            acc_1_0 <= acc_1_0 + prod_1_0; acc_1_1 <= acc_1_1 + prod_1_1; acc_1_2 <= acc_1_2 + prod_1_2; acc_1_3 <= acc_1_3 + prod_1_3;
            acc_2_0 <= acc_2_0 + prod_2_0; acc_2_1 <= acc_2_1 + prod_2_1; acc_2_2 <= acc_2_2 + prod_2_2; acc_2_3 <= acc_2_3 + prod_2_3;
            acc_3_0 <= acc_3_0 + prod_3_0; acc_3_1 <= acc_3_1 + prod_3_1; acc_3_2 <= acc_3_2 + prod_3_2; acc_3_3 <= acc_3_3 + prod_3_3;
        end
    end

    assign result0  = acc_0_0;
    assign result1  = acc_0_1;
    assign result2  = acc_0_2;
    assign result3  = acc_0_3;
    assign result4  = acc_1_0;
    assign result5  = acc_1_1;
    assign result6  = acc_1_2;
    assign result7  = acc_1_3;
    assign result8  = acc_2_0;
    assign result9  = acc_2_1;
    assign result10 = acc_2_2;
    assign result11 = acc_2_3;
    assign result12 = acc_3_0;
    assign result13 = acc_3_1;
    assign result14 = acc_3_2;
    assign result15 = acc_3_3;

endmodule
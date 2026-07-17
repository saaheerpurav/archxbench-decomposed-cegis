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
    wire done_next;

    wire [31:0] east00, east01, east02, east03;
    wire [31:0] east10, east11, east12, east13;
    wire [31:0] east20, east21, east22, east23;
    wire [31:0] east30, east31, east32, east33;

    wire [31:0] south00, south01, south02, south03;
    wire [31:0] south10, south11, south12, south13;
    wire [31:0] south20, south21, south22, south23;
    wire [31:0] south30, south31, south32, south33;

    wire [63:0] pe_result0, pe_result1, pe_result2, pe_result3;
    wire [63:0] pe_result4, pe_result5, pe_result6, pe_result7;
    wire [63:0] pe_result8, pe_result9, pe_result10, pe_result11;
    wire [63:0] pe_result12, pe_result13, pe_result14, pe_result15;

    pe pe00(.north_in(b_north0), .west_in(a_west0), .clk(clk), .rst(rst),
            .south_out(south00), .east_out(east00), .result(pe_result0));
    pe pe01(.north_in(b_north1), .west_in(east00), .clk(clk), .rst(rst),
            .south_out(south01), .east_out(east01), .result(pe_result1));
    pe pe02(.north_in(b_north2), .west_in(east01), .clk(clk), .rst(rst),
            .south_out(south02), .east_out(east02), .result(pe_result2));
    pe pe03(.north_in(b_north3), .west_in(east02), .clk(clk), .rst(rst),
            .south_out(south03), .east_out(east03), .result(pe_result3));

    pe pe10(.north_in(south00), .west_in(a_west1), .clk(clk), .rst(rst),
            .south_out(south10), .east_out(east10), .result(pe_result4));
    pe pe11(.north_in(south01), .west_in(east10), .clk(clk), .rst(rst),
            .south_out(south11), .east_out(east11), .result(pe_result5));
    pe pe12(.north_in(south02), .west_in(east11), .clk(clk), .rst(rst),
            .south_out(south12), .east_out(east12), .result(pe_result6));
    pe pe13(.north_in(south03), .west_in(east12), .clk(clk), .rst(rst),
            .south_out(south13), .east_out(east13), .result(pe_result7));

    pe pe20(.north_in(south10), .west_in(a_west2), .clk(clk), .rst(rst),
            .south_out(south20), .east_out(east20), .result(pe_result8));
    pe pe21(.north_in(south11), .west_in(east20), .clk(clk), .rst(rst),
            .south_out(south21), .east_out(east21), .result(pe_result9));
    pe pe22(.north_in(south12), .west_in(east21), .clk(clk), .rst(rst),
            .south_out(south22), .east_out(east22), .result(pe_result10));
    pe pe23(.north_in(south13), .west_in(east22), .clk(clk), .rst(rst),
            .south_out(south23), .east_out(east23), .result(pe_result11));

    pe pe30(.north_in(south20), .west_in(a_west3), .clk(clk), .rst(rst),
            .south_out(south30), .east_out(east30), .result(pe_result12));
    pe pe31(.north_in(south21), .west_in(east30), .clk(clk), .rst(rst),
            .south_out(south31), .east_out(east31), .result(pe_result13));
    pe pe32(.north_in(south22), .west_in(east31), .clk(clk), .rst(rst),
            .south_out(south32), .east_out(east32), .result(pe_result14));
    pe pe33(.north_in(south23), .west_in(east32), .clk(clk), .rst(rst),
            .south_out(south33), .east_out(east33), .result(pe_result15));

    done_control done_ctl(.cycle_count(cycle_count), .done_next(done_next));

    result_passthrough result_map(
        .in0(pe_result0), .in1(pe_result1), .in2(pe_result2), .in3(pe_result3),
        .in4(pe_result4), .in5(pe_result5), .in6(pe_result6), .in7(pe_result7),
        .in8(pe_result8), .in9(pe_result9), .in10(pe_result10), .in11(pe_result11),
        .in12(pe_result12), .in13(pe_result13), .in14(pe_result14), .in15(pe_result15),
        .out0(result0), .out1(result1), .out2(result2), .out3(result3),
        .out4(result4), .out5(result5), .out6(result6), .out7(result7),
        .out8(result8), .out9(result9), .out10(result10), .out11(result11),
        .out12(result12), .out13(result13), .out14(result14), .out15(result15)
    );

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;
        end else begin
            if (cycle_count != 4'd15)
                cycle_count <= cycle_count + 4'd1;
            done <= done_next;
        end
    end

endmodule
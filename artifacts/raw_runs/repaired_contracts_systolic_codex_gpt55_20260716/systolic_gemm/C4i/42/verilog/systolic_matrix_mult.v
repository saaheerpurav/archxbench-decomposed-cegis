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

    reg [31:0] east_reg  [0:3][0:3];
    reg [31:0] south_reg [0:3][0:3];
    reg [63:0] acc_reg   [0:3][0:3];

    wire [31:0] north_wire [0:3][0:3];
    wire [31:0] west_wire  [0:3][0:3];
    wire [31:0] east_next  [0:3][0:3];
    wire [31:0] south_next [0:3][0:3];
    wire [63:0] acc_next   [0:3][0:3];

    reg [3:0] cycle_count;

    assign north_wire[0][0] = b_north0;
    assign north_wire[0][1] = b_north1;
    assign north_wire[0][2] = b_north2;
    assign north_wire[0][3] = b_north3;

    assign north_wire[1][0] = south_reg[0][0];
    assign north_wire[1][1] = south_reg[0][1];
    assign north_wire[1][2] = south_reg[0][2];
    assign north_wire[1][3] = south_reg[0][3];

    assign north_wire[2][0] = south_reg[1][0];
    assign north_wire[2][1] = south_reg[1][1];
    assign north_wire[2][2] = south_reg[1][2];
    assign north_wire[2][3] = south_reg[1][3];

    assign north_wire[3][0] = south_reg[2][0];
    assign north_wire[3][1] = south_reg[2][1];
    assign north_wire[3][2] = south_reg[2][2];
    assign north_wire[3][3] = south_reg[2][3];

    assign west_wire[0][0] = a_west0;
    assign west_wire[1][0] = a_west1;
    assign west_wire[2][0] = a_west2;
    assign west_wire[3][0] = a_west3;

    assign west_wire[0][1] = east_reg[0][0];
    assign west_wire[1][1] = east_reg[1][0];
    assign west_wire[2][1] = east_reg[2][0];
    assign west_wire[3][1] = east_reg[3][0];

    assign west_wire[0][2] = east_reg[0][1];
    assign west_wire[1][2] = east_reg[1][1];
    assign west_wire[2][2] = east_reg[2][1];
    assign west_wire[3][2] = east_reg[3][1];

    assign west_wire[0][3] = east_reg[0][2];
    assign west_wire[1][3] = east_reg[1][2];
    assign west_wire[2][3] = east_reg[2][2];
    assign west_wire[3][3] = east_reg[3][2];

    pe_cell pe00(north_wire[0][0], west_wire[0][0], acc_reg[0][0], south_next[0][0], east_next[0][0], acc_next[0][0]);
    pe_cell pe01(north_wire[0][1], west_wire[0][1], acc_reg[0][1], south_next[0][1], east_next[0][1], acc_next[0][1]);
    pe_cell pe02(north_wire[0][2], west_wire[0][2], acc_reg[0][2], south_next[0][2], east_next[0][2], acc_next[0][2]);
    pe_cell pe03(north_wire[0][3], west_wire[0][3], acc_reg[0][3], south_next[0][3], east_next[0][3], acc_next[0][3]);

    pe_cell pe10(north_wire[1][0], west_wire[1][0], acc_reg[1][0], south_next[1][0], east_next[1][0], acc_next[1][0]);
    pe_cell pe11(north_wire[1][1], west_wire[1][1], acc_reg[1][1], south_next[1][1], east_next[1][1], acc_next[1][1]);
    pe_cell pe12(north_wire[1][2], west_wire[1][2], acc_reg[1][2], south_next[1][2], east_next[1][2], acc_next[1][2]);
    pe_cell pe13(north_wire[1][3], west_wire[1][3], acc_reg[1][3], south_next[1][3], east_next[1][3], acc_next[1][3]);

    pe_cell pe20(north_wire[2][0], west_wire[2][0], acc_reg[2][0], south_next[2][0], east_next[2][0], acc_next[2][0]);
    pe_cell pe21(north_wire[2][1], west_wire[2][1], acc_reg[2][1], south_next[2][1], east_next[2][1], acc_next[2][1]);
    pe_cell pe22(north_wire[2][2], west_wire[2][2], acc_reg[2][2], south_next[2][2], east_next[2][2], acc_next[2][2]);
    pe_cell pe23(north_wire[2][3], west_wire[2][3], acc_reg[2][3], south_next[2][3], east_next[2][3], acc_next[2][3]);

    pe_cell pe30(north_wire[3][0], west_wire[3][0], acc_reg[3][0], south_next[3][0], east_next[3][0], acc_next[3][0]);
    pe_cell pe31(north_wire[3][1], west_wire[3][1], acc_reg[3][1], south_next[3][1], east_next[3][1], acc_next[3][1]);
    pe_cell pe32(north_wire[3][2], west_wire[3][2], acc_reg[3][2], south_next[3][2], east_next[3][2], acc_next[3][2]);
    pe_cell pe33(north_wire[3][3], west_wire[3][3], acc_reg[3][3], south_next[3][3], east_next[3][3], acc_next[3][3]);

    integer r, c;
    always @(posedge clk) begin
        if (rst) begin
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    east_reg[r][c] <= 32'd0;
                    south_reg[r][c] <= 32'd0;
                    acc_reg[r][c] <= 64'd0;
                end
            end
            cycle_count <= 4'd0;
            done <= 1'b0;
        end else begin
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    east_reg[r][c] <= east_next[r][c];
                    south_reg[r][c] <= south_next[r][c];
                    acc_reg[r][c] <= acc_next[r][c];
                end
            end

            if (cycle_count < 4'd8) begin
                cycle_count <= cycle_count + 4'd1;
                done <= 1'b0;
            end else begin
                cycle_count <= cycle_count;
                done <= 1'b1;
            end
        end
    end

    assign result0  = acc_reg[0][0];
    assign result1  = acc_reg[0][1];
    assign result2  = acc_reg[0][2];
    assign result3  = acc_reg[0][3];
    assign result4  = acc_reg[1][0];
    assign result5  = acc_reg[1][1];
    assign result6  = acc_reg[1][2];
    assign result7  = acc_reg[1][3];
    assign result8  = acc_reg[2][0];
    assign result9  = acc_reg[2][1];
    assign result10 = acc_reg[2][2];
    assign result11 = acc_reg[2][3];
    assign result12 = acc_reg[3][0];
    assign result13 = acc_reg[3][1];
    assign result14 = acc_reg[3][2];
    assign result15 = acc_reg[3][3];

endmodule
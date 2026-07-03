`timescale 1ns/1ps

module input_router(a_west0, a_west1, a_west2, a_west3,
                    b_north0, b_north1, b_north2, b_north3,
                    a_row0, a_row1, a_row2, a_row3,
                    b_col0, b_col1, b_col2, b_col3);
    input [31:0] a_west0, a_west1, a_west2, a_west3;
    input [31:0] b_north0, b_north1, b_north2, b_north3;
    output [31:0] a_row0, a_row1, a_row2, a_row3;
    output [31:0] b_col0, b_col1, b_col2, b_col3;

    assign a_row0 = a_west0;
    assign a_row1 = a_west1;
    assign a_row2 = a_west2;
    assign a_row3 = a_west3;

    assign b_col0 = b_north0;
    assign b_col1 = b_north1;
    assign b_col2 = b_north2;
    assign b_col3 = b_north3;
endmodule
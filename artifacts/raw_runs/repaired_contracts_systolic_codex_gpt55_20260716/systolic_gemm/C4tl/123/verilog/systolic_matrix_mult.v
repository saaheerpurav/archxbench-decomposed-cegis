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

    reg [31:0] a_reg00, a_reg01, a_reg02, a_reg03;
    reg [31:0] a_reg10, a_reg11, a_reg12, a_reg13;
    reg [31:0] a_reg20, a_reg21, a_reg22, a_reg23;
    reg [31:0] a_reg30, a_reg31, a_reg32, a_reg33;

    reg [31:0] b_reg00, b_reg01, b_reg02, b_reg03;
    reg [31:0] b_reg10, b_reg11, b_reg12, b_reg13;
    reg [31:0] b_reg20, b_reg21, b_reg22, b_reg23;
    reg [31:0] b_reg30, b_reg31, b_reg32, b_reg33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    reg [3:0] cycle_count;

    wire [63:0] next_acc00, next_acc01, next_acc02, next_acc03;
    wire [63:0] next_acc10, next_acc11, next_acc12, next_acc13;
    wire [63:0] next_acc20, next_acc21, next_acc22, next_acc23;
    wire [63:0] next_acc30, next_acc31, next_acc32, next_acc33;

    wire [31:0] east00, east01, east02, east03;
    wire [31:0] east10, east11, east12, east13;
    wire [31:0] east20, east21, east22, east23;
    wire [31:0] east30, east31, east32, east33;

    wire [31:0] south00, south01, south02, south03;
    wire [31:0] south10, south11, south12, south13;
    wire [31:0] south20, south21, south22, south23;
    wire [31:0] south30, south31, south32, south33;

    wire done_next;

    pe_mac pe00(.north_in(b_north0), .west_in(a_west0), .accum_in(acc00), .accum_out(next_acc00));
    pe_mac pe01(.north_in(b_north1), .west_in(a_reg00), .accum_in(acc01), .accum_out(next_acc01));
    pe_mac pe02(.north_in(b_north2), .west_in(a_reg01), .accum_in(acc02), .accum_out(next_acc02));
    pe_mac pe03(.north_in(b_north3), .west_in(a_reg02), .accum_in(acc03), .accum_out(next_acc03));

    pe_mac pe10(.north_in(b_reg00), .west_in(a_west1), .accum_in(acc10), .accum_out(next_acc10));
    pe_mac pe11(.north_in(b_reg01), .west_in(a_reg10), .accum_in(acc11), .accum_out(next_acc11));
    pe_mac pe12(.north_in(b_reg02), .west_in(a_reg11), .accum_in(acc12), .accum_out(next_acc12));
    pe_mac pe13(.north_in(b_reg03), .west_in(a_reg12), .accum_in(acc13), .accum_out(next_acc13));

    pe_mac pe20(.north_in(b_reg10), .west_in(a_west2), .accum_in(acc20), .accum_out(next_acc20));
    pe_mac pe21(.north_in(b_reg11), .west_in(a_reg20), .accum_in(acc21), .accum_out(next_acc21));
    pe_mac pe22(.north_in(b_reg12), .west_in(a_reg21), .accum_in(acc22), .accum_out(next_acc22));
    pe_mac pe23(.north_in(b_reg13), .west_in(a_reg22), .accum_in(acc23), .accum_out(next_acc23));

    pe_mac pe30(.north_in(b_reg20), .west_in(a_west3), .accum_in(acc30), .accum_out(next_acc30));
    pe_mac pe31(.north_in(b_reg21), .west_in(a_reg30), .accum_in(acc31), .accum_out(next_acc31));
    pe_mac pe32(.north_in(b_reg22), .west_in(a_reg31), .accum_in(acc32), .accum_out(next_acc32));
    pe_mac pe33(.north_in(b_reg23), .west_in(a_reg32), .accum_in(acc33), .accum_out(next_acc33));

    pe_forward fw00(.north_in(b_north0), .west_in(a_west0), .south_out(south00), .east_out(east00));
    pe_forward fw01(.north_in(b_north1), .west_in(a_reg00), .south_out(south01), .east_out(east01));
    pe_forward fw02(.north_in(b_north2), .west_in(a_reg01), .south_out(south02), .east_out(east02));
    pe_forward fw03(.north_in(b_north3), .west_in(a_reg02), .south_out(south03), .east_out(east03));

    pe_forward fw10(.north_in(b_reg00), .west_in(a_west1), .south_out(south10), .east_out(east10));
    pe_forward fw11(.north_in(b_reg01), .west_in(a_reg10), .south_out(south11), .east_out(east11));
    pe_forward fw12(.north_in(b_reg02), .west_in(a_reg11), .south_out(south12), .east_out(east12));
    pe_forward fw13(.north_in(b_reg03), .west_in(a_reg12), .south_out(south13), .east_out(east13));

    pe_forward fw20(.north_in(b_reg10), .west_in(a_west2), .south_out(south20), .east_out(east20));
    pe_forward fw21(.north_in(b_reg11), .west_in(a_reg20), .south_out(south21), .east_out(east21));
    pe_forward fw22(.north_in(b_reg12), .west_in(a_reg21), .south_out(south22), .east_out(east22));
    pe_forward fw23(.north_in(b_reg13), .west_in(a_reg22), .south_out(south23), .east_out(east23));

    pe_forward fw30(.north_in(b_reg20), .west_in(a_west3), .south_out(south30), .east_out(east30));
    pe_forward fw31(.north_in(b_reg21), .west_in(a_reg30), .south_out(south31), .east_out(east31));
    pe_forward fw32(.north_in(b_reg22), .west_in(a_reg31), .south_out(south32), .east_out(east32));
    pe_forward fw33(.north_in(b_reg23), .west_in(a_reg32), .south_out(south33), .east_out(east33));

    done_logic done_u(.cycle_count(cycle_count), .done(done_next));

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
            a_reg00 <= 0; a_reg01 <= 0; a_reg02 <= 0; a_reg03 <= 0;
            a_reg10 <= 0; a_reg11 <= 0; a_reg12 <= 0; a_reg13 <= 0;
            a_reg20 <= 0; a_reg21 <= 0; a_reg22 <= 0; a_reg23 <= 0;
            a_reg30 <= 0; a_reg31 <= 0; a_reg32 <= 0; a_reg33 <= 0;

            b_reg00 <= 0; b_reg01 <= 0; b_reg02 <= 0; b_reg03 <= 0;
            b_reg10 <= 0; b_reg11 <= 0; b_reg12 <= 0; b_reg13 <= 0;
            b_reg20 <= 0; b_reg21 <= 0; b_reg22 <= 0; b_reg23 <= 0;
            b_reg30 <= 0; b_reg31 <= 0; b_reg32 <= 0; b_reg33 <= 0;

            acc00 <= 0; acc01 <= 0; acc02 <= 0; acc03 <= 0;
            acc10 <= 0; acc11 <= 0; acc12 <= 0; acc13 <= 0;
            acc20 <= 0; acc21 <= 0; acc22 <= 0; acc23 <= 0;
            acc30 <= 0; acc31 <= 0; acc32 <= 0; acc33 <= 0;

            cycle_count <= 0;
            done <= 0;
        end else begin
            a_reg00 <= east00; a_reg01 <= east01; a_reg02 <= east02; a_reg03 <= east03;
            a_reg10 <= east10; a_reg11 <= east11; a_reg12 <= east12; a_reg13 <= east13;
            a_reg20 <= east20; a_reg21 <= east21; a_reg22 <= east22; a_reg23 <= east23;
            a_reg30 <= east30; a_reg31 <= east31; a_reg32 <= east32; a_reg33 <= east33;

            b_reg00 <= south00; b_reg01 <= south01; b_reg02 <= south02; b_reg03 <= south03;
            b_reg10 <= south10; b_reg11 <= south11; b_reg12 <= south12; b_reg13 <= south13;
            b_reg20 <= south20; b_reg21 <= south21; b_reg22 <= south22; b_reg23 <= south23;
            b_reg30 <= south30; b_reg31 <= south31; b_reg32 <= south32; b_reg33 <= south33;

            acc00 <= next_acc00; acc01 <= next_acc01; acc02 <= next_acc02; acc03 <= next_acc03;
            acc10 <= next_acc10; acc11 <= next_acc11; acc12 <= next_acc12; acc13 <= next_acc13;
            acc20 <= next_acc20; acc21 <= next_acc21; acc22 <= next_acc22; acc23 <= next_acc23;
            acc30 <= next_acc30; acc31 <= next_acc31; acc32 <= next_acc32; acc33 <= next_acc33;

            if (cycle_count < 4'd9)
                cycle_count <= cycle_count + 4'd1;
            else
                cycle_count <= cycle_count;

            done <= done_next;
        end
    end

endmodule
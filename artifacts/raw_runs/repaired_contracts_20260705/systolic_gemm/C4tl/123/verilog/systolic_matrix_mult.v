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

    wire [31:0] east00, east01, east02, east03;
    wire [31:0] east10, east11, east12, east13;
    wire [31:0] east20, east21, east22, east23;
    wire [31:0] east30, east31, east32, east33;

    wire [31:0] south00, south01, south02, south03;
    wire [31:0] south10, south11, south12, south13;
    wire [31:0] south20, south21, south22, south23;
    wire [31:0] south30, south31, south32, south33;

    wire [63:0] prod00, prod01, prod02, prod03;
    wire [63:0] prod10, prod11, prod12, prod13;
    wire [63:0] prod20, prod21, prod22, prod23;
    wire [63:0] prod30, prod31, prod32, prod33;

    wire [63:0] next00, next01, next02, next03;
    wire [63:0] next10, next11, next12, next13;
    wire [63:0] next20, next21, next22, next23;
    wire [63:0] next30, next31, next32, next33;

    wire done_next;

    pe pe00(.north_in(b_reg00), .west_in(a_reg00), .clk(clk), .rst(rst), .south_out(south00), .east_out(east00), .result(prod00));
    pe pe01(.north_in(b_reg01), .west_in(a_reg01), .clk(clk), .rst(rst), .south_out(south01), .east_out(east01), .result(prod01));
    pe pe02(.north_in(b_reg02), .west_in(a_reg02), .clk(clk), .rst(rst), .south_out(south02), .east_out(east02), .result(prod02));
    pe pe03(.north_in(b_reg03), .west_in(a_reg03), .clk(clk), .rst(rst), .south_out(south03), .east_out(east03), .result(prod03));

    pe pe10(.north_in(b_reg10), .west_in(a_reg10), .clk(clk), .rst(rst), .south_out(south10), .east_out(east10), .result(prod10));
    pe pe11(.north_in(b_reg11), .west_in(a_reg11), .clk(clk), .rst(rst), .south_out(south11), .east_out(east11), .result(prod11));
    pe pe12(.north_in(b_reg12), .west_in(a_reg12), .clk(clk), .rst(rst), .south_out(south12), .east_out(east12), .result(prod12));
    pe pe13(.north_in(b_reg13), .west_in(a_reg13), .clk(clk), .rst(rst), .south_out(south13), .east_out(east13), .result(prod13));

    pe pe20(.north_in(b_reg20), .west_in(a_reg20), .clk(clk), .rst(rst), .south_out(south20), .east_out(east20), .result(prod20));
    pe pe21(.north_in(b_reg21), .west_in(a_reg21), .clk(clk), .rst(rst), .south_out(south21), .east_out(east21), .result(prod21));
    pe pe22(.north_in(b_reg22), .west_in(a_reg22), .clk(clk), .rst(rst), .south_out(south22), .east_out(east22), .result(prod22));
    pe pe23(.north_in(b_reg23), .west_in(a_reg23), .clk(clk), .rst(rst), .south_out(south23), .east_out(east23), .result(prod23));

    pe pe30(.north_in(b_reg30), .west_in(a_reg30), .clk(clk), .rst(rst), .south_out(south30), .east_out(east30), .result(prod30));
    pe pe31(.north_in(b_reg31), .west_in(a_reg31), .clk(clk), .rst(rst), .south_out(south31), .east_out(east31), .result(prod31));
    pe pe32(.north_in(b_reg32), .west_in(a_reg32), .clk(clk), .rst(rst), .south_out(south32), .east_out(east32), .result(prod32));
    pe pe33(.north_in(b_reg33), .west_in(a_reg33), .clk(clk), .rst(rst), .south_out(south33), .east_out(east33), .result(prod33));

    mac_accumulate mac00(.acc_in(acc00), .product(prod00), .acc_out(next00));
    mac_accumulate mac01(.acc_in(acc01), .product(prod01), .acc_out(next01));
    mac_accumulate mac02(.acc_in(acc02), .product(prod02), .acc_out(next02));
    mac_accumulate mac03(.acc_in(acc03), .product(prod03), .acc_out(next03));
    mac_accumulate mac10(.acc_in(acc10), .product(prod10), .acc_out(next10));
    mac_accumulate mac11(.acc_in(acc11), .product(prod11), .acc_out(next11));
    mac_accumulate mac12(.acc_in(acc12), .product(prod12), .acc_out(next12));
    mac_accumulate mac13(.acc_in(acc13), .product(prod13), .acc_out(next13));
    mac_accumulate mac20(.acc_in(acc20), .product(prod20), .acc_out(next20));
    mac_accumulate mac21(.acc_in(acc21), .product(prod21), .acc_out(next21));
    mac_accumulate mac22(.acc_in(acc22), .product(prod22), .acc_out(next22));
    mac_accumulate mac23(.acc_in(acc23), .product(prod23), .acc_out(next23));
    mac_accumulate mac30(.acc_in(acc30), .product(prod30), .acc_out(next30));
    mac_accumulate mac31(.acc_in(acc31), .product(prod31), .acc_out(next31));
    mac_accumulate mac32(.acc_in(acc32), .product(prod32), .acc_out(next32));
    mac_accumulate mac33(.acc_in(acc33), .product(prod33), .acc_out(next33));

    done_control done_logic(.cycle_count(cycle_count), .done(done_next));

    assign result0 = acc00;
    assign result1 = acc01;
    assign result2 = acc02;
    assign result3 = acc03;
    assign result4 = acc10;
    assign result5 = acc11;
    assign result6 = acc12;
    assign result7 = acc13;
    assign result8 = acc20;
    assign result9 = acc21;
    assign result10 = acc22;
    assign result11 = acc23;
    assign result12 = acc30;
    assign result13 = acc31;
    assign result14 = acc32;
    assign result15 = acc33;

    initial begin
        cycle_count = 4'd0;
        done = 1'b0;

        a_reg00 = 32'd0; a_reg01 = 32'd0; a_reg02 = 32'd0; a_reg03 = 32'd0;
        a_reg10 = 32'd0; a_reg11 = 32'd0; a_reg12 = 32'd0; a_reg13 = 32'd0;
        a_reg20 = 32'd0; a_reg21 = 32'd0; a_reg22 = 32'd0; a_reg23 = 32'd0;
        a_reg30 = 32'd0; a_reg31 = 32'd0; a_reg32 = 32'd0; a_reg33 = 32'd0;

        b_reg00 = 32'd0; b_reg01 = 32'd0; b_reg02 = 32'd0; b_reg03 = 32'd0;
        b_reg10 = 32'd0; b_reg11 = 32'd0; b_reg12 = 32'd0; b_reg13 = 32'd0;
        b_reg20 = 32'd0; b_reg21 = 32'd0; b_reg22 = 32'd0; b_reg23 = 32'd0;
        b_reg30 = 32'd0; b_reg31 = 32'd0; b_reg32 = 32'd0; b_reg33 = 32'd0;

        acc00 = 64'd0; acc01 = 64'd0; acc02 = 64'd0; acc03 = 64'd0;
        acc10 = 64'd0; acc11 = 64'd0; acc12 = 64'd0; acc13 = 64'd0;
        acc20 = 64'd0; acc21 = 64'd0; acc22 = 64'd0; acc23 = 64'd0;
        acc30 = 64'd0; acc31 = 64'd0; acc32 = 64'd0; acc33 = 64'd0;
    end

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;

            a_reg00 <= 32'd0; a_reg01 <= 32'd0; a_reg02 <= 32'd0; a_reg03 <= 32'd0;
            a_reg10 <= 32'd0; a_reg11 <= 32'd0; a_reg12 <= 32'd0; a_reg13 <= 32'd0;
            a_reg20 <= 32'd0; a_reg21 <= 32'd0; a_reg22 <= 32'd0; a_reg23 <= 32'd0;
            a_reg30 <= 32'd0; a_reg31 <= 32'd0; a_reg32 <= 32'd0; a_reg33 <= 32'd0;

            b_reg00 <= 32'd0; b_reg01 <= 32'd0; b_reg02 <= 32'd0; b_reg03 <= 32'd0;
            b_reg10 <= 32'd0; b_reg11 <= 32'd0; b_reg12 <= 32'd0; b_reg13 <= 32'd0;
            b_reg20 <= 32'd0; b_reg21 <= 32'd0; b_reg22 <= 32'd0; b_reg23 <= 32'd0;
            b_reg30 <= 32'd0; b_reg31 <= 32'd0; b_reg32 <= 32'd0; b_reg33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;
        end else begin
            if (cycle_count != 4'd9)
                cycle_count <= cycle_count + 4'd1;
            done <= done_next;

            acc00 <= next00; acc01 <= next01; acc02 <= next02; acc03 <= next03;
            acc10 <= next10; acc11 <= next11; acc12 <= next12; acc13 <= next13;
            acc20 <= next20; acc21 <= next21; acc22 <= next22; acc23 <= next23;
            acc30 <= next30; acc31 <= next31; acc32 <= next32; acc33 <= next33;

            a_reg00 <= a_west0; a_reg01 <= east00; a_reg02 <= east01; a_reg03 <= east02;
            a_reg10 <= a_west1; a_reg11 <= east10; a_reg12 <= east11; a_reg13 <= east12;
            a_reg20 <= a_west2; a_reg21 <= east20; a_reg22 <= east21; a_reg23 <= east22;
            a_reg30 <= a_west3; a_reg31 <= east30; a_reg32 <= east31; a_reg33 <= east32;

            b_reg00 <= b_north0; b_reg01 <= b_north1; b_reg02 <= b_north2; b_reg03 <= b_north3;
            b_reg10 <= south00; b_reg11 <= south01; b_reg12 <= south02; b_reg13 <= south03;
            b_reg20 <= south10; b_reg21 <= south11; b_reg22 <= south12; b_reg23 <= south13;
            b_reg30 <= south20; b_reg31 <= south21; b_reg32 <= south22; b_reg33 <= south23;
        end
    end

endmodule
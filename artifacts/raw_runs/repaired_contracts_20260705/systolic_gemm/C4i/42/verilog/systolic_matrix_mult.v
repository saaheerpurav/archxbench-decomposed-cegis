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

    reg [31:0] east00, east01, east02, east03;
    reg [31:0] east10, east11, east12, east13;
    reg [31:0] east20, east21, east22, east23;
    reg [31:0] east30, east31, east32, east33;

    reg [31:0] south00, south01, south02, south03;
    reg [31:0] south10, south11, south12, south13;
    reg [31:0] south20, south21, south22, south23;
    reg [31:0] south30, south31, south32, south33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    wire [31:0] n00, n01, n02, n03;
    wire [31:0] n10, n11, n12, n13;
    wire [31:0] n20, n21, n22, n23;
    wire [31:0] n30, n31, n32, n33;

    wire [31:0] w00, w01, w02, w03;
    wire [31:0] w10, w11, w12, w13;
    wire [31:0] w20, w21, w22, w23;
    wire [31:0] w30, w31, w32, w33;

    wire [31:0] so00, so01, so02, so03;
    wire [31:0] so10, so11, so12, so13;
    wire [31:0] so20, so21, so22, so23;
    wire [31:0] so30, so31, so32, so33;

    wire [31:0] eo00, eo01, eo02, eo03;
    wire [31:0] eo10, eo11, eo12, eo13;
    wire [31:0] eo20, eo21, eo22, eo23;
    wire [31:0] eo30, eo31, eo32, eo33;

    wire [63:0] next00, next01, next02, next03;
    wire [63:0] next10, next11, next12, next13;
    wire [63:0] next20, next21, next22, next23;
    wire [63:0] next30, next31, next32, next33;
    wire next_done;

    assign n00 = b_north0; assign n01 = b_north1; assign n02 = b_north2; assign n03 = b_north3;
    assign n10 = south00;  assign n11 = south01;  assign n12 = south02;  assign n13 = south03;
    assign n20 = south10;  assign n21 = south11;  assign n22 = south12;  assign n23 = south13;
    assign n30 = south20;  assign n31 = south21;  assign n32 = south22;  assign n33 = south23;

    assign w00 = a_west0; assign w01 = east00; assign w02 = east01; assign w03 = east02;
    assign w10 = a_west1; assign w11 = east10; assign w12 = east11; assign w13 = east12;
    assign w20 = a_west2; assign w21 = east20; assign w22 = east21; assign w23 = east22;
    assign w30 = a_west3; assign w31 = east30; assign w32 = east31; assign w33 = east32;

    pe_cell_comb pe00(n00, w00, acc00, so00, eo00, next00);
    pe_cell_comb pe01(n01, w01, acc01, so01, eo01, next01);
    pe_cell_comb pe02(n02, w02, acc02, so02, eo02, next02);
    pe_cell_comb pe03(n03, w03, acc03, so03, eo03, next03);

    pe_cell_comb pe10(n10, w10, acc10, so10, eo10, next10);
    pe_cell_comb pe11(n11, w11, acc11, so11, eo11, next11);
    pe_cell_comb pe12(n12, w12, acc12, so12, eo12, next12);
    pe_cell_comb pe13(n13, w13, acc13, so13, eo13, next13);

    pe_cell_comb pe20(n20, w20, acc20, so20, eo20, next20);
    pe_cell_comb pe21(n21, w21, acc21, so21, eo21, next21);
    pe_cell_comb pe22(n22, w22, acc22, so22, eo22, next22);
    pe_cell_comb pe23(n23, w23, acc23, so23, eo23, next23);

    pe_cell_comb pe30(n30, w30, acc30, so30, eo30, next30);
    pe_cell_comb pe31(n31, w31, acc31, so31, eo31, next31);
    pe_cell_comb pe32(n32, w32, acc32, so32, eo32, next32);
    pe_cell_comb pe33(n33, w33, acc33, so33, eo33, next33);

    done_logic done_unit(cycle_count, next_done);

    assign result0  = acc00; assign result1  = acc01; assign result2  = acc02; assign result3  = acc03;
    assign result4  = acc10; assign result5  = acc11; assign result6  = acc12; assign result7  = acc13;
    assign result8  = acc20; assign result9  = acc21; assign result10 = acc22; assign result11 = acc23;
    assign result12 = acc30; assign result13 = acc31; assign result14 = acc32; assign result15 = acc33;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 4'd0;
            done <= 1'b0;

            east00 <= 32'd0; east01 <= 32'd0; east02 <= 32'd0; east03 <= 32'd0;
            east10 <= 32'd0; east11 <= 32'd0; east12 <= 32'd0; east13 <= 32'd0;
            east20 <= 32'd0; east21 <= 32'd0; east22 <= 32'd0; east23 <= 32'd0;
            east30 <= 32'd0; east31 <= 32'd0; east32 <= 32'd0; east33 <= 32'd0;

            south00 <= 32'd0; south01 <= 32'd0; south02 <= 32'd0; south03 <= 32'd0;
            south10 <= 32'd0; south11 <= 32'd0; south12 <= 32'd0; south13 <= 32'd0;
            south20 <= 32'd0; south21 <= 32'd0; south22 <= 32'd0; south23 <= 32'd0;
            south30 <= 32'd0; south31 <= 32'd0; south32 <= 32'd0; south33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;
        end else begin
            if (cycle_count != 4'd15)
                cycle_count <= cycle_count + 4'd1;
            done <= next_done;

            east00 <= eo00; east01 <= eo01; east02 <= eo02; east03 <= eo03;
            east10 <= eo10; east11 <= eo11; east12 <= eo12; east13 <= eo13;
            east20 <= eo20; east21 <= eo21; east22 <= eo22; east23 <= eo23;
            east30 <= eo30; east31 <= eo31; east32 <= eo32; east33 <= eo33;

            south00 <= so00; south01 <= so01; south02 <= so02; south03 <= so03;
            south10 <= so10; south11 <= so11; south12 <= so12; south13 <= so13;
            south20 <= so20; south21 <= so21; south22 <= so22; south23 <= so23;
            south30 <= so30; south31 <= so31; south32 <= so32; south33 <= so33;

            acc00 <= next00; acc01 <= next01; acc02 <= next02; acc03 <= next03;
            acc10 <= next10; acc11 <= next11; acc12 <= next12; acc13 <= next13;
            acc20 <= next20; acc21 <= next21; acc22 <= next22; acc23 <= next23;
            acc30 <= next30; acc31 <= next31; acc32 <= next32; acc33 <= next33;
        end
    end

endmodule
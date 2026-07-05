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

    reg [31:0] east_reg00, east_reg01, east_reg02, east_reg03;
    reg [31:0] east_reg10, east_reg11, east_reg12, east_reg13;
    reg [31:0] east_reg20, east_reg21, east_reg22, east_reg23;
    reg [31:0] east_reg30, east_reg31, east_reg32, east_reg33;

    reg [31:0] south_reg00, south_reg01, south_reg02, south_reg03;
    reg [31:0] south_reg10, south_reg11, south_reg12, south_reg13;
    reg [31:0] south_reg20, south_reg21, south_reg22, south_reg23;
    reg [31:0] south_reg30, south_reg31, south_reg32, south_reg33;

    reg [63:0] acc00, acc01, acc02, acc03;
    reg [63:0] acc10, acc11, acc12, acc13;
    reg [63:0] acc20, acc21, acc22, acc23;
    reg [63:0] acc30, acc31, acc32, acc33;

    reg [3:0] cycle_count;

    wire [31:0] east_next00, east_next01, east_next02, east_next03;
    wire [31:0] east_next10, east_next11, east_next12, east_next13;
    wire [31:0] east_next20, east_next21, east_next22, east_next23;
    wire [31:0] east_next30, east_next31, east_next32, east_next33;

    wire [31:0] south_next00, south_next01, south_next02, south_next03;
    wire [31:0] south_next10, south_next11, south_next12, south_next13;
    wire [31:0] south_next20, south_next21, south_next22, south_next23;
    wire [31:0] south_next30, south_next31, south_next32, south_next33;

    wire [63:0] prod00, prod01, prod02, prod03;
    wire [63:0] prod10, prod11, prod12, prod13;
    wire [63:0] prod20, prod21, prod22, prod23;
    wire [63:0] prod30, prod31, prod32, prod33;

    wire [63:0] sum00, sum01, sum02, sum03;
    wire [63:0] sum10, sum11, sum12, sum13;
    wire [63:0] sum20, sum21, sum22, sum23;
    wire [63:0] sum30, sum31, sum32, sum33;

    pe_forward fw00(a_west0, b_north0, east_next00, south_next00);
    pe_forward fw01(east_reg00, b_north1, east_next01, south_next01);
    pe_forward fw02(east_reg01, b_north2, east_next02, south_next02);
    pe_forward fw03(east_reg02, b_north3, east_next03, south_next03);

    pe_forward fw10(a_west1, south_reg00, east_next10, south_next10);
    pe_forward fw11(east_reg10, south_reg01, east_next11, south_next11);
    pe_forward fw12(east_reg11, south_reg02, east_next12, south_next12);
    pe_forward fw13(east_reg12, south_reg03, east_next13, south_next13);

    pe_forward fw20(a_west2, south_reg10, east_next20, south_next20);
    pe_forward fw21(east_reg20, south_reg11, east_next21, south_next21);
    pe_forward fw22(east_reg21, south_reg12, east_next22, south_next22);
    pe_forward fw23(east_reg22, south_reg13, east_next23, south_next23);

    pe_forward fw30(a_west3, south_reg20, east_next30, south_next30);
    pe_forward fw31(east_reg30, south_reg21, east_next31, south_next31);
    pe_forward fw32(east_reg31, south_reg22, east_next32, south_next32);
    pe_forward fw33(east_reg32, south_reg23, east_next33, south_next33);

    pe_product mul00(a_west0, b_north0, prod00);
    pe_product mul01(east_reg00, b_north1, prod01);
    pe_product mul02(east_reg01, b_north2, prod02);
    pe_product mul03(east_reg02, b_north3, prod03);

    pe_product mul10(a_west1, south_reg00, prod10);
    pe_product mul11(east_reg10, south_reg01, prod11);
    pe_product mul12(east_reg11, south_reg02, prod12);
    pe_product mul13(east_reg12, south_reg03, prod13);

    pe_product mul20(a_west2, south_reg10, prod20);
    pe_product mul21(east_reg20, south_reg11, prod21);
    pe_product mul22(east_reg21, south_reg12, prod22);
    pe_product mul23(east_reg22, south_reg13, prod23);

    pe_product mul30(a_west3, south_reg20, prod30);
    pe_product mul31(east_reg30, south_reg21, prod31);
    pe_product mul32(east_reg31, south_reg22, prod32);
    pe_product mul33(east_reg32, south_reg23, prod33);

    pe_accumulate add00(acc00, prod00, sum00);
    pe_accumulate add01(acc01, prod01, sum01);
    pe_accumulate add02(acc02, prod02, sum02);
    pe_accumulate add03(acc03, prod03, sum03);

    pe_accumulate add10(acc10, prod10, sum10);
    pe_accumulate add11(acc11, prod11, sum11);
    pe_accumulate add12(acc12, prod12, sum12);
    pe_accumulate add13(acc13, prod13, sum13);

    pe_accumulate add20(acc20, prod20, sum20);
    pe_accumulate add21(acc21, prod21, sum21);
    pe_accumulate add22(acc22, prod22, sum22);
    pe_accumulate add23(acc23, prod23, sum23);

    pe_accumulate add30(acc30, prod30, sum30);
    pe_accumulate add31(acc31, prod31, sum31);
    pe_accumulate add32(acc32, prod32, sum32);
    pe_accumulate add33(acc33, prod33, sum33);

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
            east_reg00 <= 32'd0; east_reg01 <= 32'd0; east_reg02 <= 32'd0; east_reg03 <= 32'd0;
            east_reg10 <= 32'd0; east_reg11 <= 32'd0; east_reg12 <= 32'd0; east_reg13 <= 32'd0;
            east_reg20 <= 32'd0; east_reg21 <= 32'd0; east_reg22 <= 32'd0; east_reg23 <= 32'd0;
            east_reg30 <= 32'd0; east_reg31 <= 32'd0; east_reg32 <= 32'd0; east_reg33 <= 32'd0;

            south_reg00 <= 32'd0; south_reg01 <= 32'd0; south_reg02 <= 32'd0; south_reg03 <= 32'd0;
            south_reg10 <= 32'd0; south_reg11 <= 32'd0; south_reg12 <= 32'd0; south_reg13 <= 32'd0;
            south_reg20 <= 32'd0; south_reg21 <= 32'd0; south_reg22 <= 32'd0; south_reg23 <= 32'd0;
            south_reg30 <= 32'd0; south_reg31 <= 32'd0; south_reg32 <= 32'd0; south_reg33 <= 32'd0;

            acc00 <= 64'd0; acc01 <= 64'd0; acc02 <= 64'd0; acc03 <= 64'd0;
            acc10 <= 64'd0; acc11 <= 64'd0; acc12 <= 64'd0; acc13 <= 64'd0;
            acc20 <= 64'd0; acc21 <= 64'd0; acc22 <= 64'd0; acc23 <= 64'd0;
            acc30 <= 64'd0; acc31 <= 64'd0; acc32 <= 64'd0; acc33 <= 64'd0;

            cycle_count <= 4'd0;
            done <= 1'b0;
        end else begin
            east_reg00 <= east_next00; east_reg01 <= east_next01; east_reg02 <= east_next02; east_reg03 <= east_next03;
            east_reg10 <= east_next10; east_reg11 <= east_next11; east_reg12 <= east_next12; east_reg13 <= east_next13;
            east_reg20 <= east_next20; east_reg21 <= east_next21; east_reg22 <= east_next22; east_reg23 <= east_next23;
            east_reg30 <= east_next30; east_reg31 <= east_next31; east_reg32 <= east_next32; east_reg33 <= east_next33;

            south_reg00 <= south_next00; south_reg01 <= south_next01; south_reg02 <= south_next02; south_reg03 <= south_next03;
            south_reg10 <= south_next10; south_reg11 <= south_next11; south_reg12 <= south_next12; south_reg13 <= south_next13;
            south_reg20 <= south_next20; south_reg21 <= south_next21; south_reg22 <= south_next22; south_reg23 <= south_next23;
            south_reg30 <= south_next30; south_reg31 <= south_next31; south_reg32 <= south_next32; south_reg33 <= south_next33;

            acc00 <= sum00; acc01 <= sum01; acc02 <= sum02; acc03 <= sum03;
            acc10 <= sum10; acc11 <= sum11; acc12 <= sum12; acc13 <= sum13;
            acc20 <= sum20; acc21 <= sum21; acc22 <= sum22; acc23 <= sum23;
            acc30 <= sum30; acc31 <= sum31; acc32 <= sum32; acc33 <= sum33;

            if (cycle_count < 4'd8) begin
                cycle_count <= cycle_count + 4'd1;
                done <= 1'b0;
            end else begin
                cycle_count <= cycle_count;
                done <= 1'b1;
            end
        end
    end

endmodule